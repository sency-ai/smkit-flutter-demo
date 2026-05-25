# smkit-flutter-demo

Demo Flutter app for [flutter_smkit](https://pub.dev/packages/flutter_smkit) — Sency's SMKit Flutter plugin.

This demo targets `flutter_smkit` `^1.0.6`, iOS `SMKit` `1.9.1`, and Android `com.sency.smkit:smkit` `1.6.5`.

## Flows

**2D Session** — Select one or more exercises, enable/disable skeleton overlay, run them sequentially with real-time rep counting and feedback.

**Demo Assessment** — Fixed assessment flow with body calibration, elevated/floor phone mode, and a scored summary per exercise.

## Setup

### Auth key

Create a local `.env` file in the project root:

```bash
cp .env.example .env
```

Then set `API_PUBLIC_KEY` in `.env`. The `.env` file is ignored by git and is bundled only into local builds.

### iOS

The demo `ios/Podfile` pins **SMKit** `1.9.1` from the Sency CocoaPods specs repo. After changing SDK versions, run from `ios/`:

```bash
pod install --repo-update
```

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is required for motion analysis.</string>
```

### Android

Add the SMKit Maven repository to `android/build.gradle` or use a local `../smkit_android/repo` with `com.sency.smkit:smkit:1.6.5`:

```groovy
allprojects {
    repositories {
        maven { url = uri("https://your-maven-repo/smkit") }
    }
}
```

Ensure `minSdkVersion 26` in `android/app/build.gradle`.

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## Run

```bash
flutter pub get
flutter run
```

## Structure

```
lib/
├── main.dart                        # App entry, WelcomePage, SDK configure
├── pages/
│   ├── pre_session_page.dart        # Exercise selection + skeleton toggle
│   ├── session_page.dart            # Camera, detection, feedback, rep counter
│   ├── assessment_summary_page.dart # Per-exercise score cards
│   └── summary_page.dart           # Raw JSON session result
├── models/
│   └── assessment_exercise_result.dart
└── widgets/
    ├── exercise_indicator.dart      # Animated rep counter / breathing circle
    ├── rom_gauge.dart               # Semi-circle ROM arc gauge
    └── skeleton_painter.dart        # 2D pose overlay (CustomPainter)
```

## License

MIT
