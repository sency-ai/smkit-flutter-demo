import 'package:flutter/material.dart';

/// Limb connections using SMBase.Joint enum case names (as sent from native).
const List<(String, String)> kSkeletonConnections = [
  ('Head', 'Neck'),
  ('Neck', 'LShoulder'),
  ('Neck', 'RShoulder'),
  ('LShoulder', 'LElbow'),
  ('LElbow', 'LWrist'),
  ('RShoulder', 'RElbow'),
  ('RElbow', 'RWrist'),
  ('LShoulder', 'LHip'),
  ('RShoulder', 'RHip'),
  ('LHip', 'RHip'),
  ('LHip', 'LKnee'),
  ('LKnee', 'LAnkle'),
  ('RHip', 'RKnee'),
  ('RKnee', 'RAnkle'),
  ('Nose', 'REye'),
  ('Nose', 'LEye'),
  ('REye', 'REar'),
  ('LEye', 'LEar'),
];

/// Known joint key variants (SMBase.Joint, Android SMKitJoint, etc.).
String? _resolveKey(Map<String, dynamic> data, String name) {
  if (data.containsKey(name)) return name;
  final lower = name.toLowerCase();
  if (data.containsKey(lower)) return lower;
  if (name == 'RShoulder' && data.containsKey('right_shoulder')) return 'right_shoulder';
  if (name == 'LShoulder' && data.containsKey('left_shoulder')) return 'left_shoulder';
  if (name == 'RElbow' && data.containsKey('right_elbow')) return 'right_elbow';
  if (name == 'LElbow' && data.containsKey('left_elbow')) return 'left_elbow';
  if (name == 'RWrist' && data.containsKey('right_wrist')) return 'right_wrist';
  if (name == 'LWrist' && data.containsKey('left_wrist')) return 'left_wrist';
  if (name == 'RHip' && data.containsKey('right_hip')) return 'right_hip';
  if (name == 'LHip' && data.containsKey('left_hip')) return 'left_hip';
  if (name == 'RKnee' && data.containsKey('right_knee')) return 'right_knee';
  if (name == 'LKnee' && data.containsKey('left_knee')) return 'left_knee';
  if (name == 'RAnkle' && data.containsKey('right_ankle')) return 'right_ankle';
  if (name == 'LAnkle' && data.containsKey('left_ankle')) return 'left_ankle';
  if (name == 'REye' && data.containsKey('right_eye')) return 'right_eye';
  if (name == 'LEye' && data.containsKey('left_eye')) return 'left_eye';
  if (name == 'REar' && data.containsKey('right_ear')) return 'right_ear';
  if (name == 'LEar' && data.containsKey('left_ear')) return 'left_ear';
  return null;
}

/// Draws 2D pose joints and limb connections over the camera preview.
/// Design matches the iOS demo default: black dots with white stroke, white connection lines.
/// [positionData] maps joint name → { 'x': double, 'y': double } normalized 0–1.
class SkeletonPainter extends CustomPainter {
  const SkeletonPainter({
    required this.positionData,
    required this.size,
    this.frameAspect,
    this.showDebugLabel = false,
  });

  final Map<String, dynamic> positionData;
  final Size size;
  /// When non-null (Android), apply aspect-fill transform matching PreviewView.
  /// When null (iOS), coordinates are already in compatible aspect space.
  final double? frameAspect;
  final bool showDebugLabel;

  /// Convert normalized [0-1] coords to screen position, accounting for aspect-fill.
  Offset _toScreen(double nx, double ny) {
    if (frameAspect != null) {
      final vA = frameAspect!;
      final sA = size.width / size.height;
      final double scaledW, scaledH, offsetX, offsetY;
      if (sA < vA) {
        scaledH = size.height;
        scaledW = size.height * vA;
        offsetX = (size.width - scaledW) / 2;
        offsetY = 0;
      } else {
        scaledW = size.width;
        scaledH = size.width / vA;
        offsetX = 0;
        offsetY = (size.height - scaledH) / 2;
      }
      return Offset(nx * scaledW + offsetX, ny * scaledH + offsetY);
    }
    return Offset(nx * size.width, ny * size.height);
  }

  Offset? _offsetFromRaw(dynamic raw) {
    if (raw is Map) {
      final x = (raw['x'] as num?)?.toDouble();
      final y = (raw['y'] as num?)?.toDouble();
      if (x != null && y != null) return _toScreen(x, y);
    } else if (raw is List && raw.length >= 2) {
      final x = (raw[0] as num?)?.toDouble();
      final y = (raw[1] as num?)?.toDouble();
      if (x != null && y != null) return _toScreen(x, y);
    }
    return null;
  }

  Offset? _joint(String name) {
    final key = _resolveKey(positionData, name);
    if (key == null) return null;
    final raw = positionData[key];
    double? x;
    double? y;
    if (raw is Map) {
      x = (raw['x'] as num?)?.toDouble();
      y = (raw['y'] as num?)?.toDouble();
    } else if (raw is List && raw.length >= 2) {
      x = (raw[0] as num?)?.toDouble();
      y = (raw[1] as num?)?.toDouble();
    }
    if (x == null || y == null) return null;
    return _toScreen(x, y);
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // White connection lines — 7px width, matching iOS demo KitDataHolder.defaultLimbStyle
    final limbPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Black fill for joints, white stroke — matches iOS demo JointStyle defaults
    final jointFill = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final jointStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw limb connections
    for (final (a, b) in kSkeletonConnections) {
      final pa = _joint(a);
      final pb = _joint(b);
      if (pa != null && pb != null) {
        canvas.drawLine(pa, pb, limbPaint);
      }
    }

    // Collect joint positions — from named connections and any extra keys
    final drawn = <Offset>{};
    for (final (a, b) in kSkeletonConnections) {
      final pa = _joint(a);
      final pb = _joint(b);
      if (pa != null) drawn.add(pa);
      if (pb != null) drawn.add(pb);
    }
    for (final entry in positionData.entries) {
      final o = _offsetFromRaw(entry.value);
      if (o != null) drawn.add(o);
    }

    // Draw joints: radius 8, black fill + white stroke — matches iOS demo pointRad=8
    for (final offset in drawn) {
      canvas.drawCircle(offset, 8, jointFill);
      canvas.drawCircle(offset, 8, jointStroke);
    }

    if (showDebugLabel) {
      final count = positionData.entries.where((e) => _offsetFromRaw(e.value) != null).length;
      final textPainter = TextPainter(
        text: TextSpan(
          text: count > 0 ? 'Pose: $count joints' : 'Waiting for pose...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, const Offset(12, 12));
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) =>
      oldDelegate.positionData != positionData ||
      oldDelegate.size != size ||
      oldDelegate.frameAspect != frameAspect ||
      oldDelegate.showDebugLabel != showDebugLabel;
}
