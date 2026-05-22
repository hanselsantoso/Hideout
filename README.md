# BeyTourney HIDEOUT

Flutter Web app untuk Turney/BeyTourney: public landing, player dashboard,
community tournament ops, judge console, dan super admin platform ops.

## Live

- Production domain: https://turney.id
- Firebase project: `tournamentmanagement-942ef`
- Hosting target: Firebase Hosting `build/web`

## Demo Accounts

Empat akun demo utama dipertahankan oleh script reset:

- `hideout.player@example.com`
- `hideout.judge@example.com`
- `hideout.community@example.com`
- `hideout.super@example.com`

Password demo tidak disimpan di repository. Set env berikut sebelum menjalankan
script live:

```powershell
$env:HIDEOUT_DEMO_PASSWORD="..."
```

## Local Verification

```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test --reporter expanded
flutter build web
npm run test:rules
```

## Firebase Workflows

Seed data pendukung:

```powershell
node tooling/seed_firestore_client.cjs
```

Trial end-to-end live:

```powershell
node tooling/trial_end_to_end.cjs
```

Reset data trial/prototype sambil menjaga 4 akun demo dan parts:

```powershell
node tooling/reset_firebase_trial_data.cjs
node tooling/reset_firebase_trial_data.cjs --execute-cli
```

Gunakan `--execute-cli` untuk production cleanup karena Firebase CLI menjalankan
delete recursive sampai subcollection. `--execute` dipakai hanya kalau rules masih
mengizinkan REST client membaca seluruh tree.

Deploy:

```powershell
npx firebase deploy --only firestore:rules --project tournamentmanagement-942ef
npx firebase deploy --only hosting --project tournamentmanagement-942ef
```
