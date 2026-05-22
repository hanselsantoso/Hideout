const projectId = process.env.FIREBASE_PROJECT_ID || 'tournamentmanagement-942ef';
const apiKey =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyDsYg8Cc1WK3b5JY4wWGYEwDqe4EJXwz7Q';
const demoPassword = process.env.HIDEOUT_DEMO_PASSWORD;

const stamp = new Date()
  .toISOString()
  .replace(/[-:.TZ]/g, '')
  .slice(0, 12)
  .toLowerCase();
const trialPassword = process.env.HIDEOUT_TRIAL_PASSWORD || `TurneyTrial${stamp}!`;

if (!demoPassword) {
  throw new Error('Set HIDEOUT_DEMO_PASSWORD before running this live trial.');
}

const ids = {
  application: `trial-app-${stamp}`,
  community: `trial-community-${stamp}`,
  tournament: `trial-tournament-${stamp}`,
};

const demo = {
  superEmail: 'hideout.super@example.com',
  judgeEmail: 'hideout.judge@example.com',
  judgeUid: 'demo-judge-bayu',
  judgeName: 'Bayu Judge',
};

function encodePath(value) {
  return value.split('/').map(encodeURIComponent).join('/');
}

function firestoreUrl(path) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${encodePath(path)}`;
}

async function requestJson(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  const body = text ? JSON.parse(text) : {};
  if (!response.ok) {
    throw new Error(`${options.method || 'GET'} ${url} failed: ${text}`);
  }
  return body;
}

function toValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toValue) } };
  }
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, item]) => [key, toValue(item)]),
        ),
      },
    };
  }
  return { stringValue: String(value) };
}

function fieldsFor(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, toValue(value)]),
  );
}

async function signIn(email, password) {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;
  const body = await requestJson(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  return { uid: body.localId, token: body.idToken, email };
}

async function signUp(email, displayName, region = 'Jakarta') {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`;
  let body;
  try {
    body = await requestJson(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        email,
        password: trialPassword,
        displayName,
        returnSecureToken: true,
      }),
    });
  } catch (error) {
    if (!String(error.message).includes('EMAIL_EXISTS')) throw error;
    return signIn(email, trialPassword);
  }
  const session = { uid: body.localId, token: body.idToken, email };
  await patchDoc(session.token, `users/${session.uid}`, {
    uid: session.uid,
    displayName,
    email,
    region,
    role: 'player',
    roles: ['player'],
    eloRating: 1000,
    totalWins: 0,
    totalLosses: 0,
    totalMatches: 0,
    isQrActivated: true,
    isActive: true,
    trialSeed: stamp,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
  return session;
}

async function patchDoc(token, docPath, data) {
  const url = new URL(firestoreUrl(docPath));
  for (const key of Object.keys(data)) {
    url.searchParams.append('updateMask.fieldPaths', key);
  }
  await requestJson(url, {
    method: 'PATCH',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ fields: fieldsFor(data) }),
  });
}

async function listDocs(token, collectionPath) {
  const body = await requestJson(firestoreUrl(collectionPath), {
    headers: { authorization: `Bearer ${token}` },
  }).catch((error) => {
    if (String(error.message).includes('NOT_FOUND')) return { documents: [] };
    throw error;
  });
  return body.documents || [];
}

async function createCommunityApplication(leader) {
  await patchDoc(leader.token, `communityApplications/${ids.application}`, {
    id: ids.application,
    requesterId: leader.uid,
    communityName: 'Turney Trial Arena',
    city: 'Jakarta',
    leaderUserId: leader.uid,
    description: 'End-to-end trial community for validating the initial Turney flow.',
    tag: 'TTA',
    type: 'Regional Club',
    region: 'Jakarta',
    website: 'https://turney.id',
    leader: {
      name: 'Nadia Trial Lead',
      email: leader.email,
      phone: '081200001111',
      instagram: '@turney_trial',
    },
    financeAccount: {
      bankName: 'BCA',
      accountNumber: '1122334455',
      holderName: 'Nadia Trial Lead',
      branch: 'Jakarta',
      withdrawMode: 'community_admin_auto',
    },
    documents: {
      logoUploaded: true,
      idUploaded: true,
      letterUploaded: true,
    },
    status: 'pending',
    trialSeed: stamp,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
}

async function approveCommunity(superAdmin, leader) {
  await patchDoc(superAdmin.token, `communities/${ids.community}`, {
    id: ids.community,
    name: 'Turney Trial Arena',
    tag: 'TTA',
    type: 'Regional Club',
    city: 'Jakarta',
    region: 'Jakarta',
    website: 'https://turney.id',
    description: 'End-to-end trial community for validating the initial Turney flow.',
    leaderUserId: leader.uid,
    leader: {
      name: 'Nadia Trial Lead',
      email: leader.email,
      phone: '081200001111',
      instagram: '@turney_trial',
    },
    financeAccount: {
      bankName: 'BCA',
      accountNumber: '1122334455',
      holderName: 'Nadia Trial Lead',
      branch: 'Jakarta',
      withdrawMode: 'community_admin_auto',
    },
    documents: {
      logoUploaded: true,
      idUploaded: true,
      letterUploaded: true,
    },
    adminIds: [leader.uid],
    memberCount: 1,
    status: 'active',
    sourceApplicationId: ids.application,
    trialSeed: stamp,
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  await patchDoc(superAdmin.token, `communityApplications/${ids.application}`, {
    status: 'approved',
    reviewerId: superAdmin.uid,
    communityId: ids.community,
    reviewedAt: new Date(),
    updatedAt: new Date(),
    reviewEvents: [
      {
        status: 'approved',
        reviewerId: superAdmin.uid,
        communityId: ids.community,
        at: new Date().toISOString(),
      },
    ],
  });

  await patchDoc(superAdmin.token, `users/${leader.uid}`, {
    role: 'community_admin',
    roles: ['community_admin', 'player'],
    communityIds: [ids.community],
    updatedAt: new Date(),
  });
}

async function createTournament(leader) {
  const start = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000);
  const deadline = new Date(Date.now() + 24 * 60 * 60 * 1000);
  await patchDoc(leader.token, `tournaments/${ids.tournament}`, {
    id: ids.tournament,
    name: 'Turney Trial Cup',
    description: 'Trial event from clean data: registration, group builder, judges, and scoring.',
    status: 'registrationOpen',
    bracketType: 'roundRobinTopCut',
    location: 'Jakarta, Turney Trial Arena',
    registrationFee: 25000,
    maxParticipants: 24,
    currentParticipantCount: 0,
    startDate: start,
    endDate: new Date(start.getTime() + 6 * 60 * 60 * 1000),
    registrationDeadline: deadline,
    communityId: ids.community,
    organizerId: leader.uid,
    judgeIds: [demo.judgeUid],
    matchPointTarget: 4,
    rules: {
      allowSameComboMultiple: false,
      maxDecksPerPlayer: 3,
      penaltyThreshold: 2,
      publicVisibility: {
        showRules: true,
        showBracket: true,
        showGroupStandings: true,
        showNextCall: true,
        showResults: true,
      },
    },
    stages: [
      {
        index: 1,
        name: 'Stage 1',
        format: 'roundRobin',
        bestOf: 'BO5',
        groupCount: 3,
        advancePerGroup: 2,
        pairing: 'roundRobinAllPlayAll',
      },
      {
        index: 2,
        name: 'Stage 2',
        format: 'doubleElimination',
        bestOf: 'BO5',
        advanceTotal: 6,
      },
    ],
    organizerPayout: {
      netRegistrationFeePerPlayer: 25000,
      status: 'notRequested',
    },
    trialSeed: stamp,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
}

function playerEmail(index) {
  return `turney.trial.p${index}.${stamp}@example.com`;
}

async function registerPlayers(leader) {
  const players = [];
  for (let i = 1; i <= 6; i++) {
    const player = await signUp(playerEmail(i), `Trial Player ${i}`, 'Jakarta');
    const registrationId = `trial-reg-${stamp}-${i}`;
    const deckName = [
      'Phoenix Wing Rush',
      'Wizard Rod Ball',
      'Dran Buster Taper',
      'Knight Shield Needle',
      'Shark Edge Low Flat',
      'Unicorn Sting Point',
    ][i - 1];
    await patchDoc(
      player.token,
      `tournaments/${ids.tournament}/registrations/${registrationId}`,
      {
        id: registrationId,
        tournamentId: ids.tournament,
        playerId: player.uid,
        playerName: `Trial Player ${i}`,
        deckId: `trial-deck-${i}`,
        deckName,
        deckSnapshot: {
          id: `trial-deck-${i}`,
          name: deckName,
          combos: [
            { blade: 'Phoenix Wing', ratchet: '9-60', bit: 'Rush' },
            { blade: 'Wizard Rod', ratchet: '3-60', bit: 'Ball' },
            { blade: 'Dran Buster', ratchet: '5-60', bit: 'Taper' },
          ],
        },
        paymentStatus: 'pending',
        registrationStatus: 'pendingPayment',
        checkInStatus: 'pending',
        deckVerificationStatus: 'pending',
        trialSeed: stamp,
        registeredAt: new Date(),
        updatedAt: new Date(),
      },
    );
    players.push({ ...player, registrationId, deckName, name: `Trial Player ${i}` });
  }

  for (const player of players) {
    await patchDoc(
      leader.token,
      `tournaments/${ids.tournament}/registrations/${player.registrationId}`,
      {
        paymentStatus: 'paid',
        registrationStatus: 'active',
        paymentId: `TRIAL-PAY-${player.registrationId}`,
        paidAt: new Date(),
        activatedAt: new Date(),
        updatedAt: new Date(),
      },
    );
  }
  await patchDoc(leader.token, `tournaments/${ids.tournament}`, {
    currentParticipantCount: players.length,
    updatedAt: new Date(),
  });
  return players;
}

async function saveGroupsAndGenerateMatches(leader, players) {
  const groupDefs = [
    { name: 'Alpha Burst', players: [players[0], players[3]] },
    { name: 'Beta Launch', players: [players[1], players[4]] },
    { name: 'Gamma Spin', players: [players[2], players[5]] },
  ];

  await patchDoc(leader.token, `tournaments/${ids.tournament}`, {
    roundRobin: {
      groupCount: groupDefs.length,
      assignmentMode: 'manualDraft',
      draftGroups: groupDefs.map((group, index) => ({
        name: group.name,
        index: index + 1,
        playerCount: group.players.length,
        players: group.players.map((player) => ({
          registrationId: player.registrationId,
          playerId: player.uid,
          playerName: player.name,
          deckId: `trial-deck-${player.name.split(' ').at(-1)}`,
          deckName: player.deckName,
          paymentStatus: 'paid',
          registrationStatus: 'active',
        })),
      })),
      draftUpdatedAt: new Date(),
      advancePerGroup: 2,
      totalMatches: groupDefs.length,
      groupNames: groupDefs.map((group) => group.name),
    },
    status: 'running',
    currentStage: 1,
    currentRoundId: 'stage-1-group-1',
    stageStatus: { stage1: 'running', stage2: 'waitingTopCut' },
    updatedAt: new Date(),
  });

  const matches = [];
  for (let i = 0; i < groupDefs.length; i++) {
    const group = groupDefs[i];
    const roundId = `stage-1-group-${i + 1}`;
    await patchDoc(leader.token, `tournaments/${ids.tournament}/rounds/${roundId}`, {
      id: roundId,
      tournamentId: ids.tournament,
      name: group.name,
      index: i + 1,
      format: 'roundRobin',
      stage: 1,
      status: 'ready',
      groupName: group.name,
      matchCount: 1,
      advancePerGroup: 2,
      tiebreaker: 'Match win percentage, point difference, head-to-head, sudden death',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const [a, b] = group.players;
    const matchId = 'm-001';
    const matchCode = `${String.fromCharCode(65 + i)}-001`;
    await patchDoc(
      leader.token,
      `tournaments/${ids.tournament}/rounds/${roundId}/matches/${matchId}`,
      {
        id: matchId,
        tournamentId: ids.tournament,
        roundId,
        matchCode,
        status: i === 0 ? 'ready' : 'queued',
        stage: 1,
        format: 'roundRobin',
        groupName: group.name,
        arena: `Arena 0${i + 1}`,
        judgeId: demo.judgeUid,
        judgeName: demo.judgeName,
        matchPointTarget: 4,
        playerAId: a.uid,
        playerAName: a.name,
        playerADeckId: `trial-deck-${i + 1}-a`,
        playerADeckName: a.deckName,
        playerARegistrationId: a.registrationId,
        playerBId: b.uid,
        playerBName: b.name,
        playerBDeckId: `trial-deck-${i + 1}-b`,
        playerBDeckName: b.deckName,
        playerBRegistrationId: b.registrationId,
        bracketPosition: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    );
    matches.push({ roundId, matchId, matchCode, a, b });
  }
  return matches;
}

async function judgeScanAndScore(judge, matches) {
  const first = matches[0];
  await patchDoc(
    judge.token,
    `tournaments/${ids.tournament}/registrations/${first.a.registrationId}`,
    {
      checkInStatus: 'checkedIn',
      deckVerificationStatus: 'verified',
      judgeChecks: [
        {
          judgeId: demo.judgeUid,
          status: 'verified',
          side: 'A',
          at: new Date().toISOString(),
        },
      ],
      lastJudgeActionAt: new Date(),
      updatedAt: new Date(),
    },
  );
  await patchDoc(
    judge.token,
    `tournaments/${ids.tournament}/registrations/${matches[2].b.registrationId}`,
    {
      checkInStatus: 'checkedIn',
      deckVerificationStatus: 'rejected',
      judgeChecks: [
        {
          judgeId: demo.judgeUid,
          status: 'rejected',
          reason: 'Trial mismatch check',
          at: new Date().toISOString(),
        },
      ],
      lastJudgeActionAt: new Date(),
      updatedAt: new Date(),
    },
  );
  await patchDoc(
    judge.token,
    `tournaments/${ids.tournament}/rounds/${first.roundId}/matches/${first.matchId}`,
    {
      status: 'completed',
      winnerId: first.a.uid,
      winnerName: first.a.name,
      finalScore: '4-2',
      completedAt: new Date(),
      updatedAt: new Date(),
    },
  );
}

async function verify(judge) {
  const rounds = await listDocs(judge.token, `tournaments/${ids.tournament}/rounds`);
  let matchCount = 0;
  for (const round of rounds) {
    const roundId = round.name.split('/').at(-1);
    const matches = await listDocs(
      judge.token,
      `tournaments/${ids.tournament}/rounds/${roundId}/matches`,
    );
    matchCount += matches.length;
  }
  const registrations = await listDocs(
    judge.token,
    `tournaments/${ids.tournament}/registrations`,
  );
  return { rounds: rounds.length, matches: matchCount, registrations: registrations.length };
}

async function main() {
  console.log(`Running live trial against ${projectId}`);
  console.log(`Trial seed: ${stamp}`);

  const superAdmin = await signIn(demo.superEmail, demoPassword);
  const judge = await signIn(demo.judgeEmail, demoPassword);
  const leader = await signUp(`turney.trial.lead.${stamp}@example.com`, 'Nadia Trial Lead');

  await createCommunityApplication(leader);
  console.log(`pendingApplication:${ids.application}`);

  await approveCommunity(superAdmin, leader);
  console.log(`approvedCommunity:${ids.community}`);

  const leaderSession = await signIn(leader.email, trialPassword);
  await createTournament(leaderSession);
  console.log(`tournament:${ids.tournament}`);

  const players = await registerPlayers(leaderSession);
  console.log(`playersRegistered:${players.length}`);

  const matches = await saveGroupsAndGenerateMatches(leaderSession, players);
  console.log(`matchesGenerated:${matches.length}`);

  await judgeScanAndScore(judge, matches);
  console.log(`judgeVerifiedAndScored:${matches[0].matchCode}`);

  const result = await verify(judge);
  console.log('verification:', JSON.stringify(result));
  console.log('\nTrial URLs');
  console.log(`Public: https://turney.id`);
  console.log(`Tournament id: ${ids.tournament}`);
  console.log(`Community id: ${ids.community}`);
  console.log(`Leader email: ${leader.email}`);
  console.log(`Player password: ${trialPassword}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
