import * as admin from 'firebase-admin';
import { https } from 'firebase-functions/v2';

type SubmitCommunityApplicationPayload = {
  communityName?: string;
  city?: string;
  leaderUserId?: string;
  description?: string;
};

const clean = (value: unknown) => (typeof value === 'string' ? value.trim() : '');

export const submitCommunityApplication = https.onCall(async (request) => {
  if (!request.auth) {
    throw new https.HttpsError('unauthenticated', 'Login is required.');
  }

  const payload = request.data as SubmitCommunityApplicationPayload;
  const communityName = clean(payload.communityName);
  const city = clean(payload.city);
  const leaderUserId = clean(payload.leaderUserId) || request.auth.uid;
  const description = clean(payload.description);

  if (!communityName) {
    throw new https.HttpsError('invalid-argument', 'communityName is required.');
  }
  if (!city) {
    throw new https.HttpsError('invalid-argument', 'city is required.');
  }

  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const ref = db.collection('communityApplications').doc();

  await ref.set({
    requesterId: request.auth.uid,
    communityName,
    city,
    leaderUserId,
    description,
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  });

  return { success: true, applicationId: ref.id };
});
