# یادیں · Yaadain

**A living family tree for Urdu-speaking elders with memory loss.**
Every relative is a **face + their real voice + their relationship _to the elder_** — kept entirely on the device.

> _"Yaadain keeps the family from disappearing from the elder's memory — and keeps the elder from disappearing from the family."_

---

## Why this, and why this shape

Yaadain is a culturally-grounded instantiation of two evidence-supported dementia-care approaches — **reminiscence therapy** and **simulated presence therapy** — for a population Western apps don't serve: Urdu-speaking joint families, voice-first, dialect-aware.

It deliberately avoids the parts of the "ambient AI companion" idea that are clinically contested or ethically hot (see [What we did NOT build](#what-we-deliberately-did-not-build)).

## What it does

| Feature | For whom | What it is |
|---|---|---|
| **Family tree** (میرا خاندان) | Elder | A warm grid of faces, each labelled **"YOUR daughter / beti"** — from the elder's point of view. Tap a face → hear that person's real recorded voice. |
| **Flashbacks** (یادیں) | Elder | Say or type a word — a name, a place, "Eid", "shaadi" — and Yaadain surfaces the matching **recorded** memory. Retrieval only; it can only play back what family recorded. |
| **Who is this?** (یہ کون ہے؟) | Elder | Fast recognition helper for "someone is here and I don't know them." Tap a face → big "YOUR ___, <name>" + their voice. |
| **I'm safe** (میں ٹھیک ہوں) | Elder | Calm reassurance + one-tap call to family. |
| **Safe zone** | Family | A home point + radius. Alerts **on leaving** — event-based, never a live track. |
| **"If found" card** | Family | A printable QR that encodes contact info **inside itself** — a stranger scans it offline, no app or server. |

## The Urdu-NLP piece (`lib/nlp/`)

Flashback matching is **script-tolerant**: family type triggers however they like — `شادی`, `shaadi`, `shadi`, `SHAADI` — and the elder asks in yet another spelling. We reduce **both** Urdu-script and Roman-Urdu to a shared **consonant skeleton** (short vowels dropped, digraphs folded, letter variants unified), then compare with a normalized edit-distance ratio.

- `urdu_match.dart` — normalization + transliteration-folding + similarity. Unit-tested: `شادی ↔ shaadi`, `gaon ↔ گاؤں` both match; unrelated words don't.
- `flashback_engine.dart` — ranks recorded memories against a query. **Retrieval only, never generative.**

Run the tests:
```bash
flutter test
```

## Architecture

**Offline-first. No backend. No accounts. No cloud.** Vulnerable family data (faces, voices, relationships) never leaves the phone — a deliberate privacy + low-connectivity choice, not a limitation.

```
lib/
  models/         family_member, memory_story, relationship (joint-family vocab), elder_profile
  data/           repository.dart — JSON + media files in the app's private dir
  state/          app_state.dart  — ChangeNotifier over the repository
  nlp/            urdu_match.dart, flashback_engine.dart
  services/       audio_service.dart — record + playback
  screens/
    elder/        elder_home, family_tree, member_detail, who_is_this, flashbacks, im_safe
    caregiver/    caregiver_home, edit_member, elder_profile, safe_zone, if_found_card
  widgets/        member_avatar, voice_recorder
```

- **Storage:** `data.json` + `media/<uuid>.<ext>` under the app documents dir.
- **Audio:** real recordings via `record`, played via `audioplayers`. **No voice synthesis / cloning.**
- **Elder UI:** large type, big targets, Urdu-script RTL with a Roman-Urdu toggle.
- **Caregiver UI:** reached by long-pressing the ⚙ on the elder home.

## What we deliberately did NOT build

This section is the point, not a disclaimer:

- **No voice cloning / synthesis.** Generating novel speech in a real (especially deceased) person's voice for someone who can't consent is deceptive and risks re-grief. Yaadain plays only what family actually recorded.
- **No reality-correction / forced re-orientation.** Repeatedly telling a dementia patient "you're wrong" about their reality (Reality Orientation therapy) is clinically contested and can increase distress. Deceased relatives are handled gently; the elder is never bluntly told of a death.
- **No live GPS tracking.** The safe zone stores only a home point + radius and alerts on leaving — never a continuous trail. A memory companion is not a surveillance device.
- **No agitation-detection ML.** Reliable affect/confusion detection from elderly dialect-accented speech is not a solved problem; we don't claim accuracy we can't defend. Uncertain moments fail toward **silence and a human**, never a guess.
- **No real patient data.** Demo uses consenting stand-ins.

## Run it

```bash
flutter pub get
flutter run
```

Requires Flutter 3.22+, an Android device/emulator, and (for building) JDK 11
(`flutter config --jdk-dir=<jdk11>`).

## Status

Hackathon build. Elder + caregiver flows, flashback NLP, safe zone, and the
"if found" card are implemented and the NLP is unit-tested. Background
geofencing is foreground-checked with an honest "simulate leaving" demo aid.
