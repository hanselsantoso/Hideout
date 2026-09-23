const projectId = process.env.FIREBASE_PROJECT_ID;
const apiKey =
  process.env.FIREBASE_WEB_API_KEY;
const password = process.env.HIDEOUT_DEMO_PASSWORD;

const accounts = [
  { email: 'hideout.player@example.com', expectedRole: 'player' },
  { email: 'hideout.judge@example.com', expectedRole: 'judge' },
  { email: 'hideout.community@example.com', expectedRole: 'community_admin' },
  { email: 'hideout.super@example.com', expectedRole: 'super_admin' },
];

if (!password || password.length < 12) {
  console.error('Set HIDEOUT_DEMO_PASSWORD to the demo password.');
  process.exit(1);
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

async function signIn(email) {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;
  const body = await requestJson(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });
  return { uid: body.localId, token: body.idToken };
}

async function fetchUserDoc(uid, token) {
  return requestJson(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`,
    { headers: { authorization: `Bearer ${token}` } },
  );
}

function readString(fields, key) {
  return fields?.[key]?.stringValue || '';
}

function readRoles(fields) {
  return (fields?.roles?.arrayValue?.values || [])
    .map((item) => item.stringValue)
    .filter(Boolean);
}

async function main() {
  console.log(`Verifying demo accounts for ${projectId}`);
  for (const account of accounts) {
    const session = await signIn(account.email);
    const doc = await fetchUserDoc(session.uid, session.token);
    const role = readString(doc.fields, 'role');
    const roles = readRoles(doc.fields);
    const active = doc.fields?.isActive?.booleanValue !== false;
    if (role !== account.expectedRole) {
      throw new Error(`${account.email} role mismatch: ${role}`);
    }
    if (!roles.includes(account.expectedRole)) {
      throw new Error(`${account.email} roles missing ${account.expectedRole}`);
    }
    if (!active) {
      throw new Error(`${account.email} is not active`);
    }
    console.log(
      `${account.email}: ok uid=${session.uid} role=${role} roles=${roles.join(',')}`,
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
