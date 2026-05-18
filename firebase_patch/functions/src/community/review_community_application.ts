import * as admin from 'firebase-admin';
import { https } from 'firebase-functions/v2';

type ReviewCommunityApplicationPayload = {
  applicationId?: string;
  decision?: 'approved' | 'rejected';
  reason?: string;
};

const isSuperAdminCompatible = (role: unknown) =>
  role === 'super_admin' || role === 'admin';

export const reviewCommunityApplication = https.onCall(async (request) => {
  if (!request.auth) {
    throw new https.HttpsError('unauthenticated', 'Login is required.');
  }
  if (!isSuperAdminCompatible(request.auth.token.role)) {
    throw new https.HttpsError(
      'permission-denied',
      'Only super admins can review community applications.',
    );
  }

  const { applicationId, decision, reason } =
    request.data as ReviewCommunityApplicationPayload;

  if (!applicationId) {
    throw new https.HttpsError('invalid-argument', 'applicationId is required.');
  }
  if (decision !== 'approved' && decision !== 'rejected') {
    throw new https.HttpsError(
      'invalid-argument',
      'decision must be approved or rejected.',
    );
  }

  const db = admin.firestore();
  const applicationRef = db.collection('communityApplications').doc(applicationId);
  const applicationSnap = await applicationRef.get();

  if (!applicationSnap.exists) {
    throw new https.HttpsError('not-found', 'Community application not found.');
  }

  const application = applicationSnap.data() ?? {};
  if (application.status !== 'pending') {
    throw new https.HttpsError(
      'failed-precondition',
      'Community application has already been reviewed.',
    );
  }

  const now = admin.firestore.Timestamp.now();

  if (decision === 'rejected') {
    await applicationRef.update({
      status: 'rejected',
      reviewerId: request.auth.uid,
      rejectionReason: typeof reason === 'string' ? reason.trim() : '',
      reviewedAt: now,
      updatedAt: now,
    });
    return { success: true };
  }

  const communityRef = db.collection('communities').doc();
  const leaderUserId =
    typeof application.leaderUserId === 'string' && application.leaderUserId.trim()
      ? application.leaderUserId.trim()
      : application.requesterId;

  await db.runTransaction(async (tx) => {
    tx.set(communityRef, {
      name: application.communityName ?? '',
      city: application.city ?? '',
      description: application.description ?? '',
      leaderUserId,
      adminIds: [leaderUserId],
      status: 'active',
      sourceApplicationId: applicationId,
      createdAt: now,
      updatedAt: now,
    });

    tx.update(applicationRef, {
      status: 'approved',
      reviewerId: request.auth!.uid,
      communityId: communityRef.id,
      reviewedAt: now,
      updatedAt: now,
    });

    tx.set(
      db.collection('users').doc(leaderUserId),
      {
        role: 'community_admin',
        communityIds: admin.firestore.FieldValue.arrayUnion(communityRef.id),
        updatedAt: now,
      },
      { merge: true },
    );
  });

  const leader = await admin.auth().getUser(leaderUserId);
  await admin.auth().setCustomUserClaims(leaderUserId, {
    ...(leader.customClaims ?? {}),
    role: 'community_admin',
    communityIds: [
      ...new Set([
        ...(((leader.customClaims ?? {}).communityIds as string[]) ?? []),
        communityRef.id,
      ]),
    ],
  });

  return { success: true, communityId: communityRef.id };
});
