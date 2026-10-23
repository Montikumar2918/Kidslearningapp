# Kids Learning App 🐘🐤 (v2.0)

An offline learning playground for children aged **0–5** (focus on 0–2), in pure Flutter/Dart.
No database, no API, no internet, no ads.

## What's inside
**Mascots:** Golu the elephant 🐘 and Chiku the bird 🐤, drawn in code. They blink, wave, dance when the child gets something right, and fall asleep at rest time.

**Home:** a winding "world map" path with bobbing activity stops. Seasonal themes switch on automatically: Diwali diyas and lights, Holi colours, rain, winter snow, summer butterflies, and birthday balloons on the child's birthday.

| Age | Activities |
|---|---|
| 0–2 | Animals, Fruits, Vehicles, Colors, Shapes, ABC, 123 (tap to count), अ आ इ, 🫧 Bubbles, 🎹 Animal Piano, 🚪 "Who is it?" doorbell house, 🖍️ Magic Draw, 🖌️ Color Fill |
| 2–3 | everything above + 🔎 Find It, 🧺 Catch It, 🧩 Puzzle (2 pieces), ✏️ Tracing, क ख ग |
| 3–5 | everything above + 🐛 Caterpillar / 🚂 Train ordering, 4-piece puzzles, letters/shapes in Find It |

**Tracing:** ABC, abc, 1–10, स्वर and व्यंजन. A glowing star and 👆 show where to go next, the finger leaves a rainbow trail, and the letter comes alive with its picture.

**Rewards:** confetti, a dancing Golu, spoken praise ("Well done!" / "शाबाश!") and a 🎁 sticker. Stickers go in a **Sticker Book** where the child drags them onto Farm, Jungle, Sea and Space scenes. There are no timers, streaks or "losing".

**Sound:** a soft background lullaby (can be turned off), sound effects (pop, chime, doorbell, splash, whoosh, boing) and piano notes. All of these are generated and bundled in `assets/sounds/`. Words are spoken by the phone's offline voice in English or Hindi.

**Parent Zone** (🔒 opens after a maths question):
- age mode, language, music, mute and calm mode
- screen-time limit of 10/15/20/30 minutes, after which Golu yawns and says "Time to rest!"
- child's birthday, for the birthday theme
- turn each game on or off
- progress: minutes played, stickers, letters traced, favourite games
- reset progress

Settings and progress are stored only on the phone (shared_preferences).

## Build the APK on GitHub
1. Create a new GitHub repository and upload everything in this folder, **including the hidden `.github` folder**:
   ```
   git init && git add . && git commit -m "Kids Learning App v2"
   git branch -M main
   git remote add origin https://github.com/<you>/kids-learning-app.git
   git push -u origin main
   ```
2. Open **Actions → Build APK**. It runs automatically and takes about 8 minutes.
3. Open the finished run → **Artifacts** → download `KidsLearningApp-apk` → install `KidsLearningApp.apk` on the phone.
4. Optional: `git tag v2.0.0 && git push --tags` also attaches the APK to a GitHub Release.

## Run locally (optional)
```
flutter create --platforms=android --org com.kidslearning --project-name kids_learning_app .
flutter pub get
flutter run
```

## Notes
- Hindi speech needs the Google TTS Hindi voice. If it's missing, the Parent Zone explains how to install it.
- The APK is signed with the default debug key. That's fine for your own phones; the Play Store needs your own signing key.
- To use real recorded voices later, record files and play them with `Audio.I.fx(...)` instead of `say(...)`.
