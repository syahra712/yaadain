# Connecting Firebase (remote family contribution)

The app already has the full role + sync **scaffold**. Cloud sync plugs into one
seam: `SyncService` (`lib/services/sync_service.dart`). Right now `LocalSyncService`
(no network) is wired. Connecting Firebase = create the project, then add a
`FirebaseSyncService` that implements the same interface.

## What YOU do (needs your Google account — I can't create accounts)

1. **console.firebase.google.com → Add project** → name `yaadain` (Analytics optional).
2. **Build → Firestore Database** → Create → *test mode* (for the hackathon).
3. **Build → Storage** → Get started → *test mode*.
4. **Build → Authentication → Sign-in method → Anonymous → Enable.**
5. Wire the config (either one):
   - **Recommended:** `dart pub global activate flutterfire_cli`, then from the
     project run `flutterfire configure` → pick the `yaadain` project → Android.
     It generates `lib/firebase_options.dart`.
   - **Or manual:** download `google-services.json` into `android/app/`.

Then tell me it's done.

> This repo ships `android/app/google-services.json.example` and
> `lib/firebase_options.dart.example` as templates only — the real files
> (with your project's live API key) are gitignored and must never be
> committed. Copy each `.example` to the real filename and fill in your own
> project's values, or generate them via `flutterfire configure`.

## What I do (once the project exists)

1. Add deps: `firebase_core`, `cloud_firestore`, `firebase_storage`, `firebase_auth`.
2. `Firebase.initializeApp()` + anonymous sign-in in `main()`.
3. Add `FirebaseSyncService implements SyncService`:
   - `createFamily()` → new `families/{CODE}` doc, returns the code.
   - `joinFamily(code)` → verify `families/{code}` exists, record this uid.
   - `pushMember()` → upload photo/audio to `Storage: families/{code}/media/…`,
     write member doc to `families/{code}/members/{id}` with the download URLs.
   - `fetchMembers()` / a realtime listener → mirror members into the local
     `Repository` so the **elder device still works fully offline** (Firestore
     offline persistence + our local cache).
4. Swap `LocalSyncService` → `FirebaseSyncService` in `AppState` (one line).

## Data model (Firestore)

```
families/{CODE}
  elder: { name, romanName, photoUrl, ... }
  members/{id}: { name, romanName, relationshipId, phone, isDeceased,
                  photoUrl, greetingAudioUrl, stories:[...], contributor }
```

Media lives in Cloud Storage; Firestore stores the download URLs.

## Security (harden after the hackathon)

Test-mode rules are open. Before real use, scope reads/writes to members of the
family (match the joining uid list stored on `families/{CODE}`), and move media
behind authed Storage rules.
