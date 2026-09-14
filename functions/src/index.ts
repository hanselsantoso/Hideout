import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {defineSecret} from "firebase-functions/params";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import QRCode from "qrcode";

admin.initializeApp();
setGlobalOptions({region: "asia-southeast1", maxInstances: 20, invoker: "public"});

const db = admin.firestore();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;
const xenditSecretKey = defineSecret("XENDIT_SECRET_KEY");
const xenditWebhookToken = defineSecret("XENDIT_WEBHOOK_TOKEN");
const xenditApiBase = "https://api.xendit.co";
const defaultAppBaseUrl = "https://turney.id";

type XenditSession = {
  payment_session_id?: string;
  reference_id?: string;
  status?: string;
  payment_link_url?: string | null;
  payment_id?: string | null;
  payment_request_id?: string | null;
  payment_token_id?: string | null;
  amount?: number;
  currency?: string;
  country?: string;
  metadata?: Record<string, unknown> | null;
};

type XenditQrCode = {
  id?: string;
  reference_id?: string;
  external_id?: string;
  qr_string?: string;
  status?: string;
  amount?: number;
  currency?: string;
  channel_code?: string;
  metadata?: Record<string, unknown> | null;
};

type XenditQrPayment = {
  id?: string;
  reference_id?: string;
  external_id?: string;
  qr_id?: string;
  qr_string?: string;
  qr_code?: {
    id?: string;
    reference_id?: string;
    external_id?: string;
    qr_string?: string;
    type?: string;
    metadata?: Record<string, unknown> | null;
  } | null;
  status?: string;
  amount?: number;
  currency?: string;
  payment_detail?: Record<string, unknown> | null;
  created?: string;
};

type PaymentTarget = {
  tournamentId: string;
  registrationId: string;
};

type PublicPaymentSession = {
  paymentSessionId: string;
  paymentLinkUrl: string | null;
  status: string;
  paid: boolean;
  expired: boolean;
  paymentId: string | null;
  paymentRequestId: string | null;
  paymentMode?: "checkout" | "qris" | "free";
  qrisReferenceId?: string | null;
  qrisQrId?: string | null;
  qrisQrString?: string | null;
  qrisQrImageDataUrl?: string | null;
  message?: string;
};

function requireAuth(uid?: string): string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in before paying.");
  }
  return uid;
}

function requireString(data: unknown, key: string): string {
  if (!data || typeof data !== "object") {
    throw new HttpsError("invalid-argument", "Missing request body.");
  }
  const value = (data as Record<string, unknown>)[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `Missing ${key}.`);
  }
  return value.trim();
}

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" ? value : fallback;
}

function asPositiveInt(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, Math.round(value));
  }
  return 0;
}

function truncate(value: string, max: number): string {
  return value.length <= max ? value : value.slice(0, max);
}

function alphanumeric(value: string): string {
  return value.replace(/[^a-zA-Z0-9]/g, "");
}

function normalizeHttpsBaseUrl(raw: unknown): string {
  if (typeof raw !== "string" || raw.trim().length === 0) {
    return process.env.APP_BASE_URL || defaultAppBaseUrl;
  }
  try {
    const parsed = new URL(raw.trim());
    if (parsed.protocol !== "https:") {
      return process.env.APP_BASE_URL || defaultAppBaseUrl;
    }
    return parsed.origin;
  } catch (_) {
    return process.env.APP_BASE_URL || defaultAppBaseUrl;
  }
}

function makeReferenceId(registrationId: string): string {
  const compactRegistration = alphanumeric(registrationId).slice(0, 14);
  const compactTime = Date.now().toString(36);
  return truncate(`turney${compactRegistration}${compactTime}`, 64);
}

function sessionStatus(session: XenditSession): string {
  return asString(session.status, "ACTIVE").toUpperCase();
}

function isPaidSession(session: XenditSession): boolean {
  return sessionStatus(session) === "COMPLETED";
}

function isExpiredSession(session: XenditSession): boolean {
  const status = sessionStatus(session);
  return status === "EXPIRED" || status === "CANCELED";
}

function publicSession(session: XenditSession, message?: string): PublicPaymentSession {
  const result: PublicPaymentSession = {
    paymentSessionId: asString(session.payment_session_id),
    paymentLinkUrl: session.payment_link_url ?? null,
    status: sessionStatus(session),
    paid: isPaidSession(session),
    expired: isExpiredSession(session),
    paymentId: session.payment_id ?? null,
    paymentRequestId: session.payment_request_id ?? null,
  };
  if (message) {
    result.message = message;
  }
  return result;
}

function xenditAuthHeader(): string {
  const secret = xenditSecretKey.value();
  if (!secret) {
    throw new HttpsError(
      "failed-precondition",
      "Xendit secret is not configured.",
    );
  }
  return `Basic ${Buffer.from(`${secret}:`).toString("base64")}`;
}

async function xenditRequest<T>(
  method: "GET" | "POST",
  path: string,
  body?: Record<string, unknown>,
  extraHeaders: Record<string, string> = {},
): Promise<T> {
  const response = await fetch(`${xenditApiBase}${path}`, {
    method,
    headers: {
      Authorization: xenditAuthHeader(),
      "Content-Type": "application/json",
      ...extraHeaders,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let payload: unknown = {};
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch (_) {
      payload = {message: text};
    }
  }
  if (!response.ok) {
    logger.error("Xendit request failed", {
      method,
      path,
      status: response.status,
      payload,
    });
    const errorPayload = payload as Record<string, unknown>;
    const message = asString(errorPayload.message, "Xendit request failed.");
    throw new HttpsError("internal", message);
  }
  return payload as T;
}

async function qrisDataUrl(qrString: string): Promise<string> {
  return QRCode.toDataURL(qrString, {
    errorCorrectionLevel: "M",
    margin: 1,
    width: 420,
  });
}

async function lookupQrisPayments(
  referenceId: string,
  qrId: string,
): Promise<XenditQrPayment[]> {
  const headers = {"api-version": "2022-07-31"};
  const paths = [
    `/qr_codes/payments?external_id=${encodeURIComponent(referenceId)}&limit=10`,
    `/qr_codes/payments?reference_id=${encodeURIComponent(referenceId)}&limit=10`,
    `/qr_codes/${encodeURIComponent(qrId)}/payments`,
  ];
  for (const path of paths) {
    try {
      const payments = await xenditRequest<XenditQrPayment[]>("GET", path, undefined, headers);
      if (payments.length > 0) {
        return payments;
      }
    } catch (error) {
      logger.warn("Xendit QRIS payment lookup failed", {referenceId, qrId, path, error});
    }
  }
  return [];
}

async function resolveQrisTarget(payment: XenditQrPayment): Promise<PaymentTarget | null> {
  const referenceId =
    asString(payment.reference_id) ||
    asString(payment.external_id) ||
    asString(payment.qr_code?.reference_id) ||
    asString(payment.qr_code?.external_id);
  const qrId = asString(payment.qr_id) || asString(payment.qr_code?.id);
  let query: admin.firestore.Query<admin.firestore.DocumentData> | null = null;
  if (referenceId) {
    query = db
      .collectionGroup("registrations")
      .where("xenditQrisReferenceId", "==", referenceId)
      .limit(1);
  } else if (qrId) {
    query = db
      .collectionGroup("registrations")
      .where("xenditQrisId", "==", qrId)
      .limit(1);
  }
  if (!query) {
    return null;
  }
  const snapshot = await query.get();
  const registrationDoc = snapshot.docs[0];
  const tournamentDoc = registrationDoc?.ref.parent.parent;
  if (!registrationDoc || !tournamentDoc) {
    return null;
  }
  return {tournamentId: tournamentDoc.id, registrationId: registrationDoc.id};
}

function qrisFromPayment(
  payment: XenditQrPayment,
  registration: admin.firestore.DocumentData,
): XenditQrCode {
  return {
    id:
      asString(payment.qr_id) ||
      asString(payment.qr_code?.id) ||
      asString(registration.xenditQrisId),
    reference_id:
      asString(payment.reference_id) ||
      asString(payment.external_id) ||
      asString(payment.qr_code?.reference_id) ||
      asString(payment.qr_code?.external_id) ||
      asString(registration.xenditQrisReferenceId),
    qr_string:
      asString(payment.qr_string) ||
      asString(payment.qr_code?.qr_string) ||
      asString(registration.xenditQrisQrString),
    status: asString(payment.status, "COMPLETED"),
    amount:
      asPositiveInt(payment.amount) ||
      asPositiveInt(registration.userPayableAmount),
    currency: payment.currency ?? "IDR",
  };
}

async function getUserRoles(uid: string): Promise<Set<string>> {
  const snap = await db.doc(`users/${uid}`).get();
  const data = snap.data() ?? {};
  const roles = new Set<string>();
  const role = data.role;
  if (typeof role === "string") {
    roles.add(role);
  }
  if (Array.isArray(data.roles)) {
    for (const value of data.roles) {
      if (typeof value === "string") {
        roles.add(value);
      }
    }
  }
  return roles;
}

function hasAdminRole(roles: Set<string>): boolean {
  return roles.has("admin") || roles.has("super_admin") || roles.has("superAdmin");
}

async function assertCanViewPayment(
  uid: string,
  target: PaymentTarget,
): Promise<void> {
  const [registrationSnap, tournamentSnap, roles] = await Promise.all([
    db.doc(`tournaments/${target.tournamentId}/registrations/${target.registrationId}`).get(),
    db.doc(`tournaments/${target.tournamentId}`).get(),
    getUserRoles(uid),
  ]);
  if (!registrationSnap.exists) {
    throw new HttpsError("not-found", "Registration was not found.");
  }
  const registration = registrationSnap.data() ?? {};
  const tournament = tournamentSnap.data() ?? {};
  const ownsRegistration = registration.playerId === uid;
  const ownsTournament = tournament.organizerId === uid;
  if (!ownsRegistration && !ownsTournament && !hasAdminRole(roles)) {
    throw new HttpsError("permission-denied", "You cannot view this payment.");
  }
}

function paymentTargetFromSession(session: XenditSession): PaymentTarget | null {
  const metadata = session.metadata ?? {};
  const tournamentId = asString(metadata.tournamentId);
  const registrationId = asString(metadata.registrationId);
  if (tournamentId && registrationId) {
    return {tournamentId, registrationId};
  }
  return null;
}

async function resolvePaymentTarget(session: XenditSession): Promise<PaymentTarget | null> {
  const fromMetadata = paymentTargetFromSession(session);
  if (fromMetadata) {
    return fromMetadata;
  }
  const sessionId = asString(session.payment_session_id);
  if (!sessionId) {
    return null;
  }
  const snap = await db
    .collectionGroup("payments")
    .where("xenditPaymentSessionId", "==", sessionId)
    .limit(1)
    .get();
  if (snap.empty) {
    return null;
  }
  const payment = snap.docs[0];
  const tournamentRef = payment.ref.parent.parent;
  const registrationId = asString(payment.data().registrationId);
  if (!tournamentRef || !registrationId) {
    return null;
  }
  return {tournamentId: tournamentRef.id, registrationId};
}

async function writePaymentSessionState(
  target: PaymentTarget,
  session: XenditSession,
  source: string,
): Promise<PublicPaymentSession> {
  const sessionId = asString(session.payment_session_id);
  if (!sessionId) {
    throw new HttpsError("internal", "Xendit did not return a payment session id.");
  }
  const registrationRef = db.doc(
    `tournaments/${target.tournamentId}/registrations/${target.registrationId}`,
  );
  const tournamentRef = db.doc(`tournaments/${target.tournamentId}`);
  const paymentRef = db.doc(`tournaments/${target.tournamentId}/payments/${sessionId}`);
  const status = sessionStatus(session);
  const paid = isPaidSession(session);
  const expired = isExpiredSession(session);

  await db.runTransaction(async (tx) => {
    const registrationSnap = await tx.get(registrationRef);
    if (!registrationSnap.exists) {
      throw new HttpsError("not-found", "Registration was not found.");
    }
    const registration = registrationSnap.data() ?? {};
    const wasReady =
      registration.paymentStatus === "paid" &&
      registration.registrationStatus === "active";
    const alreadyPaid = registration.paymentStatus === "paid";
    const baseRegistrationUpdate: admin.firestore.UpdateData<Record<string, unknown>> = {
      paymentProvider: registration.paymentProvider ?? "xendit",
      xenditPaymentSessionId: sessionId,
      xenditPaymentLinkUrl: session.payment_link_url ?? registration.xenditPaymentLinkUrl ?? null,
      xenditReferenceId: session.reference_id ?? registration.xenditReferenceId ?? null,
      xenditSessionStatus: status,
      xenditPaymentId: session.payment_id ?? registration.xenditPaymentId ?? null,
      xenditPaymentRequestId:
        session.payment_request_id ?? registration.xenditPaymentRequestId ?? null,
      paymentUpdatedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    const paymentDoc = {
      id: sessionId,
      tournamentId: target.tournamentId,
      registrationId: target.registrationId,
      playerId: asString(registration.playerId),
      playerName: asString(registration.playerName, "Player"),
      provider: "xendit",
      xenditPaymentSessionId: sessionId,
      xenditPaymentLinkUrl: session.payment_link_url ?? null,
      xenditReferenceId: session.reference_id ?? null,
      xenditPaymentId: session.payment_id ?? null,
      xenditPaymentRequestId: session.payment_request_id ?? null,
      xenditPaymentTokenId: session.payment_token_id ?? null,
      xenditStatus: status,
      currency: session.currency ?? "IDR",
      grossAmount:
        asPositiveInt(session.amount) ||
        asPositiveInt(registration.userPayableAmount),
      adminNetAmount: asPositiveInt(registration.adminNetAmount),
      platformFeeAmount: asPositiveInt(registration.platformFeeAmount),
      paymentGatewayFeeAmount: asPositiveInt(registration.paymentGatewayFeeAmount),
      status: paid ? "paid" : expired ? "expired" : "processing",
      source,
      updatedAt: serverTimestamp(),
    };

    if (paid) {
      tx.set(
        registrationRef,
        {
          ...baseRegistrationUpdate,
          paymentStatus: "paid",
          registrationStatus: "active",
          paymentId: sessionId,
          paidAt: registration.paidAt ?? serverTimestamp(),
          activatedAt: registration.activatedAt ?? serverTimestamp(),
        },
        {merge: true},
      );
      tx.set(
        paymentRef,
        {
          ...paymentDoc,
          paidAt: serverTimestamp(),
        },
        {merge: true},
      );
      if (!wasReady) {
        tx.set(
          tournamentRef,
          {
            currentParticipantCount: admin.firestore.FieldValue.increment(1),
            updatedAt: serverTimestamp(),
          },
          {merge: true},
        );
      }
      return;
    }

    if (expired && !alreadyPaid) {
      tx.set(
        registrationRef,
        {
          ...baseRegistrationUpdate,
          paymentStatus: "expired",
          registrationStatus: "paymentExpired",
          paymentId: sessionId,
          expiredAt: serverTimestamp(),
        },
        {merge: true},
      );
      tx.set(
        paymentRef,
        {
          ...paymentDoc,
          expiredAt: serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    if (!alreadyPaid) {
      tx.set(
        registrationRef,
        {
          ...baseRegistrationUpdate,
          paymentStatus: "processing",
          registrationStatus: "pendingPayment",
          paymentId: sessionId,
        },
        {merge: true},
      );
    }
    tx.set(
      paymentRef,
      {
        ...paymentDoc,
        createdAt: registration.xenditPaymentSessionId === sessionId ?
          registration.paymentCreatedAt ?? serverTimestamp() :
          serverTimestamp(),
      },
      {merge: true},
    );
  });

  return publicSession(session);
}

async function writeQrisState(
  target: PaymentTarget,
  qr: XenditQrCode,
  source: string,
  paidPayment?: XenditQrPayment,
): Promise<PublicPaymentSession> {
  const referenceId = asString(qr.reference_id || qr.external_id);
  const qrId = asString(qr.id);
  const qrString = asString(qr.qr_string);
  if (!referenceId || !qrId || !qrString) {
    throw new HttpsError("internal", "Xendit did not return a QRIS code.");
  }
  const registrationRef = db.doc(
    `tournaments/${target.tournamentId}/registrations/${target.registrationId}`,
  );
  const tournamentRef = db.doc(`tournaments/${target.tournamentId}`);
  const paymentRef = db.doc(`tournaments/${target.tournamentId}/payments/${qrId}`);
  const paidStatus = asString(paidPayment?.status).toUpperCase();
  const paid = paidStatus === "SUCCEEDED" || paidStatus === "COMPLETED";
  const status = paid ? "COMPLETED" : asString(qr.status, "ACTIVE").toUpperCase();
  const imageDataUrl = await qrisDataUrl(qrString);

  await db.runTransaction(async (tx) => {
    const registrationSnap = await tx.get(registrationRef);
    if (!registrationSnap.exists) {
      throw new HttpsError("not-found", "Registration was not found.");
    }
    const registration = registrationSnap.data() ?? {};
    const wasReady =
      registration.paymentStatus === "paid" &&
      registration.registrationStatus === "active";
    const paymentDoc = {
      id: qrId,
      tournamentId: target.tournamentId,
      registrationId: target.registrationId,
      playerId: asString(registration.playerId),
      playerName: asString(registration.playerName, "Player"),
      provider: "xendit_qris",
      xenditQrisId: qrId,
      xenditQrisReferenceId: referenceId,
      xenditQrisStatus: status,
      xenditQrisPaymentId: asString(paidPayment?.id) || null,
      currency: qr.currency ?? paidPayment?.currency ?? "IDR",
      grossAmount:
        asPositiveInt(qr.amount) ||
        asPositiveInt(paidPayment?.amount) ||
        asPositiveInt(registration.userPayableAmount),
      adminNetAmount: asPositiveInt(registration.adminNetAmount),
      platformFeeAmount: asPositiveInt(registration.platformFeeAmount),
      paymentGatewayFeeAmount: asPositiveInt(registration.paymentGatewayFeeAmount),
      status: paid ? "paid" : "processing",
      source,
      updatedAt: serverTimestamp(),
    };

    tx.set(
      registrationRef,
      {
        paymentProvider: "xendit_qris",
        xenditQrisId: qrId,
        xenditQrisReferenceId: referenceId,
        xenditQrisQrString: qrString,
        xenditQrisStatus: status,
        paymentUpdatedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        ...(paid ?
          {
            paymentStatus: "paid",
            registrationStatus: "active",
            paymentId: asString(paidPayment?.id) || qrId,
            paidAt: registration.paidAt ?? serverTimestamp(),
            activatedAt: registration.activatedAt ?? serverTimestamp(),
          } :
          {
            paymentStatus: "processing",
            registrationStatus: "pendingPayment",
            paymentId: qrId,
          }),
      },
      {merge: true},
    );
    tx.set(
      paymentRef,
      {
        ...paymentDoc,
        ...(paid ? {paidAt: serverTimestamp()} : {createdAt: serverTimestamp()}),
      },
      {merge: true},
    );
    if (paid && !wasReady) {
      tx.set(
        tournamentRef,
        {
          currentParticipantCount: admin.firestore.FieldValue.increment(1),
          updatedAt: serverTimestamp(),
        },
        {merge: true},
      );
    }
  });

  return {
    paymentSessionId: qrId,
    paymentLinkUrl: null,
    status,
    paid,
    expired: false,
    paymentId: paid ? asString(paidPayment?.id) || qrId : qrId,
    paymentRequestId: null,
    paymentMode: "qris",
    qrisReferenceId: referenceId,
    qrisQrId: qrId,
    qrisQrString: qrString,
    qrisQrImageDataUrl: imageDataUrl,
    message: paid ? "QRIS payment received." : "Scan this QRIS code to pay.",
  };
}

async function activateFreeRegistration(target: PaymentTarget): Promise<PublicPaymentSession> {
  const registrationRef = db.doc(
    `tournaments/${target.tournamentId}/registrations/${target.registrationId}`,
  );
  const tournamentRef = db.doc(`tournaments/${target.tournamentId}`);
  await db.runTransaction(async (tx) => {
    const registrationSnap = await tx.get(registrationRef);
    if (!registrationSnap.exists) {
      throw new HttpsError("not-found", "Registration was not found.");
    }
    const registration = registrationSnap.data() ?? {};
    const wasReady =
      registration.paymentStatus === "paid" &&
      registration.registrationStatus === "active";
    tx.set(
      registrationRef,
      {
        paymentProvider: "free",
        paymentStatus: "paid",
        registrationStatus: "active",
        paymentId: `FREE-${target.registrationId}`,
        paidAt: registration.paidAt ?? serverTimestamp(),
        activatedAt: registration.activatedAt ?? serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      {merge: true},
    );
    if (!wasReady) {
      tx.set(
        tournamentRef,
        {
          currentParticipantCount: admin.firestore.FieldValue.increment(1),
          updatedAt: serverTimestamp(),
        },
        {merge: true},
      );
    }
  });
  return {
    paymentSessionId: `FREE-${target.registrationId}`,
    paymentLinkUrl: null,
    status: "COMPLETED",
    paid: true,
    expired: false,
    paymentId: `FREE-${target.registrationId}`,
    paymentRequestId: null,
    message: "Free registration activated.",
  };
}

export const createXenditPaymentSession = onCall(
  {secrets: [xenditSecretKey]},
  async (request) => {
    const uid = requireAuth(request.auth?.uid);
    const tournamentId = requireString(request.data, "tournamentId");
    const registrationId = requireString(request.data, "registrationId");
    const target = {tournamentId, registrationId};
    const registrationRef = db.doc(
      `tournaments/${tournamentId}/registrations/${registrationId}`,
    );
    const tournamentRef = db.doc(`tournaments/${tournamentId}`);
    const [registrationSnap, tournamentSnap] = await Promise.all([
      registrationRef.get(),
      tournamentRef.get(),
    ]);
    if (!registrationSnap.exists) {
      throw new HttpsError("not-found", "Registration was not found.");
    }
    if (!tournamentSnap.exists) {
      throw new HttpsError("not-found", "Tournament was not found.");
    }
    const registration = registrationSnap.data() ?? {};
    if (registration.playerId !== uid) {
      throw new HttpsError("permission-denied", "Only the registered player can pay.");
    }
    if (
      registration.paymentProvider === "xendit" &&
      typeof registration.xenditPaymentSessionId === "string" &&
      typeof registration.xenditPaymentLinkUrl === "string" &&
      registration.xenditSessionStatus !== "EXPIRED" &&
      registration.xenditSessionStatus !== "CANCELED"
    ) {
      return {
        paymentSessionId: registration.xenditPaymentSessionId,
        paymentLinkUrl: registration.xenditPaymentLinkUrl,
        status: asString(registration.xenditSessionStatus, "ACTIVE"),
        paid: registration.paymentStatus === "paid",
        expired: false,
        paymentId: asString(registration.xenditPaymentId) || null,
        paymentRequestId: asString(registration.xenditPaymentRequestId) || null,
        message: "Existing payment session reused.",
      };
    }

    const tournament = tournamentSnap.data() ?? {};
    const amount =
      asPositiveInt(registration.userPayableAmount) ||
      asPositiveInt((registration.feePolicy as Record<string, unknown> | undefined)?.userPayable) ||
      asPositiveInt(tournament.registrationFee);
    if (amount <= 0) {
      return activateFreeRegistration(target);
    }

    const appBaseUrl = normalizeHttpsBaseUrl(request.data?.appBaseUrl);
    const referenceId = makeReferenceId(registrationId);
    const tournamentName = truncate(asString(tournament.name, "Turney Tournament"), 90);
    const playerName = truncate(asString(registration.playerName, "Player"), 80);
    const session = await xenditRequest<XenditSession>("POST", "/sessions", {
      reference_id: referenceId,
      session_type: "PAY",
      mode: "PAYMENT_LINK",
      allow_save_payment_method: "DISABLED",
      capture_method: "AUTOMATIC",
      amount,
      currency: "IDR",
      country: "ID",
      locale: "en",
      description: truncate(`Turney registration for ${tournamentName}`, 1000),
      success_return_url: `${appBaseUrl}/me/tournaments`,
      cancel_return_url: `${appBaseUrl}/tournaments/${tournamentId}`,
      metadata: {
        tournamentId: truncate(tournamentId, 80),
        registrationId: truncate(registrationId, 80),
        playerId: truncate(uid, 80),
      },
      items: [
        {
          reference_id: truncate(registrationId, 255),
          type: "DIGITAL_SERVICE",
          name: truncate(`${tournamentName} registration`, 255),
          net_unit_amount: amount,
          quantity: 1,
          category: "Tournament",
          description: truncate(`Registration for ${playerName}`, 255),
        },
      ],
    });
    return writePaymentSessionState(target, session, "created");
  },
);

export const createXenditQrisPayment = onCall(
  {secrets: [xenditSecretKey]},
  async (request) => {
    const uid = requireAuth(request.auth?.uid);
    const tournamentId = requireString(request.data, "tournamentId");
    const registrationId = requireString(request.data, "registrationId");
    const target = {tournamentId, registrationId};
    const registrationRef = db.doc(
      `tournaments/${tournamentId}/registrations/${registrationId}`,
    );
    const tournamentRef = db.doc(`tournaments/${tournamentId}`);
    const [registrationSnap, tournamentSnap] = await Promise.all([
      registrationRef.get(),
      tournamentRef.get(),
    ]);
    if (!registrationSnap.exists) {
      throw new HttpsError("not-found", "Registration was not found.");
    }
    if (!tournamentSnap.exists) {
      throw new HttpsError("not-found", "Tournament was not found.");
    }
    const registration = registrationSnap.data() ?? {};
    if (registration.playerId !== uid) {
      throw new HttpsError("permission-denied", "Only the registered player can pay.");
    }
    if (registration.paymentStatus === "paid" && registration.registrationStatus === "active") {
      const qrString = asString(registration.xenditQrisQrString);
      return {
        paymentSessionId:
          asString(registration.xenditQrisId) ||
          asString(registration.paymentId) ||
          `PAID-${registrationId}`,
        paymentLinkUrl: null,
        status: "COMPLETED",
        paid: true,
        expired: false,
        paymentId: asString(registration.paymentId) || null,
        paymentRequestId: null,
        paymentMode: "qris",
        qrisReferenceId: asString(registration.xenditQrisReferenceId) || null,
        qrisQrId: asString(registration.xenditQrisId) || null,
        qrisQrString: qrString || null,
        qrisQrImageDataUrl: qrString ? await qrisDataUrl(qrString) : null,
        message: "Registration payment has already been confirmed.",
      };
    }
    if (
      registration.paymentProvider === "xendit_qris" &&
      typeof registration.xenditQrisId === "string" &&
      typeof registration.xenditQrisReferenceId === "string" &&
      typeof registration.xenditQrisQrString === "string" &&
      registration.paymentStatus !== "paid"
    ) {
      return {
        paymentSessionId: registration.xenditQrisId,
        paymentLinkUrl: null,
        status: asString(registration.xenditQrisStatus, "ACTIVE"),
        paid: false,
        expired: false,
        paymentId: asString(registration.paymentId) || registration.xenditQrisId,
        paymentRequestId: null,
        paymentMode: "qris",
        qrisReferenceId: registration.xenditQrisReferenceId,
        qrisQrId: registration.xenditQrisId,
        qrisQrString: registration.xenditQrisQrString,
        qrisQrImageDataUrl: await qrisDataUrl(registration.xenditQrisQrString),
        message: "Existing QRIS code reused.",
      };
    }

    const tournament = tournamentSnap.data() ?? {};
    const amount =
      asPositiveInt(registration.userPayableAmount) ||
      asPositiveInt((registration.feePolicy as Record<string, unknown> | undefined)?.userPayable) ||
      asPositiveInt(tournament.registrationFee);
    if (amount <= 0) {
      return activateFreeRegistration(target);
    }

    const referenceId = makeReferenceId(registrationId);
    const qr = await xenditRequest<XenditQrCode>(
      "POST",
      "/qr_codes",
      {
        reference_id: referenceId,
        type: "DYNAMIC",
        currency: "IDR",
        amount,
        metadata: {
          tournamentId: truncate(tournamentId, 80),
          registrationId: truncate(registrationId, 80),
          playerId: truncate(uid, 80),
        },
      },
      {"api-version": "2022-07-31"},
    );
    return writeQrisState(target, qr, "created");
  },
);

export const syncXenditQrisPayment = onCall(
  {secrets: [xenditSecretKey]},
  async (request) => {
    const uid = requireAuth(request.auth?.uid);
    const tournamentId = requireString(request.data, "tournamentId");
    const registrationId = requireString(request.data, "registrationId");
    const target = {tournamentId, registrationId};
    await assertCanViewPayment(uid, target);
    const registrationSnap = await db
      .doc(`tournaments/${tournamentId}/registrations/${registrationId}`)
      .get();
    const registration = registrationSnap.data() ?? {};
    const referenceId =
      asString(request.data?.qrisReferenceId) ||
      asString(registration.xenditQrisReferenceId);
    const qrId = asString(registration.xenditQrisId);
    const qrString = asString(registration.xenditQrisQrString);
    if (!referenceId || !qrId || !qrString) {
      throw new HttpsError("failed-precondition", "No Xendit QRIS code exists yet.");
    }
    const payments = await lookupQrisPayments(referenceId, qrId);
    const paidPayment = payments.find((payment) =>
      ["SUCCEEDED", "COMPLETED"].includes(asString(payment.status).toUpperCase()),
    );
    return writeQrisState(
      target,
      {
        id: qrId,
        reference_id: referenceId,
        qr_string: qrString,
        status: paidPayment ? "COMPLETED" : asString(registration.xenditQrisStatus, "ACTIVE"),
        amount: asPositiveInt(registration.userPayableAmount),
        currency: "IDR",
      },
      "manualSync",
      paidPayment,
    );
  },
);

export const syncXenditPaymentSession = onCall(
  {secrets: [xenditSecretKey]},
  async (request) => {
    const uid = requireAuth(request.auth?.uid);
    const tournamentId = requireString(request.data, "tournamentId");
    const registrationId = requireString(request.data, "registrationId");
    const target = {tournamentId, registrationId};
    await assertCanViewPayment(uid, target);
    const registrationSnap = await db
      .doc(`tournaments/${tournamentId}/registrations/${registrationId}`)
      .get();
    const registration = registrationSnap.data() ?? {};
    const sessionId =
      asString(request.data?.paymentSessionId) ||
      asString(registration.xenditPaymentSessionId);
    if (!sessionId) {
      throw new HttpsError("failed-precondition", "No Xendit payment session exists yet.");
    }
    if (sessionId.startsWith("FREE-")) {
      return {
        paymentSessionId: sessionId,
        paymentLinkUrl: null,
        status: "COMPLETED",
        paid: true,
        expired: false,
        paymentId: sessionId,
        paymentRequestId: null,
      };
    }
    const session = await xenditRequest<XenditSession>("GET", `/sessions/${sessionId}`);
    const resolvedTarget = paymentTargetFromSession(session) ?? target;
    return writePaymentSessionState(resolvedTarget, session, "manualSync");
  },
);

export const xenditPaymentSessionWebhook = onRequest(
  {secrets: [xenditWebhookToken]},
  async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).send("Method not allowed");
    return;
  }
  const expectedToken = process.env.XENDIT_WEBHOOK_TOKEN;
  if (expectedToken && request.get("x-callback-token") !== expectedToken) {
    response.status(401).send("Unauthorized");
    return;
  }
  const event = asString(request.body?.event);
  if (!["payment_session.completed", "payment_session.expired"].includes(event)) {
    response.status(200).json({ignored: true});
    return;
  }
  const session = (request.body?.data ?? {}) as XenditSession;
  try {
    const target = await resolvePaymentTarget(session);
    if (!target) {
      logger.warn("Xendit webhook target not found", {
        event,
        paymentSessionId: session.payment_session_id,
        referenceId: session.reference_id,
      });
      response.status(202).json({accepted: true, targetFound: false});
      return;
    }
    await writePaymentSessionState(target, session, `webhook:${event}`);
    response.status(200).json({ok: true});
  } catch (error) {
    logger.error("Xendit webhook failed", {event, error});
    response.status(500).json({ok: false});
  }
});

export const xenditQrisWebhook = onRequest(
  {secrets: [xenditWebhookToken]},
  async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).send("Method not allowed");
    return;
  }
  const expectedToken = process.env.XENDIT_WEBHOOK_TOKEN;
  if (expectedToken && request.get("x-callback-token") !== expectedToken) {
    response.status(401).send("Unauthorized");
    return;
  }
  const payment = (request.body?.data ?? request.body ?? {}) as XenditQrPayment;
  try {
    const target = await resolveQrisTarget(payment);
    if (!target) {
      logger.warn("Xendit QRIS webhook target not found", {
        paymentId: payment.id,
        referenceId: payment.reference_id ?? payment.external_id,
        qrId: payment.qr_id ?? payment.qr_code?.id,
      });
      response.status(202).json({accepted: true, targetFound: false});
      return;
    }
    const registrationSnap = await db
      .doc(`tournaments/${target.tournamentId}/registrations/${target.registrationId}`)
      .get();
    const registration = registrationSnap.data() ?? {};
    await writeQrisState(
      target,
      qrisFromPayment(payment, registration),
      "webhook:qris",
      payment,
    );
    response.status(200).json({ok: true});
  } catch (error) {
    logger.error("Xendit QRIS webhook failed", {error});
    response.status(500).json({ok: false});
  }
});

type XenditDisbursement = {
  id?: string;
  external_id?: string;
  bank_code?: string;
  account_holder_name?: string;
  account_number?: string;
  amount?: number;
  status?: string;
  fee?: number;
};

type PayoutTarget = {
  tournamentId: string;
  withdrawalId: string;
};

const supportedBankHint =
  "BCA, BNI, BRI, Mandiri, Permata, CIMB, Danamon, Maybank, Panin, OCBC/NISP, BSI";

function bankCodeFor(bankName: string): string {
  const v = bankName.toLowerCase();
  if (v.includes("bca") || v.includes("central asia")) return "BCA";
  if (v.includes("bni")) return "BNI";
  if (v.includes("bri") || v.includes("rakyat indonesia")) return "BRI";
  if (v.includes("mandiri")) return "MANDIRI";
  if (v.includes("permata")) return "PERMATA";
  if (v.includes("cimb")) return "CIMB";
  if (v.includes("danamon")) return "DANAMON";
  if (v.includes("maybank")) return "MAYBANK_INDONESIA";
  if (v.includes("panin")) return "PANIN";
  if (v.includes("ocbc") || v.includes("nisp")) return "OCBC_NISP";
  if (v.includes("bsi") || v.includes("syariah")) return "BSI";
  throw new HttpsError(
    "invalid-argument",
    `Unsupported bank "${bankName}". Supported: ${supportedBankHint}.`,
  );
}

async function assertSuperAdmin(uid: string): Promise<void> {
  const snap = await db.doc(`users/${uid}`).get();
  const data = snap.data() ?? {};
  const roles = Array.isArray(data.roles) ? (data.roles as string[]) : [];
  const role = asString(data.role);
  const allowed =
    roles.includes("super_admin") ||
    roles.includes("admin") ||
    role === "super_admin" ||
    role === "admin";
  if (!allowed) {
    throw new HttpsError(
      "permission-denied",
      "Only platform admins can process payouts.",
    );
  }
}

function disbursementStatus(value: unknown): string {
  const status = asString(value).toUpperCase();
  if (status === "COMPLETED") return "completed";
  if (status === "FAILED") return "failed";
  return "processing";
}

async function writeDisbursementState(
  target: PayoutTarget,
  disb: XenditDisbursement,
  source: string,
): Promise<Record<string, unknown>> {
  const withdrawalRef = db.doc(
    `tournaments/${target.tournamentId}/withdrawals/${target.withdrawalId}`,
  );
  const tournamentRef = db.doc(`tournaments/${target.tournamentId}`);
  const status = disbursementStatus(disb.status);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(withdrawalRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Withdrawal was not found.");
    }
    tx.set(
      withdrawalRef,
      {
        status,
        xenditDisbursementId: asString(disb.id) || null,
        xenditDisbursementStatus: asString(disb.status).toUpperCase() || null,
        xenditBankCode: asString(disb.bank_code) || null,
        payoutFeeAmount: asPositiveInt(disb.fee),
        payoutSource: source,
        payoutUpdatedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      {merge: true},
    );
    tx.set(
      tournamentRef,
      {
        organizerPayout: {
          status,
          lastWithdrawalId: target.withdrawalId,
          xenditDisbursementId: asString(disb.id) || null,
          updatedAt: serverTimestamp(),
        },
        updatedAt: serverTimestamp(),
      },
      {merge: true},
    );
  });
  return {
    withdrawalId: target.withdrawalId,
    tournamentId: target.tournamentId,
    status,
    xenditDisbursementId: asString(disb.id) || null,
    xenditStatus: asString(disb.status).toUpperCase() || null,
  };
}

async function resolvePayoutTarget(
  externalId: string,
): Promise<PayoutTarget | null> {
  if (!externalId.startsWith("wd-")) return null;
  const withdrawalId = externalId.slice(3);
  const snap = await db
    .collectionGroup("withdrawals")
    .where("id", "==", withdrawalId)
    .limit(1)
    .get();
  if (snap.empty) return null;
  const ref = snap.docs[0].ref;
  return {tournamentId: ref.parent.parent?.id ?? "", withdrawalId};
}

export const createXenditDisbursement = onCall(
  {secrets: [xenditSecretKey]},
  async (request) => {
    const uid = requireAuth(request.auth?.uid);
    await assertSuperAdmin(uid);
    const tournamentId = requireString(request.data, "tournamentId");
    const withdrawalId = requireString(request.data, "withdrawalId");
    const target = {tournamentId, withdrawalId};
    const withdrawalRef = db.doc(
      `tournaments/${tournamentId}/withdrawals/${withdrawalId}`,
    );
    const snap = await withdrawalRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Withdrawal was not found.");
    }
    const withdrawal = snap.data() ?? {};
    if (asString(withdrawal.status) === "completed") {
      return {
        withdrawalId,
        tournamentId,
        status: "completed",
        xenditDisbursementId: asString(withdrawal.xenditDisbursementId) || null,
        message: "Withdrawal has already been paid out.",
      };
    }
    const existingId = asString(withdrawal.xenditDisbursementId);
    if (existingId) {
      const disb = await xenditRequest<XenditDisbursement>(
        "GET",
        `/disbursements/${existingId}`,
      );
      return writeDisbursementState(target, disb, "syncBeforeCreate");
    }
    const amount = asPositiveInt(withdrawal.amount);
    if (amount <= 0) {
      throw new HttpsError("invalid-argument", "Withdrawal amount is invalid.");
    }
    const disb = await xenditRequest<XenditDisbursement>(
      "POST",
      "/disbursements",
      {
        external_id: `wd-${withdrawalId}`,
        amount,
        bank_code: bankCodeFor(asString(withdrawal.bankName)),
        account_holder_name: truncate(
          asString(withdrawal.accountName, "Account Holder"),
          100,
        ),
        account_number: alphanumeric(asString(withdrawal.accountNumber)),
        description: truncate(
          `Turney community payout for tournament ${tournamentId}`,
          255,
        ),
      },
    );
    return writeDisbursementState(target, disb, "created");
  },
);

export const syncXenditDisbursement = onCall(
  {secrets: [xenditSecretKey]},
  async (request) => {
    const uid = requireAuth(request.auth?.uid);
    await assertSuperAdmin(uid);
    const tournamentId = requireString(request.data, "tournamentId");
    const withdrawalId = requireString(request.data, "withdrawalId");
    const target = {tournamentId, withdrawalId};
    const snap = await db
      .doc(`tournaments/${tournamentId}/withdrawals/${withdrawalId}`)
      .get();
    const withdrawal = snap.data() ?? {};
    const disbId = asString(withdrawal.xenditDisbursementId);
    if (!disbId) {
      throw new HttpsError(
        "failed-precondition",
        "No Xendit disbursement exists for this withdrawal yet.",
      );
    }
    const disb = await xenditRequest<XenditDisbursement>(
      "GET",
      `/disbursements/${disbId}`,
    );
    return writeDisbursementState(target, disb, "manualSync");
  },
);

export const xenditDisbursementWebhook = onRequest(
  {secrets: [xenditWebhookToken]},
  async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).send("Method not allowed");
    return;
  }
  const expectedToken = process.env.XENDIT_WEBHOOK_TOKEN;
  if (expectedToken && request.get("x-callback-token") !== expectedToken) {
    response.status(401).send("Unauthorized");
    return;
  }
  const event = asString(request.body?.event);
  if (
    event &&
    !["disbursement.completed", "disbursement.failed"].includes(event)
  ) {
    response.status(200).json({ignored: true});
    return;
  }
  const disb = (request.body?.data ?? request.body ?? {}) as XenditDisbursement;
  try {
    const target = await resolvePayoutTarget(asString(disb.external_id));
    if (!target) {
      logger.warn("Xendit disbursement webhook target not found", {
        event,
        externalId: disb.external_id,
      });
      response.status(202).json({accepted: true, targetFound: false});
      return;
    }
    await writeDisbursementState(target, disb, `webhook:${event || "status"}`);
    response.status(200).json({ok: true});
  } catch (error) {
    logger.error("Xendit disbursement webhook failed", {event, error});
    response.status(500).json({ok: false});
  }
});

const allowedPlatformRoles = new Set([
  "super_admin",
  "admin",
  "community_admin",
  "judge",
  "player",
]);

function normalizeRole(value: string): string {
  const v = value.trim().toLowerCase();
  if (v === "superadmin") return "super_admin";
  if (v === "communityadmin") return "community_admin";
  if (v === "juri") return "judge";
  if (v === "admin") return "super_admin";
  return v;
}

function primaryRoleFor(roles: string[]): string {
  if (roles.includes("super_admin")) return "super_admin";
  if (roles.includes("community_admin")) return "community_admin";
  if (roles.includes("judge")) return "judge";
  return "player";
}

export const assignJudge = onCall(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const actorSnap = await db.doc(`users/${uid}`).get();
  const actorRoles = Array.isArray(actorSnap.data()?.roles)
    ? (actorSnap.data()?.roles as string[])
    : [];
  const actorRole = asString(actorSnap.data()?.role);
  const canManage =
    actorRoles.includes("community_admin") ||
    actorRoles.includes("super_admin") ||
    actorRole === "community_admin" ||
    actorRole === "super_admin" ||
    actorRole === "admin";
  if (!canManage) {
    throw new HttpsError(
      "permission-denied",
      "Only community admins or platform admins can assign judges.",
    );
  }
  const targetUid = requireString(request.data, "targetUid");
  if (targetUid === uid) {
    throw new HttpsError("invalid-argument", "Cannot change your own role.");
  }
  const targetRef = db.doc(`users/${targetUid}`);
  const snap = await targetRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Target user was not found.");
  }
  const currentRole = asString(snap.data()?.role);
  if (!["player", "judge"].includes(currentRole)) {
    throw new HttpsError(
      "failed-precondition",
      "Only players or judges can be assigned the judge role.",
    );
  }
  const roles = new Set<string>(["player", "judge"]);
  await targetRef.set(
    {
      role: "judge",
      roles: [...roles].sort(),
      judgeAssignedBy: uid,
      judgeAssignedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    },
    {merge: true},
  );
  return {success: true, uid: targetUid, role: "judge"};
});

export const submitCommunityApplication = onCall(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const communityName = requireString(data, "communityName");
  const leaderUserId = requireString(data, "leaderUserId");
  const ref = db.collection("communityApplications").doc();
  await ref.set({
    requesterId: uid,
    communityName: communityName,
    city: asString(data.city),
    leaderUserId,
    description: asString(data.description),
    tag: asString(data.tag),
    type: asString(data.type),
    region: asString(data.region),
    website: asString(data.website),
    leader: (data.leader as Record<string, unknown>) ?? {},
    financeAccount: (data.financeAccount as Record<string, unknown>) ?? {},
    documents: (data.documents as Record<string, unknown>) ?? {},
    status: "pending",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return {applicationId: ref.id};
});

export const reviewCommunityApplication = onCall(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  await assertSuperAdmin(uid);
  const applicationId = requireString(request.data, "applicationId");
  const decision = requireString(request.data, "decision");
  const reason = asString(request.data?.reason);
  const applicationRef = db.doc(`communityApplications/${applicationId}`);
  const snap = await applicationRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Application was not found.");
  }
  const application = snap.data() ?? {};
  if (asString(application.status) !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      "Application has already been reviewed.",
    );
  }
  const leaderUserId = asString(application.leaderUserId);
  if (decision === "approved") {
    const communityRef = db.collection("communities").doc();
    await db.runTransaction(async (tx) => {
      tx.set(communityRef, {
        name: asString(application.communityName),
        tag: asString(application.tag),
        type: asString(application.type),
        city: asString(application.city),
        region: asString(application.region),
        website: asString(application.website),
        description: asString(application.description),
        leaderUserId,
        leader: (application.leader as Record<string, unknown>) ?? {},
        financeAccount:
          (application.financeAccount as Record<string, unknown>) ?? {},
        documents: (application.documents as Record<string, unknown>) ?? {},
        adminIds: [leaderUserId],
        memberCount: 1,
        status: "active",
        sourceApplicationId: applicationId,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      tx.set(
        applicationRef,
        {
          status: "approved",
          reviewerId: uid,
          communityId: communityRef.id,
          reviewedAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        },
        {merge: true},
      );
      if (leaderUserId) {
        const leaderRef = db.doc(`users/${leaderUserId}`);
        const leaderSnap = await tx.get(leaderRef);
        const existing = Array.isArray(leaderSnap.data()?.roles)
          ? (leaderSnap.data()?.roles as string[])
          : [];
        const roles = new Set<string>([...existing, "player", "community_admin"]);
        tx.set(
          leaderRef,
          {
            role: primaryRoleFor([...roles]),
            roles: [...roles].sort(),
            communityIds: admin.firestore.FieldValue.arrayUnion(communityRef.id),
            updatedAt: serverTimestamp(),
          },
          {merge: true},
        );
      }
    });
    if (leaderUserId) {
      await db.collection("notifications").add({
        recipientId: leaderUserId,
        type: "communityApplication",
        title: "Community approved",
        body: "The community application review is complete.",
        isRead: false,
        createdAt: serverTimestamp(),
      });
    }
    return {communityId: communityRef.id};
  }
  if (decision === "rejected") {
    await applicationRef.set(
      {
        status: "rejected",
        reviewerId: uid,
        rejectionReason: reason,
        reviewedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      {merge: true},
    );
    const recipient = asString(application.requesterId) || leaderUserId;
    if (recipient) {
      await db.collection("notifications").add({
        recipientId: recipient,
        type: "communityApplication",
        title: "Community application rejected",
        body: reason || "The community application was rejected.",
        isRead: false,
        createdAt: serverTimestamp(),
      });
    }
    return {communityId: ""};
  }
  throw new HttpsError("invalid-argument", "Decision must be approved/rejected.");
});

export const setPlatformRole = onCall(async (request) => {
  const uid = requireAuth(request.auth?.uid);
  await assertSuperAdmin(uid);
  const targetUid = requireString(request.data, "targetUid");
  const requested = Array.isArray(request.data?.roles)
    ? (request.data.roles as unknown[]).map((r) => normalizeRole(asString(r)))
    : [normalizeRole(asString(request.data?.role))];
  for (const role of requested) {
    if (!allowedPlatformRoles.has(role)) {
      throw new HttpsError("invalid-argument", `Unsupported role: ${role}`);
    }
  }
  const roles = new Set<string>(requested);
  if (!roles.has("super_admin")) roles.add("player");
  const primary = primaryRoleFor([...roles]);
  const existingUser = await admin.auth().getUser(targetUid);
  await admin.auth().setCustomUserClaims(targetUid, {
    ...(existingUser.customClaims ?? {}),
    role: primary,
  });
  await db.doc(`users/${targetUid}`).set(
    {
      role: primary,
      roles: [...roles].sort(),
      roleUpdatedAt: serverTimestamp(),
      roleUpdatedBy: uid,
      updatedAt: serverTimestamp(),
    },
    {merge: true},
  );
  return {success: true, uid: targetUid, role: primary};
});

import {onDocumentWritten} from "firebase-functions/v2/firestore";

// ── Player performance: ELO + totals, applied exactly once per match ──────
// The judge client cannot update another player's users document, so stats
// are applied server-side when a match transitions to 'completed'.
export const onMatchCompletedApplyStats = onDocumentWritten(
  "tournaments/{tournamentId}/rounds/{roundId}/matches/{matchId}",
  async (event) => {
    const after = event.data?.after.data() ?? {};
    const before = event.data?.before.data() ?? {};
    const status = asString(after.status).toLowerCase();
    const winnerId = asString(after.winnerId);
    if (status !== "completed" || !winnerId) return;
    if (after.statsAppliedAt || before.statsAppliedAt) return;
    if (before.status === "completed") return;

    const playerAId = asString(after.playerAId);
    const playerBId = asString(after.playerBId);
    if (!playerAId || !playerBId || playerBId === "player-b") return;
    if (playerAId === playerBId) return;

    const [aSnap, bSnap] = await Promise.all([
      db.doc(`users/${playerAId}`).get(),
      db.doc(`users/${playerBId}`).get(),
    ]);
    const aElo = asPositiveInt(aSnap.data()?.eloRating);
    const bElo = asPositiveInt(bSnap.data()?.eloRating);
    const aWon = winnerId === playerAId;
    const expectedA = 1 / (1 + Math.pow(10, (bElo - aElo) / 400));
    const K = 32;
    const scoreA = aWon ? 1 : 0;
    const nextAElo = Math.max(0, Math.round(aElo + K * (scoreA - expectedA)));
    const nextBElo = Math.max(0, Math.round(bElo + K * (1 - scoreA - (1 - expectedA))));
    const aTotals = {
      totalMatches: asPositiveInt(aSnap.data()?.totalMatches) + 1,
      totalWins: asPositiveInt(aSnap.data()?.totalWins) + (aWon ? 1 : 0),
      totalLosses: asPositiveInt(aSnap.data()?.totalLosses) + (aWon ? 0 : 1),
    };
    const bTotals = {
      totalMatches: asPositiveInt(bSnap.data()?.totalMatches) + 1,
      totalWins: asPositiveInt(bSnap.data()?.totalWins) + (aWon ? 0 : 1),
      totalLosses: asPositiveInt(bSnap.data()?.totalLosses) + (aWon ? 1 : 0),
    };
    await db.runTransaction(async (tx) => {
      tx.set(
        db.doc(`users/${playerAId}`),
        {
          ...aTotals,
          eloRating: nextAElo,
          lastMatchAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        },
        {merge: true},
      );
      tx.set(
        db.doc(`users/${playerBId}`),
        {
          ...bTotals,
          eloRating: nextBElo,
          lastMatchAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        },
        {merge: true},
      );
      if (event.data?.after.ref) {
        tx.set(
          event.data.after.ref,
          {statsAppliedAt: serverTimestamp()},
          {merge: true},
        );
      }
      await db.collection("elo_history").add({
        matchId: event.params?.matchId ?? "",
        tournamentId: event.params?.tournamentId ?? "",
        playerAId,
        playerBId,
        winnerId,
        aBefore: aElo,
        bBefore: bElo,
        aAfter: nextAElo,
        bAfter: nextBElo,
        createdAt: serverTimestamp(),
      });
    });
  },
);
