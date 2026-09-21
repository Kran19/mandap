import 'package:flutter/foundation.dart';
import '../domain/entities/boundary_pole.dart';
import '../domain/entities/boundary_side.dart';
import '../domain/entities/boundary_truss_run.dart';
import '../domain/entities/truss_material_requirement.dart';
import '../domain/entities/truss_size.dart';
import '../domain/services/boundary_pole_generator.dart';
import '../domain/services/center_cross_geometry_service.dart';
import '../domain/services/initial_boundary_pattern_service.dart';
import '../domain/services/truss_material_service.dart';
import '../domain/services/truss_pole_requirement_service.dart';
import 'commands/boundary_commands.dart';

enum EditingTool { pencil, eraser }
enum BoundaryViewMode { mode2D, mode3D }

/// Authoritative single-source controller for Freeform Boundary Truss Editing.
class TrussBoundaryController extends ChangeNotifier {
  double _plotWidth;
  double _plotDepth;
  TrussSize _initialTrussSize;
  double? _customTrussSpan;

  // The 4 boundary sides: 'north', 'east', 'south', 'west'
  Map<String, BoundarySide> _fourSides = {};
  
  // Center cross runs (branches from center (W/2, D/2) to boundary midpoints)
  List<BoundaryTrussRun> _centerRuns = [];

  // Derived structural data
  List<BoundaryPole> _uniquePoles = [];
  Map<String, List<TrussMaterialRequirement>> _materialRequirements = {};

  // Editor states
  BoundaryViewMode _viewMode = BoundaryViewMode.mode2D;
  EditingTool _activeTool = EditingTool.pencil;
  String? _errorMessage;

  // Undo / Redo Stacks
  final List<BoundaryCommand> _undoStack = [];
  final List<BoundaryCommand> _redoStack = [];

  TrussBoundaryController({
    required double plotWidth,
    required double plotDepth,
    required TrussSize trussSize,
    double? customTrussSpan,
  })  : _plotWidth = plotWidth,
        _plotDepth = plotDepth,
        _initialTrussSize = trussSize,
        _customTrussSpan = customTrussSpan {
    _initializePerimeter();
  }

  void _initializePerimeter() {
    _fourSides = InitialBoundaryPatternService.generateFourSides(
      plotWidth: _plotWidth,
      plotDepth: _plotDepth,
      trussSize: _initialTrussSize,
      customSpan: _customTrussSpan,
    );
    _centerRuns = [];
    _recalculateAll();
  }

  /// Updates dimensions and reinitializes layout dynamically
  void updateDimensions({
    required double plotWidth,
    required double plotDepth,
    double? customTrussSpan,
    TrussSize? trussSize,
  }) {
    _plotWidth = plotWidth;
    _plotDepth = plotDepth;
    if (customTrussSpan != null && customTrussSpan > 0) {
      _customTrussSpan = customTrussSpan;
      _initialTrussSize = TrussSize.fromLength(customTrussSpan);
    } else if (trussSize != null) {
      _initialTrussSize = trussSize;
      _customTrussSpan = trussSize.spanInFeet > 0 ? trussSize.spanInFeet : null;
    }
    _undoStack.clear();
    _redoStack.clear();
    _initializePerimeter();
    notifyListeners();
  }

  // --- Getters ---
  Map<String, BoundarySide> get fourSides => Map.unmodifiable(_fourSides);
  List<BoundaryTrussRun> get centerRuns => List.unmodifiable(_centerRuns);
  bool get isCenterCrossActive => _centerRuns.isNotEmpty;
  
  List<BoundaryPole> get uniquePoles => _uniquePoles;
  Map<String, List<TrussMaterialRequirement>> get materialRequirements => _materialRequirements;
  
  BoundaryViewMode get viewMode => _viewMode;
  EditingTool get activeTool => _activeTool;
  String? get errorMessage => _errorMessage;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  
  double get plotWidth => _plotWidth;
  double get plotDepth => _plotDepth;
  TrussSize get initialTrussSize => _initialTrussSize;
  double? get customTrussSpan => _customTrussSpan;

  String get displayTrussLabel {
    if (_customTrussSpan != null && _customTrussSpan! > 0) {
      final spanStr = _customTrussSpan! % 1 == 0
          ? _customTrussSpan!.toInt().toString()
          : _customTrussSpan!.toStringAsFixed(1);
      return '$spanStr ft';
    }
    return _initialTrussSize.label;
  }

  /// Required support poles evaluated strictly by calculating actual section sequences
  /// against the support interval for the selected truss size.
  int get requiredPolesCount {
    final allRuns = <BoundaryTrussRun>[];
    for (final side in _fourSides.values) {
      allRuns.addAll(side.runs);
    }
    allRuns.addAll(_centerRuns);

    return TrussPoleRequirementService.calculateRequiredSupportPoles(
      trussSize: _initialTrussSize,
      runs: allRuns,
    );
  }

  /// Structural Nodes: All unique graph vertices / connection joints in the layout.
  int get structuralNodesCount => _uniquePoles.length;

  /// Actual Poles: Nodes that are designated as physical support poles (including corners).
  int get actualPolesCount => _uniquePoles.where((p) => p.isSupportPole || p.isCorner).length;

  /// Legacy getter for backward compatibility
  int get totalPolesCount => actualPolesCount;

  /// Legacy getter for backward compatibility with canonical tests
  BoundarySide get canonicalSide => _fourSides['north'] ?? BoundarySide(id: 'north', runs: []);
  
  int get totalGeometricRunsCount {
    final perimeterRuns = _fourSides.values.fold(0, (sum, side) => sum + side.runs.length);
    return perimeterRuns + _centerRuns.length;
  }

  double get totalBoundaryLength {
    final perimeterLength = _fourSides.values.fold(0.0, (sum, side) => sum + side.totalLength);
    final centerLength = _centerRuns.fold(0.0, (sum, run) => sum + run.geometricSpan);
    return perimeterLength + centerLength;
  }

  // --- View & Tool Modes ---
  void setViewMode(BoundaryViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void setActiveTool(EditingTool tool) {
    if (_activeTool != tool) {
      _activeTool = tool;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // --- Center Light / Cross Actions ---
  
  /// Triggered when tapping the center light target on canvas.
  /// Creates the actual '+' structural geometry if not already created,
  /// atomically splitting boundary sides at midpoints if no node exists.
  void handleCenterLightTap() {
    if (isCenterCrossActive) return;

    final result = CenterCrossGeometryService.generateCenterCross(
      fourSides: _fourSides,
      plotWidth: _plotWidth,
      plotDepth: _plotDepth,
    );

    _executeCommand(
      CreateCenterCrossCommand(
        beforeFourSides: Map<String, BoundarySide>.from(_fourSides),
        afterFourSides: result.updatedFourSides,
        beforeCenterRuns: List.from(_centerRuns),
        afterCenterRuns: result.centerRuns,
        onApply: (fourSidesMap, centerRunsList) {
          _fourSides = Map<String, BoundarySide>.from(fourSidesMap);
          _centerRuns = List.from(centerRunsList);
          _recalculateAll();
          notifyListeners();
        },
      ),
    );
  }

  /// Triggered when the Eraser taps an individual center cross member.
  void handleEraserCenterRunTap(String targetRunId) {
    if (_activeTool != EditingTool.eraser) return;

    _executeCommand(
      DeleteCenterRunCommand(
        beforeCenterRuns: List.from(_centerRuns),
        targetRunId: targetRunId,
        onApply: (runs) {
          _centerRuns = List.from(runs);
          _recalculateAll();
          notifyListeners();
        },
      ),
    );
  }

  // --- Geometry Actions ---
  
  /// Triggered when the Pencil tool taps a perimeter truss run to split it.
  void handlePencilTap({
    required String sideId,
    required String targetRunId,
    required double splitOffset,
  }) {
    if (_activeTool != EditingTool.pencil) return;

    final side = _fourSides[sideId];
    if (side == null) return;

    final newPoleId = '${sideId}_pole_split_${DateTime.now().microsecondsSinceEpoch}';

    _executeCommand(
      SplitTrussCommand(
        beforeSide: side,
        targetRunId: targetRunId,
        splitOffset: splitOffset,
        newPoleId: newPoleId,
        onApply: (newSide) {
          _applySideChange(sideId, newSide);
        },
      ),
    );
  }

  /// Triggered when the Eraser tool taps a joint to merge adjacent runs.
  void handleEraserTap({
    required String sideId,
    required String runIdA,
    required String runIdB,
  }) {
    if (_activeTool != EditingTool.eraser) return;

    final side = _fourSides[sideId];
    if (side == null) return;

    try {
      _executeCommand(
        MergeTrussCommand(
          beforeSide: side,
          runIdA: runIdA,
          runIdB: runIdB,
          onApply: (newSide) {
            _applySideChange(sideId, newSide);
          },
        ),
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Backward compatible wrapper for tests
  void mergeSections(String sectionIdA, String sectionIdB) {
    for (final side in _fourSides.values) {
      final indexA = side.runs.indexWhere((r) => r.id == sectionIdA);
      final indexB = side.runs.indexWhere((r) => r.id == sectionIdB);
      if (indexA != -1 && indexB != -1) {
        setActiveTool(EditingTool.eraser);
        handleEraserTap(sideId: side.id, runIdA: sectionIdA, runIdB: sectionIdB);
        return;
      }
    }
  }

  /// Backward compatible toggle method for legacy test calls
  void toggleLightPoint(String lightId) {
    handleCenterLightTap();
  }

  void _applySideChange(String sideId, BoundarySide newSide) {
    _fourSides[sideId] = newSide;
    _errorMessage = null;
    _recalculateAll();
    notifyListeners();
  }

  // --- Core Calculations ---
  void _recalculateAll() {
    // 1. Recalculate unique structural nodes including perimeter and internal center poles.
    final basePoles = BoundaryPoleGenerator.generatePoles(
      _fourSides, 
      width: _plotWidth, 
      depth: _plotDepth,
      trussSize: _initialTrussSize,
    );

    final allPoles = List<BoundaryPole>.from(basePoles);

    // If center cross is active, add center node at actual intersection
    if (isCenterCrossActive) {
      double centerX = _plotWidth / 2.0;
      double centerZ = _plotDepth / 2.0;

      for (final run in _centerRuns) {
        if (run.id == 'center_run_west') {
          centerX = run.geometricSpan;
        } else if (run.id == 'center_run_north') {
          centerZ = run.geometricSpan;
        }
      }

      final hasCenterPole = allPoles.any((p) => (p.x - centerX).abs() < 0.1 && (p.z - centerZ).abs() < 0.1);
      if (!hasCenterPole) {
        allPoles.add(
          BoundaryPole(
            id: 'pole_center_${centerX.round()}_${centerZ.round()}',
            x: centerX,
            z: centerZ,
            isCorner: false,
            isSupportPole: true, // Center column
            connectedSideIds: ['center'],
          ),
        );
      }
    }

    _uniquePoles = List.unmodifiable(allPoles);

    // 2. Resolve material requirements from geometry for the BOM.
    _materialRequirements = {};
    for (final entry in _fourSides.entries) {
      final sideId = entry.key;
      final side = entry.value;
      
      final reqs = <TrussMaterialRequirement>[];
      for (final run in side.runs) {
        reqs.addAll(TrussMaterialService.resolveRun(run));
      }
      _materialRequirements[sideId] = reqs;
    }

    // Add material requirements for center cross runs
    if (_centerRuns.isNotEmpty) {
      final centerReqs = <TrussMaterialRequirement>[];
      for (final run in _centerRuns) {
        centerReqs.addAll(TrussMaterialService.resolveRun(run));
      }
      _materialRequirements['center'] = centerReqs;
    }
  }

  // --- Command Infrastructure ---
  void _executeCommand(BoundaryCommand command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      final command = _undoStack.removeLast();
      command.undo();
      _redoStack.add(command);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final command = _redoStack.removeLast();
      command.redo();
      _undoStack.add(command);
    }
  }
}
