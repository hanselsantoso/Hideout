const fs = require('node:fs');
const path = require('node:path');

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const {
  FieldValue,
  Timestamp,
  getFirestore,
} = require('firebase-admin/firestore');

const projectId = process.env.FIREBASE_PROJECT_ID || 'tournamentmanagement-942ef';
const demoPassword = process.env.HIDEOUT_DEMO_PASSWORD;

if (!demoPassword || demoPassword.length < 12) {
  console.error(
    'Set HIDEOUT_DEMO_PASSWORD to a temporary demo password with at least 12 characters.',
  );
  process.exit(1);
}

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const auth = getAuth();
const db = getFirestore();

const catalogPath = path.resolve(__dirname, '../assets/data/beyparts.json');
const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));

const users = [
  {
    uid: 'demo-player-kaede',
    email: 'hideout.player@example.com',
    displayName: 'Kaede Demo',
    region: 'JKT',
    role: 'player',
    roles: ['player'],
    eloRating: 2840,
    totalWins: 142,
    totalLosses: 38,
    isQrActivated: true,
  },
  {
    uid: 'demo-judge-bayu',
    email: 'hideout.judge@example.com',
    displayName: 'Bayu Judge',
    region: 'BDG',
    role: 'judge',
    roles: ['player', 'judge'],
    eloRating: 2672,
    totalWins: 88,
    totalLosses: 49,
    isQrActivated: true,
  },
  {
    uid: 'demo-community-admin-nadia',
    email: 'hideout.community@example.com',
    displayName: 'Nadia Community',
    region: 'SBY',
    role: 'community_admin',
    roles: ['player', 'community_admin'],
    eloRating: 2760,
    totalWins: 116,
    totalLosses: 44,
    isQrActivated: true,
  },
  {
    uid: 'demo-super-admin-hansel',
    email: 'hideout.super@example.com',
    displayName: 'Hansel Platform',
    region: 'ID',
    role: 'super_admin',
    roles: ['super_admin'],
    eloRating: 3000,
    totalWins: 0,
    totalLosses: 0,
    isQrActivated: true,
  },
  {
    uid: 'demo-mixed-raka',
    email: 'hideout.mixed@example.com',
    displayName: 'Raka Judge Lead',
    region: 'JKT',
    role: 'community_admin',
    roles: ['player', 'community_admin', 'judge'],
    eloRating: 2716,
    totalWins: 92,
    totalLosses: 41,
    isQrActivated: true,
  },
  {
    uid: 'demo-banned-user',
    email: 'hideout.banned@example.com',
    displayName: 'Banned Demo',
    region: 'JKT',
    role: 'player',
    roles: ['player'],
    eloRating: 1200,
    totalWins: 1,
    totalLosses: 9,
    isQrActivated: false,
    isActive: false,
  },
];

const communities = [
  {
    id: 'jkt-wolves',
    name: 'JKT WOLVES',
    city: 'Jakarta',
    region: 'Jakarta',
    status: '2 LIVE',
    memberCount: 1248,
    adminIds: ['demo-community-admin-nadia'],
    description: 'Weekly ranked community for the Jakarta area.',
  },
  {
    id: 'sby-spin',
    name: 'SBY SPIN',
    city: 'Surabaya',
    region: 'Jawa Timur',
    status: '1 LIVE',
    memberCount: 843,
    adminIds: ['demo-community-admin-nadia'],
    description: 'Surabaya community arena for Swiss and finals formats.',
  },
  {
    id: 'bdg-grinders',
    name: 'BDG GRINDERS',
    city: 'Bandung',
    region: 'Jawa Barat',
    status: 'OPEN',
    memberCount: 712,
    adminIds: ['demo-community-admin-nadia'],
    description: 'Practice community, deck testing, and beginner events.',
  },
];

const tournaments = [
  {
    id: 'hideout-cup-04',
    name: 'HIDEOUT CUP #04',
    description: 'Ranked weekend cup with Swiss stage and top cut.',
    status: 'registrationOpen',
    bracketType: 'swissTopCut',
    location: 'Jakarta, JKT WOLVES Arena',
    registrationFee: 50000,
    maxParticipants: 32,
    currentParticipantCount: 28,
    startDate: '2026-05-24T13:00:00+07:00',
    registrationDeadline: '2026-05-23T21:00:00+07:00',
    communityId: 'jkt-wolves',
    organizerId: 'demo-community-admin-nadia',
    judgeIds: ['demo-judge-bayu'],
  },
  {
    id: 'east-coast-showdown',
    name: 'EAST COAST SHOWDOWN',
    description: 'Live Surabaya event for active community players.',
    status: 'running',
    bracketType: 'singleElimination',
    location: 'Surabaya, SBY SPIN Base',
    registrationFee: 35000,
    maxParticipants: 16,
    currentParticipantCount: 16,
    startDate: '2026-05-26T15:00:00+07:00',
    registrationDeadline: '2026-05-25T21:00:00+07:00',
    communityId: 'sby-spin',
    organizerId: 'demo-community-admin-nadia',
    judgeIds: ['demo-judge-bayu'],
  },
  {
    id: 'highland-open',
    name: 'HIGHLAND OPEN',
    description: 'Open Bandung event for testing the new meta.',
    status: 'upcoming',
    bracketType: 'swiss',
    location: 'Bandung, BDG GRINDERS Hideout',
    registrationFee: 40000,
    maxParticipants: 24,
    currentParticipantCount: 12,
    startDate: '2026-05-31T11:00:00+07:00',
    registrationDeadline: '2026-05-30T20:00:00+07:00',
    communityId: 'bdg-grinders',
    organizerId: 'demo-community-admin-nadia',
    judgeIds: ['demo-judge-bayu'],
  },
];

const componentStats = [
  ['blades', 'Phoenix Wing', 1204, 700, 504],
  ['bits', 'Rush', 902, 495, 407],
  ['ratchets', '9-60', 744, 390, 354],
  ['bits', 'Ball', 488, 243, 245],
  ['blades', 'Wizard Rod', 428, 232, 196],
  ['blades', 'Dran Buster', 382, 214, 168],
  ['ratchets', '3-60', 366, 190, 176],
  ['bits', 'Taper', 341, 177, 164],
];

const pendingApplications = [
  {
    id: 'demo-app-solo-burst',
    communityName: 'Solo Burst Lab',
    city: 'Surakarta',
    leaderUserId: 'demo-player-kaede',
    requesterId: 'demo-player-kaede',
    tag: 'SBL',
    type: 'Regional Club',
    region: 'Yogyakarta',
    website: 'https://solo-burst.example',
    leader: {
      name: 'Kaede Demo',
      email: 'hideout.player@example.com',
      phone: '081234567890',
      instagram: '@solo_burst_lab',
    },
    financeAccount: {
      bankName: 'BCA',
      accountNumber: '1234567890',
      holderName: 'Kaede Demo',
      branch: 'Solo',
      withdrawMode: 'community_admin_auto',
    },
    documents: {
      logoUploaded: true,
      idUploaded: true,
      letterUploaded: true,
    },
    description:
      'New Solo community with 40+ active players. ID verified, weekly venue schedule is available.',
  },
  {
    id: 'demo-app-medan-bey',
    communityName: 'Medan Beybladers',
    city: 'Medan',
    leaderUserId: 'demo-judge-bayu',
    requesterId: 'demo-judge-bayu',
    tag: 'MDB',
    type: 'Campuran',
    region: 'Medan',
    website: '',
    leader: {
      name: 'Bayu Judge',
      email: 'hideout.judge@example.com',
      phone: '081987654321',
      instagram: '@medan_beybladers',
    },
    financeAccount: {
      bankName: 'Bank Mandiri',
      accountNumber: '9876543210',
      holderName: 'Bayu Judge',
      branch: 'Medan Kota',
      withdrawMode: 'community_admin_auto',
    },
    documents: {
      logoUploaded: false,
      idUploaded: true,
      letterUploaded: false,
    },
    description:
      'Medan community application. Venue documents are available; responsible party data needs another check.',
  },
];

const reviewedApplications = [
  {
    id: 'demo-app-jkt-wolves-approved',
    communityName: 'JKT WOLVES',
    city: 'Jakarta',
    leaderUserId: 'demo-community-admin-nadia',
    requesterId: 'demo-community-admin-nadia',
    tag: 'WLV',
    type: 'Kompetitif',
    region: 'Jakarta',
    status: 'approved',
    communityId: 'jkt-wolves',
    reviewerId: 'demo-super-admin-hansel',
    description: 'Existing verified Jakarta community.',
  },
  {
    id: 'demo-app-bali-rejected',
    communityName: 'Bali Spin House',
    city: 'Denpasar',
    leaderUserId: 'demo-player-kaede',
    requesterId: 'demo-player-kaede',
    tag: 'BSH',
    type: 'Casual & Community',
    region: 'Bali',
    status: 'rejected',
    reviewerId: 'demo-super-admin-hansel',
    rejectionReason: 'Venue data and responsible party identity are incomplete.',
    description: 'Demo application intentionally rejected for review history.',
  },
];

const componentMaster = [
  ['blades', 'Phoenix Wing'],
  ['bits', 'Rush'],
  ['ratchets', '9-60'],
  ['bits', 'Ball'],
  ['blades', 'Wizard Rod'],
  ['blades', 'Dran Buster'],
  ['ratchets', '3-60'],
  ['bits', 'Taper'],
];

const payments = [
  ['hideout-cup-04', 'pay-001', 'demo-player-kaede', 55000, 5000, 'paid'],
  ['hideout-cup-04', 'pay-002', 'demo-judge-bayu', 55000, 5000, 'paid'],
  ['east-coast-showdown', 'pay-003', 'demo-player-kaede', 38500, 3500, 'paid'],
  ['highland-open', 'pay-004', 'demo-mixed-raka', 44000, 4000, 'paid'],
];

const withdrawals = [
  {
    tournamentId: 'hideout-cup-04',
    id: 'wd-001',
    requesterId: 'demo-community-admin-nadia',
    requesterName: 'Nadia Community',
    amount: 850000,
    bankName: 'BCA',
    accountNumber: '1234567890',
    accountName: 'Nadia Community',
    status: 'processing',
    approvalMode: 'community_admin_auto',
  },
  {
    tournamentId: 'east-coast-showdown',
    id: 'wd-002',
    requesterId: 'demo-community-admin-nadia',
    requesterName: 'Nadia Community',
    amount: 420000,
    bankName: 'Mandiri',
    accountNumber: '9876543210',
    accountName: 'Nadia Community',
    status: 'paid',
    approvalMode: 'community_admin_auto',
  },
];

function slug(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function partId(category, name) {
  return `${category}_${slug(name)}`;
}

function findPart(category, name) {
  return (catalog[category] || []).find((part) => part.name === name);
}

function statsForPart(part) {
  const fallback = part?.modes?.[0] || part || {};
  return {
    attack: fallback.attack || 0,
    defense: fallback.defense || 0,
    stamina: fallback.stamina || 0,
    xDash: fallback.xDash || 0,
    burstResistance: fallback.burstResistance || 0,
  };
}

async function upsertUser(user) {
  let record;
  try {
    record = await auth.getUserByEmail(user.email);
    await auth.updateUser(record.uid, {
      displayName: user.displayName,
      password: demoPassword,
      disabled: false,
    });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    record = await auth.createUser({
      uid: user.uid,
      email: user.email,
      emailVerified: true,
      password: demoPassword,
      displayName: user.displayName,
      disabled: false,
    });
  }

  await auth.setCustomUserClaims(record.uid, {
    role: user.role,
    roles: user.roles,
  });

  await db.collection('users').doc(record.uid).set(
    {
      uid: record.uid,
      displayName: user.displayName,
      email: user.email,
      region: user.region,
      role: user.role,
      roles: user.roles,
      eloRating: user.eloRating,
      totalWins: user.totalWins,
      totalLosses: user.totalLosses,
      totalMatches: user.totalWins + user.totalLosses,
      isQrActivated: user.isQrActivated,
      isActive: user.isActive !== false,
      seeded: true,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return record.uid;
}

async function seedUsers() {
  for (const user of users) {
    const uid = await upsertUser(user);
    console.log(`user:${uid}`);
  }
}

async function seedCommunities() {
  for (const community of communities) {
    await db.collection('communities').doc(community.id).set(
      {
        ...community,
        seeded: true,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log(`community:${community.id}`);
  }
}

async function seedTournaments() {
  for (const tournament of tournaments) {
    const { id, startDate, registrationDeadline, registrationFee, ...data } = tournament;
    await db.collection('tournaments').doc(id).set(
      {
        ...data,
        registrationFee,
        organizerPayout: {
          netRegistrationFeePerPlayer: registrationFee,
          status: 'notRequested',
        },
        startDate: Timestamp.fromDate(new Date(startDate)),
        registrationDeadline: Timestamp.fromDate(new Date(registrationDeadline)),
        seeded: true,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await db
      .collection('tournaments')
      .doc(id)
      .collection('registrations')
      .doc('demo-player-kaede')
      .set(
        {
          playerId: 'demo-player-kaede',
          playerName: 'Kaede Demo',
          status: 'confirmed',
          checkInStatus: id === 'east-coast-showdown' ? 'checkedIn' : 'pending',
          deckVerificationStatus: 'pending',
          registeredAt: FieldValue.serverTimestamp(),
          seeded: true,
        },
        { merge: true },
      );
    console.log(`tournament:${id}`);
  }
}

async function seedComponentStats() {
  for (const [category, name, appearances, wins, losses] of componentStats) {
    const part = findPart(category, name);
    const id = partId(category, name);
    await db.collection('componentStats').doc(id).set(
      {
        category,
        name,
        type: part?.type || 'balance',
        image: part?.image || null,
        appearances,
        wins,
        losses,
        seeded: true,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log(`componentStats:${id}`);
  }
}

async function seedComponents() {
  for (const [category, name] of componentMaster) {
    const part = findPart(category, name);
    if (!part) continue;
    const id = partId(category, name);
    const stats = statsForPart(part);
    await db.collection('components').doc(id).set(
      {
        id,
        category,
        name,
        alias: part.alias || null,
        type: part.type || 'balance',
        line: part.line || '',
        image: part.image || null,
        integratedRatchet: part.integratedRatchet || null,
        description: part.description || null,
        source: ['BeyBrew', 'Seed'],
        active: true,
        stats,
        manualPerformance: {
          appearances: 0,
          wins: 0,
          losses: 0,
        },
        seeded: true,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log(`component:${id}`);
  }
}

async function seedPendingApplications() {
  for (const application of pendingApplications) {
    await db.collection('communityApplications').doc(application.id).set(
      {
        ...application,
        status: 'pending',
        seeded: true,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log(`communityApplication:${application.id}`);
  }

  for (const application of reviewedApplications) {
    await db.collection('communityApplications').doc(application.id).set(
      {
        ...application,
        seeded: true,
        reviewEvents: [
          {
            status: application.status,
            reviewerId: application.reviewerId,
            communityId: application.communityId || '',
            reason: application.rejectionReason || '',
            at: new Date().toISOString(),
          },
        ],
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
        reviewedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log(`communityApplication:${application.id}`);
  }
}

async function seedFinance() {
  for (const [tournamentId, id, playerId, amount, platformFee, status] of payments) {
    await db
      .collection('tournaments')
      .doc(tournamentId)
      .collection('payments')
      .doc(id)
      .set(
        {
          id,
          tournamentId,
          playerId,
          amount,
          platformFee,
          providerFee: Math.round(amount * 0.03),
          status,
          method: 'demo_qris',
          seeded: true,
          paidAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    console.log(`payment:${tournamentId}/${id}`);
  }

  for (const withdrawal of withdrawals) {
    const { tournamentId, id, ...data } = withdrawal;
    const tournament = tournaments.find((item) => item.id === tournamentId);
    await db
      .collection('tournaments')
      .doc(tournamentId)
      .collection('withdrawals')
      .doc(id)
      .set(
        {
          id,
          tournamentId,
          ...data,
          seeded: true,
          requestedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    await db.collection('tournaments').doc(tournamentId).set(
      {
        organizerPayout: {
          netRegistrationFeePerPlayer: tournament?.registrationFee || data.amount,
          status: data.status === 'paid' ? 'paid' : 'processing',
          requestedAmount: data.amount,
          lastWithdrawalId: id,
          feeBorneBy: 'player',
          approvalMode: 'community_admin_auto',
          updatedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log(`withdrawal:${tournamentId}/${id}`);
  }
}

async function seedWeeklyRelease() {
  const selectedIds = componentStats
    .map(([category, name, appearances, wins, losses]) => ({
      id: partId(category, name),
      rate: wins / Math.max(1, wins + losses),
      appearances,
    }))
    .sort((a, b) => b.rate - a.rate || b.appearances - a.appearances)
    .slice(0, 4)
    .map((item) => item.id);
  await db.collection('weeklyComponentReleases').doc('current').set(
    {
      id: 'current',
      weekLabel: '2026-W21',
      source: 'manual',
      selectedIds,
      seeded: true,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  console.log('weeklyComponentRelease:current');
}

async function main() {
  console.log(`Seeding Firebase project ${projectId}`);
  await seedUsers();
  await seedCommunities();
  await seedTournaments();
  await seedPendingApplications();
  await seedComponents();
  await seedComponentStats();
  await seedFinance();
  await seedWeeklyRelease();
  console.log('Seed complete');
  console.log('Demo password source: HIDEOUT_DEMO_PASSWORD');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
