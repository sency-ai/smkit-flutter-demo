import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_smkit/smkit.dart';

import 'pages/pre_session_page.dart';
import 'pages/session_page.dart';
import 'pages/workout_builder_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(const SmKitDemoApp());
}

class SmKitDemoApp extends StatelessWidget {
  const SmKitDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMKit Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isConfiguring = true;
  bool _isConfigured = false;
  bool _useElevatedMode = true;
  String? _configureError;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  Future<void> _configure() async {
    setState(() {
      _isConfiguring = true;
      _configureError = null;
    });
    try {
      final authKey = dotenv.env['API_PUBLIC_KEY']?.trim() ??
          const String.fromEnvironment('API_PUBLIC_KEY').trim();
      if (authKey.isEmpty) {
        throw StateError('Missing API_PUBLIC_KEY in .env');
      }
      await SmKit.configure(
        authKey: authKey,
        support3D: false,
        poseModelChoice: SmKitPoseModelChoice.adaptiveChoice,
      );
      if (mounted) {
        setState(() {
          _isConfigured = true;
          _isConfiguring = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConfiguring = false;
          _configureError = '$e';
        });
      }
    }
  }

  void _startSession() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreSessionPage(useElevatedMode: _useElevatedMode),
      ),
    );
  }

  void _startWorkoutBuilder() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutBuilderPage(useElevatedMode: _useElevatedMode),
      ),
    );
  }

  void _startAssessment() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPage(
          exercises: const [
            'OverheadMobility',
            'SquatRegularOverheadStatic',
            'JeffersonCurl',
            'StandingSideBendRight',
            'StandingSideBendLeft',
          ],
          showSkeleton: true,
          isAssessment: true,
          useElevatedMode: _useElevatedMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'SMKit Demo',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sency motion analysis — no UI',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_isConfiguring) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                const Text(
                  'Configuring SDK…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ] else if (_configureError != null) ...[
                Text(
                  'Configuration failed:\n$_configureError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'Retry',
                  color: Colors.grey,
                  onPressed: _configure,
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.phone_iphone),
                    title: const Text(
                      'Elevated Mode',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    value: _useElevatedMode,
                    onChanged: (value) =>
                        setState(() => _useElevatedMode = value),
                  ),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'Start 2D Session',
                  color: Colors.blue,
                  onPressed: _isConfigured ? _startSession : null,
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'Build Workout',
                  color: Colors.teal,
                  onPressed: _isConfigured ? _startWorkoutBuilder : null,
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'Demo Assessment',
                  color: Colors.deepPurple,
                  onPressed: _isConfigured ? _startAssessment : null,
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
