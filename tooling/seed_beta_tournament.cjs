const projectId = process.env.FIREBASE_PROJECT_ID || 'tournamentmanagement-942ef';
const apiKey = process.env.FIREBASE_WEB_API_KEY || 'AIzaSyDsYg8Cc1WK3b5JY4wWGYEwDqe4EJXwz7Q';
const email = process.env.HIDEOUT_SUPER_EMAIL || 'hideout.super@example.com';
const password = process.env.HIDEOUT_DEMO_PASSWORD;

if (!password || password.length < 8) {
  console.error('Set HIDEOUT_DEMO_PASSWORD to a super admin password.');
  process.exit(1);
}

const tournamentId = process.env.BETA_TOURNAMENT_ID || 'turney-beta-open-20260527';
const organizerId = process.env.BETA_ORGANIZER_UID || 'demo-community-admin-nadia';
const now = () => new Date().toISOString();

const tournament = {
  id: tournamentId,
  name: process.env.BETA_TOURNAMENT_NAME || 'TURNEY.ID BETA OPEN TRIAL',
  tagline: 'Sandbox payment and registration beta test',
  description:
    'Open registration tournament for beta testing registration, Xendit sandbox checkout, deck lock, QR check-in, and judge assignment.',
  status: 'registrationOpen',
  bracketType: 'swissTopCut',
  format: 'Swiss + Top Cut',
  tier: 'standard',
  city: 'Jakarta',
  venue: 'Turney Beta Arena',
  location: 'Jakarta, Turney Beta Arena',
  address: 'Jakarta, Indonesia',
  registrationFee: 10000,
  maxParticipants: 32,
  currentParticipantCount: 0,
  participantCount: 0,
  startDate: '2026-05-31T14:00:00+07:00',
  registrationDeadline: '2026-05-30T23:59:00+07:00',
  communityId: 'turney-beta-community',
  communityName: 'Turney Beta Community',
  organizerId,
  judgeIds: [],
  stadiumIds: [],
  maxDecksPerPlayer: 3,
  matchPointTarget: 4,
  lockDeckAfterPayment: true,
  verifiedOnly: true,
  beta: true,
  demo: false,
  seeded: true,
  feePolicy: {
    netFee: 10000,
    platformFee: 1000,
    gatewayFee: 300,
    withdrawFeeCoverage: 500,
    userPayable: 11800,
    feeBorneBy: 'player',
    adminReceives: 10000,
  },
  organizerPayout: {
    netRegistrationFeePerPlayer: 10000,
    status: 'notRequested',
  },
  stageStatus: {
    stage1: 'registrationOpen',
    stage2: 'waitingTopCut',
  },
  stages: [
    {
      index: 0,
      name: 'Swiss Groups',
      format: 'swiss',
      bestOf: 'BO3',
      groupCount: 4,
      advancePerGroup: 4,
    },
    {
      index: 1,
      name: 'Top Cut',
      format: 'singleElimination',
      bestOf: 'BO5',
      advance: 0,
    },
  ],
  rules: [
    'Players must use a saved deck from their profile.',
    'Decks are locked after successful Xendit payment.',
    'Judges may reject deck scans that do not match registration data.',
  ],
  prizes: [
    'Champion: Beta badge + community highlight',
    'Runner-up: Beta badge',
    'Top 4: Profile achievement',
  ],
  schedule: [
    {
      label: 'Registration closes',
      at: '2026-05-30T23:59:00+07:00',
    },
    {
      label: 'Check-in opens',
      at: '2026-05-31T12:30:00+07:00',
    },
    {
      label: 'Tournament starts',
      at: '2026-05-31T14:00:00+07:00',
    },
  ],
};

const community = {
  id: 'turney-beta-community',
  name: 'Turney Beta Community',
  tag: 'TBC',
  city: 'Jakarta',
  region: 'ID',
  status: 'active',
  adminIds: [organizerId],
  beta: true,
  demo: false,
};

function encodePath(path) {
  return path
    .split('/')
    .map((part) => encodeURIComponent(part))
    .join('/');
}

function toValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
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
    return { mapValue: { fields: fieldsFor(value) } };
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
  await patchDoc(token, `communities/${community.id}`, {
    ...community,
    updatedAt: now(),
    createdAt: now(),
  });
  await patchDoc(token, `tournaments/${tournamentId}`, {
    ...tournament,
    updatedAt: now(),
    createdAt: now(),
  });
  console.log(`Seeded beta tournament: ${tournamentId}`);
  console.log('Registration deadline: 2026-05-30T23:59:00+07:00');
  console.log('User payable amount: Rp 11.800');
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
