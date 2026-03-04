import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ROM (range of motion) gauge mirroring iOS RomGaugeView from the demo.
/// Semi-circle arc with green target zone and needle; shows value as 0–100%.
class RomGauge extends StatelessWidget {
  const RomGauge({
    super.key,
    required this.value,
    required this.rangeMin,
    required this.rangeMax,
    this.isInPosition = false,
  });

  /// Current ROM value, typically 0.0–1.0.
  final double value;

  /// Target zone lower bound (0.0–1.0).
  final double rangeMin;

  /// Target zone upper bound (0.0–1.0).
  final double rangeMax;

  /// Whether user is in position (affects percentage text color when in range).
  final bool isInPosition;

  /// Normalize value for half-circle: 0..1 -> 0.5..1.0 (matches iOS).
  static double _normalize(double v) => 0.5 * v + 0.5;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = _normalize(value.clamp(0.0, 1.0));
    final normalizedMin = _normalize(rangeMin.clamp(0.0, 1.0));
    final normalizedMax = _normalize(rangeMax.clamp(0.0, 1.0));
    final isInRange = normalizedValue >= normalizedMin && normalizedValue <= normalizedMax;
    // Needle: 0 -> -90°, 1 -> 90° (from vertical)
    final needleAngleDeg = -90 + value.clamp(0.0, 1.0) * 180;

    return SizedBox(
      height: 100, // Increased to safely contain the 140px circle's top half + text
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            size: const Size(140, 140),
            painter: _RomGaugePainter(
              normalizedValue: normalizedValue,
              normalizedRangeStart: normalizedMin,
              normalizedRangeEnd: normalizedMax,
            ),
          ),
          Transform.rotate(
            angle: needleAngleDeg * math.pi / 180,
            child: Container(
              width: 6,
              height: 60,
              margin: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value.clamp(0.0, 1.0) * 100).round()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isInRange ? Colors.green : Colors.white,
                  ),
                ),
                Text(
                  'ROM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RomGaugePainter extends CustomPainter {
  _RomGaugePainter({
    required this.normalizedValue,
    required this.normalizedRangeStart,
    required this.normalizedRangeEnd,
  });

  final double normalizedValue;
  final double normalizedRangeStart;
  final double normalizedRangeEnd;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 30.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc: semi-circle (trim 0.5 to 1.0 in Swift = bottom half)
    // In Flutter: startAngle pi, sweepAngle pi.
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, backgroundPaint);

    // Target zone arc: trim 0.5..1.0 = pi..2*pi, so trim t -> angle = 2*pi*t
    final rangeStart = 2 * math.pi * normalizedRangeStart;
    final rangeSweep = (normalizedRangeEnd - normalizedRangeStart).clamp(0.0, 1.0) * 2 * math.pi;
    final zonePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.green, Colors.green.withValues(alpha: 0.6)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, rangeStart, rangeSweep, false, zonePaint);
  }

  @override
  bool shouldRepaint(covariant _RomGaugePainter oldDelegate) {
    return oldDelegate.normalizedValue != normalizedValue ||
        oldDelegate.normalizedRangeStart != normalizedRangeStart ||
        oldDelegate.normalizedRangeEnd != normalizedRangeEnd;
  }
}
