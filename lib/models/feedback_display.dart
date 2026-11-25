import 'feedback_text.dart';

/// Readable text for an SMKit feedback ID.
///
/// flutter_smkit reports feedback as IDs (for example `SquatHipCreaseDepth`)
/// on both platforms. This uses the English text SMKit iOS ships for each ID,
/// and otherwise splits the ID into words. Text that is already a sentence
/// (the demo adds a few of its own) is returned unchanged.
String feedbackDisplayText(String feedback) {
  final text = smkitFeedbackText[feedback];
  if (text != null) return text;
  if (feedback.contains(' ')) return feedback;
  final words = feedback
      .replaceAllMapped(
          RegExp(r'(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
          (_) => ' ')
      .trim();
  if (words.isEmpty) return feedback;
  return words[0].toUpperCase() + words.substring(1).toLowerCase();
}
