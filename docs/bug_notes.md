# Catatan Perbaikan — BeyTourney HIDEOUT

Tanggal: 2026-09-06
Basis: `flutter analyze` (0 error / 0 warning / 79 info) · `flutter test` (6/6 pass) ·
rules test (14/14 pass) · `functions` tsc build (clean) · review rules vs client-write.

---

## A. KRITIS — Backend / Keamanan

### A1. Request withdrawal ditolak Firestore rules (bug nyata)
- `requestTournamentWithdrawal` menulis `tournament.organizerPayout` (tournament_repository.dart:2057)
- Rules `canUpdateTournamentOps` hanya izinkan key: status, currentParticipantCount, currentStage,
  currentRoundId, stageStatus, roundRobin, topCut, bracketSize, seededMatchCount, activeMatchCount,
  byeCount, startedAt, updatedAt (firestore.rules:115-136) → **`organizerPayout` TIDAK diizinkan**
- Efek: community admin yang request payout akan ditolak di produksi (hanya isAdmin() yang lolos)
- **Fix:** tambahkan `organizerPayout` ke `hasOnly` di `canUpdateTournamentOps`, atau pindahkan write
  ke Cloud Function.

### A2. Payout hanya "request", transfer tidak pernah jalan
- Hanya ada `requestTournamentWithdrawal` (data: status `processing` + no. rekening)
- Tidak ada: approve oleh super admin, call Xendit Disbursement, webhook status, complete/refund
- **Fix:** buat flow: super admin approve → `createDisbursement` (Xendit) → webhook → update status
  (mis. `completed`/`failed`). Lihat juga Doku Sub-Account sebagai opsi arsitektur.

### A3. `firebase_patch/functions/` tidak bisa di-deploy
- `src/index.ts` mere-export 20+ modul yang **tidak ada di folder**: auth/on_user_create,
  auth/set_admin_role, auth/assign_judge, payment/*, bracket/*, match/*, elo/*, analytics/*, admin/*,
  community/review_community_application (file community/ ada) — hanya 3 file yang benar-benar ada
- Tidak ada `package.json`/`tsconfig.json` → tidak bisa build
- `firebase.json` juga menunjuk `functions/` (bukan `firebase_patch/functions/`)
- **Fix:** pilih satu: (a) selesaikan firebase_patch dan pindahkan source ke `functions/`, atau
  (b) hapus referensi modul yang tidak ada.

### A4. Callable dipanggil client tapi tidak di-deploy
- Client memanggil `assignJudge`, `submitCommunityApplication`, `reviewCommunityApplication`
  (community_repository.dart:97,150,195) — tidak ada di `functions/src/index.ts` (hanya Xendit)
- Efek: selalu jatuh ke fallback write langsung dari client (diam-diam, tanpa validasi server)
- **Fix:** implementasi server-side (dengan verifikasi role via token/users doc) atau hapus callable
  dan perkuat rules.

### A5. Custom claims tidak pernah diset
- `setPlatformRole` ada tapi **tidak dipanggil di mana pun** (grep lib = 0)
- `request.auth.token.role` selalu kosong → setiap fungsi server yang cek token role akan gagal
- **Fix:** panggil dari super admin UI (atau hapus dependensi token, andalkan users doc).

### ✅ SUDAH DIPERBAIKI (sesi sebelumnya)
- Rules `canCommunityManageJudgeRole` sekarang izinkan key `roles` (assign juri oleh admin jalan)
- Self-escalation via `roles` diblokir (user tidak bisa naik role sendiri)
- Route `/super-admin/parts/new` → section `components` (bukan `users`)
- **E1** — create user dibatasi: allowlist keys + `roles` maksimal `['player']` (firestore.rules:158-168)
- **A1** — `organizerPayout` ditambahkan ke `canUpdateTournamentOps` (firestore.rules:115-137)
- Rules test sekarang **16/16 pass** (2 test baru: smuggle-roles create & organizer payout)
- **Rules sudah DEPLOY ke live** (2026-09-06, akun hanselsantoso22@gmail.com)
- **B1** — review step & AppBar pakai data asli dari route args (community/date/venue/format/tier);
  fallback TBA/- jika kosong (tournament_registration_screen.dart)
- **B2** — fee dibaca dari `TournamentFeePolicy` via `fetchFeePolicy()` baru di tournament_repository;
  UI tidak lagi hardcode 10%/3%/500; breakdown menampilkan withdraw coverage & nama komunitas asli
- **B3** — semua copy "sandbox" diganti produksi ('QRIS PAYMENT', 'TURNEY.ID', instruksi wallet umum)
- **E2** — preview bracket tidak lagi pakai data demo (Hansel/Mardika dihapus); roster <2 → empty
  state "Bracket has not been created"; konstanta `_demoBracketRounds` & `_demoDoubleElimSections` dihapus
- **B4** — tombol mati dibereskan: ADD TO CALENDAR/UPLOAD IMAGE/SAVE DRAFT/RANDOM dihapus;
  SHARE (detail) → copy ke clipboard + snackbar; pill turnamen di match history jadi statis
- **B5** — auto-sync pembayaran: polling `syncXenditQrisPayment` tiap 10 detik saat QRIS aktif;
  otomatis lanjut ke tiket saat paid, stop saat expired/unmount; note UI ditambahkan
- **A2** — payout Xendit Disbursement TERIMPLEMENTASI:
  - Backend: `createXenditDisbursement` (super admin only, idempotent, mapping bank BCA/BNI/BRI/
    Mandiri/Permata/CIMB/Danamon/Maybank/Panin/OCBC/BSI), `syncXenditDisbursement`,
    `xenditDisbursementWebhook` (token-verified) di functions/src/index.ts
  - Status ditulis transaksional ke withdrawal + `tournament.organizerPayout`
    (processing/completed/failed)
  - Client: `payoutWithdrawal()` / `syncWithdrawalPayout()` di tournament_repository (tanpa fallback
    diam-diam — error ditampilkan)
  - UI: panel **PAYOUT QUEUE** di Super Admin → Reports (list withdrawal, tombol PROCESS & SYNC)
  - **Belum deploy:** butuh `firebase deploy --only functions` + secrets `XENDIT_SECRET_KEY` &
    `XENDIT_WEBHOOK_TOKEN` ter-set di project
- **A4** — callable yang dulu hilang kini ADA di `functions/src/index.ts`: `assignJudge`
  (verifikasi role actor + target player/judge + larangan ubah role sendiri),
  `submitCommunityApplication`, `reviewCommunityApplication` (transaction: community doc +
  roles leader + notification). Client tetap punya fallback, tapi kini jalur server yang dipakai.
- **A5** — `setPlatformRole` diimplementasi di functions (super admin only, set custom claims +
  users doc) dan **di-wire ke UI**: `_setRole` super admin memanggil callable dulu, fallback write
  lama. `request.auth.token.role` kini terisi.
- **A3** — folder rusak `firebase_patch/functions/` **DIHAPUS** (index.ts re-export modul fiktif,
  tanpa package.json). Sumber backend tunggal sekarang: `functions/` (sesuai firebase.json).
  Rules tetap di `firebase_patch/firestore.rules` & `storage.rules`.
- Catatan: **rules yang diperbaiki belum di-deploy ke Firebase live** — perlu
  `firebase deploy --only firestore:rules` (butuh `firebase login` + Blaze).

---

## B. UI / Tampilan — Bug

### B1. Data turnamen hardcoded di Review step
- registration_screen.dart:365-374: `JKT WOLVES`, `MAY 22, 2026 - 14:00`, `Gear Sports Arena`,
  `BO5 - RR -> SE`, `ELO RANGE 2200-3000` → bukan data turnamen yang dipilih
- **Fix:** terima data turnamen via argumen/navigation.

### B2. Fee dihitung hardcoded di UI
- registration_screen.dart:337-339 & 430: `fee*0.1 + fee*0.03 + 500` duplikat
- Server sudah punya `TournamentFeePolicy` (netFee/platformFee/gatewayFee/withdrawFeeCoverage)
- **Fix:** baca `feePolicy` dari Firestore (registration/args), jangan hardcode.

### B3. Copy "SANDBOX" bocor ke produksi
- registration_screen.dart:434-437 (`XENDIT QRIS`, `Create a Xendit sandbox QRIS code...`),
  :1065 (`TURNEY QRIS SANDBOX`), :1143, :1181-1186 (`sandbox flow or simulation from the dashboard`),
  :686 (error message)
- **Fix:** ganti dengan copy produksi (nama merchant nyata, "Scan dengan wallet QRIS...")

### B4. 6 tombol mati (`onPressed: () {}`)
| Lokasi | Tombol |
|---|---|
| registration_screen.dart:523 | ADD TO CALENDAR |
| tournament_wizard_screen.dart:1132 | UPLOAD IMAGE |
| tournament_wizard_screen.dart:1938 | SAVE DRAFT |
| my_decks_screen.dart:141 | RANDOM |
| tournament_detail_screen.dart:420 | SHARE |
| match_history_screen.dart:976 | SHARE (label nama tournament) |

### B5. Pembayaran tanpa countdown / auto-check
- User harus klik "CHECK PAYMENT STATUS" manual; tidak ada timer kedaluwarsa QRIS / polling
- **Fix:** tampilkan countdown (≈15 menit) + auto-sync tiap 5 detik saat QRIS aktif.

---

## C. KOSMETIK (79 info, tidak fatal)
- `withOpacity` deprecated → `withValues()` (notifications_screen, tournaments_screen, dll.)
- `prefer_const_constructors` (±50 tempat: onboarding, check_in_pass, tournament_detail, dll.)
- Tidak memengaruhi runtime; bisa dibersihkan di akhir.

---

## D. INFRA (belum selesai)
- BigQuery extension belum di-install (perlu `firebase login` + Blaze) — params siap di
  `firebase_patch/ext.bigquery.params.json`, query di `docs/bigquery_analytics_queries.sql`
- Draft schema Postgres siap di `docs/schema_postgres.sql` (migrasi fase berikutnya)
- `mocha` sudah di-upgrade ke 11 (kompatibel Node 26); `node_modules` root sudah terpasang
- Java emulator: pakai JBR Android Studio (`/Applications/Android Studio.app/Contents/jbr/...`)

---

## E. HASIL PENDALAMAN (sesi 2 — helper backend, webhook, storage, signup)

### E1. 🔴 Celah privilege escalation saat CREATE user
- Rules `users` create hanya cek `request.resource.data.role == 'player'`
  (firestore.rules:158-160) — **field `roles` tidak dibatasi saat create**
- App membaca capabilities dari array `roles` (app_user.dart:30-40) → attacker bisa buat dokumen
  sendiri dengan `role: 'player'` + `roles: ['super_admin']` lewat Firestore API langsung
- Client signUp aman (hanya menulis `role: 'player'`, auth_repository.dart:69), tapi rules harus
  dikeraskan
- **Fix:** tambah syarat create: `request.resource.data.roles == ['player']`
  (atau `hasOnly` keys + roles maksimal ['player'])

### E2. 🟡 Tournament Ops menampilkan data demo saat tanpa argumen
- `_demoBracketRounds` (tournamentId `demo-tourney`, nama Hansel/Mardika, skor 4-2) di
  tournament_ops_screen.dart:10-114; dipakai saat `demo: true` (:809) dan label
  `DEMO BRACKET FLOW` / `DEMO REGISTRATION ROSTER` (:3378, :3789)
- Dibuka dari sidebar `/admin/tournaments/ops` tanpa pilih turnamen → user melihat bracket palsu
- **Fix:** tampilkan empty-state "pilih turnamen" alih-alih data demo

### E3. ✅ Terverifikasi bersih (tidak perlu aksi)
- `functions/src/index.ts` helper + `writeQrisState`/`writePaymentSessionState`: transactional,
  idempotent (`paidAt ?? existing`, `alreadyPaid` guard), webhook pakai `x-callback-token`
- `firebase_patch/storage.rules`: upload komponen hanya admin, <5MB, `image/*` — sudah benar
- Status display label konsisten (`registrationOpen` → `REGISTRATION OPEN` dinormalisasi di
  tournaments_screen.dart:826) — bukan bug

---

## Urutan rekomendasi pengerjaan
1. ~~**E1** + **A1**~~ ✅ SELESAI + **rules sudah di-deploy ke live**
2. ~~**B1+B2**~~ ✅ SELESAI (data asli dari args + feePolicy dari Firestore)
3. ~~**B3** + **E2**~~ ✅ SELESAI
4. ~~**A2**~~ ✅ SELESAI (kode) — sisa: deploy functions + secrets Xendit
5. ~~**B4+B5**~~ ✅ SELESAI (tombol mati + auto-sync pembayaran)
6. ~~**A3-A5**~~ ✅ SELESAI (callable lengkap, setPlatformRole wired, folder rusak dihapus)
   — sisa: **deploy functions** + secrets + daftarkan webhook URL di dashboard Xendit
7. ~~**C**~~ ✅ SELESAI — `dart fix --apply` (84 fix, 13 file): withOpacity→withValues, prefer_const;
   `flutter analyze` kini **No issues found!**

---

## STATUS AKHIR (2026-09-06)
- **BACKLOG A-E PENUH SELESAI. Semua backend LIVE di produksi (2026-09-06):**
  - Functions ter-deploy: Xendit QRIS/session/disbursement + 3 webhook + assignJudge,
    submitCommunityApplication, reviewCommunityApplication, setPlatformRole,
    **onMatchCompletedApplyStats** (ELO + total menang/kalah otomatis, idempotent via
    `statsAppliedAt`), 5 fungsi warisan Midtrans dihapus
  - Secrets: `XENDIT_SECRET_KEY` (dev) + `XENDIT_WEBHOOK_TOKEN` (token acak, file
    `xendit_webhook_token.local.txt`, di-gitignore)
- **BUG KRITIS ELO DIPERBAIKI:** sebelumnya client (juri) menulis ELO ke users doc pemain lain
  → ditolak rules → skor juri gagal & ELO tak pernah naik. Kini: client hanya menulis
  match/standings/componentStats; **ELO+totals dihitung server via trigger Firestore**.
- Rules tambahan: standings round-robin (organizer/staff/judge, create via keys(), update via
  diff), self-update user memblokir eloRating/totalWins/totalLosses/totalMatches — **21/21 test,
  deploy live**.
- ELO default mulai dari 0 (signup + semua fallback); 20 user live sudah di-reset ke 0.
- **Role Panitia (Staff):** staffIds per turnamen (wizard), Registration Desk `/staff/desk`
  (MARK PAID dengan audit / CHECK-IN / WALK OUT), rules 20/20 → live.
- **Judge gating:** absen (judgeCheckIns) unlock scan; score butuh absen + deck terverifikasi.
- **Dashboard ketua:** kartu MY TOURNAMENTS (klik → ops), TOURNAMENTS HISTORY, wizard notice
  juri/panitia, menu Community Registration & ops sidebar dihapus.
- **Yang masih manual (bukan blokir teknis):**
  1. Daftarkan 3 URL webhook di dashboard Xendit + isi callback token dari
     `xendit_webhook_token.local.txt` (atau `firebase functions:secrets:access XENDIT_WEBHOOK_TOKEN`)
  2. Kalau Xendit live (bukan sandbox): ganti `XENDIT_SECRET_KEY` dengan kunci produksi
  3. Opsional: BigQuery extension (Blaze) untuk analytics
- Rules firestore LIVE (21/21). Flutter: analyze 0 issue · test 6/6 · build web fresh.
- **ROLE PANITIA (STAFF) TERIMPLEMENTASI (2026-09-06):**
  - Model: `tournament.staffIds[]` — di-assign ketua komunitas per turnamen (wizard step Judges &
    Arena → blok PANITIA), **tanpa mengubah roles di users doc** (aman, multi-turnamen ✓)
  - Rules: `isTournamentStaff()` + ops registrasi (mark paid + audit `paidBy/paidByName`,
    check-in, walk-out) + ops turnamen + write rounds/matches; staff TIDAK bisa ubah staffIds,
    buat turnamen, atau withdrawal — **20/20 test, DEPLOY LIVE**
  - UI: picker panitia di wizard + layar **Registration Desk** `/staff/desk`
    (pilih turnamen di-assign → roster: MARK PAID / CHECK-IN / WALK OUT + link bracket)
  - Sidebar: 'Panitia (Staff)' untuk semua akun sign-in (kosong = belum di-assign)
- **Judge gating TERIMPLEMENTASI (2026-09-06):**
  - `judgeCheckIns.{uid}` di tournament doc (rules diizinkan + test + **deploy live**)
  - Judge Schedule dikelompokkan per turnamen: tombol CHECK IN (ABSEN) → unlock SCAN A/B
  - SCORE hanya setelah: absen ✓ + deck kedua pemain terverifikasi ✓ (hint jelas di kartu match)
  - Scanner tanpa absen → layar "CHECK IN REQUIRED"; score tanpa syarat → "NOT READY YET"
  - Sidebar juri: hanya **Judge Schedule** (Scan & Score dipindah ke konteks schedule);
    dashboard quick actions dirapikan
  - Lanjutan UX: My Tournaments card klik → detail (+ Check-in Pass QR asli via qr_flutter),
    My Matches redesign (statistik + grafik + pagination + sort), deck edit fix, semua data
    dummy dihapus, DB turnamen/notifications/applications di-reset live
- **Yang masih manual (produksi):**
  1. `firebase deploy --only functions` (butuh secrets `XENDIT_SECRET_KEY` & `XENDIT_WEBHOOK_TOKEN`)
  2. Daftarkan URL webhook Xendit (payment session, QRIS, disbursement) di dashboard Xendit
  3. Install BigQuery extension (Blaze): `firebase ext:install firebase/firestore-bigquery-export
     --params=firebase_patch/ext.bigquery.params.json`
- Rules firestore **sudah live** (termasuk judgeCheckIns).
