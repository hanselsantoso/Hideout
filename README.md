# Turney — HIDEOUT

Aplikasi turnamen **Beyblade X multiplatform (Flutter Web)** untuk komunitas Indonesia:
landing publik, dashboard pemain, panel juri, **meja panitia (staff)**, operasi turnamen
ketua komunitas, dan platform ops super admin. Porting dari prototype web BJX/HIDEOUT.

**Backend:** Firebase (Auth, Firestore, Functions, Hosting, Storage) — 100% serverless.
**Pembayaran:** Xendit (QRIS + payment session + disbursement/payout).

---

## Fitur

| Area | Fitur |
|---|---|
| Publik | Landing, turnamen browser (filter/sort), leaderboard, komunitas, katalog part Beyblade |
| Pemain | Deck builder (legal check + banned part), registrasi turnamen, **entry GRATIS**, QRIS Xendit, My Tournaments + **Check-in Pass (QR asli)** di detail turnamen, **My Matches** (statistik + grafik + pagination + sort) |
| Juri | Jadwal match per turnamen, **absen (check-in) hari-H** → membuka scan QR → verifikasi deck A/B → input skor; ELO otomatis server-side |
| **Panitia (Staff)** | Di-assign per turnamen oleh ketua; **Registration Desk**: MARK PAID (offline, ter-audit), CHECK-IN, WALK OUT; multi-turnamen |
| Ketua Komunitas | Dashboard kartu MY TOURNAMENTS + HISTORY, wizard bertahap (dengan notice juri/panitia), Tournament Ops (bracket, roster, grup), kelola juri, withdrawal + payout Xendit |
| Super Admin | Approve komunitas, kelola role (custom claims), komponen + stats, metrik, **Payout Queue** |

**Role:** `player` · `judge` · `community_admin` (multi-role: pemain+juri+ketua sekaligus didukung) ·
`super_admin` · panitia = assignment per-turnamen (`staffIds`), bukan role global.

---

## Quickstart

```bash
git clone <repo> && cd <repo>
flutter pub get
flutter run -d chrome            # dev server lokal
```

### 1. Hubungkan Firebase project kamu

Cara cepat (generate config otomatis):

```bash
npm i -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure   # pilih project + web
```

Atau manual dengan `--dart-define`:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=xxx \
  --dart-define=FIREBASE_APP_ID=1:xxx:web:xxx \
  --dart-define=FIREBASE_SENDER_ID=xxx \
  --dart-define=FIREBASE_PROJECT_ID=xxx \
  --dart-define=FIREBASE_AUTH_DOMAIN=xxx.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=xxx.appspot.com
```

Untuk build/hosting produksi, pasang nilai yang sama pada `--dart-define=...`
(`flutter build web`).

> **Mode demo:** tambahkan `--dart-define=SHOW_DEMO_LOGIN=true` untuk menampilkan
> 4 tombol login demo (player/judge/lead/super admin) di halaman sign-in.
> Default: **tersembunyi** (jangan aktifkan di produksi publik).

### 2. Aktifkan di Firebase Console

- Authentication → Email/Password **enable**
- Firestore → create database (production mode)
- Storage (untuk upload gambar komponen super admin)
- Hosting (opsional)

### 3. Deploy backend (rules, index, functions)

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes,functions
```

- Rules: `firebase_patch/firestore.rules` — role-based, multi-role, panitia per-turnamen
- Index: `firestore.indexes.json` (query collectionGroup)
- Functions: `functions/` — pembayaran Xendit, role management, **ELO trigger**, webhook

### 4. Secrets Functions

```bash
firebase functions:secrets:set XENDIT_SECRET_KEY      # xnd_development_... (sandbox) / xnd_production_...
firebase functions:secrets:set XENDIT_WEBHOOK_TOKEN   # string acak, dipakai juga di dashboard Xendit
```

### 5. Seed data komponen (katalog part)

```bash
FIREBASE_PROJECT_ID=xxx FIREBASE_WEB_API_KEY=xxx node tooling/seed_firebase.cjs
```

Detail selangkah demi selangkah: **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** ·
Pembayaran: **[docs/PAYMENT.md](docs/PAYMENT.md)** ·
Model keamanan: **[docs/SECURITY.md](docs/SECURITY.md)**

---

## Pengembangan Lokal

```bash
flutter analyze --no-fatal-infos   # harus 0 issue
flutter test                       # unit test (route access, paths)
npm run test:rules                 # 21 rules test (butuh Java untuk emulator Firestore)
npm run build --prefix functions   # build TypeScript functions
flutter build web                  # production bundle → build/web
```

Server statis lokal: `node tooling/local_server.mjs build/web` (port 5455).

### Data demo / reset

```bash
export FIREBASE_PROJECT_ID=xxx FIREBASE_WEB_API_KEY=xxx
export HIDEOUT_SUPER_EMAIL=... HIDEOUT_DEMO_PASSWORD=...
node tooling/reset_firebase_trial_data.cjs --execute   # reset data, nolkan ELO, pertahankan 4 akun demo
```

Checklist uji manual semua halaman & alur: **[docs/testing_checklist.md](docs/testing_checklist.md)**

---

## Struktur Proyek

```
lib/
  core/            theme, tokens, widgets, route access (RBAC)
  data/            models + repositories (Firestore/Functions)
  features/        layar per fitur (auth, dashboard, decks, tournaments,
                   judge, staff, community, super_admin, public, ...)
functions/         Cloud Functions (TypeScript) — pembayaran, role, ELO
firebase_patch/    firestore.rules + storage.rules (sumber deploy)
tooling/           seed, reset, smoke test (Node)
docs/              panduan setup, pembayaran, keamanan, checklist
```

## Kontribusi & Lisensi

PR welcome. Untuk pertanyaan setup, baca `docs/` atau buka issue.
