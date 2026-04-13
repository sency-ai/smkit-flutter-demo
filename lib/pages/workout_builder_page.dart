import 'package:flutter/material.dart';

import 'session_page.dart';

// ── Exercise catalogue (sourced from smkit-ui-flutter-demo WorkoutBuilderScreen) ─

enum _Category { dynamic_, static_, mobility }

class _Exercise {
  const _Exercise(this.name, this.category);
  final String name;
  final _Category category;
}

const List<_Exercise> _allExercises = [
  // ── Dynamic ──────────────────────────────────────────────────────────────────
  _Exercise('AirJumpRope', _Category.dynamic_),
  _Exercise('AlternateWindmillToeTouch', _Category.dynamic_),
  _Exercise('BackSuperman', _Category.dynamic_),
  _Exercise('BackSupermanHold', _Category.dynamic_),
  _Exercise('BirdDog', _Category.dynamic_),
  _Exercise('Burpees', _Category.dynamic_),
  _Exercise('ButtKicks', _Category.dynamic_),
  _Exercise('CalfRaises', _Category.dynamic_),
  _Exercise('ClamshellsLeft', _Category.dynamic_),
  _Exercise('ClamshellsRight', _Category.dynamic_),
  _Exercise('Crunches', _Category.dynamic_),
  _Exercise('FastMarchRun', _Category.dynamic_),
  _Exercise('Froggers', _Category.dynamic_),
  _Exercise('GlutesBridge', _Category.dynamic_),
  _Exercise('HandGrip', _Category.dynamic_),
  _Exercise('HighKnees', _Category.dynamic_),
  _Exercise('JumpingJacks', _Category.dynamic_),
  _Exercise('Jumps', _Category.dynamic_),
  _Exercise('LateralHandRaise', _Category.dynamic_),
  _Exercise('LateralHandRaiseLeft', _Category.dynamic_),
  _Exercise('LateralHandRaiseRight', _Category.dynamic_),
  _Exercise('LateralRaises', _Category.dynamic_),
  _Exercise('LungeFront', _Category.dynamic_),
  _Exercise('LungeFrontAlternate', _Category.dynamic_),
  _Exercise('LungeFrontLeft', _Category.dynamic_),
  _Exercise('LungeFrontRight', _Category.dynamic_),
  _Exercise('LungeJumps', _Category.dynamic_),
  _Exercise('LungeRegularStatic', _Category.dynamic_),
  _Exercise('LungeSide', _Category.dynamic_),
  _Exercise('LungeSideLeft', _Category.dynamic_),
  _Exercise('LungeSideRight', _Category.dynamic_),
  _Exercise('PlankCommando', _Category.dynamic_),
  _Exercise('PlankHighShoulderTaps', _Category.dynamic_),
  _Exercise('PlankHighToeTaps', _Category.dynamic_),
  _Exercise('PlankJacksHigh', _Category.dynamic_),
  _Exercise('PlankLowHipTwist', _Category.dynamic_),
  _Exercise('PlankWalkouts', _Category.dynamic_),
  _Exercise('PogoJumps', _Category.dynamic_),
  _Exercise('PowerWalkInPlace', _Category.dynamic_),
  _Exercise('PushupKnees', _Category.dynamic_),
  _Exercise('PushupRegular', _Category.dynamic_),
  _Exercise('PushupWide', _Category.dynamic_),
  _Exercise('QuadThoraticRotation', _Category.dynamic_),
  _Exercise('QuadThoraticRotationLeft', _Category.dynamic_),
  _Exercise('QuadThoraticRotationRight', _Category.dynamic_),
  _Exercise('QuickFeet', _Category.dynamic_),
  _Exercise('ReverseSitToTableTop', _Category.dynamic_),
  _Exercise('SeatedShadowBoxing', _Category.dynamic_),
  _Exercise('ShoulderCircles', _Category.dynamic_),
  _Exercise('ShouldersPress', _Category.dynamic_),
  _Exercise('SideLunge', _Category.dynamic_),
  _Exercise('SideStepJacks', _Category.dynamic_),
  _Exercise('SingleHandOverheadHealDigs', _Category.dynamic_),
  _Exercise('SitToStand', _Category.dynamic_),
  _Exercise('SitupPenguin', _Category.dynamic_),
  _Exercise('SitupRussianTwist', _Category.dynamic_),
  _Exercise('SkaterHops', _Category.dynamic_),
  _Exercise('SkiJumps', _Category.dynamic_),
  _Exercise('Skydivers', _Category.dynamic_),
  _Exercise('SkydiversHold', _Category.dynamic_),
  _Exercise('SquatAndKick', _Category.dynamic_),
  _Exercise('SquatAndRotationJab', _Category.dynamic_),
  _Exercise('SquatAndStep', _Category.dynamic_),
  _Exercise('SquatNarrow', _Category.dynamic_),
  _Exercise('SquatPulsing', _Category.dynamic_),
  _Exercise('SquatRegular', _Category.dynamic_),
  _Exercise('SquatRegularOverhead', _Category.dynamic_),
  _Exercise('SquatSumo', _Category.dynamic_),
  _Exercise('StandingAlternateToeTouch', _Category.dynamic_),
  _Exercise('StandingBicycleCrunches', _Category.dynamic_),
  _Exercise('StandingObliqueCrunches', _Category.dynamic_),
  _Exercise('ToesRaises', _Category.dynamic_),

  // ── Static ───────────────────────────────────────────────────────────────────
  _Exercise('GlutesBridgeHold', _Category.static_),
  _Exercise('HollowHold', _Category.static_),
  _Exercise('PlankHighStatic', _Category.static_),
  _Exercise('PlankLowStatic', _Category.static_),
  _Exercise('PlankSideHighStatic', _Category.static_),
  _Exercise('PlankSideHighStaticLeft', _Category.static_),
  _Exercise('PlankSideHighStaticRight', _Category.static_),
  _Exercise('PlankSideLowStatic', _Category.static_),
  _Exercise('PlankSideLowStaticLeft', _Category.static_),
  _Exercise('PlankSideLowStaticRight', _Category.static_),
  _Exercise('ReverseTableTopHold', _Category.static_),
  _Exercise('SitupRussianTwistStatic', _Category.static_),
  _Exercise('SquatRegularOverheadStatic', _Category.static_),
  _Exercise('SquatRegularStatic', _Category.static_),
  _Exercise('SquatSumoStatic', _Category.static_),
  _Exercise('StandingForwardFold', _Category.static_),
  _Exercise('TuckHold', _Category.static_),

  // ── Mobility ─────────────────────────────────────────────────────────────────
  _Exercise('AnkleMobilityLeft', _Category.mobility),
  _Exercise('AnkleMobilityRight', _Category.mobility),
  _Exercise('CalfStretchLungePositionLeft', _Category.mobility),
  _Exercise('CalfStretchLungePositionRight', _Category.mobility),
  _Exercise('DownwardDogStretch', _Category.mobility),
  _Exercise('GlutesStretchOnTheFloorLeft', _Category.mobility),
  _Exercise('GlutesStretchOnTheFloorRight', _Category.mobility),
  _Exercise('GroinAndAdductor', _Category.mobility),
  _Exercise('HamstringMobility', _Category.mobility),
  _Exercise('HappyBaby', _Category.mobility),
  _Exercise('HipExternalRotationFigureFourStretchLeft', _Category.mobility),
  _Exercise('HipExternalRotationFigureFourStretchRight', _Category.mobility),
  _Exercise('HipExternalRotationLeft', _Category.mobility),
  _Exercise('HipExternalRotationRight', _Category.mobility),
  _Exercise('HipFlexionLeft', _Category.mobility),
  _Exercise('HipFlexionRight', _Category.mobility),
  _Exercise('HipFlexorLungeStretchLeft', _Category.mobility),
  _Exercise('HipFlexorLungeStretchRight', _Category.mobility),
  _Exercise('HipFlexorStretchLeft', _Category.mobility),
  _Exercise('HipFlexorStretchRight', _Category.mobility),
  _Exercise('HipInternalRotationLeft', _Category.mobility),
  _Exercise('HipInternalRotationRight', _Category.mobility),
  _Exercise('InnerThighMobility', _Category.mobility),
  _Exercise('InternalRotationSideStretchLeft', _Category.mobility),
  _Exercise('InternalRotationSideStretchRight', _Category.mobility),
  _Exercise('JeffersonCurl', _Category.mobility),
  _Exercise('KneelingQuadStretchLeft', _Category.mobility),
  _Exercise('KneelingQuadStretchRight', _Category.mobility),
  _Exercise('LatStretchLeft', _Category.mobility),
  _Exercise('LatStretchRight', _Category.mobility),
  _Exercise('LumbarRotationsSeatedLeft', _Category.mobility),
  _Exercise('LumbarRotationsSeatedRight', _Category.mobility),
  _Exercise('LungeSideStaticLeft', _Category.mobility),
  _Exercise('LungeSideStaticRight', _Category.mobility),
  _Exercise('OverheadMobility', _Category.mobility),
  _Exercise('PrayerStretch', _Category.mobility),
  _Exercise('RhomboidStretch', _Category.mobility),
  _Exercise('SeatedBowArrowThoracicMobilityLeft', _Category.mobility),
  _Exercise('SeatedBowArrowThoracicMobilityRight', _Category.mobility),
  _Exercise('SeatedHipRotationsLeft', _Category.mobility),
  _Exercise('SeatedHipRotationsRight', _Category.mobility),
  _Exercise('SeatedThoracicSideBendingLeft', _Category.mobility),
  _Exercise('SeatedThoracicSideBendingRight', _Category.mobility),
  _Exercise('SideLungeHoldLeft', _Category.mobility),
  _Exercise('SideLungeHoldRight', _Category.mobility),
  _Exercise('SingleLegHamstringStretchLeft', _Category.mobility),
  _Exercise('SingleLegHamstringStretchRight', _Category.mobility),
  _Exercise('SingleLegStanceLeft', _Category.mobility),
  _Exercise('SingleLegStanceRight', _Category.mobility),
  _Exercise('StandingHamstringMobility', _Category.mobility),
  _Exercise('StandingKneeRaiseLeft', _Category.mobility),
  _Exercise('StandingKneeRaiseRight', _Category.mobility),
  _Exercise('StandingSideBendLeft', _Category.mobility),
  _Exercise('StandingSideBendRight', _Category.mobility),
  _Exercise('WideInnerThighStretch', _Category.mobility),
];

// ── WorkoutBuilderPage ────────────────────────────────────────────────────────

class WorkoutBuilderPage extends StatefulWidget {
  const WorkoutBuilderPage({super.key});

  @override
  State<WorkoutBuilderPage> createState() => _WorkoutBuilderPageState();
}

class _WorkoutBuilderPageState extends State<WorkoutBuilderPage> {
  _Category? _filterCategory; // null = All
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Ordered list so the workout runs in the user's chosen order
  final List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Exercise> get _filtered {
    return _allExercises.where((e) {
      final matchesCat = _filterCategory == null || e.category == _filterCategory;
      final matchesQuery = _query.isEmpty || e.name.toLowerCase().contains(_query);
      return matchesCat && matchesQuery;
    }).toList();
  }

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  void _start() {
    if (_selected.isEmpty) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SessionPage(
          exercises: List<String>.from(_selected),
          showSkeleton: false,
          isAssessment: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Workout'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_selected.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_selected.length} selected',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterCategory == null,
                  onTap: () => setState(() => _filterCategory = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Dynamic',
                  selected: _filterCategory == _Category.dynamic_,
                  onTap: () => setState(() => _filterCategory = _Category.dynamic_),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Static',
                  selected: _filterCategory == _Category.static_,
                  onTap: () => setState(() => _filterCategory = _Category.static_),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Mobility',
                  selected: _filterCategory == _Category.mobility,
                  onTap: () => setState(() => _filterCategory = _Category.mobility),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No exercises found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      final isSelected = _selected.contains(ex.name);
                      final selectionIndex = isSelected ? _selected.indexOf(ex.name) + 1 : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _toggle(ex.name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Category dot
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white54
                                        : _categoryColor(ex.category),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ex.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white24,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$selectionIndex',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Start button
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
                child: Text(
                  _selected.isEmpty
                      ? 'START'
                      : 'START  (${_selected.length} exercise${_selected.length == 1 ? '' : 's'})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(_Category cat) {
    switch (cat) {
      case _Category.dynamic_:
        return Colors.blue;
      case _Category.static_:
        return Colors.orange;
      case _Category.mobility:
        return Colors.green;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
