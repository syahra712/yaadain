# یادیں · Yaadain

**A living family tree for Urdu-speaking elders with memory loss.**
Every relative is a **face + their real voice + their relationship _to the elder_** — kept entirely on the device.

> _"Yaadain keeps the family from disappearing from the elder's memory — and keeps the elder from disappearing from the family."_

---

## Yaadain 2: the redesign

Version 2 redesigns the whole app: 35 screens across every phone in the family. All of them are built into the app, and the Android build plays the whole story on one phone in demo mode ([how to run it](#run-it)).

- **One language per screen.** The elder's screens are entirely Urdu, set in Noto Nastaliq. The family's screens are entirely English. Nothing mixes the two, and every screen passes an automated script-mixing check.
- **Built for his hands and eyes.** Touch targets are 56px or larger (main actions 64 to 80px), no Urdu text is smaller than 20px, and every screen has the same back and home buttons. One warm clay colour marks the single most important action on a screen.
- **The family can find him.** If Dada Jaan leaves a safe zone, the family is alerted and can see where he is. One of them taps "I'm on my way", and his phone tells him, in Urdu, that Bilal is coming.

<p align="center"><img src="design/screens/FlowMap.png" alt="Flow map of every screen and how they connect"></p>

### Setting up

<table>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/Splash.png" width="190" alt="Launch"><br><sub>Launch</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/RoleSelection.png" width="190" alt="Who will use this phone?"><br><sub>Who will use this phone?</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/JoinFamily.png" width="190" alt="Join with a family code"><br><sub>Join with a family code</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/ElderPhoneSetup.png" width="190" alt="Set up his phone"><br><sub>Set up his phone</sub></td></tr>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/Permissions.png" width="190" alt="What his phone needs"><br><sub>What his phone needs</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/Khayal.png" width="190" alt="Consent, explained to him in Urdu"><br><sub>Consent, explained to him in Urdu</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/ConsentRecord.png" width="190" alt="Consent recorded"><br><sub>Consent recorded</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/AppIcon.png" width="190" alt="App icon"><br><sub>App icon</sub></td></tr>
</table>

### The elder's phone (Urdu only)

<table>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/Main.png" width="190" alt="Home, daytime"><br><sub>Home, daytime</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/ElderHomeEvening.png" width="190" alt="Home, evening"><br><sub>Home, evening</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/FamilyTree.png" width="190" alt="My family"><br><sub>My family</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/WhoIsThis.png" width="190" alt="Who is this?"><br><sub>Who is this?</sub></td></tr>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/MemberDetail.png" width="190" alt="A relative: Bilal"><br><sub>A relative: Bilal</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/Poochhein.png" width="190" alt="Ask (Poochhein)"><br><sub>Ask (Poochhein)</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/Sukoon.png" width="190" alt="Calm (Sukoon)"><br><sub>Calm (Sukoon)</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/Voices.png" width="190" alt="Voices"><br><sub>Voices</sub></td></tr>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/RoutinePrompt.png" width="190" alt="Medicine reminder"><br><sub>Medicine reminder</sub></td></tr>
</table>

### Safety: keeping him found

<table>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/Madad.png" width="190" alt="Help: when he is outside"><br><sub>Help: when he is outside</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/ImSafe.png" width="190" alt="You are safe"><br><sub>You are safe</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/IfFoundUr.png" width="190" alt="If found (Urdu)"><br><sub>If found (Urdu)</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/IfFoundEn.png" width="190" alt="If found (English)"><br><sub>If found (English)</sub></td></tr>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/NightAnchor.png" width="190" alt="Night"><br><sub>Night</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/WhereIsAbu.png" width="190" alt="Where is Abu (family)"><br><sub>Where is Abu (family)</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/AlertDetail.png" width="190" alt="Alert (family)"><br><sub>Alert (family)</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/SafeZones.png" width="190" alt="Safe zones (family)"><br><sub>Safe zones (family)</sub></td></tr>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/FindAbu.png" width="190" alt="Find Abu (family)"><br><sub>Find Abu (family)</sub></td></tr>
</table>

### The family's phones (English only)

<table>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/CaregiverHome.png" width="190" alt="Caregiver home"><br><sub>Caregiver home</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/FamilyHome.png" width="190" alt="Family member home"><br><sub>Family member home</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/AddRelative.png" width="190" alt="Add a relative"><br><sub>Add a relative</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/AnswersEditor.png" width="190" alt="Answers he can ask for"><br><sub>Answers he can ask for</sub></td></tr>
<tr><td align="center" valign="top" width="25%"><img src="design/screens/Routine.png" width="190" alt="Routine and medicine"><br><sub>Routine and medicine</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/WeeklyReport.png" width="190" alt="Weekly report"><br><sub>Weekly report</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/RecordHello.png" width="190" alt="Record a hello"><br><sub>Record a hello</sub></td><td align="center" valign="top" width="25%"><img src="design/screens/CareCircle.png" width="190" alt="Care circle"><br><sub>Care circle</sub></td></tr>
</table>

### Design system

| | |
|---|---|
| Colour | Paper `#F3EBDC`, ink `#2C2620`, teal `#1F6F5C`. Clay `#9E5626` marks the one care action per screen. Red `#B3261E` is used only for a true emergency. A sepia ring `#A9998A` marks relatives who have passed away. |
| Type | Noto Nastaliq Urdu for Urdu; Nunito and Fraunces for English. |
| Motif | A jaali lattice, taken from South Asian screen windows. |
| Demo family | Dada Jaan (Muhammad Akram, 78), his son and caregiver Bilal, his daughter Fatima in Lahore, his daughter-in-law Ayesha, his grandchildren Zaid, Maryam and Hassan, and Ruqayya, his late wife. All are fictional. |

### Design files

- `design/screens/`: a PNG of every screen
- `design/boards/`: the HTML source of every screen; open any file in a browser
- `design/canvas.json`: the layout of the design canvas

---

## Why this, and why this shape

Yaadain is a culturally-grounded instantiation of two evidence-supported dementia-care approaches — **reminiscence therapy** and **simulated presence therapy** — for a population Western apps don't serve: Urdu-speaking joint families, voice-first, dialect-aware.

It deliberately avoids the parts of the "ambient AI companion" idea that are clinically contested or ethically hot (see [What we did NOT build](#what-we-deliberately-did-not-build)).

## What it does

| Feature | For whom | What it is |
|---|---|---|
| **Home** (گھر) | Elder | One calm card: the day, the date (Gregorian and Hijri), whether he is at home, who is home, the next prayer and what comes next. It changes for the evening and for the night. |
| **My family** (میرا خاندان) | Elder | Faces labelled from his point of view: "your son, Bilal". A relative who has passed away has a sepia ring and is spoken of gently. |
| **Who is this?** (یہ کون ہے؟) | Elder | Someone is here and he can't place them. Tap a face to see who they are to him. |
| **Ask** (پوچھیں) | Elder | The six questions he asks again and again, answered in the family's own words and voices. Every ask is logged for the weekly report. |
| **Voices** (آوازیں) | Elder | Short hellos the family records for him. |
| **Calm** (سکون) | Elder | A quiet screen for unsettled moments, day or night. |
| **Help** (مجھے مدد چاہیے) | Elder | One big button. When he is outside it alerts the family, and his phone tells him in Urdu who is coming. |
| **If found card** | Elder, for a stranger | Who he is, where he lives and whom to call. Urdu first, with an English version one tap away. |
| **Where is Abu** | Family | Is he home, a radar of home, his safe zones and where he is, and a timeline of today. |
| **Alerts** | Family | He left a safe zone. Tap "I'm on my way" and his phone shows that you are coming. The alert shows who is next in the circle if nobody answers. |
| **Find Abu** | Family | Last known position and a missing-person pack ready to share: what he looks like today, medication, places he may go. |
| **Care circle** | Family | Who is on duty, shifts and handoff notes. |
| **Weekly report** | Family | When he got confused this week and about what, from his asks. |
| **Set up for him** | Family | Relatives, the answers to his questions, routine and medicine, and recorded hellos. |

## The Urdu-NLP piece (`lib/nlp/`)

In version 2 the elder asks from six fixed questions instead of searching, so this matcher is not wired into the new screens yet. It is kept, and unit-tested, for spoken questions later.

Flashback matching is **script-tolerant**: family type triggers however they like — `شادی`, `shaadi`, `shadi`, `SHAADI` — and the elder asks in yet another spelling. We reduce **both** Urdu-script and Roman-Urdu to a shared **consonant skeleton** (short vowels dropped, digraphs folded, letter variants unified), then compare with a normalized edit-distance ratio.

- `urdu_match.dart` — normalization + transliteration-folding + similarity. Unit-tested: `شادی ↔ shaadi`, `gaon ↔ گاؤں` both match; unrelated words don't.
- `flashback_engine.dart` — ranks recorded memories against a query. **Retrieval only, never generative.**

Run the tests:
```bash
flutter test
```

## Architecture

**Offline-first.** Everything works with no network and no account: faces, voices and relationships live on the phone. Sharing his status between family phones goes through Firebase. It is optional and switched off in the demo build ([FIREBASE_SYNC.md](FIREBASE_SYNC.md)).

```
lib/
  main.dart, routes.dart   start-up and every screen route
  config.dart              the tracking switch: demo or firestore
  design/       scaffolds (elder Urdu RTL, family English), buttons, cards, avatar, jaali pattern
  util/         Urdu digits and dates, Hijri date, approximate Karachi prayer times, app clock
  models/       family_member, kinship, care (routine, circle, alerts, zones), elder_profile, episode_log
  data/         repository.dart (JSON on the phone), demo_seed.dart (the demo family)
  state/        app_state.dart, a ChangeNotifier over the repository
  tracking/     one interface with a scripted demo source and a Firestore source;
                elder_reaction opens Help and "I'm safe" on his phone
  demo/         presenter controls
  settings/     PIN-locked settings on the elder's phone
  services/     audio, notifications, Firebase gate and sync, platform wrappers
  nlp/          urdu_match, flashback_engine
  screens/      onboarding/, elder/, safety/, family/
```

- **Storage:** `data.json` + `media/<uuid>.<ext>` under the app documents dir.
- **Audio:** real recordings via `record`, played via `audioplayers`. **No voice synthesis / cloning.**
- **Elder UI:** Urdu only, Noto Nastaliq, right to left, Urdu digits, touch targets of 56px or more.
- **Family UI:** English only.
- **Tests:** `flutter test` runs the NLP unit tests and a screenshot test of every screen (`test/visual/`).

## What we deliberately did NOT build

This section is the point, not a disclaimer:

- **No voice cloning / synthesis.** Generating novel speech in a real (especially deceased) person's voice for someone who can't consent is deceptive and risks re-grief. Yaadain plays only what family actually recorded.
- **No reality-correction / forced re-orientation.** Repeatedly telling a dementia patient "you're wrong" about their reality (Reality Orientation therapy) is clinically contested and can increase distress. Deceased relatives are handled gently; the elder is never bluntly told of a death.
- **No location trail.** The family sees only his latest position, one point overwritten every two minutes, and an alert when he leaves a safe zone. No history of where he has been is kept. A memory companion is not a surveillance device.
- **No agitation-detection ML.** Reliable affect/confusion detection from elderly dialect-accented speech is not a solved problem; we don't claim accuracy we can't defend. Uncertain moments fail toward **silence and a human**, never a guess.
- **No real patient data.** Demo uses consenting stand-ins.

## Run it

```bash
flutter pub get
flutter run
```

Requires Flutter 3.22+, an Android device or emulator, and JDK 17 for building
(`flutter config --jdk-dir=<jdk17>`).

The Firebase config files are not in the repo. To build without Firebase, copy
`lib/firebase_options.dart.example` to `lib/firebase_options.dart` and
`android/app/google-services.json.example` to `android/app/google-services.json`.
The app sees the placeholder keys and runs offline. To connect a real project,
follow [FIREBASE_SYNC.md](FIREBASE_SYNC.md).

**Demo mode.** One phone plays the whole story. On the elder's home screen, hold
the logo for 3 seconds, enter PIN 1947 and open **Demo controls**. From there you
can load the demo family, switch between Dada Jaan's, Bilal's and Fatima's phones,
make him leave home, answer the alert, and preview the evening and night screens.

**For reviewers:** [Technical brief](docs/TECHNICAL.md) (architecture, hard engineering, tests, honest limitations).

## Watch it

**Presentation.** A 13-slide walkthrough of the whole app.

- **One click:** [**Open the presentation**](docs/PRESENTATION.md). All 13 slides, right in GitHub.
- **Animated version:** [open the cinematic page](https://htmlpreview.github.io/?https://github.com/syahra712/yaadain/blob/main/docs/index.html). The slides animate there. The recordings play from [`docs/media/`](docs/media/).
- Offline: download the repo and double-click `docs/index.html`.

[![Title slide](docs/preview/slide-01.png)](docs/PRESENTATION.md)

| | |
|---|---|
| [![The elder's phone](docs/preview/slide-05.png)](docs/PRESENTATION.md) | [![The safety story](docs/preview/slide-06.png)](docs/PRESENTATION.md) |
| [![Tools for the family](docs/preview/slide-07.png)](docs/PRESENTATION.md) | [![The demo](docs/preview/slide-11.png)](docs/PRESENTATION.md) |

**Recordings.** Three short screen recordings of the Android build, taken on an emulator in demo mode. GitHub plays each one in the browser:

- [The elder's phone](docs/media/01-elder-phone.mp4): setup, then Dada Jaan's Urdu home, family tree, "who is this", questions, calm and voices.
- [The safety story](docs/media/02-safety-story.mp4): he leaves the home zone, Bilal sees the alert and answers, Dada Jaan sees "Bilal is coming".
- [Day and night](docs/media/03-day-and-night.mp4): the night, evening and day home screens.

## Status

Competition build, October 2026. All 35 Yaadain 2 screens are in the app, the
Android release runs the demo story on one phone, and `flutter test` passes
(93 tests, including a screenshot test of every screen). Sharing his status
between two phones is written but switched off until a Firebase project is
connected ([FIREBASE_SYNC.md](FIREBASE_SYNC.md)).
