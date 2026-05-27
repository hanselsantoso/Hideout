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

export const xenditPaymentSessionWebhook = onRequest(async (request, response) => {
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

export const xenditQrisWebhook = onRequest(async (request, response) => {
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
