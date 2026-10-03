# Yaadain 2: Technical Brief

Audience: competition technical judges. Everything below was read from the repository on 3 October 2026. Where something is not implemented, switched off, or inconsistent, it is stated as such. Paths are relative to the repository root.

## 1. Summary

Yaadain is a Flutter 3.22.3 / Dart 3.4.4 Android app for Urdu-speaking elders with memory loss and the family who care for them. One codebase ships two experiences chosen by a device role (`elder` or `family`): an Urdu-only, right-to-left, Nastaliq elder phone (family tree with faces and real recorded voices, six fixed "Poochhein" questions, calm screen, help button, "if found" card), and an English-only caregiver phone (safe zones, radar, alerts, care circle, routine, weekly report, record-a-hello). Data is stored on the device as JSON plus media files; the app works with no network and no account. A scripted demo mode plays the whole "elder leaves home, family responds" story on a single phone. A Firestore two-phone sync adapter is written and wired but OFF in the shipped build. There is no generative model, no voice synthesis and no location history.

## 2. Architecture

### 2.1 Layers (`lib/`, 93 Dart files)

| Layer | Path | Role |
|---|---|---|
| Entry and routing | `lib/main.dart`, `lib/routes.dart` | Boot, locale and theme switch by role, named-route table (`onGenerateRoute`) |
| Config | `lib/config.dart` | Build-time switches: tracking backend, settings PIN, family-code prefix |
| Design system | `lib/design/` | `ElderTheme`/`FamilyTheme` scaffolds, `UrduText`, `EnText`, buttons, cards, avatar, jaali pattern, custom-painted icons (`icons.dart`, `svg_path.dart`) |
| Models | `lib/models/` | `FamilyMember`, `MemoryStory`, kinship/relationship tables, `ElderProfile`, `AppSettings`, `care.dart` (answers, routine, consent, circle, safe zones, alerts), `Episode` log |
| Data | `lib/data/repository.dart`, `lib/data/demo_seed.dart` | JSON persistence; the demo family |
| State | `lib/state/app_state.dart` (1,102 lines) | One `ChangeNotifier` over the repository: all business logic |
| Tracking | `lib/tracking/` | `TrackingSource` interface, demo and Firestore implementations, `ElderReaction` |
| Services | `lib/services/` | Audio, notifications, confusion detector, Firebase gate and sync, platform ports |
| NLP | `lib/nlp/` | Script-tolerant Urdu / Roman-Urdu matcher and retrieval engine |
| Util | `lib/util/` | Urdu digits and dates, Hijri date, approximate Karachi prayer times, app clock |
| Screens | `lib/screens/{onboarding,elder,safety,family}/` | 31 `*_screen.dart` files plus widget parts |

### 2.2 State management (Provider)

`AppState` (`lib/state/app_state.dart`) is the single store, exposed with `provider` (`context.watch<AppState>()` / `read`). It owns the `Repository`, the `SyncService`, the active `TrackingSource`, and two timers (routine check every 30 s, GPS check every 2 min on the Firestore backend only). Screens read derived getters (`activeAlert`, `elderStatus`, `answerText`, `homePoint`) and call intent methods (`acknowledgeAlert`, `imOnMyWay`, `markFound`, `raiseHelp`, `saveAnswer`). Writes call `repo.save()` then `notifyListeners()`. There are no per-feature state classes; the trade-off is a large file.

### 2.3 Routing and role reaction

`lib/routes.dart` is a named-route table. `AppState.initialRoute` picks the root from role and time of day (elder home, or the night screen). `lib/tracking/elder_reaction.dart` makes the elder phone react without any screen subscribing:

- alert raised: push `/elder/madad` (once per alert id)
- family "I'm on my way" arrives: push `/elder/safe` with the visitor's name and ETA (a visit takes priority over Madad)
- alert resolved: pop back to the root
- routine item due: push the routine prompt (suppressed during a crisis screen)
- time of day changes: swap root between home and night

### 2.4 Tracking backend abstraction (`demo | firestore`)

`lib/tracking/tracking_source.dart` defines one interface with three broadcast streams (`status`, `alert`, `visit`), synchronous `current*` getters (so a screen can render before the first event), elder-side methods (`publishStatus`, `raiseAlert`, `raiseHelp`), family-side methods (`acknowledge`, `onMyWay`, `markFound`) and demo-only methods (`simulateLeaving`, `fireAlertNow`, `reset`).

- `lib/config.dart`: `kTrackingBackend` is `demo` unless built with `--dart-define=YAADAIN_TRACKING=firestore`.
- `AppState.startTracking()` chooses `FirestoreTrackingSource` only if the backend is `firestore` AND `FirebaseGate.available` is true; otherwise it falls back to `DemoTrackingSource` on its own.
- `lib/services/firebase_gate.dart`: `main()` calls `Firebase.initializeApp` only when the config is not a placeholder (`FirebaseGate.isPlaceholder`), with a 4 s timeout; any failure leaves the gate false and the app runs offline.

### 2.5 Data models and storage

- Persistence: `data.json` plus `media/<uuid>.<ext>` under the app documents directory (`lib/data/repository.dart`, `path_provider`). The care data lives under key `care` (`lib/models/care.dart`).
- Key types: `FamilyMember` (name, relationship id, deceased flag, photo, greeting, stories); `PoochheinQuestion` / `Answer` (text, audio path, who recorded it, ask counter); `RoutineItem` / `RoutineLog` (clock-based or prayer-anchored, with offset); `ConsentRecord`; `CircleMember` (escalation order, `escalateAfterMin`); `SafeZone` (lat, lng, radius, rule text, enabled); `AlertRecord` (kind, distance, bearing, ack, ETA, resolution); `Episode` (category, severity, timestamp, optional note), the base for the weekly report.
- Relationship model: kinship is stored from the elder's point of view (`lib/models/relationship.dart`, `kinship.dart`), so faces are labelled "your son, Bilal"; generation banding is tested.

### 2.6 Services

- Audio: real recording via `record`, playback via `audioplayers` (`lib/services/audio_service.dart`). No synthesis.
- Notifications: `flutter_local_notifications` for a family-device banner, once per alert id (`AppState._onAlert`).
- Platform ports: `lib/services/platform/ports.dart` with `real.dart` (geolocator, url_launcher, audio, notify) and `fakes.dart`. Every real call is wrapped in try/catch and fails quietly; tests swap in fakes with `Svc.useFakes()`.
- Sync: `SyncService` with `LocalSyncService` (no-op) and `FirebaseSyncService`, chosen by `FirebaseGate.available`. Family create/join calls have 5 to 8 s timeouts and never block the elder screens.
- Speech: `speech_to_text` 6.6.2, used only by `ConfusionDetector` (see 3.3).

## 3. The hard engineering

### 3.1 Urdu Nastaliq right-to-left rendering rules

Enforced in code, not just by convention:

- `YaadainTheme.ur()` (`lib/theme.dart`) clamps every Urdu style to size >= 20, line height >= 1.8 (default 1.9), weight 400, font family `NastaliqUrdu` (bundled `assets/fonts/NotoNastaliqUrdu.ttf`). Nastaliq has tall ascenders and descenders that clip at normal line height, and heavier weights distort the joins.
- `UrduText` (`lib/design/text.dart`) forces `TextDirection.rtl` and, in debug builds, prints a warning if the string contains Latin letters, because a Latin glyph falls back to a different font. `hasLatinLetters` is also used at runtime: in `lib/screens/elder/poochhein_screen.dart` an answer containing Latin letters is not shown to the elder and a safe Urdu fallback is used instead.
- `ElderTheme` (`lib/design/elder_scaffold.dart`) wraps the subtree in `Directionality(rtl)` with `Locale('ur')`; `main.dart` sets `Locale('ur')` for the elder role and `Locale('en')` for family, with `flutter_localizations`. In RTL the back button sits on the right and its arrow icon points right.
- One script per screen: elder screens are Urdu only, family screens English only. Dates and digits are rendered by `lib/util/urdu_format.dart` (Urdu digits, Urdu weekdays and day periods) and `lib/util/hijri.dart`.
- Limitation: the "automated script-mixing check" mentioned in README.md is, as far as I could find, only this debug `assert` plus `hasLatinLetters` guards. No test in `test/` asserts script purity across screens.

### 3.2 Offline-first and no-network behaviour

- All elder data (faces, voices, relationships, answers, routine, consent) is local JSON. Nothing in the elder flow awaits the network.
- Firebase is skipped entirely when the config is a placeholder or init fails (`main.dart`, `FirebaseGate`). Network-touching calls in `AppState` are bounded by `.timeout()` with calm fallbacks (`onTimeout: () => <FamilyMember>[]`).
- Plugin failures (no microphone, no GPS, missing audio file, no notification channel) are swallowed in `lib/services/platform/real.dart` and `main.dart`; the UI shows a calm state rather than an error.
- On the Firestore backend, write errors are swallowed because Firestore queues writes offline (FIREBASE_SYNC.md section 3). The test plan in section 7 of that file includes an airplane-mode check; I have not seen a recorded result for it.
- Android permissions requested (`android/app/src/main/AndroidManifest.xml`): INTERNET, RECORD_AUDIO, CAMERA, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, CALL_PHONE, POST_NOTIFICATIONS.

### 3.3 The Poochhein "fixed-question answering" design, and what `lib/nlp` actually does

This is the part most likely to be misread, so precisely:

**Poochhein in v2 is not NLP.** The elder picks one of six fixed questions (`kQuestions` in `lib/models/care.dart`): what day is it, where am I, where is Bilal, when is the meal, when is my medicine, where is Ruqayya. There is no free-text or spoken matching on this screen. Answers are derived like this (`AppState.answerText`, `PoochheinScreen._text`):

1. `medicine`: always computed live from the family's Routine (`medicineAnswerUr`): next enabled, unlogged medicine item today, with prayer-anchored times resolved from the Karachi prayer table (`lib/util/prayer.dart`); or "all of today's medicine is taken".
2. Every other question: the family-authored Urdu text, with `{day}` and `{part}` placeholders filled from the live clock; a family-recorded voice answer plays if one exists (`audioPath`).
3. If no valid text exists: built-in Urdu fallbacks (day/period from the clock and whether he is home from the tracking status; "you are in your house, all is well"; or "your family will answer this shortly").
4. Every ask increments a counter and logs an `Episode` (category `question`; the Ruqayya question, about his late wife, is logged at severity 2) for the weekly report.

So answers are retrieved or computed from family-entered or clock-derived data. Nothing is generated.

**What `lib/nlp/` is, and where it is used:**

- `lib/nlp/urdu_match.dart`: script-tolerant similarity. Both Urdu script and Roman-Urdu are reduced to a shared consonant skeleton (diacritics and tatweel dropped; alef/yeh/heh/kaf variants unified; Roman digraphs folded, vowels, `y`, `w`, `h` dropped; repeated letters collapsed), then compared by normalised Levenshtein ratio (`1 - distance / maxLen`). So `شادی`, `shaadi`, `shadi` match each other.
- `lib/nlp/flashback_engine.dart`: ranks recorded memory stories against a query with a threshold of 0.72, matching tokens against story triggers and title; stories without audio are never returned. Retrieval only. As the README states, it is not wired into any v2 screen. A repository-wide search found no use outside `lib/nlp` and the confusion detector.
- Actual live use of the matcher: `lib/services/confusion_detector.dart` with `lib/data/confusion_phrases.dart` (Urdu, Roman-Urdu and Punjabi variants such as "tusi kaun ho"). It listens on-device via `speech_to_text` (Urdu locale if present), matches final results at threshold 0.80, responds immediately to severity >= 2 phrases but to mild disorientation only on repetition within 120 s, with a 60 s cooldown, and fails silent if speech is unavailable. Whether this detector is switched on in the shipped v2 flow, I did not verify; the README states "No agitation-detection ML".
- Honest scale: this is a ~180-line string-similarity primitive, not a trained model. The consonant-skeleton approach will conflate unrelated words with the same consonants (threshold-dependent) and does not understand meaning.

### 3.4 Safe-zone geofencing and the radar

- Geometry: haversine distance and initial bearing (`lib/services/platform/real.dart`, `haversineM`, `bearingDeg`; 0 = north, clockwise). On the real GPS path `Geolocator.distanceBetween` is used for distance.
- Zones: `SafeZone` (name in English and Urdu, centre, radius default 150 m, rule text, enabled). `AppState.homePoint` resolves the home zone, else the elder profile's stored home, else the Karachi demo coordinates.
- Real monitor (`AppState._gpsCheck`, Firestore backend and elder role only): every 2 minutes get a high-accuracy fix (15 s limit), compute distance and bearing, publish status, raise an alert on crossing outward (also when the first reading is already outside), and auto-resolve with `returned` when he comes back in. A secondary flag "Outside after dark" (`_unusualReason`) is set if the time is before Fajr or after Isha. Polling every 2 minutes, not continuous tracking or OS geofencing, so there is detection latency of up to roughly two minutes plus GPS fix time.
- Limitation: the monitor checks only the single home point from `homePoint`. Other safe zones and their rule text are stored and drawn on the radar, but I found no code that evaluates them for alerting.
- Radar (`lib/screens/safety/widgets/safety_family_radar.dart`): a `CustomPaint` (`_RadarPainter`) draws a disc, dashed rings at 2x and 3x the home radius, compass ticks, other zones as places, and his dot. Geometry converts lat/lng to east/north metres with a local equirectangular approximation (`offsetMeters`), accurate at neighbourhood scale, then to canvas polar offsets. `bearingWords` maps a bearing to compass words ("north-east") for the text sentence.

### 3.5 Alert and escalation flow

1. Source raises `ActiveAlert` (kind `zone_exit` or `help`) with distance, bearing, battery, optional unusual reason.
2. `AppState._onAlert` writes an `AlertRecord`, logs an `Episode`, and on family devices shows one system notification per alert id.
3. Elder phone: `ElderReaction` opens the Madad screen (help and call actions use `tel:` / `sms:` intents via `RealLauncher`).
4. Family: `AlertDetailScreen` shows distance, direction and last position; "I'm on my way" calls `onMyWay`, which creates a `Visit` and acknowledges the alert.
5. Elder phone receives the visit and shows ImSafe: "Bilal is coming" in Urdu.
6. Either side closes it: `markFound` or auto-return resolves; both phones return to normal.

Escalation: `CircleMember.escalationOrder` and `escalateAfterMin` define a chain. `AlertDetailScreen` computes and displays "Escalates to <person> in N min, then <person>" as a countdown from `raisedAt`. I found no code that automatically notifies the next person when the timer expires; the chain is shown to the family, not enforced by a background job. Treat escalation as a displayed policy.

### 3.6 Demo mode scripted simulation

`lib/tracking/demo_tracking_source.dart` (no GPS, no network): `simulateLeaving()` starts a 1 s tick. Position moves along a fixed vector from 40% to 100% of ~226 m north and ~226 m east of the Karachi home point. He crosses the 150 m ring after about 12 s (`inside` becomes false from the haversine distance), the alert fires at t = 60 s (battery 64 to 61), and he holds at about 320 m by t = 90 s. `fireAlertNow()` jumps straight to the alert. `lib/demo/demo_controls.dart` (long-press the logo 3 s, PIN 1947, "Demo controls") switches one phone between Elder, Bilal and Fatima views, simulates leaving, fires and clears the alert, and previews day, evening and night through `AppClock`. The real GPS monitor is deliberately off in demo mode so an emulator or presenter phone never false-alerts. Family screens show a "Demo" chip while `kTrackingIsDemo` is true. Demo data (`lib/data/demo_seed.dart`) is a fictional family.

### 3.7 Privacy and consent model

- Consent is explained to the elder in Urdu on the Khayal screen and stored as a `ConsentRecord` (`lib/models/care.dart`): date, who was present, what is shared (status, zones, last position to Bilal only), `historyDays`, his response ("That's fine" / "Not now"), and when to ask again (91 days if agreed, 7 days if declined). The record screen shows it to the family in English.
- Data minimisation: the tracking status is one latest point; Firestore overwrites it every 2 minutes (FIREBASE_SYNC.md, section 3). No location trail is stored; history consists of alert records and `Episode` events (no coordinates in `Episode`).
- No cloud account is needed; media sync (when enabled) is compressed into Firestore documents, no Cloud Storage.
- Known inconsistency: see Q4 in section 7 (consent screen says 7 days of history kept; nothing consumes `historyDays`).

### 3.8 Elder-safety UX decisions

- Touch sizes: elder primary buttons are 64 px (80 px for the large variant) (`lib/design/buttons.dart`); elder scaffold back/home controls are 80 px (`elder_scaffold.dart`); family minimum touch is 56 px (`YaadainTheme.familyTouch`, `family_scaffold.dart`). The README states >= 56 px everywhere; I verified these constants but did not audit every tappable widget.
- Hidden settings: the settings gate is a 3-second press-and-hold on the logo (`ElderLogoGate`, `lib/settings/locked_settings.dart`) followed by a PIN dialog (`kSettingsPin`, `lib/config.dart`). A short tap does nothing so the elder never opens it by accident. The PIN is a hard-coded constant (1947), also documented in FIREBASE_SYNC.md and README.md, so it is a guard against accidents, not a security control.
- One colour for the one care action per screen; red only for real emergency (README design system).
- Fail toward silence and a human: the confusion detector requires repetition for mild phrases and has a cooldown; speech failure is silent; deceased relatives get a sepia ring and gentle wording, and the elder is never told bluntly of a death.
- Never stall in his hands: consent save, audio, GPS and notification failures are all best-effort (`try/catch`) and the flow continues.
- Back from the If-found card never exits the app (a regression test exists, `test/visual/safety-elder_test.dart`).

## 4. Firestore sync design (OFF in the shipped build)

Source: `FIREBASE_SYNC.md`, `lib/tracking/firestore_tracking_source.dart`, `lib/services/firebase_sync_service.dart`.

**State:** the adapter is written and wired but OFF. The default build is demo mode. The owner's Firebase project is on another PC; no Firebase keys or config files are in the repository (`lib/firebase_options.dart` and `android/app/google-services.json` are gitignored; only `.example` placeholders exist, which the gate recognises and treats as "no Firebase"). I have not run this adapter against a live project and no two-phone test result is recorded in the repo.

**Switch:** `lib/config.dart` default `'demo'` to `'firestore'`, or `--dart-define=YAADAIN_TRACKING=firestore`. Used only if Firebase also initialised with real keys.

**Data layout:** one family document `families/{CODE}` (code without the `YD-` prefix, upper case), written with merge-sets:

| Field | Written by | Content |
|---|---|---|
| `status` | elder phone every 2 min | lat, lng, server time, battery, inside, distanceM, bearingDeg |
| `lastAlert` | elder raises; family acks; either resolves | id, outside, kind, distance, bearing, ack fields, ETA, resolution |
| `help` | elder "I need help" | timestamp (also raises a `help` alert if none open) |
| `visit` | family "I'm on my way" | by, memberId, etaMin, at; read only if under 60 min old and an alert is active |
| `alertAck` | family | by, at |

Pre-existing from `FirebaseSyncService`: `elder`, `authorizedEmails`, `safeZone`, `members/{id}`, and `media/{id}` (base64). The newer `lastAlert` is a superset of the old three-field shape so old and new builds interoperate. Not synced: routine, the six answers, consent record, episode log.

**Robustness rules:** an alert is active when `outside == true` and `resolution` is empty; timestamps accept Firestore Timestamp, ISO string or epoch ms; malformed documents are ignored; write errors are swallowed.

**Security:** `firestore.rules` is in the repo and FIREBASE_SYNC.md proposes tighter rules (`hasOnly` key allow-list, no list/delete on families). The doc states the current rules let any signed-in (anonymous) device read and write everything and that anonymous auth proves only "I know the code". The family code is the only secret. That is acceptable for a demonstration and not for real families.

**Planned verification:** a five-step two-phone test plan is in FIREBASE_SYNC.md section 7 (create, join, alert, respond, resolve, plus airplane mode).

## 5. Testing and verification

Command run on this machine: `flutter test --no-pub` (Flutter 3.22.3 from `$HOME/development/flutter`, JDK 17). Result: **95 tests ran, all passed ("All tests passed!")**. I did not run `flutter pub get`, `flutter analyze` or any build. README.md says 93 tests; the measured count today is 95, so the README is slightly stale.

| File | Tests | Covers |
|---|---|---|
| `test/logic_test.dart` | 8 | Generation banding of relationships (child +1, grandchild +2, elder -1, peer 0, unknown 0); confusion-phrase matching (recognition, place, severity 2, Punjabi variant, calm sentences do not trigger); flashback retrieval (Urdu query vs Roman trigger, by title, unrelated returns nothing, no-audio story not surfaced) |
| `test/widget_test.dart` | 7 | `UrduMatch` skeleton and similarity cases (shadi/shaadi, `شادی`, gaon vs `گاؤں`, unrelated words low); boot routing (seeded elder to elder home, empty install to splash); route table resolves known routes |
| `test/visual/foundation_test.dart` | 10 | Design foundation galleries and elder/family stub screens with live alert banner |
| `test/visual/onboarding_test.dart` | 11 | Splash, role selection, join family, elder phone setup, permissions, Khayal consent, consent record (populated and empty states) |
| `test/visual/elder-a_test.dart` | 7 | Elder-side screens in the elder-a group (see the file for the exact list; not itemised here) |
| `test/visual/elder-b_test.dart` | 14 | Family tree, who-is-this, member detail (memorial, missing, bare), Poochhein (idle, answer, empty), Voices, routine prompt |
| `test/visual/safety-elder_test.dart` | 12 | Madad (home, empty), I'm safe (including no voice), If-found Urdu/English, Back-button behaviour |
| `test/visual/safety-family_test.dart` | 11 | Where is Abu (home, outside, Fatima view, empty), alert detail (coming, none), safe zones, find Abu |
| `test/visual/family-a_test.dart` | 6 | Caregiver home, family home (with alert), care circle, weekly report, empty family |
| `test/visual/family-b_test.dart` | 9 | Add relative (add, edit, errors, recorded), answers editor, routine, record hello |
| `test/visual/harness.dart` | n/a | Shared harness: loads the real Nunito, NastaliqUrdu, Fraunces and Material icon fonts; 390 px wide phone at DPR 1; fake platform plugins (`Svc.useFakes()`); injected demo state and fixed clock (3 Oct 2026, 9:41 am) |

The visual tests are golden-image tests against 80 PNG files in `test/visual/goldens/`. They guard against layout regressions and overflow on every screen and state. They do not test behaviour such as alert timing against real GPS.

Not covered by any test I found: `AppState` alert/escalation logic end to end, `ElderReaction` navigation, `DemoTrackingSource` timeline, `FirestoreTrackingSource`, the GPS monitor, consent persistence, and no integration or on-device test. Not verified by me in this session: the running Android build, the demo recordings in `docs/media/`, and anything involving a live Firebase project.

## 6. Metrics (measured on the working tree, 3 October 2026)

| Metric | Value | How measured |
|---|---|---|
| Dart files in `lib/` | 93 | `find lib -name '*.dart'` |
| Dart lines in `lib/` | 25,438 | `wc -l` over those files |
| Largest file | `lib/state/app_state.dart`, 1,102 lines | `wc -l` |
| Screen files (`*_screen.dart`) | 31 (onboarding 7, elder 9, safety 7, family 8) | `find lib/screens` |
| README claim | "35 screens" (counts design-board screens/states, including app icon and flow map) | README.md; not equal to the 31 screen files |
| Test files | 10 (`*_test.dart`) | `find test` |
| Test lines | 1,167 (including `harness.dart`) | `wc -l` |
| Tests executed | 95, all passed | `flutter test --no-pub`, this session |
| Golden images | 80 | `ls test/visual/goldens` |
| Git commits | 8 (first 2026-09-04, rest 2026-10-02 to 2026-10-03) | `git log` |
| Bundled font files | 6 (Nunito, NotoNastaliqUrdu, Fraunces x4) | `ls assets/fonts` |
| Android permissions | 7 | `AndroidManifest.xml` |
| Runtime dependencies (direct) | 18 in `pubspec.yaml` (excluding the Flutter SDK and flutter_localizations) including firebase_core, cloud_firestore, firebase_auth, google_sign_in, provider, record, audioplayers, speech_to_text, geolocator, qr_flutter, mobile_scanner | `pubspec.yaml` |

Only the commit history indicates when the work was done: 7 of 8 commits are dated 2 to 3 October 2026, i.e. the v2 redesign is a very recent build.

## 7. Likely judge Q&A

**Q1. Is the "NLP" real? Is there a language model?**
No language model and no machine learning. `lib/nlp/` is a deterministic consonant-skeleton plus Levenshtein matcher for Urdu script and Roman-Urdu. It is unit-tested. In v2 the Poochhein screen does not use it; the elder chooses from six fixed questions. The matcher is used by the confusion detector and kept for future spoken questions. We call it a normalisation primitive, not AI.

**Q2. How does Poochhein produce an answer?**
Medicine is computed from the family's routine and the prayer-time table; the rest is the family's own written or recorded answer, with day and day-part filled from the clock; fallbacks are fixed Urdu sentences. Nothing is generated, so the app cannot say something the family did not choose, apart from the clock-derived sentence and the fallbacks, which are fixed text.

**Q3. Does the tracking actually work, or is it a demo?**
In the shipped default build it is a scripted demo (`DemoTrackingSource`), by design, so it can run on one phone and never false-alerts on an emulator. A real GPS path exists (`AppState._gpsCheck`, `FirestoreTrackingSource`) but only runs with the `firestore` switch and a real Firebase project. We have not recorded a live two-phone test in the repository, so we do not claim it has been validated in the field.

**Q4. The consent screen says history is kept for 7 days, but you say there is no location trail. Which is it?**
That is an inconsistency in the current build. `ConsentRecord.historyDays` is set to 7 on agreement (`lib/screens/onboarding/khayal_screen.dart`) and the English consent record shows "History kept: 7 days". Nothing else in `lib/` reads `historyDays`, and the app stores no coordinate history: the latest position is a single overwritten point, and history is only alert records and event categories with timestamps (used for the weekly report). The honest fix is to change the label to describe what is actually kept (alerts and events) or to implement a bounded history; as it stands the label overstates what is stored.

**Q5. Is Firebase sync working? Where are your keys?**
Sync is written and wired but OFF. No keys or config are in the repository by design; the owner's Firebase project is on another PC. Without keys the app detects the placeholder config and runs fully offline. Turning it on needs a `flutterfire configure` run, the rules from FIREBASE_SYNC.md, and the one-line switch.

**Q6. How secure is the sync design?**
Not production-grade, and the docs say so. Anonymous auth plus a family code as the only secret; current rules allow any signed-in device to read and write. The proposed rules restrict keys and forbid listing and deleting but still cannot prove family membership; the suggested hardening is storing member uids on the family doc. Photos and audio would be stored as base64 in Firestore documents (free-plan workaround), which has size limits.

**Q7. What happens if nobody responds to an alert? Does it escalate automatically?**
The escalation chain (order and minutes) is configured in the care circle and shown on the alert screen as a countdown. There is no background service that automatically notifies the next person when the timer expires, and a family device only gets a local notification if the app process is running; there is no push messaging (FCM) in the dependency list. This is a real limitation.

**Q8. What is the detection latency and battery cost of the geofence?**
Polling every 2 minutes with a high-accuracy fix, so up to about 2 minutes plus fix time (15 s limit) after he crosses the boundary. Polling was chosen over continuous GPS to limit battery use. It uses a foreground timer in the app process; I did not find a foreground service or OS-level geofence, so behaviour while the app is killed or the phone is in deep doze is unverified and likely degraded. Only the home zone is evaluated.

**Q9. Why not clone the family's voices or use an LLM companion?**
Deliberate. Synthesising a deceased person's voice for someone who cannot consent is deceptive and risks re-grief; reality correction is clinically contested; reliable distress detection in accented elderly Urdu speech is not solved. The app plays only real recordings and fails toward silence and a human.

**Q10. How do you know the Urdu renders correctly and the UI is elder-friendly?**
Rendering is constrained by the theme (size >= 20, line height >= 1.8, Nastaliq, RTL, one script per screen) and checked by 80 golden screenshots using the real bundled fonts. That proves layout stability, not usability. There has been no recorded user study with elders in the repository; the design decisions follow accessibility conventions (large targets, hidden settings, single primary action) and should be validated with real users and caregivers.

**Q11 (bonus). Is the PIN secure?**
No. `kSettingsPin = '1947'` is a hard-coded constant in `lib/config.dart` and is printed in the docs. It prevents accidental entry by the elder. A real deployment would set a per-family PIN at setup.

**Q12 (bonus). Why one large `AppState`?**
It kept 31 screens and the tracking, routine and alert logic consistent under a tight deadline. The cost is a 1,100-line file and coupled concerns; splitting it into repositories or per-feature notifiers is the obvious next refactor. Platform access is already behind ports with fakes, which is what makes the screens testable.
