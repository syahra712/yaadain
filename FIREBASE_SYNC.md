# Yaadain 2: turning on real two-phone sync

Short version: the app ships in **demo mode**. Everything runs on one phone with scripted data.
Real sync is already written (a Firestore adapter). It is switched off by one line.

## 1. What demo mode does

- `DemoTrackingSource` (`lib/tracking/demo_tracking_source.dart`) plays the "Dada Jaan leaves home" story from a timer.
  Walk starts inside the 150 m ring, crosses it after about 12 s, the alert fires at 60 s, about 320 m out at 90 s.
- Demo controls (long-press the logo 3 s on the elder home, PIN 1947, "Demo controls") switch one phone between
  Elder, Bilal and Fatima, simulate leaving, fire the alert, mark found, and preview day, evening and night.
- The real GPS monitor is OFF in demo mode, so an emulator or a presenter's phone never false-alerts.
- Family data (relatives, routine, answers) is stored locally. Nothing leaves the phone.
- If Firebase is not configured, or the config is a placeholder, the app skips Firebase completely
  (`lib/services/firebase_gate.dart`). No spinner, no error, the elder screens never wait on the network.

## 2. The switch

File `lib/config.dart`, line 11. Change the default:

```dart
const String _kTrackingDefine = String.fromEnvironment('YAADAIN_TRACKING', defaultValue: 'demo');
//                                                                         change 'demo' -> 'firestore'
```

Or leave the file alone and build with:

```
flutter run --dart-define=YAADAIN_TRACKING=firestore
flutter build apk --dart-define=YAADAIN_TRACKING=firestore
```

The adapter is only used when `kTrackingBackend == firestore` AND Firebase initialised with real keys
(`FirestoreTrackingSource.available`). Otherwise the app falls back to demo tracking on its own.
Note: in firestore mode "Simulate leaving" and "Fire the alert now" do nothing. The elder phone's GPS drives the alert.

## 3. What gets read and written

Everything lives on the existing family document. The doc id is the family code **without** `YD-`, upper case
(`YD-7F3K` is stored as `families/7F3K`). Writes are merge-sets, so they never wipe the other fields.

`families/{CODE}`

| Field | Written by | Shape |
|---|---|---|
| `status` | elder phone, every 2 min (GPS check) | `{lat, lng, at (serverTimestamp), battery?, inside (bool), distanceM, bearingDeg}` |
| `lastAlert` | elder phone raises it; family phone acks; either resolves | `{id, outside (bool), kind ('zone_exit' or 'help'), distanceMeters, bearingDeg, battery?, unusualReason?, at, ackBy?, ackAt?, etaMin?, resolution ('' while open)}` |
| `help` | elder phone, "I need help" button | `{at}` (also raises a `lastAlert` of kind `help` if none is open) |
| `visit` | Bilal's "I'm on my way" | `{by, memberId, etaMin (default 8), at}`. Deleted on a new alert, on mark found and on reset |
| `alertAck` | family phone | `{by, at}` |

How the readers behave:

- An alert is **active** when `lastAlert.outside == true` and `resolution` is empty. Setting `outside:false` or any `resolution` closes it.
- `visit` is only picked up when it is under 60 minutes old and an alert is active. That makes the elder phone open "Bilal is coming".
- `at` may be a Firestore Timestamp, an ISO string or epoch milliseconds.
- A malformed document is ignored, never a crash. Write errors are swallowed (Firestore queues them offline).
- `reset()` writes `lastAlert {outside:false, resolution:'reset'}` and deletes `visit`.

## 4. Collections that already existed and are reused

These come from the older `FirebaseSyncService` and are unchanged:

- `families/{CODE}`: `createdAt`, `elder {name, romanName, photo}`, `authorizedEmails[]`,
  `lastAlert {outside, distanceMeters, at}` (the old three-field shape is a subset of the new one, so old and new builds interoperate),
  `safeZone {lat, lng, address, radiusMeters, updatedAt}`.
- `families/{CODE}/members/{id}`: `id, name, romanName, relationshipId, phone, isDeceased, photo, greeting, stories[{id,title,triggers,audio,photo}], contributor, updatedAt`.
- `families/{CODE}/media/{id}`: `{ext, data (base64)}`.

Not synced yet (stay on each phone): routine items, the six "Poochhein" answers, consent record, episode log.

## 5. Suggested firestore.rules (review, then paste by hand)

I did **not** touch `firestore.rules`. The current file lets any signed-in device read and write everything, which is fine for a hackathon and not for real families.
This tightens it so a device can only reach a family it created or joined. Review before use.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }

    // Family doc: anyone signed in can read it (needed to join by code),
    // create it, and merge-update it. Nobody can delete a family from a phone.
    match /families/{code} {
      allow get: if signedIn();
      allow list: if false;                     // no scanning for codes
      allow create, update: if signedIn()
        && request.resource.data.keys().hasOnly(
             ['createdAt','elder','authorizedEmails','lastAlert','safeZone',
              'status','help','visit','alertAck']);
      allow delete: if false;

      match /members/{id} {
        allow read, write: if signedIn();
      }
      match /media/{id} {
        allow read, write: if signedIn();
      }
    }
  }
}
```

Known limit: anonymous auth cannot prove "I belong to this family", only "I know the code". The code is the secret.
For stricter rules, store member uids on the family doc at join time and check `request.auth.uid in resource.data.memberUids`.
Also check `hasOnly` against `resource.data` on update if you later add fields, or it will reject them.

## 6. Dropping in your real Firebase config

Neither file is in the repo; both are gitignored. For a build without Firebase, copy the two `.example` files to `lib/firebase_options.dart` and `android/app/google-services.json` unchanged: the gate recognises their placeholder keys and the app runs offline.

1. Create the project, enable **Firestore**, **Authentication > Anonymous**, add an Android app with package `com.yaadain.yaadain`.
2. Easiest: `dart pub global activate flutterfire_cli`, then `flutterfire configure` in the project root.
   It overwrites `lib/firebase_options.dart` and writes `android/app/google-services.json`.
3. Manual: replace `lib/firebase_options.dart` with your generated one, and put the downloaded `google-services.json` in `android/app/`.
4. Paste the rules from section 5 in the console (or `firebase deploy --only firestore:rules`).
5. Rebuild with the switch from section 2. The gate sees non-placeholder keys and initialises Firebase.

## 7. Five-step two-phone test plan

Phone A = elder, phone B = Bilal. Both on the same build with the firestore switch on, both online, location permission granted on A.

1. **Create:** on A, onboarding as the elder phone, finish setup (home address, permissions). Note the family code in Settings (long-press logo 3 s, PIN 1947), e.g. `YD-7F3K`. In the console, confirm `families/7F3K` exists.
2. **Join:** on B, choose "I’m a family member", enter the code. B should show "Where is Abu" with a status line within a couple of minutes. Check `families/7F3K.status` updating every 2 min.
3. **Alert:** carry A about 200 m beyond the home radius (or temporarily set a tiny radius in Safe zones). Within one 2-minute tick `lastAlert.outside` becomes true. B shows the "left the home zone" banner and A opens the Madad screen on its own.
4. **Respond:** on B tap "I'm on my way". `visit` and `lastAlert.ackBy` appear. A switches to "Bilal is coming" by itself.
5. **Resolve:** walk A back inside, or on B tap "Mark as found". `lastAlert.outside` goes false with a resolution, `visit` disappears, A returns to its home screen. Also test airplane mode on A for a minute: the app must stay calm and catch up when back online.
