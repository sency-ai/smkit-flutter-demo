import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_smkit/smkit.dart';

import '../models/assessment_exercise_result.dart';
import '../widgets/exercise_indicator.dart';
import '../widgets/rom_gauge.dart';
import '../widgets/skeleton_painter.dart';
import 'assessment_summary_page.dart';
import 'summary_page.dart';

/// Supports a queue of exercises for regular 2D sessions and a timed assessment
/// mode that mirrors AssessmentViewController from the iOS demo.
class SessionPage extends StatefulWidget {
  const SessionPage({
    super.key,
    required this.exercises,
    required this.showSkeleton,
    this.isAssessment = false,
  });

  final List<String> exercises;
  final bool showSkeleton;
  final bool isAssessment;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  static int _nextCameraViewId = 42;
  late final int _cameraViewId;

  /// Assessment: each exercise runs for 15 seconds (mirrors iOS demo exerciseDuration=15).
  static const int _assessmentDurationSecs = 15;

  StreamSubscription<SmKitSessionEvent>? _eventSub;

  // Exercise queue
  int _exerciseIndex = 0;
  String get _currentExercise => widget.exercises[_exerciseIndex];

  // Exercise type resolved from SDK after startDetection
  bool _isDynamic = false;

  // Detection state
  bool _sessionReady = false;
  bool _isDetecting = false;
  bool _isPaused = false;

  // Rep / position (regular mode)
  int _reps = 0;
  bool _inPosition = false;
  bool _lastRepWasGood = false;
  bool _prevDidFinishMovement = false;
  List<String> _feedbacks = [];

  // Elapsed timer
  Timer? _ticker;
  double _timePassed = 0.0;

  // ── Calibration state (assessment mode) ──────────────────────────────────
  // Mirrors CalibrationViewModel from the iOS demo.
  bool _isPhoneReady = false;
  bool _isBodyInFrame = false;
  bool _isTooClose = false; // body calibration: user too close (mirrors iOS demo)
  bool _calibrationDismissed = false; // user pressed Skip or both checks passed

  // Bounding box guide (from didRecivedBoundingBox — normalized video coords 0–1)
  BoundingBoxData? _boundingBox;

  bool get _calibrationComplete =>
      _isPhoneReady && _isBodyInFrame && !_isTooClose;

  // Show calibration overlay in assessment until user skips or both checks pass.
  bool get _showCalibration => widget.isAssessment && !_calibrationDismissed;

  // ── Countdown (assessment only, 3-2-1 before each exercise) ───────────────
  bool _isCountdown = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;

  // ── ROM gauge (assessment + regular e.g. Squat Regular) ───────────────────
  double? _romRangeMin;
  double? _romRangeMax;
  double _currentRomValue = 0.0;

  // ── Assessment-specific state ─────────────────────────────────────────────
  List<double> _techniqueScores = [];
  List<double> _romValues = [];
  double _timeInPosition = 0.0;
  Set<String> _feedbackSet = {};
  // Green-zone: only when ROM is in target range (mirrors iOS currentFeedbacks vs greenZoneFeedbacks)
  List<double> _greenZoneTechniqueScores = [];
  Set<String> _greenZoneFeedbackSet = {};
  int _perfectRepsCount = 0; // Track perfect reps for summary
  final List<AssessmentExerciseResult> _assessmentResults = [];

  int get _remainingSecs =>
      (_assessmentDurationSecs - _timePassed).ceil().clamp(0, _assessmentDurationSecs);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cameraViewId = _nextCameraViewId++;
    _eventSub = SmKit.sessionEventStream.listen(_onEvent);
    _requestPermissionThenStart();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _ticker?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  Future<void> _requestPermissionThenStart() async {
    if (Platform.isAndroid) {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        _showError('Camera permission is required to use SMKit.');
        return;
      }
    }
    // Start session after the first frame so SmKitCameraView is built and registered
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSession();
    });
  }

  Future<void> _startSession() async {
    try {
      await SmKit.startSession(
        viewId: _cameraViewId,
        settings: SessionSettings(
          phonePosition: 'Floor',
          include3D: false,
          enableBodyCalibration: widget.isAssessment,
          enablePhoneCalibration: widget.isAssessment,
        ),
      );
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  Future<void> _startDetection() async {
    try {
      final result = await SmKit.startDetection(exercise: _currentExercise);
      if (mounted) {
        setState(() {
          _isDetecting = true;
          // Use the exercise type returned by the SDK to determine dynamic vs static.
          _isDynamic = result?.exerciseType == SMBaseExerciseType.dynamic_;
          _reps = 0;
          _inPosition = false;
          _prevDidFinishMovement = false;
          _feedbacks = [];
          _timePassed = 0;
          _techniqueScores = [];
          _romValues = [];
          _timeInPosition = 0.0;
          _feedbackSet = {};
          _greenZoneTechniqueScores = [];
          _greenZoneFeedbackSet = {};
          _perfectRepsCount = 0;
          _currentRomValue = 0.0;
          if (result?.minRom != null && result?.maxRom != null) {
            _romRangeMin = result!.minRom;
            _romRangeMax = result.maxRom;
          } else {
            _romRangeMin = null;
            _romRangeMax = null;
          }
        });
        _startTimer();

      }
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  /// Finishes the current exercise, saves assessment result, and advances.
  /// Mirrors finishCurrentExercise() from the iOS demo.
  Future<void> _finishCurrentExercise() async {
    _stopTimer();

    if (widget.isAssessment) {
      // Use green-zone scores if user ever reached target ROM (mirrors iOS); always show all feedbacks so summary lists every correction
      final scoresToUse = _greenZoneTechniqueScores.isEmpty
          ? _techniqueScores
          : _greenZoneTechniqueScores;
      final feedbacksToShow = _feedbackSet.toList();
      final avgScore = scoresToUse.isEmpty
          ? 0.0
          : scoresToUse.reduce((a, b) => a + b) / scoresToUse.length;
      final peakRom =
          _romValues.isEmpty ? null : _romValues.reduce(math.max);
      _assessmentResults.add(AssessmentExerciseResult(
        name: _currentExercise,
        techniqueScore: avgScore * 100,
        feedbacks: feedbacksToShow,
        timeInPosition: _timeInPosition,
        peakRom: peakRom,
        reps: _isDynamic ? _reps : null,
        perfectReps: _isDynamic ? _perfectRepsCount : null,
      ));
    }

    await _stopDetectionAndAdvance();
  }

  Future<void> _stopDetectionAndAdvance() async {
    try {
      await SmKit.stopDetection();
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _isDynamic = false;
        _reps = 0;
        _perfectRepsCount = 0;
        _inPosition = false;
        _feedbacks = [];
        _timePassed = 0;
        _romRangeMin = null;
        _romRangeMax = null;
        _currentRomValue = 0.0;
        // Calibration disabled — keep dismissed so it never re-triggers
        if (widget.isAssessment) {
          _calibrationDismissed = true;
          _boundingBox = null;
          _isTooClose = false;
        }
      });

      if (_exerciseIndex >= widget.exercises.length - 1) {
        await _quit();
      } else {
        setState(() => _exerciseIndex++);
        // Calibration temporarily disabled — start next exercise directly.
        await _startDetection();
      }
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  Future<void> _quit() async {
    _stopTimer();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    try {
      final result = await SmKit.stopSession();
      if (!mounted) return;
      // Allow native side to release camera before navigating away
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      if (widget.isAssessment) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => AssessmentSummaryPage(results: _assessmentResults),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => SummaryPage(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('$e');
        Navigator.of(context).pop();
      }
    }
  }

  void _skipCalibration() {
    setState(() {
      _calibrationDismissed = true;
      _boundingBox = null; // dismiss bounding box guide (mirrors iOS beginAssessment removing it)
    });
    if (widget.isAssessment) {
      _startCountdown();
    } else {
      _startDetection();
    }
  }

  /// 3-2-1 countdown then start detection (assessment only).
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdown = true;
      _countdownValue = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
      } else {
        _countdownTimer?.cancel();
        _countdownTimer = null;
        setState(() => _isCountdown = false);

        _startDetection();
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isPaused || !mounted) return;
      setState(() {
        _timePassed += 0.1;
        if (widget.isAssessment && _inPosition) {
          _timeInPosition += 0.1;
        }
      });
      if (widget.isAssessment &&
          _isDetecting &&
          _timePassed >= _assessmentDurationSecs) {
        _finishCurrentExercise();
      }
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  String get _formattedTime {
    if (widget.isAssessment) {
      final secs = _remainingSecs;
      return '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
    }
    final total = _timePassed.toInt();
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }

  // ── Event handler ─────────────────────────────────────────────────────────

  // Feedbacks that are ROM-depth cues — suppress when already in the green zone
  static const Set<String> _romDepthFeedbacks = {
    "Let your hands reach a bit further toward the floor.", // JeffersonCurl
    "Lower your hips a bit further down.", // SquatRegularOverheadStatic
  };

  void _onEvent(SmKitSessionEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case SmKitSessionEventType.captureSessionReady:
        setState(() => _sessionReady = true);
        // In assessment: show calibration first; do not start detection until calibration is dismissed.
        if (!widget.isAssessment) {
          _startDetection();
        }
        break;
      case SmKitSessionEventType.detectionData:
        final d = event.detectionData;
        if (d == null || _isPaused) return;
        setState(() {
          _inPosition = d.isInPosition;

          // Filter ROM-depth feedbacks if already in target ROM (mirrors AssessmentViewModel.swift)
          final isRomInRange = _romRangeMin != null &&
              _romRangeMax != null &&
              _currentRomValue >= _romRangeMin! &&
              _currentRomValue <= _romRangeMax!;
          // Green zone for this frame: ROM in target range (use current frame ROM)
          final inGreenZone = _romRangeMin != null &&
              _romRangeMax != null &&
              d.currentRomValue >= _romRangeMin! &&
              d.currentRomValue <= _romRangeMax!;

          if (d.isInPosition) {
            _feedbacks = isRomInRange
                ? d.feedback
                    .where((f) => !_romDepthFeedbacks.contains(f))
                    .toList()
                : d.feedback;
          } else if (_isDynamic && d.didFinishMovement) {
            // Dynamic exercises: show per-rep feedbacks on movement completion
            _feedbacks = d.feedback;
          } else {
            _feedbacks = [];
          }

          final didFinishMovementRisingEdge =
              d.didFinishMovement && !_prevDidFinishMovement;
          _prevDidFinishMovement = d.didFinishMovement;
          if (didFinishMovementRisingEdge && _isDynamic) {
            _reps++;
            _lastRepWasGood = d.isPerfectForm;
            if (d.isPerfectForm) _perfectRepsCount++;
          }
          _currentRomValue = d.currentRomValue;
          if (widget.isAssessment) {
            // Technique scores: only when in position (mirrors iOS: if isInPosition)
            if (d.isInPosition || (_isDynamic && d.didFinishMovement)) {
              if (d.techniqueScore > 0) _techniqueScores.add(d.techniqueScore);
            }
            // ROM values: always (mirrors iOS: if let r = rom { currentRomValues.append(r) })
            if (d.currentRomValue > 0) _romValues.add(d.currentRomValue);
            // Feedbacks: only when in position (mirrors iOS: if isInPosition { currentFeedbacks.insert })
            if (d.isInPosition || (_isDynamic && d.didFinishMovement)) {
              if (d.feedback.isNotEmpty) {
                final filtered = isRomInRange
                    ? d.feedback.where((f) => !_romDepthFeedbacks.contains(f))
                    : d.feedback;
                for (final f in filtered) {
                  _feedbackSet.add(f);
                }
              }
              if (d.isShallowRep) _feedbackSet.add("Maintain full range of motion");
            }
            // Green zone: collect regardless of isInPosition (mirrors iOS exactly)
            if (inGreenZone && d.techniqueScore > 0) {
              _greenZoneTechniqueScores.add(d.techniqueScore);
              for (final f in d.feedback) {
                _greenZoneFeedbackSet.add(f);
              }
            }
          }
        });
        break;
      case SmKitSessionEventType.phoneCalibration:
        if (event.isPhoneReady != null) {
          setState(() => _isPhoneReady = event.isPhoneReady!);
          // Auto-dismiss calibration once both checks pass.
          if (widget.isAssessment && _calibrationComplete && !_calibrationDismissed) {
            _skipCalibration();
          }
        }
        break;
      case SmKitSessionEventType.bodyCalibration:
        final cal = event.calibrationData;
        if (cal != null) {
          setState(() {
            switch (cal.state) {
              case BodyCalibrationStateType.didEnterFrame:
                _isBodyInFrame = true;
                _isTooClose = false;
                break;
              case BodyCalibrationStateType.didLeaveFrame:
                _isBodyInFrame = false;
                _isTooClose = false;
                break;
              case BodyCalibrationStateType.tooClose:
                _isTooClose = cal.isTooClose;
                break;
            }
          });
          if (widget.isAssessment && _calibrationComplete && !_calibrationDismissed) {
            _skipCalibration();
          }
        }
        break;
      case SmKitSessionEventType.boundingBox:
        if (event.boundingBox != null) {
          setState(() => _boundingBox = event.boundingBox);
        }
        break;
      case SmKitSessionEventType.positionData:
        if (event.positionData != null) setState(() {});
        break;
      case SmKitSessionEventType.sessionError:
        _showError(event.errorMessage ?? event.errorCode ?? 'Unknown error');
        break;
      default:
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// Overlay content (session UI). Used in-tree on iOS; on Android drawn via [Overlay] above platform view.
  Widget _buildOverlayContent(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
          // Left side control panel (hidden during calibration overlay)
          if (!_showCalibration)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 50, // Slightly restricted width
              child: SafeArea(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!widget.isAssessment)
                        _SidePanelButton(
                          icon: Icons.navigate_next,
                          onPressed: _isDetecting ? _finishCurrentExercise : null,
                        ),
                      _SidePanelButton(
                        icon: _isPaused ? Icons.play_arrow : Icons.pause,
                        onPressed: _isDetecting ? _togglePause : null,
                      ),
                      _SidePanelButton(
                        icon: Icons.stop,
                        onPressed: _quit,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main content column (hidden during calibration overlay)
          if (!_showCalibration)
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      color: Colors.black.withValues(alpha: 0.6),
                      padding: const EdgeInsets.fromLTRB(56, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentExercise,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.isAssessment)
                            Text(
                              '${_exerciseIndex + 1} / ${widget.exercises.length}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                        ],
                      ),
                    ),

                    // Middle: Gauge and Indicator (Flexible & Scrollable if needed)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_romRangeMin != null && _romRangeMax != null) ...[
                              RomGauge(
                                value: _currentRomValue.clamp(0.0, 1.0),
                                rangeMin: _romRangeMin!,
                                rangeMax: _romRangeMax!,
                                isInPosition: _inPosition,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _inPosition ? 'In Position' : 'Get in position',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _inPosition ? Colors.green : Colors.white,
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            ExerciseIndicator(
                              reps: _reps,
                              isDynamic: _isDynamic,
                              inPosition: _inPosition,
                              lastRepWasGood: _lastRepWasGood,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom: Timer and Progress
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isAssessment
                                ? (_timePassed <= 0 ? "15.0" : (_assessmentDurationSecs - _timePassed).toStringAsFixed(1))
                                : _formattedTime,
                            style: TextStyle(
                              color: widget.isAssessment && _remainingSecs <= 5
                                  ? Colors.orange
                                  : Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.isAssessment)
                            Container(
                              height: 6,
                              width: double.infinity,
                              color: Colors.white.withValues(alpha: 0.2),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: ((_assessmentDurationSecs - _timePassed) / _assessmentDurationSecs).clamp(0.0, 1.0),
                                child: Container(
                                  color: _remainingSecs > 10
                                      ? Colors.green
                                      : _remainingSecs > 5
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Real-time feedbacks overlay (Floating above bottom)
          if (!_showCalibration && _feedbacks.isNotEmpty)
            Positioned(
              left: 56,
              right: 16,
              bottom: widget.isAssessment ? 100 : 80, // Offset to not cover timer/progress
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _feedbacks.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 16))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),


          // Loading overlay (before camera is ready)
          if (!_sessionReady)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Skeleton overlay
          if (widget.showSkeleton && !_showCalibration)
            Positioned.fill(
              key: const ValueKey('skeleton'),
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final overlaySize =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    return _SkeletonOverlay(size: overlaySize);
                  },
                ),
              ),
            ),

          // Dark fallback background for calibration when bounding box not yet received
          if (_showCalibration && _boundingBox == null)
            Container(color: Colors.black.withValues(alpha: 0.7)),

          // Bounding box guide — shown during calibration; provides dark surround + camera cutout
          if (_showCalibration && _boundingBox != null)
            Positioned.fill(
              child: IgnorePointer(
                child: _BoundingBoxGuide(
                  box: _boundingBox!,
                  isInPosition: _isBodyInFrame,
                ),
              ),
            ),

          // Calibration overlay — shown in assessment before each exercise starts (no background — bounding box guide provides the dark overlay)
          if (_showCalibration)
            _CalibrationOverlay(
              isPhoneReady: _isPhoneReady,
              isBodyInFrame: _isBodyInFrame,
              isTooClose: _isTooClose,
              exerciseIndex: _exerciseIndex,
              totalExercises: widget.exercises.length,
              exerciseName: _currentExercise,
              onStop: _quit,
              onSkip: _skipCalibration,
              showPhoneCalibration: true,
            ),

          // 3-2-1 countdown overlay (assessment only)
          if (widget.isAssessment && _isCountdown)
            _CountdownOverlay(
              exerciseName: _currentExercise,
              countdownValue: _countdownValue,
              onStop: _quit,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SmKitCameraView(
            viewId: _cameraViewId,
            width: size.width,
            height: size.height,
          ),
          Positioned.fill(child: _buildOverlayContent(context)),
        ],
      ),
    );
  }
}

// ── Countdown overlay (3-2-1) ─────────────────────────────────────────────────
// Mirrors countdownOverlay from AssessmentViews in the iOS demo.

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({
    required this.exerciseName,
    required this.countdownValue,
    required this.onStop,
  });

  final String exerciseName;
  final int countdownValue;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onStop,
                ),
              ),
              const SizedBox(height: 40),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEXT UP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '$countdownValue',
                      key: ValueKey<int>(countdownValue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Calibration overlay ───────────────────────────────────────────────────────
// Mirrors CalibrationView from the iOS demo.

class _CalibrationOverlay extends StatelessWidget {
  const _CalibrationOverlay({
    required this.isPhoneReady,
    required this.isBodyInFrame,
    required this.isTooClose,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.exerciseName,
    required this.onStop,
    required this.onSkip,
    this.showPhoneCalibration = true,
  });

  final bool isPhoneReady;
  final bool isBodyInFrame;
  final bool isTooClose;
  final int exerciseIndex;
  final int totalExercises;
  final String exerciseName;
  final VoidCallback onStop;
  final VoidCallback onSkip;
  final bool showPhoneCalibration;

  /// Mirrors CalibrationView.statusMessage from iOS demo (order: too close, phone, body, hold still).
  String get _statusMessage {
    if (isTooClose) return 'Too close — step back';
    if (showPhoneCalibration && !isPhoneReady) return 'Tilt your phone upright';
    if (!isBodyInFrame) return 'Step into the frame';
    return 'Hold still…';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Exercise ${exerciseIndex + 1} / $totalExercises',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onStop,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Calibration card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Text(
                      'Calibration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exerciseName,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          if (showPhoneCalibration) ...[
                            _CalibrationRow(
                              icon: Icons.phone_iphone,
                              label: 'Phone angle',
                              isReady: isPhoneReady,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _CalibrationRow(
                            icon: Icons.accessibility_new,
                            label: 'Body in frame',
                            isReady: isBodyInFrame && !isTooClose,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Skip Calibration',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
    );
  }
}

class _CalibrationRow extends StatelessWidget {
  const _CalibrationRow({
    required this.icon,
    required this.label,
    required this.isReady,
  });

  final IconData icon;
  final String label;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
        Icon(
          isReady ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isReady ? Colors.green : Colors.white54,
          size: 22,
        ),
      ],
    );
  }
}

// ── Skeleton overlay ──────────────────────────────────────────────────────────

class _SkeletonOverlay extends StatefulWidget {
  const _SkeletonOverlay({required this.size});
  final Size size;

  @override
  State<_SkeletonOverlay> createState() => _SkeletonOverlayState();
}

class _SkeletonOverlayState extends State<_SkeletonOverlay> {
  Map<String, dynamic> _positionData = {};
  double? _frameAspect;
  StreamSubscription<SmKitSessionEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SmKit.sessionEventStream.listen((event) {
      if (event.type == SmKitSessionEventType.positionData &&
          event.positionData != null &&
          mounted) {
        setState(() {
          if (event.positionData!.isNotEmpty) {
            _positionData = Map<String, dynamic>.from(event.positionData!);
          }
          if (event.frameAspect != null) _frameAspect = event.frameAspect;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: SkeletonPainter(
        positionData: _positionData,
        size: widget.size,
        frameAspect: _frameAspect,
        showDebugLabel: false,
      ),
    );
  }
}

// ── Bounding box guide ────────────────────────────────────────────────────────
// Mirrors BodyCalibrationGuideView from the iOS demo:
// dark surround with a clear cutout rectangle and a white/green border.

class _BoundingBoxGuide extends StatelessWidget {
  const _BoundingBoxGuide({
    required this.box,
    required this.isInPosition,
  });

  final BoundingBoxData box;
  final bool isInPosition;

  /// Converts normalized video rect to screen rect, accounting for resizeAspectFill.
  Rect _toScreenRect(Size screenSize) {
    final vA = box.videoAspect;
    final sA = screenSize.width / screenSize.height;
    double scaledW, scaledH, offsetX, offsetY;
    if (sA < vA) {
      // Portrait screen, landscape video: fill by matching screen height to video height
      scaledH = screenSize.height;
      scaledW = screenSize.height * vA;
      offsetX = (screenSize.width - scaledW) / 2;
      offsetY = 0;
    } else {
      // Fill by matching screen width to video width
      scaledW = screenSize.width;
      scaledH = screenSize.width / vA;
      offsetX = 0;
      offsetY = (screenSize.height - scaledH) / 2;
    }
    return Rect.fromLTWH(
      box.x * scaledW + offsetX,
      box.y * scaledH + offsetY,
      box.width * scaledW,
      box.height * scaledH,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final guideRect = _toScreenRect(size);
    return CustomPaint(
      size: size,
      painter: _BoundingBoxPainter(guideRect: guideRect, isInPosition: isInPosition),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  const _BoundingBoxPainter({required this.guideRect, required this.isInPosition});

  final Rect guideRect;
  final bool isInPosition;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(guideRect, const Radius.circular(12));

    // Dark surround with clear cutout
    final overlayPaint = Paint()..color = const Color(0x80000000); // black 0.5 alpha
    final fullRect = Offset.zero & size;
    final path = ui.Path()
      ..addRect(fullRect)
      ..addRRect(rrect)
      ..fillType = ui.PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Border: white or green
    final borderPaint = Paint()
      ..color = isInPosition ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(_BoundingBoxPainter old) =>
      old.guideRect != guideRect || old.isInPosition != isInPosition;
}

// ── Side panel button ─────────────────────────────────────────────────────────

class _SidePanelButton extends StatelessWidget {
  const _SidePanelButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: Colors.white,
      iconSize: 28,
      onPressed: onPressed,
    );
  }
}
