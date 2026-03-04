import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smkit/smkit.dart';

/// Mirrors SummaryScreen from the iOS demo.
/// Shows the raw JSON session result with a back (counterclockwise arrow) button
/// and a copy-to-clipboard button.
class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key, this.result, this.title = 'Workout Summary'});

  final DetectionSessionResultData? result;
  final String title;

  String get _summaryJson {
    if (result == null) return 'No result data.';
    final map = {
      'sessionId': result!.sessionId,
      'startDate': result!.startDate,
      'endDate': result!.endDate,
      'totalTime': result!.totalTime,
      'totalScore': result!.totalScore,
      'exercises': result!.exercises.map((e) => {
        'exerciseName': e.exerciseName,
        'type': e.type,
        'sessionId': e.sessionId,
        'startTime': e.startTime,
        'endTime': e.endTime,
        'totalTime': e.totalTime,
        'techniqueScore': e.techniqueScore,
        'feedbacks': e.feedbacks,
        if (e.numberOfPerformedReps != null)
          'numberOfPerformedReps': e.numberOfPerformedReps,
        if (e.perfectReps != null) 'perfectReps': e.perfectReps,
        if (e.timeInPosition != null) 'timeInPosition': e.timeInPosition,
        if (e.peakRangeOfMotionScore != null)
          'peakRangeOfMotionScore': e.peakRangeOfMotionScore,
        if (e.performedReps != null)
          'performedReps': e.performedReps!.map((r) => {
            'isGood': r.isGood,
            'isShallowRep': r.isShallowRep,
            'romScore': r.romScore,
            'techniqueScore': r.techniqueScore,
          }).toList(),
      }).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(map);
  }

  @override
  Widget build(BuildContext context) {
    final json = _summaryJson;
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
              right: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.replay, color: Colors.white),
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),

          // JSON body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                json,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
