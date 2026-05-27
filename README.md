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
npx firebase deploy --only functions --project tournamentmanagement-942ef
npx firebase deploy --only hosting --project tournamentmanagement-942ef
```

## Xendit Sandbox

Payments use Xendit Payment Session in `PAYMENT_LINK` mode. The secret key must
stay server-side in Firebase Functions; do not commit it to the repository.

Set the Firebase secret before deploying functions:

```powershell
# If this project has never used Firebase secrets, enable Secret Manager API
# first from Google Cloud Console:
# https://console.developers.google.com/apis/api/secretmanager.googleapis.com/overview?project=tournamentmanagement-942ef

firebase functions:secrets:set XENDIT_SECRET_KEY --project tournamentmanagement-942ef
```

Optional webhook verification can be enabled by setting `XENDIT_WEBHOOK_TOKEN`
in the functions runtime environment, then configuring the same token in the
Xendit dashboard.

Register this webhook URL in the Xendit dashboard for Payment Session events:

```text
https://asia-southeast1-tournamentmanagement-942ef.cloudfunctions.net/xenditPaymentSessionWebhook
```

Local sandbox smoke test:

```powershell
$env:XENDIT_SECRET_KEY="..."
npm run smoke:xendit
```

The smoke test creates a hosted checkout without `allowed_payment_channels`, so
Xendit shows every sandbox channel enabled for the account. Use
`XENDIT_PAYMENT_SESSION_ID` to re-check an existing session instead of creating
a new one.

Seed the beta registration tournament:

```powershell
$env:HIDEOUT_DEMO_PASSWORD="..."
npm run seed:beta-tournament
```
