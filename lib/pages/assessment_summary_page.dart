import 'package:flutter/material.dart';

import '../models/assessment_exercise_result.dart';

/// Mirrors AssessmentSummaryView from the iOS demo.
/// Shows overall score and a per-exercise breakdown card for each exercise.
class AssessmentSummaryPage extends StatelessWidget {
  const AssessmentSummaryPage({super.key, required this.results});

  final List<AssessmentExerciseResult> results;

  int get _overallScore {
    if (results.isEmpty) return 0;
    final avg = results.map((r) => r.techniqueScore).reduce((a, b) => a + b) /
        results.length;
    return avg.round();
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overallScore;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: Colors.grey,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 8,
              right: 16,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.replay,
                      color: Colors.white),
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                const Expanded(
                  child: Text(
                    'Assessment Results',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance the back button
              ],
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Overall score card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Overall Score',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$overall',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(overall.toDouble()),
                          ),
                        ),
                        const Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Per-exercise cards
                  ...results.map((r) => _ExerciseResultCard(
                        result: r,
                        scoreColor: _scoreColor(r.techniqueScore),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseResultCard extends StatelessWidget {
  const _ExerciseResultCard({
    required this.result,
    required this.scoreColor,
  });

  final AssessmentExerciseResult result;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    final tip = result.timeInPosition;
    final tipStr = tip < 60
        ? '${tip.toStringAsFixed(1)}s'
        : '${(tip / 60).toStringAsFixed(1)}min';
    final romStr = result.peakRom != null
        ? '${(result.peakRom! * 100).round()}%'
        : null;

    final isDynamic = result.reps != null;

    // No issues = had time in position, no form corrections, and score reflects good form (avoid showing "No issues" when score says form needs improvement)
    final isPerfect = result.feedbacks.isEmpty &&
        result.timeInPosition > 0 &&
        result.techniqueScore >= 80;
    final neverInPosition = result.timeInPosition == 0 && (!isDynamic || (result.reps ?? 0) == 0);

    final scoreExplanation = result.techniqueScore >= 80
        ? "Form score when in position (and in target ROM when applicable)."
        : result.techniqueScore >= 60
            ? "Form had some issues while in position."
            : "Form needs improvement when in position.";

    final romExplanation = result.peakRom == null
        ? null
        : result.peakRom! >= 1.0
            ? "You reached the full target range."
            : "You reached ${(result.peakRom! * 100).round()}% of the target range (100% = full range).";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + score
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPerfect)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "No issues",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${result.techniqueScore.round()}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        const Text(
                          ' / 100',
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Text(
                      'Technique',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            if (isPerfect)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  "No form corrections were given while you were in position.",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 12),

            // Score bar (mirrors iOS ExerciseResultCard)
            Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (result.techniqueScore / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              scoreExplanation,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Metrics Row
            Row(
              children: [
                if (!isDynamic)
                  _MetricTile(
                    label: 'Time in Pos',
                    value: tipStr,
                    icon: Icons.timer_outlined,
                  ),
                if (isDynamic) ...[
                  _MetricTile(
                    label: 'Reps',
                    value: '${result.reps ?? 0}',
                    icon: Icons.repeat,
                  ),
                  const SizedBox(width: 12),
                  _MetricTile(
                    label: 'Perfect',
                    value: '${result.perfectReps ?? 0}',
                    icon: Icons.star_border,
                  ),
                ],
                if (romStr != null) ...[
                  const SizedBox(width: 12),
                  _MetricTile(
                    label: 'Peak ROM',
                    value: romStr,
                    icon: Icons.straighten_outlined,
                  ),
                ],
              ],
            ),
            if (romExplanation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  romExplanation,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            const Divider(height: 24),

            // Status / feedbacks (match iOS ExerciseResultCard: "Issues detected:" + list)
            if (neverInPosition) ...[
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isDynamic ? 'No Reps Completed' : 'Position Not Reached',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isDynamic
                    ? 'Ensure you are performing the full movement within the frame.'
                    : 'Try to stay within the frame and follow the instructions.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ] else if (result.feedbacks.isNotEmpty) ...[
              Text(
                'Issues detected:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              ...result.feedbacks.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outlined, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (isDynamic && (result.reps ?? 0) > (result.perfectReps ?? 0)) ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Form Improvements Needed',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(result.reps ?? 0) - (result.perfectReps ?? 0)} out of ${result.reps ?? 0} reps had form issues.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
