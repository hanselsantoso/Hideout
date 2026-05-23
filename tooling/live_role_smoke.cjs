const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { chromium } = require('playwright-core');

const baseUrl = process.env.TURNEY_BASE_URL || 'https://turney.id';
const screenshotDir =
  process.env.TURNEY_ROLE_SMOKE_DIR ||
  path.join('C:', 'tmp', 'turney-role-smoke');

const chromeCandidates = [
  process.env.CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
].filter(Boolean);

const roles = [
  {
    name: 'player',
    demoY: 542,
    routes: [
      ['dashboard', '/dashboard'],
      ['my-tournaments', '/me/tournaments'],
      ['my-decks', '/me/decks'],
    ],
    blockedRoutes: [
      ['blocked-judge-matches', '/juri/matches'],
      ['blocked-community-admin', '/community/admin'],
      ['blocked-super-admin', '/super-admin/reports'],
    ],
  },
  {
    name: 'judge',
    demoY: 602,
    routes: [
      ['dashboard', '/dashboard'],
      ['judge-matches', '/juri/matches'],
      ['judge-scan', '/juri/scan'],
    ],
    blockedRoutes: [
      ['blocked-community-admin', '/community/admin'],
      ['blocked-super-admin', '/super-admin/reports'],
    ],
  },
  {
    name: 'community',
    demoY: 662,
    routes: [
      ['dashboard', '/dashboard'],
      ['community-admin', '/community/admin'],
      ['tournament-ops', '/admin/tournaments/ops'],
    ],
    blockedRoutes: [
      ['blocked-judge-matches', '/juri/matches'],
      ['blocked-super-admin', '/super-admin/reports'],
    ],
  },
  {
    name: 'super-admin',
    demoY: 722,
    routes: [
      ['reports', '/super-admin/reports'],
      ['approvals', '/super-admin/community-approvals'],
      ['users', '/super-admin/users'],
    ],
    blockedRoutes: [
      ['blocked-dashboard', '/dashboard'],
      ['blocked-judge-matches', '/juri/matches'],
    ],
  },
];

function findBrowser() {
  const found = chromeCandidates.find((candidate) => fs.existsSync(candidate));
  if (!found) {
    throw new Error('Chrome/Edge executable not found. Set CHROME_PATH.');
  }
  return found;
}

function sanitize(value) {
  return value.replace(/[^a-z0-9-]+/gi, '-').toLowerCase();
}

async function waitForFlutter(page) {
  await page.waitForLoadState('domcontentloaded');
  await page.waitForSelector('flt-glass-pane, flutter-view, body', {
    timeout: 20000,
  });
  await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
  await page.waitForTimeout(1200);
}

async function capture(page, name) {
  const file = path.join(screenshotDir, `${sanitize(name)}.png`);
  const buffer = await page.screenshot({ path: file, fullPage: false });
  if (buffer.length < 8000) {
    throw new Error(`${name} screenshot looks too small (${buffer.length} bytes)`);
  }
  return {
    file,
    hash: crypto.createHash('sha256').update(buffer).digest('hex'),
  };
}

async function loginWithDemo(page, role) {
  await page.goto(`${baseUrl}/signin`, {
    waitUntil: 'domcontentloaded',
    timeout: 45000,
  });
  await waitForFlutter(page);
  await page.mouse.click(680, role.demoY);
  await page.waitForTimeout(4500);
  await waitForFlutter(page);
  const url = page.url();
  if (url.includes('/signin')) {
    throw new Error(`${role.name} demo login did not leave the sign-in page`);
  }
  await capture(page, `${role.name}-after-login`);
}

async function openRoleRoute(page, role, route) {
  const [name, pathName] = route;
  await page.goto(`${baseUrl}${pathName}`, {
    waitUntil: 'domcontentloaded',
    timeout: 45000,
  });
  await waitForFlutter(page);
  const url = page.url();
  if (url.includes('/signin')) {
    throw new Error(`${role.name} was redirected to sign-in for ${pathName}`);
  }
  const screenshot = await capture(page, `${role.name}-${name}`);
  console.log(
    `${role.name}:${name}: ok url=${url} screenshot=${screenshot.file}`,
  );
}

async function openBlockedRoute(page, role, route) {
  const [name, pathName] = route;
  await page.goto(`${baseUrl}${pathName}`, {
    waitUntil: 'domcontentloaded',
    timeout: 45000,
  });
  await waitForFlutter(page);
  const url = page.url();
  if (url.includes('/signin')) {
    throw new Error(`${role.name} was signed out while checking ${pathName}`);
  }
  const screenshot = await capture(page, `${role.name}-${name}`);
  console.log(
    `${role.name}:${name}: denied-smoke url=${url} screenshot=${screenshot.file}`,
  );
}

async function main() {
  fs.mkdirSync(screenshotDir, { recursive: true });
  const browser = await chromium.launch({
    executablePath: findBrowser(),
    headless: true,
    args: ['--no-sandbox', '--disable-gpu'],
  });
  const errors = [];

  try {
    for (const role of roles) {
      const context = await browser.newContext({
        viewport: { width: 1366, height: 768 },
      });
      const page = await context.newPage();
      page.setDefaultTimeout(18000);
      page.setDefaultNavigationTimeout(45000);
      page.on('pageerror', (error) =>
        errors.push(`${role.name}: pageerror: ${error.message}`),
      );
      page.on('console', (message) => {
        if (message.type() === 'error') {
          errors.push(`${role.name}: console: ${message.text()}`);
        }
      });

      try {
        await loginWithDemo(page, role);
        for (const route of role.routes) {
          await openRoleRoute(page, role, route);
        }
        for (const route of role.blockedRoutes || []) {
          await openBlockedRoute(page, role, route);
        }
      } finally {
        await context.close().catch(() => {});
      }
    }
  } finally {
    await browser.close().catch(() => {});
  }

  const severe = errors.filter(
    (item) =>
      !item.includes('favicon') &&
      !item.includes('Failed to load resource: the server responded with a status of 404'),
  );
  if (severe.length) {
    throw new Error(`Browser errors:\n${severe.join('\n')}`);
  }
  console.log(`Role screenshots saved in ${screenshotDir}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
