# smkit-flutter-demo

Demo Flutter app for [flutter_smkit](https://pub.dev/packages/flutter_smkit) — Sency's SMKit (no-UI) Flutter plugin.

Mirrors the iOS and Android demo apps: exercise selection → camera session → real-time feedback → summary.

## Flows

**2D Session** — Select one or more exercises, enable/disable skeleton overlay, run them sequentially with real-time rep counting and feedback.

**Demo Assessment** — Fixed set of 5 exercises (15 seconds each), body calibration, then a scored summary per exercise.

## Setup

### Auth key

Open `lib/main.dart` and set your auth key:

```dart
await SmKit.configure(authKey: 'YOUR_AUTH_KEY');
```

### iOS

Add **SMKit** and **SMBase** to your Xcode project via Swift Package Manager:
- In Xcode: **File → Add Package Dependencies**
- Use the Sency iOS SDK repository

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is required for motion analysis.</string>
```

### Android

Add the SMKit Maven repository to `android/build.gradle`:

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
