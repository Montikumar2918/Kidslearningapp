# Kids Learning App 🧸

A gentle, offline learning app for babies **0–2 years**, written in pure Flutter/Dart.
No database, no API, no internet, no ads.

## What's inside
| Section | What the baby does |
|---|---|
| 🐄 Animals | One big animal at a time; tap → bounce, stars, name + animal sound ("Cow… Moo! Moo!") |
| 🍎 Fruits, 🚗 Vehicles | Same tap-and-hear, vehicles make sounds ("Choo choo!") |
| 🔤 ABC | A–Z with a big letter + picture ("A for Apple") |
| अ आ इ | Hindi स्वर अ–अः ("अ से अनार") |
| 🔢 123 | Numbers 1–10, tap each picture to count aloud |
| 🎨 Colors, ⭐ Shapes | Big colour circles and smiling hand-drawn shapes |
| 🫧 Bubbles | Floating bubbles — tap to pop and hear what's inside |
| 🔎 Find It | "Where is the cow?" with 2 big pictures; wrong taps just wiggle, never "lose" |

Swipe left/right or use the big arrows. 🔊 repeats the word. The **A / अ** button switches English ↔ Hindi.
**Parents:** press and hold the 🔒 for 3 seconds → Hindi, Calm mode (less motion), Mute.

**Graphics:** emoji pictures + custom-drawn shapes, star bursts and clouds (no image files needed).
**Audio:** the phone's built-in offline text-to-speech (slow, high, friendly voice) + bundled soft chime/pop sounds in `assets/sounds/`.

## Build the APK on GitHub (no Flutter needed on your PC)
1. Create a new repository on GitHub.
2. Upload everything in this folder (including the hidden `.github` folder) to it, or:
   ```
   git init && git add . && git commit -m "Kids Learning App"
   git branch -M main
   git remote add origin https://github.com/<you>/kids-learning-app.git
   git push -u origin main
   ```
3. Open the **Actions** tab → "Build APK" runs automatically (~6–8 minutes).
4. Open the finished run → **Artifacts** → download `KidsLearningApp-apk` (a zip containing `KidsLearningApp.apk`).
5. Copy it to the phone and install (allow "Install unknown apps").

Optional: push a tag (`git tag v1.0.0 && git push --tags`) and the APK is attached to a GitHub Release.

## Build locally (optional)
```
flutter create --platforms=android --org com.kidslearning --project-name kids_learning_app .
flutter pub get
flutter run            # or: flutter build apk --release
```

## Notes
- Hindi speech uses the phone's Google TTS Hindi voice. If it's missing, the Parents screen shows how to install it.
- The release APK is signed with the default debug key — fine for installing on your own phones, but for Play Store you need your own signing key.
- Settings are kept in memory only (no storage), so they reset when the app is closed.
