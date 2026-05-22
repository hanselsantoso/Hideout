# BeyTourney HIDEOUT

Flutter Web app for Turney/BeyTourney: public landing, player dashboard,
community tournament ops, judge console, and super admin platform ops.

## Live

- Production domain: https://turney.id
- Firebase project: `tournamentmanagement-942ef`
- Hosting target: Firebase Hosting `build/web`

## Demo Accounts

The reset script preserves four main demo accounts:

- `hideout.player@example.com`
- `hideout.judge@example.com`
- `hideout.community@example.com`
- `hideout.super@example.com`

The demo password is not stored in the repository. Set the following env var
before running live scripts:

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

The live smoke test uses local Chrome/Edge:

```powershell
node tooling/verify_demo_accounts.cjs
npm run smoke:live
```

`smoke:live` opens production routes, captures screenshots to
`C:\tmp\turney-live-smoke`, and fails if the login/register/dashboard guards
still render identically to the landing page.

## Firebase Workflows

Seed supporting data:

```powershell
node tooling/seed_firestore_client.cjs
```

Trial end-to-end live:

```powershell
node tooling/trial_end_to_end.cjs
```

Reset trial/prototype data while preserving the 4 demo accounts and parts:

```powershell
node tooling/reset_firebase_trial_data.cjs
node tooling/reset_firebase_trial_data.cjs --execute-cli
node tooling/reset_firebase_trial_data.cjs --execute-cli --delete-auth-users
```

Use `--execute-cli` for production cleanup because Firebase CLI performs
recursive deletes through subcollections. Use `--execute` only when rules still
allow the REST client to read the entire tree.

Add `--delete-auth-users` if non-demo Firebase Auth users also need to be
cleaned. This mode preserves the four main demo emails and requires a Firebase
CLI account with `firebaseauth.users.delete` permission.

Deploy:

```powershell
npx firebase deploy --only firestore:rules --project tournamentmanagement-942ef
npx firebase deploy --only hosting --project tournamentmanagement-942ef
```
