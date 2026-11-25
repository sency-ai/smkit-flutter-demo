# smkit-flutter-demo

Demo Flutter app for [flutter_smkit](https://pub.dev/packages/flutter_smkit) — Sency's SMKit Flutter plugin.

Uses `flutter_smkit` `1.1.8` from pub.dev, iOS `SMKit` `2.7.3`, and Android `com.sency.smkit:smkit` `1.9.9` from Sency Artifactory.

## Flows

**2D Session** — Select one or more exercises, enable/disable skeleton overlay, run them sequentially with real-time rep counting and feedback.

**Demo Assessment** — Fixed assessment flow with body calibration, elevated/floor phone mode, and a scored summary per exercise.

## Setup

### Auth key

Copy the template in the project root and paste your key into the copy:

```bash
cp AuthKey.local.properties.example AuthKey.local.properties
```

```properties
SMKIT_AUTH_KEY=your_sency_sdk_key_here
```

`AuthKey.local.properties` is git-ignored, so the key never shows up in `git status` or a commit. Pass it to every run or build:

```bash
flutter run --dart-define-from-file=AuthKey.local.properties
```

For CI, pass the key from an environment variable instead:

```bash
flutter build apk --dart-define=SMKIT_AUTH_KEY="$SMKIT_AUTH_KEY"
```

The app reads the key as `String.fromEnvironment('SMKIT_AUTH_KEY')`. Builds started from Xcode or Android Studio without these flags have no key, and the welcome screen says so.

### iOS

The demo `ios/Podfile` pins **SMKit** `2.7.3` from the Sency CocoaPods specs repo, matching the plugin. Run `flutter pub get`, then from `ios/`:

```bash
pod install --repo-update
```

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is required for motion analysis.</string>
```

### Android

The demo resolves the Android SDK from Sency Artifactory:

```kotlin
maven { url = uri("https://artifacts.sency.ai/artifactory/release") }
```

The plugin pins:

```text
com.sency.smkit:smkit:1.9.9
com.sency.smbase.nativeclient:smbase-native-client:1.9.9
```

Ensure `minSdkVersion 24` in `android/app/build.gradle`.

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## Feedback text

flutter_smkit reports feedback as IDs (for example `SquatHipCreaseDepth`) on
both platforms. The demo shows them through `feedbackDisplayText`, which uses
SMKit iOS's English wording from `lib/models/feedback_text.dart` and otherwise
splits the ID into words. Regenerate that file when the SDK's feedback text
changes.

## Local plugin checkout

To build against a local `flutter-smkit` checkout instead of pub.dev, create a git-ignored `pubspec_overrides.yaml` in the project root:

```yaml
dependency_overrides:
  flutter_smkit:
    path: ../flutter-smkit/packages/smkit
```

## Run

```bash
flutter pub get
flutter run --dart-define-from-file=AuthKey.local.properties
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
│   ├── assessment_exercise_result.dart
│   ├── feedback_display.dart        # Readable text for SMKit feedback IDs
│   ├── feedback_text.dart           # Generated from SMKit iOS 2.7.3 feedback text
│   └── smkit_error_text.dart        # Messages for flutter_smkit errors
└── widgets/
    ├── exercise_indicator.dart      # Animated rep counter / breathing circle
    ├── rom_gauge.dart               # Semi-circle ROM arc gauge
    └── skeleton_painter.dart        # 2D pose overlay (CustomPainter)
```

## License

MIT
