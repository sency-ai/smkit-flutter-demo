import 'package:flutter/material.dart';

import 'session_page.dart';

/// Available exercises for a 2D session — mirrors DemoExercises enum from the iOS demo.
const List<String> _demoExercises = [
  'AnkleMobilityLeft',
  'AnkleMobilityRight',
  'JeffersonCurl',
  'PlankHighStatic',
  'SquatRegular',
  'SquatRegularOverheadStatic',
  'StandingKneeRaiseLeft',
  'StandingKneeRaiseRight',
  'StandingSideBendLeft',
  'StandingSideBendRight',
];

/// Exercise selection screen — mirrors Pre2DExerciseView from the iOS demo.
/// User taps exercises to toggle selection, then taps START.
class PreSessionPage extends StatefulWidget {
  const PreSessionPage({super.key});

  @override
  State<PreSessionPage> createState() => _PreSessionPageState();
}

class _PreSessionPageState extends State<PreSessionPage> {
  final Set<String> _selected = {};
  bool _showSkeleton = true;

  void _toggle(String exercise) {
    setState(() {
      if (_selected.contains(exercise)) {
        _selected.remove(exercise);
      } else {
        _selected.add(exercise);
      }
    });
  }

  void _start() {
    if (_selected.isEmpty) return;
    // Preserve the list order from _demoExercises
    final ordered = _demoExercises.where(_selected.contains).toList();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SessionPage(
          exercises: ordered,
          showSkeleton: _showSkeleton,
          isAssessment: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Exercises'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._demoExercises.map((exercise) {
                  final isSelected = _selected.contains(exercise);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _toggle(exercise),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                exercise,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _ToggleRow(
                  label: 'Show Skeleton',
                  value: _showSkeleton,
                  onChanged: (v) => setState(() => _showSkeleton = v),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: _selected.isNotEmpty ? _start : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
