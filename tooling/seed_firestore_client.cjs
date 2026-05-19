const fs = require('node:fs');
const path = require('node:path');

const projectId = process.env.FIREBASE_PROJECT_ID || 'tournamentmanagement-942ef';
const apiKey = process.env.FIREBASE_WEB_API_KEY || 'AIzaSyDsYg8Cc1WK3b5JY4wWGYEwDqe4EJXwz7Q';
const email = process.env.HIDEOUT_SUPER_EMAIL || 'hideout.super@example.com';
const password = process.env.HIDEOUT_DEMO_PASSWORD;

if (!password || password.length < 12) {
  console.error('Set HIDEOUT_DEMO_PASSWORD to the demo super admin password.');
  process.exit(1);
}

const now = () => new Date().toISOString();
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
    isActive: true,
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
    isActive: true,
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
    isActive: true,
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
    isActive: true,
  },
  {
    uid: 'demo-mixed-raka',
    email: 'hideout.mixed@example.com',
    displayName: 'Raka Judge Ketua',
    region: 'JKT',
    role: 'community_admin',
    roles: ['player', 'community_admin', 'judge'],
    eloRating: 2716,
    totalWins: 92,
    totalLosses: 41,
    isQrActivated: true,
    isActive: true,
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

const pendingApplications = [
  {
    id: 'demo-app-solo-burst',
    communityName: 'Solo Burst Lab',
    city: 'Surakarta',
    leaderUserId: 'demo-player-kaede',
    requesterId: 'demo-player-kaede',
    description:
      'Komunitas baru Solo dengan 40+ pemain aktif. KTP OK, jadwal venue mingguan sudah tersedia.',
  },
  {
    id: 'demo-app-medan-bey',
    communityName: 'Medan Beybladers',
    city: 'Medan',
    leaderUserId: 'demo-judge-bayu',
    requesterId: 'demo-judge-bayu',
    description:
      'Pengajuan komunitas Medan. Dokumen venue sudah ada, perlu cek ulang data penanggung jawab.',
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

function encodePath(docPath) {
  return docPath.split('/').map(encodeURIComponent).join('/');
}

function toValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toValue) } };
  }
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
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

async function signIn() {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Sign-in failed: ${JSON.stringify(body)}`);
  }
  return body.idToken;
}

async function patchDoc(token, docPath, data) {
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${encodePath(docPath)}`,
  );
  for (const key of Object.keys(data)) {
    url.searchParams.append('updateMask.fieldPaths', key);
  }
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ fields: fieldsFor(data) }),
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Write ${docPath} failed: ${JSON.stringify(body)}`);
  }
}

async function main() {
  const token = await signIn();
  console.log(`Client seeding Firebase project ${projectId}`);

  for (const user of users) {
    await patchDoc(token, `users/${user.uid}`, {
      ...user,
      totalMatches: user.totalWins + user.totalLosses,
      seeded: true,
      updatedAt: now(),
      createdAt: now(),
    });
    console.log(`user:${user.uid}`);
  }

  for (const application of pendingApplications) {
    await patchDoc(token, `communityApplications/${application.id}`, {
      ...application,
      status: 'pending',
      seeded: true,
      updatedAt: now(),
      createdAt: now(),
    });
    console.log(`communityApplication:${application.id}`);
  }

  for (const tournament of tournaments) {
    const { id, registrationFee, ...data } = tournament;
    await patchDoc(token, `tournaments/${id}`, {
      id,
      ...data,
      registrationFee,
      organizerPayout: {
        netRegistrationFeePerPlayer: registrationFee,
        status: 'notRequested',
      },
      seeded: true,
      updatedAt: now(),
      createdAt: now(),
    });
    console.log(`tournament:${id}`);
  }

  for (const [category, name, appearances, wins, losses] of componentStats) {
    const part = findPart(category, name);
    const id = partId(category, name);
    if (part) {
      await patchDoc(token, `components/${id}`, {
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
        stats: statsForPart(part),
        manualPerformance: { appearances: 0, wins: 0, losses: 0 },
        seeded: true,
        updatedAt: now(),
        createdAt: now(),
      });
      console.log(`component:${id}`);
    }
    await patchDoc(token, `componentStats/${id}`, {
      partId: id,
      category,
      name,
      type: part?.type || 'balance',
      image: part?.image || null,
      appearances,
      wins,
      losses,
      seeded: true,
      updatedAt: now(),
    });
    console.log(`componentStats:${id}`);
  }

  for (const [tournamentId, id, playerId, amount, platformFee, status] of payments) {
    await patchDoc(token, `tournaments/${tournamentId}/payments/${id}`, {
      id,
      tournamentId,
      playerId,
      amount,
      platformFee,
      providerFee: Math.round(amount * 0.03),
      status,
      method: 'demo_qris',
      seeded: true,
      paidAt: now(),
      updatedAt: now(),
    });
    console.log(`payment:${tournamentId}/${id}`);
  }

  for (const withdrawal of withdrawals) {
    const { tournamentId, id, ...data } = withdrawal;
    const tournament = tournaments.find((item) => item.id === tournamentId);
    await patchDoc(token, `tournaments/${tournamentId}/withdrawals/${id}`, {
      id,
      tournamentId,
      ...data,
      seeded: true,
      requestedAt: now(),
      updatedAt: now(),
    });
    await patchDoc(token, `tournaments/${tournamentId}`, {
      organizerPayout: {
        netRegistrationFeePerPlayer: tournament?.registrationFee || data.amount,
        status: data.status === 'paid' ? 'paid' : 'processing',
        requestedAmount: data.amount,
        lastWithdrawalId: id,
        feeBorneBy: 'player',
        approvalMode: 'community_admin_auto',
        updatedAt: now(),
      },
      updatedAt: now(),
    });
    console.log(`withdrawal:${tournamentId}/${id}`);
  }

  const selectedIds = componentStats
    .map(([category, name, appearances, wins, losses]) => ({
      id: partId(category, name),
      rate: wins / Math.max(1, wins + losses),
      appearances,
    }))
    .sort((a, b) => b.rate - a.rate || b.appearances - a.appearances)
    .slice(0, 4)
    .map((item) => item.id);
  await patchDoc(token, 'weeklyComponentReleases/current', {
    id: 'current',
    weekLabel: '2026-W21',
    source: 'manual',
    selectedIds,
    seeded: true,
    updatedAt: now(),
  });
  console.log('weeklyComponentRelease:current');
  console.log('Client seed complete');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
