# Checklist Uji Manual — BeyTourney HIDEOUT

Cara jalan: `flutter run -d chrome --web-port 3000` (atau dev server yang sudah hidup di
http://localhost:3000). Semua aksi menulis ke Firebase live — jaga data demo.

## 1. PUBLIK (tanpa login)
- [ ] `/` Landing — hero, menu atas, tombol Sign in / Buat akun
- [ ] `/public/tournaments` — daftar turnamen publik, kartu bisa diklik → detail
- [ ] `/public/leaderboard` — leaderboard publik
- [ ] `/communities` — daftar komunitas
- [ ] `/components` — katalog komponen (bagian bey)
- [ ] Security: buka `/dashboard`, `/me/decks` → HARUS muncul "LOGIN REQUIRED" → SIGN IN

## 2. AUTH
- [ ] `/signup` — daftar akun baru → otomatis ke `/onboarding`
- [ ] `/signin` — login → diarahkan sesuai role (dashboard / super-admin)
- [ ] Logo HIDEOUT di auth frame → balik `/`
- [ ] Link "sudah punya akun?" antar signin/signup

## 3. ONBOARDING
- [ ] `/onboarding` — pilih role (player) → `/dashboard`
- [ ] Opsi "buka komunitas" → `/communities/new`

## 4. PLAYER (pemain biasa)
Sidebar: Home · Dashboard · Tournaments · My Tournaments · My Decks · QR · Leaderboard ·
Matches · Notifications · Open a Community
- [ ] `/dashboard` — kartu ringkas + tombol per role
- [ ] `/tournaments` — pilih turnamen → `/tournaments/detail`
- [ ] `/tournaments/detail` — tab overview/bracket; tombol REGISTER
- [ ] `/me/decks` — daftar deck; `/me/decks/new` — builder; simpan → balik list
- [ ] `/me/tournaments` — status registrasi; tombol PAY QRIS (jika pending)
- [ ] `/me/qr` — pass check-in; tombol balik dashboard
- [ ] `/leaderboard`, `/matches`, `/notifications`
- [ ] `/communities/new` — form lamaran komunitas → submit (lihat §6)

## 5. ALUR TERUJI: registrasi turnamen GRATIS (fee 0)
1. (Super admin) buat turnamen fee 0 → label **FREE** di daftar
2. (Player) `/tournaments` → detail → REGISTER
3. Wizard: pilih deck → Review (breakdown menunjukkan 0/GRATIS) → step 4 tampil
   **FREE ENTRY** (tanpa QRIS) → tombol **CONFIRM FREE ENTRY**
4. Langsung ke tiket → My Tournaments status **ACTIVE** (bukan PENDING PAYMENT)

## 6. ALUR TERUJI: daftar komunitas → dibuat turnamen
1. Kandidat ketua: daftar akun baru → dashboard → "Open a Community" (`/communities/new`)
2. Isi form (nama, kota, rekening, dsb.) → submit → status PENDING
3. Login super admin → `/super-admin/community-approvals` → **APPROVE**
4. Akun ketua: refresh dashboard → sidebar pemain + panel **LEAD** muncul
5. `/community/admin` — dashboard komunitas (data rekening, notice)
6. `/admin/tournaments/new` — wizard: nama/fee 0/arena/juri → publish
7. Jika pakai juri: juri di-assign → jangan lupa atur `judgeIds` di arena wizard
8. Player lain: daftar ke turnamen (gratis/bayar) → cek di ops

## 7. JURI (butuh role juri)
- [ ] `/juri/matches` —jadwal match; tombol SCAN
- [ ] `/juri/scan` — scan QR pemain
- [ ] `/juri/score` — input skor → selesai → balik jadwal

## 8. SUPER ADMIN
- [ ] `/super-admin/reports` — metrik + **PAYOUT QUEUE** (butuh functions ter-deploy untuk tombol PROCESS/SYNC)
- [ ] `/super-admin/community-approvals` — approve/reject
- [ ] `/super-admin/components` — CRUD komponen + upload gambar (Storage)
- [ ] `/super-admin/component-stats`
- [ ] `/super-admin/users` — dropdown role (Player/Judge/Lead/Lead+Judge) + ban/unban
- [ ] Security: buka `/super-admin/users` dari akun player → HARUS "ACCESS DENIED"

## 9. CATATAN
- Payout/social_real: tombol PROCESS butuh deploy functions + secret (sesi berikutnya)
- Rules live ✓; `XENDIT_WEBHOOK_TOKEN` belum diset — pembayaran live belum aktif
