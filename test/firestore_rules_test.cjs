const fs = require('node:fs');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

let testEnv;

const rules = fs.readFileSync('firebase_patch/firestore.rules', 'utf8');

describe('firestore security rules', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'hideout-rules-test',
      firestore: { rules },
    });
  });

  after(async () => {
    if (testEnv) await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/player-a'), {
        role: 'player',
        roles: ['player'],
        isActive: true,
      });
      await setDoc(doc(db, 'users/community-a'), {
        role: 'player',
        roles: ['player', 'community_admin', 'judge'],
        isActive: true,
      });
      await setDoc(doc(db, 'users/community-b'), {
        role: 'community_admin',
        roles: ['player', 'community_admin'],
        isActive: true,
      });
      await setDoc(doc(db, 'users/judge-a'), {
        role: 'judge',
        roles: ['player', 'judge'],
        isActive: true,
      });
      await setDoc(doc(db, 'users/judge-b'), {
        role: 'judge',
        roles: ['player', 'judge'],
        isActive: true,
      });
      await setDoc(doc(db, 'users/super-a'), {
        role: 'super_admin',
        roles: ['super_admin'],
        isActive: true,
      });
      await setDoc(doc(db, 'tournaments/owned-event'), {
        name: 'Owned Event',
        organizerId: 'community-a',
        status: 'draft',
      });
      await setDoc(doc(db, 'tournaments/other-event'), {
        name: 'Other Event',
        organizerId: 'community-b',
        status: 'draft',
      });
      await setDoc(doc(db, 'tournaments/owned-event/withdrawals/wd-a'), {
        requesterId: 'community-a',
        amount: 100000,
        status: 'processing',
      });
      await setDoc(doc(db, 'tournaments/owned-event/registrations/reg-a'), {
        playerId: 'player-a',
        paymentStatus: 'pending',
        registrationStatus: 'pendingPayment',
      });
      await setDoc(doc(db, 'tournaments/owned-event/rounds/round-a'), {
        index: 1,
        name: 'Round A',
      });
      await setDoc(doc(db, 'tournaments/owned-event/rounds/round-a/matches/match-a'), {
        judgeId: 'judge-a',
        status: 'ready',
      });
    });
  });

  function authedDb(uid, token = {}) {
    return testEnv.authenticatedContext(uid, token).firestore();
  }

  it('accepts roles array for mixed community admin and judge accounts', async () => {
    const db = authedDb('community-a');
    await assertSucceeds(
      setDoc(doc(db, 'tournaments/new-owned-event'), {
        name: 'New Owned Event',
        organizerId: 'community-a',
        status: 'draft',
      }),
    );
  });

  it('blocks community admins from mutating tournaments they do not own', async () => {
    const db = authedDb('community-a');
    await assertFails(
      updateDoc(doc(db, 'tournaments/other-event'), {
        name: 'Hijacked Event',
      }),
    );
  });

  it('allows tournament organizers to update only ops fields', async () => {
    const db = authedDb('community-a');
    await assertSucceeds(
      updateDoc(doc(db, 'tournaments/owned-event'), {
        currentParticipantCount: 1,
        updatedAt: 'now',
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'tournaments/owned-event'), {
        organizerId: 'community-b',
      }),
    );
  });

  it('allows organizers and players to update limited registration ops fields', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('community-a'), 'tournaments/owned-event/registrations/reg-a'), {
        paymentStatus: 'paid',
        registrationStatus: 'active',
        updatedAt: 'now',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(authedDb('player-a'), 'tournaments/owned-event/registrations/reg-a'), {
        paymentStatus: 'paid',
        registrationStatus: 'active',
        updatedAt: 'now',
      }),
    );
    await assertFails(
      updateDoc(doc(authedDb('player-a'), 'tournaments/owned-event/registrations/reg-a'), {
        playerId: 'judge-a',
      }),
    );
  });

  it('keeps round and match creation limited to organizers, not arbitrary judges', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('community-a'), 'tournaments/owned-event/rounds/round-b'), {
        index: 2,
        name: 'Round B',
      }),
    );
    await assertFails(
      setDoc(doc(authedDb('judge-a'), 'tournaments/owned-event/rounds/round-c'), {
        index: 3,
        name: 'Round C',
      }),
    );
    await assertSucceeds(
      setDoc(doc(authedDb('community-a'), 'tournaments/owned-event/rounds/round-a/matches/match-b'), {
        judgeId: 'judge-a',
        status: 'queued',
      }),
    );
    await assertFails(
      setDoc(doc(authedDb('judge-a'), 'tournaments/owned-event/rounds/round-a/matches/match-c'), {
        judgeId: 'judge-a',
        status: 'queued',
      }),
    );
  });

  it('allows only the assigned judge to update an existing match', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('judge-a'), 'tournaments/owned-event/rounds/round-a/matches/match-a'), {
        status: 'completed',
      }),
    );
    await assertFails(
      updateDoc(doc(authedDb('judge-b'), 'tournaments/owned-event/rounds/round-a/matches/match-a'), {
        status: 'completed',
      }),
    );
  });

  it('allows a community owner to create their own withdraw only', async () => {
    const db = authedDb('community-a');
    await assertSucceeds(
      setDoc(doc(db, 'tournaments/owned-event/withdrawals/wd-own'), {
        requesterId: 'community-a',
        amount: 250000,
        status: 'processing',
      }),
    );
    await assertFails(
      setDoc(doc(db, 'tournaments/other-event/withdrawals/wd-other'), {
        requesterId: 'community-a',
        amount: 250000,
        status: 'processing',
      }),
    );
  });

  it('keeps withdraw documents private to requester or super admin', async () => {
    await assertSucceeds(
      getDoc(doc(authedDb('community-a'), 'tournaments/owned-event/withdrawals/wd-a')),
    );
    await assertFails(
      getDoc(doc(authedDb('community-b'), 'tournaments/owned-event/withdrawals/wd-a')),
    );
    await assertSucceeds(
      getDoc(doc(authedDb('super-a'), 'tournaments/owned-event/withdrawals/wd-a')),
    );
  });

  it('blocks players from escalating their own role', async () => {
    const db = authedDb('player-a');
    await assertFails(
      updateDoc(doc(db, 'users/player-a'), {
        role: 'super_admin',
      }),
    );
  });

  it('allows admins to create review notifications for applicants', async () => {
    const db = authedDb('super-a');
    await assertSucceeds(
      setDoc(doc(db, 'notifications/review-1'), {
        recipientId: 'player-a',
        type: 'communityApplication',
        title: 'Komunitas disetujui',
        body: 'Pengajuan komunitas sudah selesai direview.',
        isRead: false,
      }),
    );
    const playerDb = authedDb('player-a');
    await assertFails(
      setDoc(doc(playerDb, 'notifications/review-2'), {
        recipientId: 'player-a',
        title: 'fake',
      }),
    );
  });
});
