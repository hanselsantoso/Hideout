# Model Keamanan

Semua enforcement berlapis: **Firestore rules** (server) + **guard route di app**
+ **Cloud Functions** (Admin SDK). Client dipercaya minimum.

---

## Role & Capabilities

| Role | Bisa |
|---|---|
| `player` (default) | registrasi, deck, QRIS, lihat turnamen/leaderboard |
| `judge` | semuanya player + jadwal juri, absen, verifikasi deck, input skor |
| `community_admin` | + buat turnamen, ops bracket/roster, kelola juri, withdrawal, assign panitia |
| `super_admin` | approve komunitas, kelola role semua user, komponen, payout queue |
| **Panitia (staff)** | **bukan role** — `staffIds[]` di dokumen turnamen; hanya berlaku di turnamen yang di-assign |

Multi-role: satu akun bisa player + juri + ketua sekaligus (array `roles`, capabilities
additive). Super admin menimpa.

## Yang dilarang keras oleh rules (dites, 21 test)

1. **Self-escalation** — user tidak bisa mengubah `role`/`roles`/`communityIds` sendiri
2. **Create user dibatasi** — signup hanya `role: player`, field `roles` maksimal `['player']`,
   allowlist keys (menutup smuggle super_admin via API langsung)
3. **Statistik pemain** — `eloRating/totalWins/totalLosses/totalMatches` HANYA bisa ditulis
   Cloud Function (`onMatchCompletedApplyStats`); client tidak bisa menulis milik sendiri
   maupun orang lain
4. **Panitia terbatas konteks** — staff hanya boleh ops registrasi (payment/check-in/walkout
   + audit `paidBy`) dan ops turnamen di turnamen yang menugaskan mereka; tidak bisa ubah
   `staffIds`, buat turnamen, atau withdrawal
5. **Juri terbatas** — match hanya miliknya; absen (`judgeCheckIns`) hanya menambah field itu;
   standings round-robin dengan allowlist field
6. **Pembayaran** — dokumen `payments` hanya ditulis Admin SDK; client hanya baca
7. **Users self-update** — allowlist field + blok field sensitif (role*, elo, dll.)

## ELO Server-Side

- Skor juri hanya menulis match/standings/componentStats (yang rules izinkan)
- ELO + W/L dihitung **trigger Firestore** saat match `completed` — idempotent
  (`statsAppliedAt`), floor 0, BYE/draw tidak diberi poin, ter-audit di `elo_history`

## Custom Claims

`setPlatformRole` (super admin only) menulis `role` ke custom claims **dan** users doc —
siap untuk enforcement future; saat ini rules membaca users doc (`signedInUserRole()`).

## Praktik Keamanan Repo

- API key pembayaran & webhook token → `functions:secrets:set` (TIDAK di repo)
- Konfigurasi Firebase klien lewat `--dart-define` (tidak di-commit)
- `.firebaserc` lokal di-gitignore (ada `.firebaserc.example`)
- Demo login disembunyikan (`SHOW_DEMO_LOGIN`) & password demo tidak dipakai produksi
