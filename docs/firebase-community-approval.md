# Firebase Community Approval Contract

This app uses the existing Firebase project from the old Flutter code:

- Project ID: `tournamentmanagement-942ef`
- Cloud Functions region: `asia-southeast1`
- Legacy roles: `admin`, `judge`, `player`

For the new BeyTourney flow, keep `admin` compatible as a temporary super admin,
then migrate to these roles:

- `super_admin`
- `community_admin`
- `judge`
- `player`

## Collections

### `communityApplications/{applicationId}`

Created when a player requests a new community.

Fields:

- `requesterId`
- `communityName`
- `city`
- `leaderUserId`
- `description`
- `status`: `pending`, `approved`, `rejected`
- `communityId`
- `reviewerId`
- `rejectionReason`
- `createdAt`
- `updatedAt`
- `reviewedAt`

### `communities/{communityId}`

Created when a super admin approves an application.

Fields:

- `name`
- `city`
- `description`
- `leaderUserId`
- `adminIds`
- `status`: `active`, `suspended`
- `sourceApplicationId`
- `createdAt`
- `updatedAt`

## Callable Functions

### `submitCommunityApplication`

Auth required. Player/admin submits a community application.

Payload:

```json
{
  "communityName": "JKT Wolves",
  "city": "Jakarta Selatan",
  "leaderUserId": "firebase-user-id-or-player-id",
  "description": "Community notes"
}
```

Returns:

```json
{ "applicationId": "..." }
```

### `reviewCommunityApplication`

Auth required. Caller must have custom claim role `super_admin` or legacy `admin`.

Payload:

```json
{
  "applicationId": "...",
  "decision": "approved",
  "reason": ""
}
```

On approval:

- Creates `communities/{communityId}`.
- Updates `communityApplications/{applicationId}` to `approved`.
- Updates the leader user doc role to `community_admin`.
- Sets custom claims for the leader: `{ role: "community_admin", communityIds: [...] }`.

Returns:

```json
{ "communityId": "..." }
```

## Rules Direction

The safest version is to let callable functions write approval state.

- Authenticated users can create their own pending application.
- Users can read their own applications.
- `super_admin`/legacy `admin` can read all applications.
- Direct updates to approval fields should be function-only.
- `community_admin` can create tournaments only for their own community.

## Local Source Status

The old Firebase project source has been updated locally at:

- `C:\laragon\www\TournamentManagement\functions\src\community\submit_community_application.ts`
- `C:\laragon\www\TournamentManagement\functions\src\community\review_community_application.ts`
- `C:\laragon\www\TournamentManagement\functions\src\auth\set_platform_role.ts`
- `C:\laragon\www\TournamentManagement\firestore.rules`
- `C:\laragon\www\TournamentManagement\functions-community\index.js`

Cloud Functions compile locally with:

```powershell
cd C:\laragon\www\TournamentManagement\functions
npm run build
```

Production deploy command, only after explicit approval:

```powershell
cd C:\laragon\www\TournamentManagement
firebase deploy --only firestore:rules,functions:submitCommunityApplication,functions:reviewCommunityApplication,functions:setPlatformRole --project tournamentmanagement-942ef
```

Actual production deploy status:

- Firestore rules: deployed.
- `community:submitCommunityApplication(asia-southeast1)`: deployed.
- `community:reviewCommunityApplication(asia-southeast1)`: deployed.
- `community:setPlatformRole(asia-southeast1)`: deployed.

The three new callable functions are deployed through the separate Firebase
Functions codebase `community` so existing legacy functions do not need to be
redeployed just to support this slice.
