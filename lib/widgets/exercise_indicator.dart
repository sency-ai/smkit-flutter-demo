import 'dart:async';

import 'package:flutter/material.dart';

/// Animated rep counter circle — mirrors ExerciseIndicatorView from the iOS demo.
///
/// - Dynamic exercises: shows rep count, scales to 1.2 (green) on good rep,
///   then 0.8 (black) after 0.8 s.
/// - Static exercises: hides rep count, plays breathing animation (1 → 1.1 → 1)
///   in green while [inPosition] is true.
class ExerciseIndicator extends StatefulWidget {
  const ExerciseIndicator({
    super.key,
    required this.reps,
    required this.isDynamic,
    required this.inPosition,
    this.lastRepWasGood = false,
  });

  final int reps;
  final bool isDynamic;
  final bool inPosition;

  /// Flips true/false each time a good rep is completed (use a ticker bool).
  final bool lastRepWasGood;

  @override
  State<ExerciseIndicator> createState() => _ExerciseIndicatorState();
}

class _ExerciseIndicatorState extends State<ExerciseIndicator>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  Color _circleColor = Colors.black.withValues(alpha: 0.8);
  bool _isBreathing = false;
  Timer? _repResetTimer;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_scaleController);
  }

  @override
  void didUpdateWidget(ExerciseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Dynamic: rep completed
    if (widget.isDynamic && widget.reps != oldWidget.reps) {
      _playRepAnim(good: widget.lastRepWasGood);
    }

    // Static: in-position changed
    if (!widget.isDynamic && widget.inPosition != oldWidget.inPosition) {
      if (widget.inPosition && !_isBreathing) {
        _playBreathingAnim();
      }
    }
  }

  void _playRepAnim({required bool good}) {
    _repResetTimer?.cancel();
    final targetScale = good ? 1.2 : 1.0;
    setState(() {
      _circleColor = good ? Colors.green : Colors.black.withValues(alpha: 0.8);
    });
    _scaleAnim = Tween<double>(begin: 1.0, end: targetScale)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
    _scaleController.forward(from: 0);

    if (good) {
      _repResetTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _scaleAnim = Tween<double>(begin: targetScale, end: 0.8)
            .animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
        _scaleController.forward(from: 0);
        setState(() { _circleColor = Colors.black.withValues(alpha: 0.8); });
      });
    }
  }

  void _playBreathingAnim() {
    if (!mounted || !widget.inPosition) {
      _isBreathing = false;
      setState(() => _circleColor = Colors.black.withValues(alpha: 0.8));
      return;
    }
    _isBreathing = true;
    setState(() => _circleColor = Colors.green);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeIn));
    _scaleController.forward(from: 0).then((_) {
      if (!mounted) return;
      _scaleAnim = Tween<double>(begin: 1.1, end: 1.0)
          .animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
      _scaleController.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 0), () => _playBreathingAnim());
      });
    });
  }

  @override
  void dispose() {
    _repResetTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, __) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _circleColor,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Opacity(
                opacity: widget.isDynamic ? 1.0 : 0.0,
                child: Text(
                  '${widget.reps}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
