const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { chromium } = require('playwright-core');

const baseUrl = process.env.TURNEY_BASE_URL || 'https://turney.id';
const screenshotDir =
  process.env.TURNEY_SMOKE_DIR || path.join('C:', 'tmp', 'turney-live-smoke');

const chromeCandidates = [
  process.env.CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
].filter(Boolean);

const routes = [
  ['landing', '/'],
  ['signin', '/signin'],
  ['signup', '/signup'],
  ['public-tournaments', '/public/tournaments'],
  ['public-leaderboard', '/public/leaderboard'],
  ['communities', '/communities'],
  ['components', '/components'],
  ['dashboard-guard', '/dashboard'],
];

function findBrowser() {
  const found = chromeCandidates.find((candidate) => fs.existsSync(candidate));
  if (!found) {
    throw new Error('Chrome/Edge executable not found. Set CHROME_PATH.');
  }
  return found;
}

function sanitizeRoute(name) {
  return name.replace(/[^a-z0-9-]+/gi, '-').toLowerCase();
}

async function waitForFlutter(page) {
  await page.waitForLoadState('domcontentloaded');
  await page.waitForSelector('flt-glass-pane, flutter-view, body', {
    timeout: 15000,
  });
  await page.waitForLoadState('networkidle', { timeout: 3000 }).catch(() => {});
  await page.waitForTimeout(900);
}

async function capture(page, name) {
  const file = path.join(screenshotDir, `${sanitizeRoute(name)}.png`);
  const buffer = await page.screenshot({ path: file, fullPage: false });
  if (buffer.length < 8000) {
    throw new Error(`${name} screenshot looks too small (${buffer.length} bytes)`);
  }
  return {
    file,
    hash: crypto.createHash('sha256').update(buffer).digest('hex'),
  };
}

async function routeSmoke(page, name, route) {
  await page.goto(`${baseUrl}${route}`, {
    waitUntil: 'domcontentloaded',
    timeout: 45000,
  });
  await waitForFlutter(page);
  const flutterRoots = await page.locator('flt-glass-pane, flutter-view').count();
  const title = await page.title();
  const screenshot = await capture(page, name);
  console.log(
    `${name}: ok url=${page.url()} title="${title}" flutterRoots=${flutterRoots} screenshot=${screenshot.file}`,
  );
  return screenshot;
}

async function withStepTimeout(name, task) {
  let timer;
  try {
    return await Promise.race([
      task(),
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error(`${name} timed out`)), 60000);
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

async function main() {
  fs.mkdirSync(screenshotDir, { recursive: true });
  const browserPath = findBrowser();
  const browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
    args: ['--no-sandbox', '--disable-gpu'],
  });
  const context = await browser.newContext({ viewport: { width: 1366, height: 768 } });
  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  page.setDefaultNavigationTimeout(45000);
  const errors = [];
  page.on('pageerror', (error) => errors.push(`pageerror: ${error.message}`));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(`console: ${message.text()}`);
  });

  try {
    const hashes = new Map();
    for (const [name, route] of routes) {
      const screenshot = await withStepTimeout(name, () =>
        routeSmoke(page, name, route),
      );
      hashes.set(name, screenshot.hash);
    }
    for (const routeName of ['signin', 'signup', 'dashboard-guard']) {
      if (hashes.get(routeName) === hashes.get('landing')) {
        throw new Error(`${routeName} rendered identically to landing`);
      }
    }
  } finally {
    await context.close().catch(() => {});
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
  console.log(`Screenshots saved in ${screenshotDir}`);
}

main().catch(async (error) => {
  console.error(error);
  process.exitCode = 1;
});
