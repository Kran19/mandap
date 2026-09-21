import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../../../core/geometry/length.dart';
import '../domain/entities/edge_id.dart';
import '../domain/entities/mandap_edge.dart';
import '../domain/entities/mandap_layout.dart';
import '../domain/entities/mandap_node.dart';
import '../domain/entities/node_id.dart';
import '../domain/entities/mandap_preset.dart';
import '../domain/entities/truss_catalog.dart';
import '../domain/entities/truss_inventory.dart';
import '../domain/entities/truss_piece_type.dart';
import '../domain/services/mandap_calculation_engine.dart';
import '../domain/value_objects/mandap_calculation_result.dart';
import '../domain/value_objects/pole_placement.dart';
import '../domain/value_objects/truss_bom_summary.dart';
import '../domain/specifications/component_specifications.dart';
import 'commands/mandap_command.dart';
import 'commands/add_edge_command.dart';
import 'commands/add_external_structure_command.dart';
import 'commands/add_node_command.dart';
import 'commands/command_history.dart';
import 'commands/delete_edge_command.dart';
import 'commands/delete_node_command.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'commands/adjust_center_control_command.dart';
import 'commands/adjust_center_front_back_command.dart';
import 'commands/adjust_center_position_command.dart';
import 'commands/create_truss_member_command.dart';
import 'commands/resize_truss_member_command.dart';
import 'commands/move_node_command.dart';
import 'commands/resize_truss_bay_command.dart';
import 'commands/create_center_cross_command.dart';
import '../domain/entities/truss_bay.dart';
import '../domain/services/truss_bay_detector.dart';
import '../domain/services/truss_support_spacing_calculator.dart';
import 'commands/resize_edge_command.dart';
import 'commands/set_node_support_command.dart';
import 'commands/update_node_dimensions_command.dart';
import 'editor_mode.dart';
import '../domain/generators/base_truss_architecture_generator.dart';
import '../domain/services/structural_graph_analyzer.dart';
import '../domain/value_objects/grid_settings.dart';
import '../domain/value_objects/structural_analysis_report.dart';
import '../domain/services/truss_display_numbering_service.dart';
import '../presentation/widgets/3d/geometry/truss_geometry_cache.dart';

/// Discrete state machine for Pen/Pencil truss member drawing.
enum PenState {
  idle,
  waitingForStart,
  waitingForEnd,
}

/// Central application controller for managing Mandap layout state, editor mode,
/// calculations, presets, and undo/redo history.
class MandapEditorController extends ChangeNotifier {
  final MandapCalculationEngine engine;
  late TrussCatalog catalog;
  late TrussInventory inventory;
  late MandapLayout layout;
  late MandapCalculationResult result;
  final CommandHistory history = CommandHistory();
  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;

  MandapPreset currentPreset = MandapPreset.rectangle40x30();
  EdgeId? selectedEdgeId;
  NodeId? selectedNodeId;
  String? _selectedBayId;
  String? get selectedBayId => _selectedBayId;

  List<TrussBay> _bays = const [];
  List<TrussBay> get bays => _bays;

  TrussBay? get selectedBay {
    if (_selectedBayId == null) return null;
    try {
      return _bays.firstWhere((b) => b.id == _selectedBayId);
    } catch (_) {
      return null;
    }
  }

  bool isShortageTestMode = false;
  bool isCustomLayout = false;

  EditorMode _mode = EditorMode.view;
  EditorMode get mode => _mode;

  /// In addEdge mode: the first tapped node awaiting a second tap.
  NodeId? pendingEdgeStartNodeId;

  // Pen State Machine
  PenState _penState = PenState.idle;
  PenState get penState => _penState;

  v64.Vector3? penStartPoint;
  v64.Vector3? penPreviewEndPoint;
  String? penDominantAxis;
  double? penPreviewLength;
  NodeId? penStartNodeId;
  NodeId? penEndNodeId;

  double _standardTrussPieceSize = 30.0;
  double get standardTrussPieceSize => _standardTrussPieceSize;

  /// Active structural analysis report reflecting live support and connectivity.
  StructuralAnalysisReport get structuralReport =>
      result.structuralReport ??
      StructuralGraphAnalyzer.analyze(
        layout,
        preferredSpacingFeet: _standardTrussPieceSize,
      );

  /// Total linear feet of truss derived directly from actual Euclidean geometry.
  double get totalLinearTrussFt {
    double sum = 0.0;
    for (final edge in layout.edges.values) {
      sum += layout.getExactGeometricLengthFeet(edge);
    }
    return sum;
  }

  /// Authoritative separate Pillar vs Upper BOM summary.
  TrussBomSummary get trussBomSummary => result.trussBomSummary;

  /// Total quantity of pillar/vertical truss members.
  int get pillarQuantity => trussBomSummary.pillarQuantity;

  /// Total linear feet of pillar/vertical truss members.
  double get pillarTotalFeet => trussBomSummary.pillarTotalFeet;

  /// Total quantity of upper/roof/custom truss members.
  int get upperQuantity => trussBomSummary.upperQuantity;

  /// Total linear feet of upper/roof/custom truss members.
  double get upperTotalFeet => trussBomSummary.upperTotalFeet;

  /// Total quantity of all truss members (pillar + upper).
  int get totalTrussQuantity => trussBomSummary.totalQuantity;

  /// Total linear feet of all truss members (pillar + upper).
  double get totalTrussFeet => trussBomSummary.totalFeet;

  /// Total physical poles derived from calculation engine.
  int get totalPoleCount => result?.poles.length ?? 0;

  double plotWidth = 100.0;
  double plotDepth = 100.0;
  double mandapHeight = 20.0;

  MandapNode? get centerControlNode {
    for (final node in layout.nodes.values) {
      if (node.isControlPoint || node.type == NodeType.controlPoint || node.id.value.contains('center')) {
        return node;
      }
    }
    return null;
  }

  double get fixedCenterX => plotWidth / 2.0;
  double get fixedCenterZ => plotDepth / 2.0;

  /// Length in feet of the currently selected edge, or null if no edge is selected.
  double? get selectedEdgeLength {
    if (selectedEdgeId == null) return null;
    final edge = layout.edges[selectedEdgeId];
    if (edge == null) return null;
    return layout.getExactGeometricLengthFeet(edge);
  }

  /// Resizes the currently selected edge to [newLengthFt]. Returns true on success.
  bool resizeSelectedEdgeLength(double newLengthFt) {
    if (selectedEdgeId == null || newLengthFt <= 0) return false;
    final edge = layout.edges[selectedEdgeId];
    if (edge == null) return false;
    final startNode = layout.getNode(edge.startNodeId);
    final endNode = layout.getNode(edge.endNodeId);
    if (startNode == null || endNode == null) return false;
    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final currentLen = math.sqrt(dx * dx + dz * dz);
    if (currentLen < 0.001) return false;
    double newX;
    double newZ;
    if (dz.abs() < 0.001) {
      newX = startNode.x + (dx >= 0 ? newLengthFt : -newLengthFt);
      newZ = startNode.z;
    } else if (dx.abs() < 0.001) {
      newX = startNode.x;
      newZ = startNode.z + (dz >= 0 ? newLengthFt : -newLengthFt);
    } else {
      final ratio = newLengthFt / currentLen;
      newX = startNode.x + dx * ratio;
      newZ = startNode.z + dz * ratio;
    }
    newX = double.parse(newX.toStringAsFixed(4));
    newZ = double.parse(newZ.toStringAsFixed(4));

    final isMovingNodeShared = layout.edges.values.where((e) => e.id != selectedEdgeId && (e.startNodeId == edge.endNodeId || e.endNodeId == edge.endNodeId)).isNotEmpty;
    MandapNode? createdNode;
    if (isMovingNodeShared) {
      createdNode = MandapNode(
        id: NodeId('n_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}'),
        x: newX,
        z: newZ,
        elevation: endNode.elevation,
        height: endNode.height,
        type: endNode.type,
        support: endNode.support,
      );
    }

    executeCommand(ResizeTrussMemberCommand(
      edgeId: selectedEdgeId!,
      anchorNodeId: edge.startNodeId,
      originalMovingNodeId: edge.endNodeId,
      createdNode: createdNode,
      oldPosition: v64.Vector3(endNode.x, endNode.elevation, endNode.z),
      newPosition: v64.Vector3(newX, endNode.elevation, newZ),
      oldLength: currentLen,
      newLength: newLengthFt,
    ));
    return true;
  }

  /// Adds a node to layout (supports object or named arguments).
  void addNode([dynamic nodeOrX, double? z, NodeType? type, double? elevation, NodeSupport? support]) {
    if (nodeOrX is MandapNode) {
      executeCommand(AddNodeCommand(node: nodeOrX));
    } else if (nodeOrX is num && z != null) {
      final id = NodeId('n_${DateTime.now().millisecondsSinceEpoch}');
      executeCommand(AddNodeCommand(node: MandapNode(
        id: id,
        x: nodeOrX.toDouble(),
        z: z,
        type: type ?? NodeType.corner,
        elevation: elevation ?? 0.0,
        height: elevation ?? 0.0,
        support: support ?? (type == NodeType.pole ? NodeSupport.pole : NodeSupport.none),
      )));
    }
  }

  NodeId? addNodeNamed({MandapNode? node, double? x, double? z, NodeType? type, double? elevation, NodeSupport? support}) {
    if (node != null) {
      executeCommand(AddNodeCommand(node: node));
      return node.id;
    } else if (x != null && z != null) {
      final id = NodeId('n_${DateTime.now().millisecondsSinceEpoch}');
      executeCommand(AddNodeCommand(node: MandapNode(
        id: id,
        x: x,
        z: z,
        type: type ?? NodeType.corner,
        elevation: elevation ?? 0.0,
        height: elevation ?? 0.0,
        support: support ?? (type == NodeType.pole ? NodeSupport.pole : NodeSupport.none),
      )));
      return id;
    }
    return null;
  }

  double _findClosestPerpendicularSnap({
    required String axis,
    required double rayCoord,
    required double targetVal,
    required double startVal,
  }) {
    final candidates = <double>{
      0.0,
      axis == 'X' ? plotWidth : plotDepth,
      axis == 'X' ? fixedCenterX : fixedCenterZ,
    };

    for (final edge in layout.edges.values) {
      final n1 = layout.getNode(edge.startNodeId);
      final n2 = layout.getNode(edge.endNodeId);
      if (n1 == null || n2 == null) continue;
      if (axis == 'X') {
        if ((n1.x - n2.x).abs() < 0.1) {
          final minZ = math.min(n1.z, n2.z) - 1.0;
          final maxZ = math.max(n1.z, n2.z) + 1.0;
          if (rayCoord >= minZ && rayCoord <= maxZ) {
            candidates.add(n1.x);
          }
        }
      } else {
        if ((n1.z - n2.z).abs() < 0.1) {
          final minX = math.min(n1.x, n2.x) - 1.0;
          final maxX = math.max(n1.x, n2.x) + 1.0;
          if (rayCoord >= minX && rayCoord <= maxX) {
            candidates.add(n1.z);
          }
        }
      }
    }

    double bestVal = targetVal;
    double minDiff = double.infinity;
    for (final c in candidates) {
      if ((c - startVal).abs() > 0.01) {
        final diff = (c - targetVal).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestVal = c;
        }
      }
    }

    if (minDiff > 25.0) {
      final signedDelta = targetVal - startVal;
      final snapped = (signedDelta / 10.0).round() * 10.0;
      final eff = (snapped.abs() < 0.001) ? ((signedDelta / 0.5).round() * 0.5) : snapped;
      bestVal = startVal + eff;
    }
    return bestVal;
  }

  /// Creates a truss member connecting two nodes or from pen points.
  bool createTrussMember({
    v64.Vector3? targetEndPoint,
    NodeId? targetEndNodeId,
    EdgeId? edgeId,
    NodeId? startNodeId,
    NodeId? endNodeId,
    double? requestedLength,
    TrussMemberRole role = TrussMemberRole.upper,
    EdgeProfile profile = EdgeProfile.box,
  }) {
    if (startNodeId != null && endNodeId != null) {
      final eId = edgeId ?? EdgeId('custom_edge_${DateTime.now().millisecondsSinceEpoch}');
      final edge = MandapEdge(
        id: eId,
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        role: role,
        profile: profile,
      );
      executeCommand(CreateTrussMemberCommand(newEdge: edge));
      return true;
    }

    if (penStartPoint == null) return false;
    final startPt = penStartPoint!;

    if (penStartNodeId != null && targetEndNodeId != null && layout.nodes.containsKey(penStartNodeId) && layout.nodes.containsKey(targetEndNodeId)) {
      final newEdgeId = edgeId ?? EdgeId('e_pen_${DateTime.now().millisecondsSinceEpoch}');
      final startNode = layout.getNode(penStartNodeId!)!;
      final endNode = layout.getNode(targetEndNodeId)!;
      final isPillar = (startNode.x == endNode.x) && (startNode.z == endNode.z) && (startNode.elevation != endNode.elevation);
      final newEdge = MandapEdge(
        id: newEdgeId,
        startNodeId: penStartNodeId!,
        endNodeId: targetEndNodeId,
        role: isPillar ? TrussMemberRole.tower : role,
        profile: profile,
      );
      executeCommand(CreateTrussMemberCommand(newEdge: newEdge));
      cancelPenDrawing();
      return true;
    }

    var endPt = targetEndPoint ?? penPreviewEndPoint ?? startPt;
    NodeId? effectiveTargetEndNodeId = targetEndNodeId;

    if (requestedLength != null && requestedLength > 0) {
      final dx = (endPt.x - startPt.x).abs();
      final dz = (endPt.z - startPt.z).abs();
      final signX = (endPt.x >= startPt.x) ? 1.0 : -1.0;
      final signZ = (endPt.z >= startPt.z) ? 1.0 : -1.0;
      if (dx >= dz) {
        endPt = v64.Vector3(startPt.x + signX * requestedLength, startPt.y, startPt.z);
      } else {
        endPt = v64.Vector3(startPt.x, startPt.y, startPt.z + signZ * requestedLength);
      }
    } else {
      // Strict orthogonal snap: dx vs dz
      final dx = (endPt.x - startPt.x).abs();
      final dz = (endPt.z - startPt.z).abs();
      if (dx >= dz) {
        final closestX = _findClosestPerpendicularSnap(
          axis: 'X',
          rayCoord: startPt.z,
          targetVal: endPt.x,
          startVal: startPt.x,
        );
        endPt = v64.Vector3(closestX, startPt.y, startPt.z);
        if (effectiveTargetEndNodeId != null) {
          final node = layout.getNode(effectiveTargetEndNodeId);
          if (node != null && (node.z - startPt.z).abs() > 0.01) {
            effectiveTargetEndNodeId = null; // Do not connect diagonally to off-axis node
          }
        }
      } else {
        final closestZ = _findClosestPerpendicularSnap(
          axis: 'Z',
          rayCoord: startPt.x,
          targetVal: endPt.z,
          startVal: startPt.z,
        );
        endPt = v64.Vector3(startPt.x, startPt.y, closestZ);
        if (effectiveTargetEndNodeId != null) {
          final node = layout.getNode(effectiveTargetEndNodeId);
          if (node != null && (node.x - startPt.x).abs() > 0.01) {
            effectiveTargetEndNodeId = null; // Do not connect diagonally to off-axis node
          }
        }
      }
    }

    NodeId sNodeId = penStartNodeId ?? NodeId('n_pen_${DateTime.now().millisecondsSinceEpoch}_s');
    MandapNode? newStartNode;
    if (!layout.nodes.containsKey(sNodeId)) {
      newStartNode = MandapNode(
        id: sNodeId,
        x: startPt.x,
        z: startPt.z,
        elevation: startPt.y,
        height: startPt.y,
        type: NodeType.corner,
        support: NodeSupport.pole,
      );
    }

    NodeId eNodeId = effectiveTargetEndNodeId ?? penEndNodeId ?? NodeId('n_pen_${DateTime.now().millisecondsSinceEpoch}_e');
    MandapNode? newEndNode;
    if (!layout.nodes.containsKey(eNodeId)) {
      newEndNode = MandapNode(
        id: eNodeId,
        x: endPt.x,
        z: endPt.z,
        elevation: endPt.y,
        height: endPt.y,
        type: NodeType.corner,
        support: NodeSupport.pole,
      );
    }

    final newEdgeId = edgeId ?? EdgeId('e_pen_${DateTime.now().millisecondsSinceEpoch}');
    final isPillar = (startPt.x == endPt.x) && (startPt.z == endPt.z) && (startPt.y != endPt.y);

    final newEdge = MandapEdge(
      id: newEdgeId,
      startNodeId: sNodeId,
      endNodeId: eNodeId,
      role: isPillar ? TrussMemberRole.tower : TrussMemberRole.upper,
      profile: EdgeProfile.box,
    );

    executeCommand(CreateTrussMemberCommand(
      newEdge: newEdge,
      newStartNode: newStartNode,
      newEndNode: newEndNode,
    ));

    cancelPenDrawing();
    return true;
  }

  /// Reconfigures and regenerates the truss structure with authoritative dimensions.
  void reconfigureTrussDimensions({
    required double plotLength,
    required double plotWidth,
    required double trussSize,
    double poleHeight = 20.0,
    bool includeTowers = true,
  }) {
    this.plotWidth = plotWidth;
    this.plotDepth = plotLength;
    mandapHeight = poleHeight;
    setStandardTrussPieceSize(trussSize);
    final params = BaseTrussGenerationParams(
      plotWidth: plotWidth,
      plotDepth: plotLength,
      preferredPoleSpacing: trussSize,
      poleHeight: poleHeight,
      includeCenterControlPoint: true,
      includeTowerEdges: includeTowers,
    );
    generateBaseArchitecture(params);
  }

  /// Generates the initial parametric base truss architecture.
  void generateBaseArchitecture(BaseTrussGenerationParams params) {
    plotWidth = params.plotWidth;
    plotDepth = params.plotDepth;
    layout = BaseTrussArchitectureGenerator.generate(params);
    selectedEdgeId = null;
    selectedNodeId = null;
    pendingEdgeStartNodeId = null;
    isCustomLayout = false;
    history.clear();
    _recalculate();
    notifyListeners();
  }

  /// Sets physical support of a node (e.g. pole, none).
  void setNodeSupport(NodeId nodeId, NodeSupport support) {
    executeCommand(SetNodeSupportCommand(nodeId: nodeId, newSupport: support));
  }

  /// Removes vertical pole support from a node without deleting the node or connected members.
  void removePoleSupport(NodeId nodeId) {
    setNodeSupport(nodeId, NodeSupport.none);
  }

  /// Attaches an external entrance/structure to a side of the main structure.
  void addExternalStructure({
    required String structureId,
    required EntranceSide side,
    required double width,
    required double projection,
    required double offset,
    double height = 20.0,
  }) {
    executeCommand(AddExternalStructureCommand(
      structureId: structureId,
      side: side,
      width: width,
      projection: projection,
      offset: offset,
      height: height,
    ));
  }

  /// Removes an external entrance/gate structure by its structureId.
  void removeExternalStructure(String structureId) {
    var current = layout;
    final edgesToRemove = current.edges.values.where((e) {
      final s = current.getNode(e.startNodeId);
      final en = current.getNode(e.endNodeId);
      return (s != null && s.structureId == structureId) ||
          (en != null && en.structureId == structureId);
    }).map((e) => e.id).toList();

    for (final eId in edgesToRemove) {
      current = current.withoutEdge(eId);
    }

    final nodesToRemove = current.nodes.values
        .where((n) => n.structureId == structureId)
        .map((n) => n.id)
        .toList();

    for (final nId in nodesToRemove) {
      current = current.withoutNode(nId);
    }

    layout = current;
    _recalculate();
    notifyListeners();
  }

  /// Total pieces of standard truss required (e.g. 90 ft / 30 ft piece = 3 pcs).
  int get totalPiecesRequired {
    if (_standardTrussPieceSize <= 0) return 0;
    final totalFt = totalLinearTrussFt;
    if (totalFt <= 0) return 0;
    return (totalFt / _standardTrussPieceSize).ceil();
  }

  /// Sets the standard stock truss piece size (e.g. 30 ft), rebuilds catalog and recalculates BOM.
  void setStandardTrussPieceSize(double sizeInFeet) {
    if (sizeInFeet <= 0) return;
    _standardTrussPieceSize = sizeInFeet;
    _updateCatalogWithStandardSize();
    _recalculate();
    notifyListeners();
  }

  void _updateCatalogWithStandardSize() {
    final maxPieceSize = _standardTrussPieceSize > 0 ? _standardTrussPieceSize : 30.0;
    final allStandardSizes = [1.0, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 15.0, 20.0, 25.0, 30.0, 40.0, 50.0];
    final sizes = allStandardSizes.where((s) => s <= maxPieceSize).toList();
    if (!sizes.contains(maxPieceSize)) {
      sizes.add(maxPieceSize);
    }
    sizes.sort();
    final types = sizes.map((ft) {
      final idLabel = '${ft.toStringAsFixed(ft.truncateToDouble() == ft ? 0 : 1)}ft';
      return TrussPieceType(
        id: idLabel,
        length: Length.fromFeet(ft),
      );
    }).toList();
    catalog = TrussCatalog(types);
  }

  GridSettings gridSettings = const GridSettings(majorSpacing: 10.0, minorSpacing: 2.0);
  
  double get baseGridSize => gridSettings.majorSpacing;
  double get subGridSize => gridSettings.minorSpacing;

  void updateGridSettings(double baseSize, double subSize) {
    gridSettings = gridSettings.copyWith(
      majorSpacing: baseSize,
      minorSpacing: subSize,
    );
    notifyListeners();
  }

  void setGridSettings(GridSettings settings) {
    gridSettings = settings;
    notifyListeners();
  }

  MandapEditorController({
    this.engine = const MandapCalculationEngine(),
    double? initialWidth,
    double? initialDepth,
    double? initialTrussSize,
    double? initialPoleHeight,
    bool includeTowerEdges = false,
  }) {
    if (initialWidth != null && initialWidth > 0) plotWidth = initialWidth;
    if (initialDepth != null && initialDepth > 0) plotDepth = initialDepth;
    if (initialPoleHeight != null && initialPoleHeight > 0) mandapHeight = initialPoleHeight;
    if (initialTrussSize != null && initialTrussSize > 0) {
      _standardTrussPieceSize = initialTrussSize;
    }
    _updateCatalogWithStandardSize();

    final effectiveW = plotWidth > 0 ? plotWidth : 100.0;
    final effectiveD = plotDepth > 0 ? plotDepth : 100.0;
    final effectiveSpacing = _standardTrussPieceSize > 0 ? _standardTrussPieceSize : 30.0;
    final effectiveHeight = initialPoleHeight ?? 20.0;

    layout = BaseTrussArchitectureGenerator.generate(
      BaseTrussGenerationParams(
        plotWidth: effectiveW,
        plotDepth: effectiveD,
        preferredPoleSpacing: effectiveSpacing,
        poleHeight: effectiveHeight,
        includeCenterControlPoint: true,
        includeTowerEdges: includeTowerEdges,
      ),
    );
    _recalculate();
  }

  /// Reconfigures layout using an exact sequence of truss pieces (e.g. [30, 30, 40] = 100ft)
  void reconfigureWithTrussPieces({
    required List<double> pieceSpans,
    double? plotLength,
    double? plotWidth,
  }) {
    if (pieceSpans.isEmpty) return;
    if (plotWidth != null && plotWidth > 0) this.plotWidth = plotWidth;
    if (plotLength != null && plotLength > 0) plotDepth = plotLength;

    final primarySpan = pieceSpans.first;
    _standardTrussPieceSize = primarySpan;
    _updateCatalogWithStandardSize();

    layout = BaseTrussArchitectureGenerator.generate(
      BaseTrussGenerationParams(
        plotWidth: this.plotWidth,
        plotDepth: plotDepth,
        preferredPoleSpacing: primarySpan,
        poleHeight: mandapHeight,
        includeCenterControlPoint: true,
        customPieceSequence: pieceSpans,
      ),
    );
    _recalculate();
    notifyListeners();
  }


  void _initLayout() {
    final effectiveW = plotWidth > 0 ? plotWidth : 100.0;
    final effectiveD = plotDepth > 0 ? plotDepth : 100.0;
    final effectiveSpacing = _standardTrussPieceSize > 0 ? _standardTrussPieceSize : 30.0;
    final effectiveHeight = mandapHeight > 0 ? mandapHeight : 20.0;

    layout = BaseTrussArchitectureGenerator.generate(
      BaseTrussGenerationParams(
        plotWidth: effectiveW,
        plotDepth: effectiveD,
        preferredPoleSpacing: effectiveSpacing,
        poleHeight: effectiveHeight,
        includeCenterControlPoint: true,
      ),
    );
    _recalculate();
  }

  /// Checks whether supporting poles exist on all 4 orthogonal directions
  /// (Forward / North, Backward / South, Left / West, Right / East) around the center.
  ({bool canActivate, List<String> missingDirections}) checkCenterCrossSupport() {
    final center = centerControlNode;
    final cX = center?.x ?? (plotWidth / 2.0);
    final cZ = center?.z ?? (plotDepth / 2.0);

    bool isPoleNode(MandapNode n) =>
        n.support == NodeSupport.pole ||
        n.type == NodeType.corner ||
        n.type == NodeType.pole;

    bool hasForward = false; // North (z < cZ - 0.5)
    bool hasBackward = false; // South (z > cZ + 0.5)
    bool hasLeft = false; // West (x < cX - 0.5)
    bool hasRight = false; // East (x > cX + 0.5)

    for (final node in layout.nodes.values) {
      if (node.isControlPoint) continue;
      if (!isPoleNode(node)) continue;

      if (node.z < cZ - 0.5) hasForward = true;
      if (node.z > cZ + 0.5) hasBackward = true;
      if (node.x < cX - 0.5) hasLeft = true;
      if (node.x > cX + 0.5) hasRight = true;
    }

    for (final pole in result.poles) {
      if (pole.z < cZ - 0.5) hasForward = true;
      if (pole.z > cZ + 0.5) hasBackward = true;
      if (pole.x < cX - 0.5) hasLeft = true;
      if (pole.x > cX + 0.5) hasRight = true;
    }

    final missing = <String>[];
    if (!hasForward) missing.add('Forward (North)');
    if (!hasBackward) missing.add('Backward (South)');
    if (!hasLeft) missing.add('Left (West)');
    if (!hasRight) missing.add('Right (East)');

    return (canActivate: missing.isEmpty, missingDirections: missing);
  }

  /// Atomically toggles or creates the real structural Center Cross '+' structure.
  void toggleCenterCross() {
    final supportCheck = checkCenterCrossSupport();
    if (!supportCheck.canActivate) return;

    executeCommand(
      CreateCenterCrossCommand(
        plotWidth: plotWidth,
        plotDepth: plotDepth,
        elevation: mandapHeight > 0 ? mandapHeight : 20.0,
      ),
    );
  }

  /// Sets a new layout dynamically from in-editor dialogs or generator.
  void setLayout(MandapLayout newLayout) {
    layout = newLayout;
    history.clear();
    selectedEdgeId = null;
    selectedNodeId = null;
    pendingEdgeStartNodeId = null;
    isCustomLayout = true;
    _recalculate();
    notifyListeners();
  }

  TrussDisplayNumberingResult _displayNumbering = const TrussDisplayNumberingResult();
  TrussDisplayNumberingResult get displayNumbering => _displayNumbering;

  void _recalculate() {
    isCustomLayout = history.canUndo;
    _displayNumbering = const TrussDisplayNumberingService().computeNumbering(layout);
    if (isShortageTestMode) {
      final p20 = catalog.getPieceByLength(catalog.pieceTypes.last.length);
      inventory = p20 != null
          ? TrussInventory({p20: 2})
          : TrussInventory.sample(catalog, defaultQty: 2);
    } else {
      inventory = TrussInventory.sample(catalog, defaultQty: 50);
    }
    result = engine.calculate(
      layout: layout,
      catalog: catalog,
      inventory: inventory,
    );

    // Auto-detect bays
    try {
      _bays = const TrussBayDetector().detectBays(layout);
    } catch (_) {
      _bays = const [];
    }

    notifyListeners();
  }

  void setMode(EditorMode newMode) {
    _mode = newMode;
    if (newMode == EditorMode.addEdge) {
      _penState = PenState.waitingForStart;
    } else {
      _penState = PenState.idle;
      penStartPoint = null;
      penPreviewEndPoint = null;
      penDominantAxis = null;
      penPreviewLength = null;
      pendingEdgeStartNodeId = null;
    }
    if (_mode != EditorMode.select && _mode != EditorMode.view) {
      clearSelection();
    }
    notifyListeners();
  }

  void setPendingNodeType(NodeType type) {
    notifyListeners();
  }

  void loadPreset(MandapPreset preset) {
    currentPreset = preset;
    _initLayout();
    notifyListeners();
  }

  void loadCustomLayout(MandapLayout newLayout) {
    layout = newLayout;
    isCustomLayout = true;
    _recalculate();
  }

  void executeCommand(MandapCommand cmd) {
    layout = history.executeCommand(cmd, layout);
    _recalculate();
  }

  void selectEdge(EdgeId? edgeId) {
    selectedEdgeId = edgeId;
    selectedNodeId = null;
    notifyListeners();
  }

  void selectNode(NodeId? nodeId) {
    selectedNodeId = nodeId;
    selectedEdgeId = null;
    notifyListeners();
  }

  void clearSelection() {
    selectedEdgeId = null;
    selectedNodeId = null;
    deselectBay();
    notifyListeners();
  }

  void selectBay(String id) {
    _selectedBayId = id;
    selectedEdgeId = null;
    selectedNodeId = null;
    notifyListeners();
  }

  void deselectBay() {
    if (_selectedBayId != null) {
      _selectedBayId = null;
      notifyListeners();
    }
  }

  void resizeBay(String bayId, {double? targetWidthFt, double? targetLengthFt}) {
    executeCommand(ResizeTrussBayCommand(
      bayId: bayId,
      targetWidthFt: targetWidthFt,
      targetLengthFt: targetLengthFt,
    ));
  }

  void resetBayToDefault(String bayId) {
    executeCommand(ResizeTrussBayCommand(
      bayId: bayId,
    ));
  }

  void resizeEdge({
    required EdgeId edgeId,
    required NodeId movingNodeId,
    required double newX,
    required double newZ,
  }) {
    final oldNode = layout.nodes[movingNodeId];
    if (oldNode != null) {
      executeCommand(ResizeEdgeCommand(
        edgeId: edgeId,
        movingNodeId: movingNodeId,
        oldX: oldNode.x,
        oldZ: oldNode.z,
        newX: newX,
        newZ: newZ,
      ));
    }
  }

  void moveNode({
    required NodeId nodeId,
    required double newX,
    required double newZ,
    double? oldX,
    double? oldZ,
  }) {
    final oldNode = layout.nodes[nodeId];
    if (oldNode == null) return;
    executeCommand(MoveNodeCommand(
      nodeId: nodeId,
      oldX: oldX ?? oldNode.x,
      oldZ: oldZ ?? oldNode.z,
      newX: newX,
      newZ: newZ,
    ));
  }

  void updateNodeDimensions({
    NodeId? nodeId,
    double? width,
    double? depth,
    double? height,
    double? elevation,
    double? newWidth,
    double? newDepth,
    double? newHeight,
    double? newElevation,
    double? newRotation,
  }) {
    if (nodeId == null) return;
    final node = layout.nodes[nodeId];
    if (node == null) return;
    final w = newWidth ?? width ?? node.width;
    final d = newDepth ?? depth ?? node.depth;
    final h = newHeight ?? height ?? node.height;
    final elev = newElevation ?? elevation ?? node.elevation;
    final rot = newRotation ?? node.rotation;
    executeCommand(UpdateNodeDimensionsCommand(
      nodeId: nodeId,
      oldWidth: node.width,
      oldDepth: node.depth,
      oldHeight: node.height,
      oldElevation: node.elevation,
      oldRotation: node.rotation,
      newWidth: w,
      newDepth: d,
      newHeight: h,
      newElevation: elev,
      newRotation: rot,
    ));
  }

  NodeId getOrCreateNodeAt(double x, double z, {double? elevation, NodeSupport? support}) {
    for (final node in layout.nodes.values) {
      if ((node.x - x).abs() < 0.25 && (node.z - z).abs() < 0.25) {
        return node.id;
      }
    }
    return addNodeNamed(
      x: x,
      z: z,
      type: NodeType.junction,
      elevation: elevation ?? mandapHeight,
      support: support,
    )!;
  }

  /// Connects a strictly straight (orthogonal horizontal or vertical) truss from
  /// [pendingEdgeStartNodeId] to target point (x, z), snapped strictly to standard dimensions or target node.
  NodeId? drawStraightTrussTo(double targetWorldX, double targetWorldZ, {NodeId? targetNodeId}) {
    if (pendingEdgeStartNodeId == null) return null;
    final startNode = layout.getNode(pendingEdgeStartNodeId!);
    if (startNode == null) {
      pendingEdgeStartNodeId = null;
      notifyListeners();
      return null;
    }

    if (targetNodeId != null && targetNodeId != pendingEdgeStartNodeId) {
      handleAddEdgeTap(targetNodeId);
      return targetNodeId;
    }

    // Check if targetWorldX / targetWorldZ is near an existing node
    MandapNode? closestExistingNode;
    double minNodeDist = double.infinity;
    for (final node in layout.nodes.values) {
      if (node.id != startNode.id && !node.isControlPoint) {
        final dist = math.sqrt(math.pow(node.x - targetWorldX, 2) + math.pow(node.z - targetWorldZ, 2));
        if (dist <= 6.0 && dist < minNodeDist) {
          minNodeDist = dist;
          closestExistingNode = node;
        }
      }
    }

    if (closestExistingNode != null) {
      handleAddEdgeTap(closestExistingNode.id);
      return closestExistingNode.id;
    }

    final dx = targetWorldX - startNode.x;
    final dz = targetWorldZ - startNode.z;
    if (dx.abs() < 0.05 && dz.abs() < 0.05) {
      return null;
    }

    final step = standardTrussPieceSize > 0 ? standardTrussPieceSize : 10.0;
    double endX;
    double endZ;

    if (dx.abs() >= dz.abs()) {
      // Strictly horizontal along X-axis
      endZ = startNode.z;
      if ((targetWorldX - plotWidth).abs() <= step) {
        endX = plotWidth;
      } else if ((targetWorldX - 0.0).abs() <= step) {
        endX = 0.0;
      } else {
        final units = math.max(1, (dx.abs() / step).round());
        endX = startNode.x + (dx >= 0 ? 1 : -1) * units * step;
      }
    } else {
      // Strictly vertical along Z-axis
      endX = startNode.x;
      if ((targetWorldZ - plotDepth).abs() <= step) {
        endZ = plotDepth;
      } else if ((targetWorldZ - 0.0).abs() <= step) {
        endZ = 0.0;
      } else {
        final units = math.max(1, (dz.abs() / step).round());
        endZ = startNode.z + (dz >= 0 ? 1 : -1) * units * step;
      }
    }

    if ((endX - startNode.x).abs() < 0.05 && (endZ - startNode.z).abs() < 0.05) {
      return null;
    }

    final endNodeId = getOrCreateNodeAt(endX, endZ, elevation: startNode.elevation);
    handleAddEdgeTap(endNodeId);
    return endNodeId;
  }

  void handleAddEdgeTap(NodeId tappedNodeId) {
    if (pendingEdgeStartNodeId == null) {
      pendingEdgeStartNodeId = tappedNodeId;
      notifyListeners();
    } else {
      if (pendingEdgeStartNodeId != tappedNodeId) {
        final startNode = layout.getNode(pendingEdgeStartNodeId!);
        final endNode = layout.getNode(tappedNodeId);

        if (startNode != null && endNode != null) {
          final isPillar = (startNode.x == endNode.x) && (startNode.z == endNode.z) && (startNode.elevation != endNode.elevation);

          final newEdge = MandapEdge(
            id: EdgeId('custom_edge_${DateTime.now().millisecondsSinceEpoch}'),
            startNodeId: pendingEdgeStartNodeId!,
            endNodeId: tappedNodeId,
            role: isPillar ? TrussMemberRole.tower : TrussMemberRole.upper,
            profile: EdgeProfile.box,
          );
          executeCommand(CreateTrussMemberCommand(newEdge: newEdge));
        }
        _mode = EditorMode.view;
        _penState = PenState.idle;
      }
      pendingEdgeStartNodeId = null;
      notifyListeners();
    }
  }

  (v64.Vector3, String, double, NodeId?) snapStraightTrussRay({
    required v64.Vector3 startPoint,
    required v64.Vector3 targetPoint,
  }) {
    final dx = (targetPoint.x - startPoint.x).abs();
    final dz = (targetPoint.z - startPoint.z).abs();
    if (dx >= dz) {
      final bestX = _findClosestPerpendicularSnap(
        axis: 'X',
        rayCoord: startPoint.z,
        targetVal: targetPoint.x,
        startVal: startPoint.x,
      );
      final len = (bestX - startPoint.x).abs();
      return (
        v64.Vector3(bestX, startPoint.y, startPoint.z),
        'X',
        len,
        null,
      );
    } else {
      final bestZ = _findClosestPerpendicularSnap(
        axis: 'Z',
        rayCoord: startPoint.x,
        targetVal: targetPoint.z,
        startVal: startPoint.z,
      );
      final len = (bestZ - startPoint.z).abs();
      return (
        v64.Vector3(startPoint.x, startPoint.y, bestZ),
        'Z',
        len,
        null,
      );
    }
  }

  void setPenStartPoint(v64.Vector3 point, {NodeId? startNodeId, bool snapToClosestTruss = false}) {
    v64.Vector3 effectivePoint = point;
    if (snapToClosestTruss && layout.edges.isNotEmpty) {
      double minDistance = double.infinity;
      v64.Vector3? bestSnap;
      for (final edge in layout.edges.values) {
        final n1 = layout.getNode(edge.startNodeId);
        final n2 = layout.getNode(edge.endNodeId);
        if (n1 != null && n2 != null) {
          if ((n1.z - n2.z).abs() < 0.01 && (point.z - n1.z).abs() < 5.0) {
            final minX = math.min(n1.x, n2.x);
            final maxX = math.max(n1.x, n2.x);
            if (point.x >= minX - 1.0 && point.x <= maxX + 1.0) {
              final dist = (point.z - n1.z).abs();
              if (dist < minDistance) {
                minDistance = dist;
                bestSnap = v64.Vector3(point.x, n1.elevation, n1.z);
              }
            }
          } else if ((n1.x - n2.x).abs() < 0.01 && (point.x - n1.x).abs() < 5.0) {
            final minZ = math.min(n1.z, n2.z);
            final maxZ = math.max(n1.z, n2.z);
            if (point.z >= minZ - 1.0 && point.z <= maxZ + 1.0) {
              final dist = (point.x - n1.x).abs();
              if (dist < minDistance) {
                minDistance = dist;
                bestSnap = v64.Vector3(n1.x, n1.elevation, point.z);
              }
            }
          }
        }
      }
      if (bestSnap != null) {
        effectivePoint = bestSnap;
      }
    }

    penStartPoint = effectivePoint;
    penPreviewEndPoint = effectivePoint;
    penStartNodeId = startNodeId;
    penDominantAxis = null;
    penPreviewLength = 0.0;
    _penState = PenState.waitingForEnd;
    notifyListeners();
  }

  void updatePenPreview(v64.Vector3 currentPoint, {NodeId? hoverNodeId}) {
    if (_penState != PenState.waitingForEnd || penStartPoint == null) return;
    final start = penStartPoint!;
    final dx = (currentPoint.x - start.x).abs();
    final dz = (currentPoint.z - start.z).abs();

    if (dx >= dz) {
      penDominantAxis = 'X';
      final signedDx = currentPoint.x - start.x;
      final snappedLen = (signedDx / 0.5).round() * 0.5;
      penPreviewEndPoint = v64.Vector3(start.x + snappedLen, start.y, start.z);
      penPreviewLength = snappedLen.abs();
    } else {
      penDominantAxis = 'Z';
      final signedDz = currentPoint.z - start.z;
      final snappedLen = (signedDz / 0.5).round() * 0.5;
      penPreviewEndPoint = v64.Vector3(start.x, start.y, start.z + snappedLen);
      penPreviewLength = snappedLen.abs();
    }
    penEndNodeId = hoverNodeId;
    notifyListeners();
  }

  void cancelPenDrawing() {
    _mode = EditorMode.view;
    _penState = PenState.idle;
    penStartPoint = null;
    penPreviewEndPoint = null;
    penDominantAxis = null;
    penPreviewLength = null;
    penStartNodeId = null;
    penEndNodeId = null;
    pendingEdgeStartNodeId = null;
    notifyListeners();
  }

  (String, double) preparePenSegment({
    required v64.Vector3 tapStart,
    required v64.Vector3 tapEnd,
  }) {
    penStartPoint = tapStart;
    final dx = (tapEnd.x - tapStart.x).abs();
    final dz = (tapEnd.z - tapStart.z).abs();
    if (dx >= dz) {
      penDominantAxis = 'X';
      final len = (tapEnd.x - tapStart.x).abs();
      penPreviewLength = len;
      return ('X', len);
    } else {
      penDominantAxis = 'Z';
      final len = (tapEnd.z - tapStart.z).abs();
      penPreviewLength = len;
      return ('Z', len);
    }
  }

  bool applyCreateTrussMember({required double requestedLength}) {
    if (penStartPoint == null || requestedLength <= 0) return false;
    final start = penStartPoint!;
    final axis = penDominantAxis ?? 'X';
    v64.Vector3 endPoint;
    if (axis == 'X') {
      endPoint = v64.Vector3(start.x + requestedLength, start.y, start.z);
    } else {
      endPoint = v64.Vector3(start.x, start.y, start.z + requestedLength);
    }
    final sNodeId = penStartNodeId ?? getOrCreateNodeAt(start.x, start.z, elevation: start.y);
    final eNodeId = getOrCreateNodeAt(endPoint.x, endPoint.z, elevation: endPoint.y);
    final success = createTrussMember(
      startNodeId: sNodeId,
      endNodeId: eNodeId,
    );
    cancelPenDrawing();
    return success;
  }

  void applyAdjustCenterControl({
    NodeId? centerNodeId,
    required double newX,
    required double newZ,
    required double newElevation,
    double? mainTrussElevation,
  }) {
    final center = centerNodeId != null ? layout.getNode(centerNodeId) : centerControlNode;
    if (center == null) return;

    double clampedElevation = newElevation;
    final baseElev = mainTrussElevation ?? mandapHeight;
    if (clampedElevation < baseElev) clampedElevation = baseElev;
    if (clampedElevation > baseElev + 10.0) clampedElevation = baseElev + 10.0;

    executeCommand(AdjustCenterControlCommand(
      centerNodeId: center.id,
      oldX: center.x,
      oldZ: center.z,
      oldElevation: center.elevation,
      newX: newX,
      newZ: newZ,
      newElevation: clampedElevation,
    ));
  }

  void adjustCenterPosition({required double newX, required double newZ}) {
    final center = centerControlNode;
    if (center == null) return;

    executeCommand(AdjustCenterPositionCommand(
      centerNodeId: center.id,
      oldX: center.x,
      oldZ: center.z,
      newX: newX,
      newZ: newZ,
    ));
  }

  void adjustCenterFrontBack({required double newZ}) {
    final center = centerControlNode;
    if (center == null) return;

    adjustCenterPosition(newX: center.x, newZ: newZ);
  }

  void deleteSelected() {
    if (selectedEdgeId != null) {
      deleteEdge(selectedEdgeId!);
    } else if (selectedNodeId != null) {
      deleteNode(selectedNodeId!);
    }
  }

  void deleteNode(NodeId nodeId) => _deleteNode(nodeId);
  void deleteEdge(EdgeId edgeId) => _deleteEdge(edgeId);

  void deletePole(PolePlacement pole) {
    NodeId? matchingNodeId;
    for (final node in layout.nodes.values) {
      if ((node.x - pole.x).abs() < 0.1 && (node.z - pole.z).abs() < 0.1) {
        matchingNodeId = node.id;
        break;
      }
    }
    if (matchingNodeId != null) {
      final node = layout.getNode(matchingNodeId);
      if (node != null && node.support == NodeSupport.pole) {
        removePoleSupport(matchingNodeId);
        return;
      }
      deleteNode(matchingNodeId);
    }
  }

  void _deleteNode(NodeId nodeId) {
    final node = layout.getNode(nodeId);
    if (node == null) return;
    if (node.isControlPoint || node.type == NodeType.controlPoint) return;

    final connected = layout.edges.values.where((e) => e.startNodeId == nodeId || e.endNodeId == nodeId).toList();

    executeCommand(DeleteNodeCommand(
      nodeId: nodeId,
      nodeSnapshot: node,
      connectedEdgeSnapshots: connected,
    ));

    if (selectedNodeId == nodeId) selectedNodeId = null;
  }

  void _deleteEdge(EdgeId edgeId) {
    final edge = layout.edges[edgeId];
    if (edge == null) return;

    executeCommand(DeleteEdgeCommand(
      edgeId: edgeId,
      snapshot: edge,
    ));

    if (selectedEdgeId == edgeId) selectedEdgeId = null;
  }

  void deleteZone(String zoneId) {
    final updatedZones = layout.zones.where((z) => z.id != zoneId).toList();
    layout = MandapLayout(
      nodes: layout.nodes,
      edges: layout.edges,
      zones: updatedZones,
    );
    _recalculate();
  }

  void clearAll() {
    layout = const MandapLayout(
      nodes: {},
      edges: {},
      zones: [],
    );
    history.clear();
    selectedEdgeId = null;
    selectedNodeId = null;
    pendingEdgeStartNodeId = null;
    isCustomLayout = true;
    _recalculate();
  }

  void toggleShortageMode(bool enableShortage) {
    isShortageTestMode = enableShortage;
    _recalculate();
  }

  void undo() {
    if (history.canUndo) {
      layout = history.undo(layout);
      selectedEdgeId = null;
      selectedNodeId = null;
      _recalculate();
    }
  }

  void redo() {
    if (history.canRedo) {
      layout = history.redo(layout);
      selectedEdgeId = null;
      selectedNodeId = null;
      _recalculate();
    }
  }
}
