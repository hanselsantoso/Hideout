const fs = require('node:fs');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
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
      await setDoc(doc(db, 'users/staff-a'), {
        role: 'player',
        roles: ['player'],
        isActive: true,
      });
      await setDoc(doc(db, 'tournaments/owned-event'), {
        name: 'Owned Event',
        organizerId: 'community-a',
        status: 'draft',
        staffIds: ['staff-a'],
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

  it('allows organizers, but not players, to update registration payment ops fields', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('community-a'), 'tournaments/owned-event/registrations/reg-a'), {
        paymentStatus: 'paid',
        registrationStatus: 'active',
        updatedAt: 'now',
      }),
    );
    await assertFails(
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

  it('allows a judge to record their own check-in on the tournament', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('judge-a'), 'tournaments/owned-event'), {
        'judgeCheckIns.judge-a': 'now',
        updatedAt: 'now',
      }),
    );
    await assertFails(
      updateDoc(doc(authedDb('judge-a'), 'tournaments/owned-event'), {
        'judgeCheckIns.judge-a': 'now',
        organizerId: 'judge-a',
      }),
    );
  });

  it('allows tournament staff to run registration and payment ops', async () => {
    const db = authedDb('staff-a');
    await assertSucceeds(
      updateDoc(doc(db, 'tournaments/owned-event/registrations/reg-a'), {
        paymentStatus: 'paid',
        registrationStatus: 'active',
        paidBy: 'staff-a',
        paidByName: 'Staff A',
        paidAt: 'now',
        updatedAt: 'now',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'tournaments/owned-event'), {
        status: 'running',
        updatedAt: 'now',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db, 'tournaments/owned-event/rounds/round-a/matches/match-a'), {
        winnerId: 'player-a',
        winnerName: 'Player A',
        updatedAt: 'now',
      }),
    );
  });

  it('blocks staff from managing staffIds, tournaments, and withdrawals', async () => {
    const db = authedDb('staff-a');
    await assertFails(
      updateDoc(doc(db, 'tournaments/owned-event'), {
        staffIds: ['player-a'],
        updatedAt: 'now',
      }),
    );
    await assertFails(
      setDoc(doc(db, 'tournaments/staff-created-event'), {
        name: 'Staff Created Event',
        organizerId: 'staff-a',
        status: 'draft',
      }),
    );
    await assertFails(
      setDoc(doc(db, 'tournaments/owned-event/withdrawals/wd-staff'), {
        requesterId: 'staff-a',
        amount: 100000,
        status: 'processing',
      }),
    );
  });

  it('blocks random players from staff registration ops', async () => {
    const db = authedDb('player-a');
    await assertFails(
      updateDoc(doc(db, 'tournaments/owned-event/registrations/reg-a'), {
        paymentStatus: 'paid',
        updatedAt: 'now',
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
    await assertFails(
      updateDoc(doc(db, 'users/player-a'), {
        roles: ['player', 'judge'],
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'users/player-a'), {
        eloRating: 99999,
        totalWins: 999,
      }),
    );
  });

  it('allows an assigned judge to maintain round robin standings', async () => {
    await assertSucceeds(
      setDoc(doc(authedDb('judge-a'), 'tournaments/owned-event/rounds/round-a/standings/player-a'), {
        playerId: 'player-a',
        playerName: 'Player A',
        groupName: 'Group 1',
        matches: 1,
        wins: 1,
        losses: 0,
        points: 3,
        scoreFor: 4,
        scoreAgainst: 2,
        pointDiff: 2,
        updatedAt: 'now',
      }),
    );
    await assertFails(
      setDoc(doc(authedDb('player-a'), 'tournaments/owned-event/rounds/round-a/standings/player-a'), {
        playerId: 'player-a',
        groupName: 'Group 1',
        wins: 99,
        updatedAt: 'now',
      }),
    );
  });

  it('allows community admins to grant judge role with the full roles array', async () => {
    const db = authedDb('community-b');
    await assertSucceeds(
      updateDoc(doc(db, 'users/player-a'), {
        role: 'judge',
        roles: ['judge', 'player'],
        judgeAssignedBy: 'community-b',
        judgeAssignedAt: 'now',
        updatedAt: 'now',
      }),
    );
  });

  it('allows community admins to revoke judge role back to player', async () => {
    const db = authedDb('community-b');
    await assertSucceeds(
      updateDoc(doc(db, 'users/judge-a'), {
        role: 'player',
        roles: ['player'],
        judgeRevokedBy: 'community-b',
        judgeRevokedAt: 'now',
        updatedAt: 'now',
      }),
    );
  });

  it('blocks community admins from granting community_admin role', async () => {
    const db = authedDb('community-b');
    await assertFails(
      updateDoc(doc(db, 'users/player-a'), {
        role: 'community_admin',
        roles: ['player', 'community_admin'],
        updatedAt: 'now',
      }),
    );
  });

  it('blocks self-created accounts from smuggling elevated roles', async () => {
    const db = authedDb('new-user');
    await assertFails(
      setDoc(doc(db, 'users/new-user'), {
        role: 'player',
        roles: ['super_admin'],
        isActive: true,
      }),
    );
    await assertFails(
      setDoc(doc(db, 'users/new-user'), {
        role: 'player',
        capabilities: ['super_admin'],
        isActive: true,
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'users/new-user'), {
        uid: 'new-user',
        displayName: 'New User',
        email: 'new@example.com',
        role: 'player',
        roles: ['player'],
        eloRating: 1000,
        isActive: true,
      }),
    );
  });

  it('allows organizers to record payout requests on their own tournament', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('community-a'), 'tournaments/owned-event'), {
        organizerPayout: { status: 'processing', requestedAmount: 100000 },
        updatedAt: 'now',
      }),
    );
    await assertFails(
      updateDoc(doc(authedDb('community-a'), 'tournaments/owned-event'), {
        organizerPayout: { status: 'processing' },
        organizerId: 'community-b',
      }),
    );
  });

  it('allows community admins to query player and judge candidates only', async () => {
    const db = authedDb('community-b');
    await assertSucceeds(
      getDocs(
        query(
          collection(db, 'users'),
          where('role', 'in', ['player', 'judge']),
        ),
      ),
    );
    await assertSucceeds(
      getDocs(
        query(collection(db, 'users'), where('role', '==', 'judge')),
      ),
    );
    await assertFails(getDocs(collection(db, 'users')));
  });

  it('allows admins to create review notifications for applicants', async () => {
    const db = authedDb('super-a');
    await assertSucceeds(
      setDoc(doc(db, 'notifications/review-1'), {
        recipientId: 'player-a',
        type: 'communityApplication',
        title: 'Community approved',
        body: 'The community application review is complete.',
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
