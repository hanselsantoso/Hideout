const projectId = process.env.FIREBASE_PROJECT_ID || 'tournamentmanagement-942ef';
const apiKey =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyDsYg8Cc1WK3b5JY4wWGYEwDqe4EJXwz7Q';
const email = process.env.HIDEOUT_SUPER_EMAIL || 'hideout.super@example.com';
const password = process.env.HIDEOUT_DEMO_PASSWORD;
const execute = process.argv.includes('--execute');
const executeCli = process.argv.includes('--execute-cli');
const deleteAuthUsers = process.argv.includes('--delete-auth-users');

const preserveDemoUids = new Set([
  'demo-player-kaede',
  'demo-judge-bayu',
  'demo-community-admin-nadia',
  'demo-super-admin-hansel',
]);

const preserveDemoEmails = new Set([
  'hideout.player@example.com',
  'hideout.judge@example.com',
  'hideout.community@example.com',
  'hideout.super@example.com',
]);

const deleteCollections = [
  'communities',
  'communityApplications',
  'notifications',
  'tournaments',
];

const preserveCollections = [
  'components',
  'componentStats',
  'weeklyComponentReleases',
];

const knownSubcollections = {
  users: ['decks'],
  tournaments: ['registrations', 'payments', 'withdrawals', 'rounds'],
  rounds: ['matches', 'standings'],
  matches: ['battles'],
};

if (!password || password.length < 12) {
  console.error('Set HIDEOUT_DEMO_PASSWORD to the demo super admin password.');
  process.exit(1);
}

function encodePath(value) {
  return value.split('/').map(encodeURIComponent).join('/');
}

function docPathFromName(name) {
  return name.split('/documents/')[1] || name;
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

async function signIn() {
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
  return body.idToken;
}

function firestoreUrl(path) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${encodePath(path)}`;
}

async function listDocuments(token, collectionPath) {
  const docs = [];
  let pageToken = '';
  do {
    const url = new URL(firestoreUrl(collectionPath));
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const body = await requestJson(url, {
      headers: { authorization: `Bearer ${token}` },
    });
    for (const doc of body.documents || []) docs.push(doc);
    pageToken = body.nextPageToken || '';
  } while (pageToken);
  return docs;
}

async function listCollectionIds(token, docPath) {
  const ids = new Set(knownSubcollections[docPath.split('/').at(-2)] || []);
  let pageToken = '';
  do {
    const url = `${firestoreUrl(docPath)}:listCollectionIds`;
    const body = await requestJson(url, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ pageSize: 100, pageToken }),
    }).catch(() => ({ collectionIds: [], nextPageToken: '' }));
    for (const id of body.collectionIds || []) ids.add(id);
    pageToken = body.nextPageToken || '';
  } while (pageToken);
  return [...ids];
}

async function deleteDoc(token, docPath, stats) {
  stats.firestoreDocs.push(docPath);
  if (!execute || executeCli) return;
  await requestJson(firestoreUrl(docPath), {
    method: 'DELETE',
    headers: { authorization: `Bearer ${token}` },
  }).catch((error) => {
    if (!String(error.message).includes('NOT_FOUND')) throw error;
  });
}

async function deleteDocumentTree(token, docPath, stats) {
  const subcollections = await listCollectionIds(token, docPath);
  for (const subcollection of subcollections) {
    const childPath = `${docPath}/${subcollection}`;
    const childDocs = await listDocuments(token, childPath).catch((error) => {
      stats.warnings.push(`${childPath} skipped: ${error.message}`);
      return [];
    });
    for (const child of childDocs) {
      await deleteDocumentTree(token, docPathFromName(child.name), stats);
    }
  }
  await deleteDoc(token, docPath, stats);
}

function shouldPreserveUser(doc) {
  const docPath = docPathFromName(doc.name);
  const uid = docPath.split('/').at(-1);
  const emailField = doc.fields?.email?.stringValue || '';
  return preserveDemoUids.has(uid) || preserveDemoEmails.has(emailField);
}

async function resetFirestore(token) {
  const stats = {
    firestoreDocs: [],
    userDocsToDelete: [],
    preservedUsers: [],
    preservedCollections: preserveCollections,
    warnings: [],
  };

  const users = await listDocuments(token, 'users').catch((error) => {
    stats.warnings.push(`users skipped: ${error.message}`);
    return [];
  });
  for (const user of users) {
    const docPath = docPathFromName(user.name);
    if (shouldPreserveUser(user)) {
      stats.preservedUsers.push(docPath);
      continue;
    }
    stats.userDocsToDelete.push(docPath);
    await deleteDocumentTree(token, docPath, stats);
  }

  for (const collection of deleteCollections) {
    const docs = await listDocuments(token, collection).catch((error) => {
      stats.warnings.push(`${collection} skipped: ${error.message}`);
      return [];
    });
    for (const doc of docs) {
      await deleteDocumentTree(token, docPathFromName(doc.name), stats);
    }
  }

  return stats;
}

async function resetAuthUsers(stats) {
  if (!deleteAuthUsers) return { checked: false, deleted: [], warning: null };
  let admin;
  try {
    admin = require('firebase-admin');
  } catch (_) {
    return {
      checked: true,
      deleted: [],
      warning:
        'firebase-admin belum terpasang, jadi Auth user cleanup dilewati. Jalankan npm install firebase-admin jika ingin menghapus Auth user non-demo.',
    };
  }

  if (!admin.apps.length) {
    admin.initializeApp({ projectId });
  }
  const auth = admin.auth();
  const deleted = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) {
      if (preserveDemoUids.has(user.uid) || preserveDemoEmails.has(user.email)) {
        continue;
      }
      deleted.push(`${user.uid} <${user.email || 'no-email'}>`);
      if (execute) await auth.deleteUser(user.uid);
    }
    pageToken = page.pageToken;
  } while (pageToken);
  return { checked: true, deleted, warning: null };
}

function runFirebaseDelete(path) {
  const bin = 'npx';
  const args = [
    'firebase',
    'firestore:delete',
    path,
    '--recursive',
    '--force',
    '--project',
    projectId,
    '--non-interactive',
  ];
  const { spawnSync } = require('node:child_process');
  const result = spawnSync(bin, args, { shell: true, stdio: 'inherit' });
  if (result.status !== 0) {
    throw new Error(`firebase firestore:delete ${path} failed`);
  }
}

function resetFirestoreWithCli(stats) {
  console.log('\nExecuting Firestore reset through Firebase CLI');
  for (const docPath of stats.userDocsToDelete) {
    runFirebaseDelete(docPath);
  }
  for (const collection of deleteCollections) {
    runFirebaseDelete(collection);
  }
}

async function main() {
  console.log(`Firebase trial reset for ${projectId}`);
  console.log(
    executeCli ? 'Mode: EXECUTE VIA FIREBASE CLI' : execute ? 'Mode: EXECUTE' : 'Mode: DRY RUN',
  );
  console.log(`Preserved collections: ${preserveCollections.join(', ')}`);
  console.log(`Preserved demo emails: ${[...preserveDemoEmails].join(', ')}`);

  const token = await signIn();
  const stats = await resetFirestore(token);
  const authStats = await resetAuthUsers(stats);
  if (executeCli) resetFirestoreWithCli(stats);

  console.log('\nFirestore summary');
  console.log(`Preserved demo user docs: ${stats.preservedUsers.length}`);
  for (const docPath of stats.preservedUsers) console.log(`  keep ${docPath}`);
  console.log(`Docs ${execute ? 'deleted' : 'to delete'}: ${stats.firestoreDocs.length}`);
  for (const docPath of stats.firestoreDocs.slice(0, 80)) {
    console.log(`  ${execute ? 'deleted' : 'delete'} ${docPath}`);
  }
  if (stats.firestoreDocs.length > 80) {
    console.log(`  ...and ${stats.firestoreDocs.length - 80} more`);
  }
  if (stats.warnings.length) {
    console.log('\nWarnings');
    for (const warning of stats.warnings) console.log(`  ${warning}`);
  }

  if (authStats.checked) {
    console.log('\nAuth summary');
    if (authStats.warning) console.log(authStats.warning);
    console.log(
      `Auth users ${execute ? 'deleted' : 'to delete'}: ${authStats.deleted.length}`,
    );
    for (const user of authStats.deleted.slice(0, 80)) {
      console.log(`  ${execute ? 'deleted' : 'delete'} ${user}`);
    }
  } else {
    console.log('\nAuth summary');
    console.log('Auth user cleanup not requested. Add --delete-auth-users after dry-run review.');
  }

  if (!execute && !executeCli) {
    console.log('\nNo data was deleted. Re-run with --execute only after reviewing this list.');
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
