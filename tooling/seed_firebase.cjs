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
    description: 'Komunitas ranked mingguan untuk area Jakarta.',
  },
  {
    id: 'sby-spin',
    name: 'SBY SPIN',
    city: 'Surabaya',
    region: 'Jawa Timur',
    status: '1 LIVE',
    memberCount: 843,
    adminIds: ['demo-community-admin-nadia'],
    description: 'Arena komunitas Surabaya untuk format Swiss dan finals.',
  },
  {
    id: 'bdg-grinders',
    name: 'BDG GRINDERS',
    city: 'Bandung',
    region: 'Jawa Barat',
    status: 'OPEN',
    memberCount: 712,
    adminIds: ['demo-community-admin-nadia'],
    description: 'Komunitas latihan, deck testing, dan event pemula.',
  },
];

const tournaments = [
  {
    id: 'hideout-cup-04',
    name: 'HIDEOUT CUP #04',
    description: 'Ranked weekend cup dengan Swiss stage dan top cut.',
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
    description: 'Event live Surabaya untuk pemain aktif komunitas.',
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
    description: 'Open event Bandung untuk testing meta baru.',
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
      isActive: true,
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
    const { id, startDate, registrationDeadline, ...data } = tournament;
    await db.collection('tournaments').doc(id).set(
      {
        ...data,
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

async function main() {
  console.log(`Seeding Firebase project ${projectId}`);
  await seedUsers();
  await seedCommunities();
  await seedTournaments();
  await seedComponentStats();
  console.log('Seed complete');
  console.log('Demo password source: HIDEOUT_DEMO_PASSWORD');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
