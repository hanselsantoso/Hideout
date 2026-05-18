import * as admin from 'firebase-admin';
import { https } from 'firebase-functions/v2';

const allowedRoles = new Set([
  'super_admin',
  'admin',
  'community_admin',
  'judge',
  'player',
]);

const canManageRoles = (role: unknown) =>
  role === 'super_admin' || role === 'admin';

export const setPlatformRole = https.onCall(async (request) => {
  if (!request.auth || !canManageRoles(request.auth.token.role)) {
    throw new https.HttpsError(
      'permission-denied',
      'Only platform admins can manage roles.',
    );
  }

  const { targetUid, role, communityIds = [] } = request.data as {
    targetUid?: string;
    role?: string;
    communityIds?: string[];
  };

  if (!targetUid) {
    throw new https.HttpsError('invalid-argument', 'targetUid is required.');
  }
  if (!role || !allowedRoles.has(role)) {
    throw new https.HttpsError('invalid-argument', 'Unsupported role.');
  }

  const existingUser = await admin.auth().getUser(targetUid);
  const nextClaims = {
    ...(existingUser.customClaims ?? {}),
    role,
    ...(role === 'community_admin' ? { communityIds } : {}),
  };

  await admin.auth().setCustomUserClaims(targetUid, nextClaims);

  await admin.firestore().collection('users').doc(targetUid).set(
    {
      role,
      ...(role === 'community_admin' ? { communityIds } : {}),
      updatedAt: admin.firestore.Timestamp.now(),
    },
    { merge: true },
  );

  return { success: true, uid: targetUid, role };
});
