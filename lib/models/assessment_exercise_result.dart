/// Per-exercise result collected during an assessment session.
/// Mirrors AssessmentExerciseResult from the iOS demo.
class AssessmentExerciseResult {
  const AssessmentExerciseResult({
    required this.name,
    required this.techniqueScore,
    required this.feedbacks,
    required this.timeInPosition,
    this.reps,
    this.perfectReps,
    this.peakRom,
  });

  final String name;
  final double techniqueScore; // 0–100
  final List<String> feedbacks;
  final double timeInPosition; // seconds
  final int? reps;
  final int? perfectReps;
  final double? peakRom; // 0.0–1.0, null if no ROM data
}
