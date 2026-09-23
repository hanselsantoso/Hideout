# Panduan Deployment

Dari clone → aplikasi live dengan backend sendiri. Prasyarat: Flutter SDK,
Node.js 20+, akun Google/Firebase, (opsional) akun Xendit.

---

## 1. Buat Project Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → **Add project**
2. Aktifkan: **Authentication (Email/Password)**, **Firestore**, **Storage**, **Hosting** (opsional)
3. Catat config web: `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`, `storageBucket`
   (Project settings → Your apps → Web app)

## 2. Konfigurasi Flutter

Preferensi: `flutterfire configure` (men-generate `lib/firebase_options.dart`).
Alternatif manual — semua nilai lewat `--dart-define`:

| Dart define | Isi |
|---|---|
| `FIREBASE_API_KEY` | apiKey web |
| `FIREBASE_APP_ID` | appId web (1:…:web:…) |
| `FIREBASE_SENDER_ID` | messagingSenderId |
| `FIREBASE_PROJECT_ID` | projectId |
| `FIREBASE_AUTH_DOMAIN` | `<project>.firebaseapp.com` |
| `FIREBASE_STORAGE_BUCKET` | `<project>.firebasestorage.app` |
| `SHOW_DEMO_LOGIN` | `true` hanya untuk evaluasi lokal |

Simpan sebagai skrip agar konsisten, mis. `tooling/env.local.sh` (jangan di-commit):

```bash
#!/usr/bin/env bash
export DART_DEFINES="--dart-define=FIREBASE_API_KEY=xxx ... "
```

`.firebaserc.example` menunjukkan format `.firebaserc` lokal:

```bash
cp .firebaserc.example .firebaserc   # isi project id kamu
```

## 3. Firestore Rules & Indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

- Rules berisi: RBAC 4 role, panitia per-turnamen, guard ELO (client tidak bisa
  menulis statistik sendiri), approval komunitas, withdrawal/payout.
- Test otomatis: `npm run test:rules` (21 test, butuh Java untuk emulator).

## 4. Cloud Functions

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

Fungsi yang ter-deploy:

| Callable | Fungsi |
|---|---|
| `createXenditQrisPayment` / `syncXenditQrisPayment` | QRIS per registrasi |
| `createXenditPaymentSession` / `syncXenditPaymentSession` | checkout session |
| `createXenditDisbursement` / `syncXenditDisbursement` | payout ke rekening ketua |
| `xenditPaymentSessionWebhook` / `xenditQrisWebhook` / `xenditDisbursementWebhook` | callback Xendit |
| `assignJudge` / `submitCommunityApplication` / `reviewCommunityApplication` | alur role |
| `setPlatformRole` | grant/revoke role + custom claims |
| `onMatchCompletedApplyStats` | ELO + W/L/M server-side (idempotent) |

## 5. Secrets

```bash
firebase functions:secrets:set XENDIT_SECRET_KEY      # mulai dari sandbox key
firebase functions:secrets:set XENDIT_WEBHOOK_TOKEN   # token acak, juga dipakai di dashboard Xendit
```

## 6. Hosting

```bash
flutter build web
firebase deploy --only hosting
```

Lampirkan custom domain di Hosting settings bila perlu.

## 7. Seed & Verifikasi

```bash
export FIREBASE_PROJECT_ID=<id> FIREBASE_WEB_API_KEY=<web-api-key>
export HIDEOUT_SUPER_EMAIL=<email-super-admin> HIDEOUT_DEMO_PASSWORD=<min-12-karakter>

node tooling/seed_firebase.cjs                  # komponen (parts) + akun demo
node tooling/verify_demo_accounts.cjs           # cek 4 akun demo
node tooling/reset_firebase_trial_data.cjs --execute   # reset data uji + nolkan ELO
```

4 akun demo (dibuat oleh seed): `hideout.player@ / judge@ / community@ / super@example.com`
— password dari `HIDEOUT_DEMO_PASSWORD`. Tampilkan tombol demo login dengan
`--dart-define=SHOW_DEMO_LOGIN=true`.

## 8. Checklist Produksi

- [ ] Rules + indexes deployed
- [ ] Functions + secrets terpasang
- [ ] Xendit sandbox teruji (QRIS end-to-end) → lihat [docs/PAYMENT.md](PAYMENT.md)
- [ ] `flutter analyze` 0 issue, `flutter test` pass, `npm run test:rules` pass
- [ ] `--dart-define` produksi (tanpa `SHOW_DEMO_LOGIN`)
- [ ] Ganti `XENDIT_SECRET_KEY` ke production key saat go-live
