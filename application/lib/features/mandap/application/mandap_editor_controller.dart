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
import 'commands/auto_connect_poles_command.dart';
import 'commands/split_edge_with_pole_command.dart';
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

  bool _showMarkings = true;
  bool get showMarkings => _showMarkings;

  void toggleShowMarkings() {
    _showMarkings = !_showMarkings;
    notifyListeners();
  }

  void setShowMarkings(bool value) {
    if (_showMarkings != value) {
      _showMarkings = value;
      notifyListeners();
    }
  }

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
  double mandapHeight = 30.0;

  MandapNode? get centerControlNode {
    for (final node in layout.nodes.values) {
      if (node.isControlPoint || node.type == NodeType.controlPoint || node.id.value.contains('center')) {
        return node;
      }
    }
    return null;
  }

  bool get hasCenterCross {
    final center = centerControlNode;
    if (center == null) return false;
    return layout.edges.values.any((e) =>
        e.startNodeId == center.id ||
        e.endNodeId == center.id ||
        e.id.value.contains('cross'));
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
    final isAlongX = dz.abs() < 0.001;
    final isAlongZ = dx.abs() < 0.001;

    // Check if endNode is an intermediate node before another node along the same line
    if (isAlongX) {
      final signX = dx >= 0 ? 1.0 : -1.0;
      double? nextX;
      for (final candidate in layout.nodes.values) {
        if (candidate.id != startNode.id && candidate.id != endNode.id && (candidate.z - startNode.z).abs() < 0.1) {
          if (signX > 0 && candidate.x > endNode.x) {
            if (nextX == null || candidate.x < nextX) nextX = candidate.x;
          } else if (signX < 0 && candidate.x < endNode.x) {
            if (nextX == null || candidate.x > nextX) nextX = candidate.x;
          }
        }
      }
      if (nextX != null) {
        final maxAllowed = (nextX - startNode.x).abs() - 5.0;
        if (maxAllowed >= 5.0 && newLengthFt > maxAllowed) {
          newLengthFt = maxAllowed;
        }
      }
    } else if (isAlongZ) {
      final signZ = dz >= 0 ? 1.0 : -1.0;
      double? nextZ;
      for (final candidate in layout.nodes.values) {
        if (candidate.id != startNode.id && candidate.id != endNode.id && (candidate.x - startNode.x).abs() < 0.1) {
          if (signZ > 0 && candidate.z > endNode.z) {
            if (nextZ == null || candidate.z < nextZ) nextZ = candidate.z;
          } else if (signZ < 0 && candidate.z < endNode.z) {
            if (nextZ == null || candidate.z > nextZ) nextZ = candidate.z;
          }
        }
      }
      if (nextZ != null) {
        final maxAllowed = (nextZ - startNode.z).abs() - 5.0;
        if (maxAllowed >= 5.0 && newLengthFt > maxAllowed) {
          newLengthFt = maxAllowed;
        }
      }
    }

    double newX;
    double newZ;
    if (isAlongX) {
      newX = startNode.x + (dx >= 0 ? newLengthFt : -newLengthFt);
      newZ = startNode.z;
    } else if (isAlongZ) {
      newX = startNode.x;
      newZ = startNode.z + (dz >= 0 ? newLengthFt : -newLengthFt);
    } else {
      final ratio = newLengthFt / currentLen;
      newX = startNode.x + dx * ratio;
      newZ = startNode.z + dz * ratio;
    }
    newX = double.parse(newX.toStringAsFixed(4));
    newZ = double.parse(newZ.toStringAsFixed(4));

    final additionalOld = <NodeId, v64.Vector3>{};
    final additionalNew = <NodeId, v64.Vector3>{};
    NodeId? parallelNodeId;
    v64.Vector3? oldParallelPos;
    v64.Vector3? newParallelPos;

    if (isAlongX) {
      final shiftX = newX - endNode.x;
      final signX = dx >= 0 ? 1.0 : -1.0;
      final wallNodes = layout.nodes.values.where((n) {
        if (n.id == endNode.id) return false;
        if (signX > 0) {
          return n.x >= endNode.x - 0.5;
        } else {
          return n.x <= endNode.x + 0.5;
        }
      }).toList();
      for (final wn in wallNodes) {
        additionalOld[wn.id] = v64.Vector3(wn.x, wn.elevation, wn.z);
        additionalNew[wn.id] = v64.Vector3(wn.x + shiftX, wn.elevation, wn.z);
      }
    } else if (isAlongZ) {
      final shiftZ = newZ - endNode.z;
      final signZ = dz >= 0 ? 1.0 : -1.0;
      final wallNodes = layout.nodes.values.where((n) {
        if (n.id == endNode.id) return false;
        if (signZ > 0) {
          return n.z >= endNode.z - 0.5;
        } else {
          return n.z <= endNode.z + 0.5;
        }
      }).toList();
      for (final wn in wallNodes) {
        additionalOld[wn.id] = v64.Vector3(wn.x, wn.elevation, wn.z);
        additionalNew[wn.id] = v64.Vector3(wn.x, wn.elevation, wn.z + shiftZ);
      }
    }

    executeCommand(ResizeTrussMemberCommand(
      edgeId: selectedEdgeId!,
      anchorNodeId: edge.startNodeId,
      movingNodeId: edge.endNodeId,
      parallelMovingNodeId: parallelNodeId,
      oldPosition: v64.Vector3(endNode.x, endNode.elevation, endNode.z),
      newPosition: v64.Vector3(newX, endNode.elevation, newZ),
      oldParallelPosition: oldParallelPos,
      newParallelPosition: newParallelPos,
      additionalOldPositions: additionalOld.isNotEmpty ? additionalOld : null,
      additionalNewPositions: additionalNew.isNotEmpty ? additionalNew : null,
      oldLength: currentLen,
      newLength: newLengthFt,
    ));

    // Merge collinear degree-2 nodes so edges <= 40ft stay direct single edges
    mergeCollinearDegree2Nodes();
    return true;
  }

  void mergeCollinearDegree2Nodes() {
    bool mergedAny = false;

    for (final node in layout.nodes.values.toList()) {
      if (node.isControlPoint || node.type == NodeType.controlPoint) continue;

      final connectedEdges = layout.edges.values
          .where((e) => e.startNodeId == node.id || e.endNodeId == node.id)
          .toList();

      if (connectedEdges.length == 2) {
        final e1 = connectedEdges[0];
        final e2 = connectedEdges[1];

        final other1Id = e1.startNodeId == node.id ? e1.endNodeId : e1.startNodeId;
        final other2Id = e2.startNodeId == node.id ? e2.endNodeId : e2.startNodeId;

        final n1 = layout.getNode(other1Id);
        final n2 = layout.getNode(other2Id);

        if (n1 != null && n2 != null && other1Id != other2Id) {
          final v1x = node.x - n1.x;
          final v1z = node.z - n1.z;
          final v2x = n2.x - node.x;
          final v2z = n2.z - node.z;

          final cross = (v1x * v2z - v1z * v2x).abs();
          final dot = v1x * v2x + v1z * v2z;

          if (cross < 0.2 && dot > 0) {
            final len1 = math.sqrt(v1x * v1x + v1z * v1z);
            final len2 = math.sqrt(v2x * v2x + v2z * v2z);
            final totalLen = len1 + len2;

            if (totalLen <= 40.0 + 0.05) {
              final mergedEdge = MandapEdge(
                id: EdgeId('e_mrg_${n1.id.value}_${n2.id.value}_${DateTime.now().microsecondsSinceEpoch}'),
                startNodeId: n1.id,
                endNodeId: n2.id,
                role: e1.role,
                profile: e1.profile,
              );

              final newEdges = Map<EdgeId, MandapEdge>.from(layout.edges);
              newEdges.remove(e1.id);
              newEdges.remove(e2.id);
              newEdges[mergedEdge.id] = mergedEdge;

              final newNodes = Map<NodeId, MandapNode>.from(layout.nodes);
              newNodes.remove(node.id);

              layout = MandapLayout(
                nodes: newNodes,
                edges: newEdges,
                zones: layout.zones,
              );

              if (selectedEdgeId == e1.id || selectedEdgeId == e2.id) {
                selectedEdgeId = mergedEdge.id;
              }

              mergedAny = true;
            }
          }
        }
      }
    }

    if (mergedAny) {
      _recalculate();
      notifyListeners();
    }
  }

  int _nodeSequence = 0;

  /// Adds a node to layout (supports object or named arguments).
  void addNode([dynamic nodeOrX, double? z, NodeType? type, double? elevation, NodeSupport? support]) {
    if (nodeOrX is MandapNode) {
      executeCommand(AddNodeCommand(node: nodeOrX));
    } else if (nodeOrX is num && z != null) {
      final id = NodeId('n_${DateTime.now().microsecondsSinceEpoch}_${_nodeSequence++}');
      final effType = type ?? NodeType.corner;
      executeCommand(AddNodeCommand(node: MandapNode(
        id: id,
        x: nodeOrX.toDouble(),
        z: z,
        type: effType,
        elevation: elevation ?? 0.0,
        height: elevation ?? 0.0,
        support: support ?? ((effType == NodeType.carpet || effType == NodeType.stage || effType == NodeType.controlPoint) ? NodeSupport.none : NodeSupport.pole),
      )));
    }
  }

  NodeId? addNodeNamed({MandapNode? node, double? x, double? z, NodeType? type, double? elevation, NodeSupport? support}) {
    if (node != null) {
      executeCommand(AddNodeCommand(node: node));
      return node.id;
    } else if (x != null && z != null) {
      final id = NodeId('n_${DateTime.now().microsecondsSinceEpoch}_${_nodeSequence++}');
      final effSupport = support ?? ((type == NodeType.carpet || type == NodeType.stage) ? NodeSupport.none : NodeSupport.pole);
      executeCommand(AddNodeCommand(node: MandapNode(
        id: id,
        x: x,
        z: z,
        type: type ?? NodeType.corner,
        elevation: elevation ?? 0.0,
        height: elevation ?? 0.0,
        support: effSupport,
      )));
      return id;
    }
    return null;
  }

  /// Automatically connects 4 unconnected poles in perimeter order with truss edges.
  /// Returns true if an auto-connection was performed, false otherwise.
  bool autoConnectUnconnectedPoles() {
    final unconnectedPoles = layout.nodes.values.where((n) {
      final isPole = n.support == NodeSupport.pole ||
          n.type == NodeType.pole ||
          n.type == NodeType.corner;
      if (!isPole) return false;
      final isConnected = layout.edges.values.any(
        (e) => e.startNodeId == n.id || e.endNodeId == n.id,
      );
      return !isConnected;
    }).toList();

    if (unconnectedPoles.length == 4) {
      final edges = AutoConnectPolesCommand.buildPerimeterEdges(unconnectedPoles);
      if (edges != null && edges.isNotEmpty) {
        executeCommand(AutoConnectPolesCommand(newEdges: edges));
        return true;
      }
    }
    return false;
  }

  /// Checks if a 2D coordinate (x, z) lies along an existing truss edge segment.
  /// Returns the matching EdgeId if found, null otherwise.
  EdgeId? findEdgePassingThrough(double x, double z, {double tolerance = 1.0}) {
    for (final edge in layout.edges.values) {
      final start = layout.getNode(edge.startNodeId);
      final end = layout.getNode(edge.endNodeId);
      if (start == null || end == null) continue;

      final dx = end.x - start.x;
      final dz = end.z - start.z;
      final l2 = dx * dx + dz * dz;
      if (l2 < 0.01) continue;

      final t = ((x - start.x) * dx + (z - start.z) * dz) / l2;
      // Must be strictly between endpoints with safe margin
      if (t > 0.04 && t < 0.96) {
        final projX = start.x + t * dx;
        final projZ = start.z + t * dz;
        final dist = math.sqrt((x - projX) * (x - projX) + (z - projZ) * (z - projZ));
        if (dist <= tolerance) {
          return edge.id;
        }
      }
    }
    return null;
  }

  /// Splits an existing truss edge into two edges with an inserted pole node.
  NodeId? splitEdgeWithPole(
    EdgeId edgeId, {
    double? x,
    double? z,
    double? elevation,
    bool snapToCenterIfClose = true,
  }) {
    final edge = layout.getEdge(edgeId);
    if (edge == null) return null;
    final start = layout.getNode(edge.startNodeId);
    final end = layout.getNode(edge.endNodeId);
    if (start == null || end == null) return null;

    double poleX;
    double poleZ;

    if (x != null && z != null) {
      final dx = end.x - start.x;
      final dz = end.z - start.z;
      final l2 = dx * dx + dz * dz;
      if (l2 > 0.01) {
        var t = ((x - start.x) * dx + (z - start.z) * dz) / l2;
        t = t.clamp(0.05, 0.95);
        if (snapToCenterIfClose && (t - 0.5).abs() < 0.15) {
          t = 0.5;
        }
        poleX = start.x + t * dx;
        poleZ = start.z + t * dz;
      } else {
        poleX = (start.x + end.x) / 2.0;
        poleZ = (start.z + end.z) / 2.0;
      }
    } else {
      poleX = (start.x + end.x) / 2.0;
      poleZ = (start.z + end.z) / 2.0;
    }

    // Align snap to matching X/Z coordinates of existing poles in layout
    for (final node in layout.nodes.values) {
      if (!node.isControlPoint) {
        if ((node.x - poleX).abs() <= 3.0) poleX = node.x;
        if ((node.z - poleZ).abs() <= 3.0) poleZ = node.z;
      }
    }

    final poleElev = elevation ?? (start.elevation > 0 ? start.elevation : mandapHeight);
    final poleNodeId = NodeId('pole_${DateTime.now().microsecondsSinceEpoch}_${_nodeSequence++}');

    final newPoleNode = MandapNode(
      id: poleNodeId,
      x: poleX,
      z: poleZ,
      type: NodeType.pole,
      elevation: poleElev,
      height: poleElev,
      support: NodeSupport.pole,
    );

    final ts = DateTime.now().microsecondsSinceEpoch;
    final edge1 = MandapEdge(
      id: EdgeId('truss_${ts}_1'),
      startNodeId: edge.startNodeId,
      endNodeId: poleNodeId,
      role: edge.role,
      profile: edge.profile,
    );
    final edge2 = MandapEdge(
      id: EdgeId('truss_${ts}_2'),
      startNodeId: poleNodeId,
      endNodeId: edge.endNodeId,
      role: edge.role,
      profile: edge.profile,
    );

    executeCommand(
      SplitEdgeWithPoleCommand(
        edgeToRemove: edge,
        newPoleNode: newPoleNode,
        edge1: edge1,
        edge2: edge2,
      ),
    );

    // Parallel edge split synchronization across opposite perimeter walls
    EdgeId? parallelEdgeId;
    MandapEdge? parallelEdge;
    double? mirrorX;
    double? mirrorZ;

    if ((start.x - 0.0).abs() < 1.5 && (end.x - 0.0).abs() < 1.5) {
      mirrorX = plotWidth;
      mirrorZ = poleZ;
      for (final e in layout.edges.values) {
        if (e.id == edge.id) continue;
        final s = layout.getNode(e.startNodeId);
        final en = layout.getNode(e.endNodeId);
        if (s != null && en != null && (s.x - plotWidth).abs() < 1.5 && (en.x - plotWidth).abs() < 1.5) {
          final minZ2 = math.min(s.z, en.z);
          final maxZ2 = math.max(s.z, en.z);
          if (poleZ >= minZ2 - 0.5 && poleZ <= maxZ2 + 0.5) {
            parallelEdge = e;
            break;
          }
        }
      }
    } else if ((start.x - plotWidth).abs() < 1.5 && (end.x - plotWidth).abs() < 1.5) {
      mirrorX = 0.0;
      mirrorZ = poleZ;
      for (final e in layout.edges.values) {
        if (e.id == edge.id) continue;
        final s = layout.getNode(e.startNodeId);
        final en = layout.getNode(e.endNodeId);
        if (s != null && en != null && (s.x - 0.0).abs() < 1.5 && (en.x - 0.0).abs() < 1.5) {
          final minZ2 = math.min(s.z, en.z);
          final maxZ2 = math.max(s.z, en.z);
          if (poleZ >= minZ2 - 0.5 && poleZ <= maxZ2 + 0.5) {
            parallelEdge = e;
            break;
          }
        }
      }
    } else if ((start.z - 0.0).abs() < 1.5 && (end.z - 0.0).abs() < 1.5) {
      mirrorX = poleX;
      mirrorZ = plotDepth;
      for (final e in layout.edges.values) {
        if (e.id == edge.id) continue;
        final s = layout.getNode(e.startNodeId);
        final en = layout.getNode(e.endNodeId);
        if (s != null && en != null && (s.z - plotDepth).abs() < 1.5 && (en.z - plotDepth).abs() < 1.5) {
          final minX2 = math.min(s.x, en.x);
          final maxX2 = math.max(s.x, en.x);
          if (poleX >= minX2 - 0.5 && poleX <= maxX2 + 0.5) {
            parallelEdge = e;
            break;
          }
        }
      }
    } else if ((start.z - plotDepth).abs() < 1.5 && (end.z - plotDepth).abs() < 1.5) {
      mirrorX = poleX;
      mirrorZ = 0.0;
      for (final e in layout.edges.values) {
        if (e.id == edge.id) continue;
        final s = layout.getNode(e.startNodeId);
        final en = layout.getNode(e.endNodeId);
        if (s != null && en != null && (s.z - 0.0).abs() < 1.5 && (en.z - 0.0).abs() < 1.5) {
          final minX2 = math.min(s.x, en.x);
          final maxX2 = math.max(s.x, en.x);
          if (poleX >= minX2 - 0.5 && poleX <= maxX2 + 0.5) {
            parallelEdge = e;
            break;
          }
        }
      }
    }

    if (parallelEdge != null && mirrorX != null && mirrorZ != null) {
      final pPoleNodeId = NodeId('pole_${ts + 1}_${_nodeSequence++}');
      final pPoleNode = MandapNode(
        id: pPoleNodeId,
        x: mirrorX,
        z: mirrorZ,
        type: NodeType.pole,
        elevation: poleElev,
        height: poleElev,
        support: NodeSupport.pole,
      );
      final pEdge1 = MandapEdge(
        id: EdgeId('truss_${ts + 1}_1'),
        startNodeId: parallelEdge.startNodeId,
        endNodeId: pPoleNodeId,
        role: parallelEdge.role,
        profile: parallelEdge.profile,
      );
      final pEdge2 = MandapEdge(
        id: EdgeId('truss_${ts + 1}_2'),
        startNodeId: pPoleNodeId,
        endNodeId: parallelEdge.endNodeId,
        role: parallelEdge.role,
        profile: parallelEdge.profile,
      );
      executeCommand(
        SplitEdgeWithPoleCommand(
          edgeToRemove: parallelEdge,
          newPoleNode: pPoleNode,
          edge1: pEdge1,
          edge2: pEdge2,
        ),
      );
    }

    return poleNodeId;
  }

  double _findClosestPerpendicularSnap({
    required String axis,
    required double rayCoord,
    required double targetVal,
    required double startVal,
  }) {
    final step = subGridSize > 0 ? subGridSize : (standardTrussPieceSize > 0 ? standardTrussPieceSize : 5.0);

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

    double? bestCandidate;
    double minDiff = double.infinity;
    for (final c in candidates) {
      if ((c - startVal).abs() > 0.01) {
        final diff = (c - targetVal).abs();
        if (diff <= 6.0 && diff < minDiff) {
          minDiff = diff;
          bestCandidate = c;
        }
      }
    }

    if (bestCandidate != null) {
      return bestCandidate;
    }

    final signedDelta = targetVal - startVal;
    int units = (signedDelta / step).round();
    if (units == 0) {
      units = signedDelta >= 0 ? 1 : -1;
    }
    return startVal + units * step;
  }

  void addOrSubdivideEdge(
    NodeId startNodeId,
    NodeId endNodeId, {
    TrussMemberRole role = TrussMemberRole.upper,
    EdgeProfile profile = EdgeProfile.box,
  }) {
    final startNode = layout.getNode(startNodeId);
    final endNode = layout.getNode(endNodeId);
    if (startNode == null || endNode == null) return;

    final isPillar = (startNode.x == endNode.x) && (startNode.z == endNode.z) && (startNode.elevation != endNode.elevation);
    if (isPillar) {
      final newEdge = MandapEdge(
        id: EdgeId('custom_edge_${DateTime.now().millisecondsSinceEpoch}'),
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        role: TrussMemberRole.tower,
        profile: profile,
      );
      executeCommand(CreateTrussMemberCommand(newEdge: newEdge));
      return;
    }

    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final length = math.sqrt(dx * dx + dz * dz);
    if (length < 0.05) return;

    final step = subGridSize > 0 ? subGridSize : (standardTrussPieceSize > 0 ? standardTrussPieceSize : 30.0);

    final nodePoints = <({double t, NodeId id})>[
      (t: 0.0, id: startNodeId),
      (t: 1.0, id: endNodeId),
    ];

    for (final node in layout.nodes.values) {
      if (node.id == startNodeId || node.id == endNodeId || node.isControlPoint) continue;
      final px = node.x - startNode.x;
      final pz = node.z - startNode.z;
      final dot = (dx.abs() >= dz.abs()) ? (dx != 0 ? px / dx : 0.0) : (dz != 0 ? pz / dz : 0.0);
      if (dot > 0.01 && dot < 0.99) {
        final projX = startNode.x + dot * dx;
        final projZ = startNode.z + dot * dz;
        final distSq = (node.x - projX) * (node.x - projX) + (node.z - projZ) * (node.z - projZ);
        if (distSq < 0.25) {
          nodePoints.add((t: dot, id: node.id));
        }
      }
    }

    // Detect line intersections with existing horizontal/vertical truss edges
    for (final existingEdge in List<MandapEdge>.from(layout.edges.values)) {
      if (existingEdge.role == TrussMemberRole.tower) continue;
      final eStart = layout.getNode(existingEdge.startNodeId);
      final eEnd = layout.getNode(existingEdge.endNodeId);
      if (eStart == null || eEnd == null) continue;

      final edx = eEnd.x - eStart.x;
      final edz = eEnd.z - eStart.z;

      final denom = dx * edz - dz * edx;
      if (denom.abs() > 0.001) {
        final t = ((eStart.x - startNode.x) * edz - (eStart.z - startNode.z) * edx) / denom;
        final u = ((eStart.x - startNode.x) * dz - (eStart.z - startNode.z) * dx) / denom;

        if (t > 0.01 && t < 0.99 && u > 0.01 && u < 0.99) {
          final ix = startNode.x + t * dx;
          final iz = startNode.z + t * dz;
          final junctionId = getOrCreateNodeAt(ix, iz, elevation: startNode.elevation, support: NodeSupport.pole);
          if (!nodePoints.any((item) => item.id == junctionId)) {
            nodePoints.add((t: t, id: junctionId));
          }
        }
      }
    }

    if (length > 40.0 + 0.05) {
      double acc = 0.0;
      final maxSpan = (step > 0 && step <= 40.0) ? step : 40.0;
      while (length - acc > 40.0 + 0.05) {
        final currentSpan = (acc == 0) ? maxSpan : 40.0;
        acc += currentSpan;
        final t = (acc / length).clamp(0.01, 0.99);
        final subX = startNode.x + t * dx;
        final subZ = startNode.z + t * dz;
        final subNodeId = getOrCreateNodeAt(subX, subZ, elevation: startNode.elevation, support: NodeSupport.pole);
        if (!nodePoints.any((item) => item.id == subNodeId)) {
          nodePoints.add((t: t, id: subNodeId));
        }
      }
    }

    nodePoints.sort((a, b) => a.t.compareTo(b.t));

    final uniqueNodes = <NodeId>[];
    for (final item in nodePoints) {
      if (uniqueNodes.isEmpty || uniqueNodes.last != item.id) {
        uniqueNodes.add(item.id);
      }
    }

    for (int i = 0; i < uniqueNodes.length - 1; i++) {
      final sId = uniqueNodes[i];
      final eId = uniqueNodes[i + 1];
      if (sId == eId) continue;

      bool exists = false;
      for (final existingEdge in layout.edges.values) {
        if ((existingEdge.startNodeId == sId && existingEdge.endNodeId == eId) ||
            (existingEdge.startNodeId == eId && existingEdge.endNodeId == sId)) {
          exists = true;
          break;
        }
      }

      if (!exists) {
        final newEdge = MandapEdge(
          id: EdgeId('e_sub_${DateTime.now().microsecondsSinceEpoch}_$i'),
          startNodeId: sId,
          endNodeId: eId,
          role: role,
          profile: profile,
        );
        executeCommand(CreateTrussMemberCommand(newEdge: newEdge));
      }
    }
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
      NodeId effectiveEndNodeId = endNodeId;
      final startNode = layout.getNode(startNodeId);
      final endNode = layout.getNode(endNodeId);
      if (startNode != null && endNode != null) {
        final isPillar = (startNode.x == endNode.x) && (startNode.z == endNode.z) && (startNode.elevation != endNode.elevation);
        if (!isPillar) {
          final dx = (endNode.x - startNode.x).abs();
          final dz = (endNode.z - startNode.z).abs();
          if (dx > 0.05 && dz > 0.05) {
            final targetX = (dx >= dz) ? endNode.x : startNode.x;
            final targetZ = (dx >= dz) ? startNode.z : endNode.z;
            effectiveEndNodeId = getOrCreateNodeAt(targetX, targetZ, elevation: startNode.elevation);
          }
        }
      }
      addOrSubdivideEdge(startNodeId, effectiveEndNodeId, role: role, profile: profile);
      return true;
    }

    if (penStartPoint == null) return false;
    final startPt = penStartPoint!;

    if (penStartNodeId != null && targetEndNodeId != null && layout.nodes.containsKey(penStartNodeId) && layout.nodes.containsKey(targetEndNodeId)) {
      final newEdgeId = edgeId ?? EdgeId('e_pen_${DateTime.now().millisecondsSinceEpoch}');
      final startNode = layout.getNode(penStartNodeId!)!;
      final endNode = layout.getNode(targetEndNodeId)!;
      final isPillar = (startNode.x == endNode.x) && (startNode.z == endNode.z) && (startNode.elevation != endNode.elevation);
      NodeId effectiveEndNodeId = targetEndNodeId;
      if (!isPillar) {
        final dx = (endNode.x - startNode.x).abs();
        final dz = (endNode.z - startNode.z).abs();
        if (dx > 0.05 && dz > 0.05) {
          final targetX = (dx >= dz) ? endNode.x : startNode.x;
          final targetZ = (dx >= dz) ? startNode.z : endNode.z;
          effectiveEndNodeId = getOrCreateNodeAt(targetX, targetZ, elevation: startNode.elevation);
        }
      }
      addOrSubdivideEdge(penStartNodeId!, effectiveEndNodeId, role: isPillar ? TrussMemberRole.tower : role, profile: profile);
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

    NodeId sNodeId = penStartNodeId ?? getOrCreateNodeAt(startPt.x, startPt.z, elevation: startPt.y);
    MandapNode? newStartNode;
    if (!layout.nodes.containsKey(sNodeId)) {
      newStartNode = layout.getNode(sNodeId);
    }

    NodeId eNodeId = effectiveTargetEndNodeId ?? penEndNodeId ?? getOrCreateNodeAt(endPt.x, endPt.z, elevation: endPt.y);
    MandapNode? newEndNode;
    if (!layout.nodes.containsKey(eNodeId)) {
      newEndNode = layout.getNode(eNodeId);
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

  double _trussCalculationUnitSize = 10.0;
  double get trussCalculationUnitSize => _trussCalculationUnitSize;

  /// Total pieces of truss required calculated based on standard truss piece size (or user calculation unit size).
  int get totalPiecesRequired {
    final totalFt = totalLinearTrussFt;
    if (totalFt <= 0) return 0;
    final unit = _trussCalculationUnitSize > 0
        ? _trussCalculationUnitSize
        : (_standardTrussPieceSize > 0 ? _standardTrussPieceSize : 10.0);
    return (totalFt / unit).ceil();
  }

  /// Total pillar/vertical pieces calculated based on the user-defined unit calculation size.
  int get pillarPiecesRequired {
    final ft = pillarTotalFeet;
    if (ft <= 0) return 0;
    final unit = _trussCalculationUnitSize > 0 ? _trussCalculationUnitSize : 10.0;
    return (ft / unit).ceil();
  }

  /// Total upper/roof pieces calculated based on the user-defined unit calculation size.
  int get upperPiecesRequired {
    final ft = upperTotalFeet;
    if (ft <= 0) return 0;
    final unit = _trussCalculationUnitSize > 0 ? _trussCalculationUnitSize : 10.0;
    return (ft / unit).ceil();
  }

  /// Sets the user-defined truss unit calculation size (e.g., 10ft, 12ft, 15ft, 20ft, 25ft, 30ft, or custom).
  void setTrussCalculationUnitSize(double sizeInFeet) {
    if (sizeInFeet <= 0) return;
    _trussCalculationUnitSize = sizeInFeet;
    _updateCatalogWithStandardSize();
    _recalculate();
    notifyListeners();
  }

  /// Sets the standard stock truss piece size, rebuilds catalog and recalculates BOM.
  void setStandardTrussPieceSize(double sizeInFeet) {
    if (sizeInFeet <= 0) return;
    _standardTrussPieceSize = sizeInFeet;
    gridSettings = gridSettings.copyWith(minorSpacing: sizeInFeet);
    _updateCatalogWithStandardSize();
    _recalculate();
    notifyListeners();
  }

  void _updateCatalogWithStandardSize() {
    final maxModularPieceSize = (_trussCalculationUnitSize > 0)
        ? _trussCalculationUnitSize
        : ((_standardTrussPieceSize > 0 && _standardTrussPieceSize < 10.0)
            ? _standardTrussPieceSize
            : 10.0);
    final allStandardSizes = [1.0, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 15.0, 20.0, 25.0, 30.0];
    final sizes = allStandardSizes.where((s) => s <= maxModularPieceSize).toSet().toList();
    if (!sizes.contains(maxModularPieceSize)) {
      sizes.add(maxModularPieceSize);
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

  GridSettings gridSettings = const GridSettings(majorSpacing: 10.0, minorSpacing: 1.0);
  
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
    double? initialCalculationUnitSize,
    double? initialPoleHeight,
    bool includeTowerEdges = false,
  }) {
    if (initialWidth != null && initialWidth > 0) plotWidth = initialWidth;
    if (initialDepth != null && initialDepth > 0) plotDepth = initialDepth;
    if (initialPoleHeight != null && initialPoleHeight > 0) mandapHeight = initialPoleHeight;
    if (initialTrussSize != null && initialTrussSize > 0) {
      _standardTrussPieceSize = initialTrussSize;
    }
    if (initialCalculationUnitSize != null && initialCalculationUnitSize > 0) {
      _trussCalculationUnitSize = initialCalculationUnitSize;
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
  /// (Forward / North, Backward / South, Left / West, Right / East) aligned with the center cross.
  ({bool canActivate, List<String> missingDirections}) checkCenterCrossSupport() {
    final center = centerControlNode;
    final cX = center?.x ?? (plotWidth / 2.0);
    final cZ = center?.z ?? (plotDepth / 2.0);

    bool isPoleNode(MandapNode n) =>
        n.support == NodeSupport.pole ||
        n.type == NodeType.corner ||
        n.type == NodeType.pole;

    // Determine actual bounding box of main layout nodes
    double minX = 0.0, maxX = plotWidth, minZ = 0.0, maxZ = plotDepth;
    if (layout.nodes.isNotEmpty) {
      final elevated = layout.nodes.values.where((n) => isPoleNode(n) && !n.isControlPoint);
      final pool = elevated.isNotEmpty ? elevated : layout.nodes.values;
      minX = pool.map((n) => n.x).reduce(math.min);
      maxX = pool.map((n) => n.x).reduce(math.max);
      minZ = pool.map((n) => n.z).reduce(math.min);
      maxZ = pool.map((n) => n.z).reduce(math.max);
    }

    bool hasForward = false;  // North side (z ~ minZ)
    bool hasBackward = false; // South side (z ~ maxZ)
    bool hasLeft = false;     // West side (x ~ minX)
    bool hasRight = false;    // East side (x ~ maxX)
    bool hasCenterPole = false;

    for (final node in layout.nodes.values) {
      if (node.isControlPoint) continue;
      if (!isPoleNode(node)) continue;

      // Check center pole
      if ((node.x - cX).abs() <= 1.0 && (node.z - cZ).abs() <= 1.0) {
        hasCenterPole = true;
      }

      // North side (z ~ minZ) - accepts any pole/corner on North boundary
      if ((node.z - minZ).abs() <= 1.5) {
        hasForward = true;
      }

      // South side (z ~ maxZ) - accepts any pole/corner on South boundary
      if ((node.z - maxZ).abs() <= 1.5) {
        hasBackward = true;
      }

      // West side (x ~ minX) - accepts any pole/corner on West boundary
      if ((node.x - minX).abs() <= 1.5) {
        hasLeft = true;
      }

      // East side (x ~ maxX) - accepts any pole/corner on East boundary
      if ((node.x - maxX).abs() <= 1.5) {
        hasRight = true;
      }
    }

    if (hasCenterPole) {
      return (canActivate: true, missingDirections: const <String>[]);
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
        preferredPoleSpacing: standardTrussPieceSize > 0 ? standardTrussPieceSize : 30.0,
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

  /// Auto-aligns any misaligned poles in the layout to match existing X and Z grid lines.
  void alignAllPoles() {
    if (layout.nodes.isEmpty) return;

    final poleXs = layout.nodes.values
        .where((n) => !n.isControlPoint && (n.support == NodeSupport.pole || n.type == NodeType.corner || n.type == NodeType.pole))
        .map((n) => n.x)
        .toList();
    final poleZs = layout.nodes.values
        .where((n) => !n.isControlPoint && (n.support == NodeSupport.pole || n.type == NodeType.corner || n.type == NodeType.pole))
        .map((n) => n.z)
        .toList();

    var updatedNodes = Map<NodeId, MandapNode>.from(layout.nodes);
    bool changed = false;

    for (final entry in layout.nodes.entries) {
      final n = entry.value;
      if (n.isControlPoint) continue;

      double newX = n.x;
      double newZ = n.z;

      for (final px in poleXs) {
        if (px != n.x && (px - n.x).abs() <= 0.25) {
          newX = px;
          break;
        }
      }
      for (final pz in poleZs) {
        if (pz != n.z && (pz - n.z).abs() <= 0.25) {
          newZ = pz;
          break;
        }
      }

      if (newX != n.x || newZ != n.z) {
        updatedNodes[entry.key] = n.copyWith(x: newX, z: newZ);
        changed = true;
      }
    }

    if (changed) {
      layout = layout.copyWith(nodes: updatedNodes);
    }
  }

  TrussDisplayNumberingResult _displayNumbering = const TrussDisplayNumberingResult();
  TrussDisplayNumberingResult get displayNumbering => _displayNumbering;

  void _recalculate() {
    alignAllPoles();
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

    _updatePlotDimensionsFromLayout();

    notifyListeners();
  }

  /// Dynamically computes and synchronizes plotWidth and plotDepth from outer structural nodes.
  void _updatePlotDimensionsFromLayout() {
    if (layout.nodes.isEmpty) return;
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minZ = double.infinity;
    double maxZ = -double.infinity;
    bool hasStructuralNode = false;

    for (final node in layout.nodes.values) {
      if (node.isControlPoint ||
          node.type == NodeType.controlPoint ||
          node.id.value.contains('center')) {
        continue;
      }
      hasStructuralNode = true;
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.z < minZ) minZ = node.z;
      if (node.z > maxZ) maxZ = node.z;
    }

    if (hasStructuralNode) {
      final spanX = (maxX - minX).abs();
      final spanZ = (maxZ - minZ).abs();
      if (spanX >= 5.0) {
        plotWidth = double.parse(spanX.toStringAsFixed(2));
      }
      if (spanZ >= 5.0) {
        plotDepth = double.parse(spanZ.toStringAsFixed(2));
      }
    }
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

  void selectEdge(EdgeId? edgeId, {double? worldX, double? worldZ}) => _selectEdge(edgeId, worldX: worldX, worldZ: worldZ);
  void selectEdgeAt(EdgeId edgeId, {double? worldX, double? worldZ}) => _selectEdge(edgeId, worldX: worldX, worldZ: worldZ);

  void _selectEdge(EdgeId? edgeId, {double? worldX, double? worldZ}) {
    if (edgeId == null) {
      selectedEdgeId = null;
      selectedNodeId = null;
      notifyListeners();
      return;
    }

    final edge = layout.edges[edgeId];
    if (edge == null) {
      selectedEdgeId = edgeId;
      selectedNodeId = null;
      notifyListeners();
      return;
    }

    if (worldX != null && worldZ != null) {
      final res = _subdivideEdgeForInteraction(edgeId, worldX: worldX, worldZ: worldZ);
      if (res.targetedEdge != null) {
        selectedEdgeId = res.targetedEdge!.id;
      } else {
        selectedEdgeId = edgeId;
      }
    } else {
      selectedEdgeId = edgeId;
    }

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
    // 1. Search for an existing node within Euclidean distance <= 1.5 ft to join directly
    MandapNode? closestNode;
    double minSqDist = double.infinity;
    for (final node in layout.nodes.values) {
      if (!node.isControlPoint) {
        final dx = node.x - x;
        final dz = node.z - z;
        final sqDist = dx * dx + dz * dz;
        if (sqDist <= 2.25 && sqDist < minSqDist) {
          minSqDist = sqDist;
          closestNode = node;
        }
      }
    }

    if (closestNode != null) {
      if (!closestNode.hasPole && (support == NodeSupport.pole || support == null)) {
        executeCommand(SetNodeSupportCommand(nodeId: closestNode.id, newSupport: NodeSupport.pole));
      }
      return closestNode.id;
    }

    // 2. Axis-alignment snap
    double snappedX = x;
    double snappedZ = z;
    for (final node in layout.nodes.values) {
      if (!node.isControlPoint) {
        if ((node.x - x).abs() <= 2.5) snappedX = node.x;
        if ((node.z - z).abs() <= 2.5) snappedZ = node.z;
      }
    }

    // 3. Search if any node exists at snapped coordinates within 1.0 ft
    for (final node in layout.nodes.values) {
      if (!node.isControlPoint) {
        final dx = node.x - snappedX;
        final dz = node.z - snappedZ;
        if (dx * dx + dz * dz <= 1.0) {
          if (!node.hasPole && (support == NodeSupport.pole || support == null)) {
            executeCommand(SetNodeSupportCommand(nodeId: node.id, newSupport: NodeSupport.pole));
          }
          return node.id;
        }
      }
    }

    return addNodeNamed(
      x: snappedX,
      z: snappedZ,
      type: NodeType.junction,
      elevation: elevation ?? mandapHeight,
      support: support ?? NodeSupport.pole,
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

    // Check if targetWorldX / targetWorldZ is near ANY existing node (within 5.0 ft)
    MandapNode? closestExistingNode;
    double minNodeDist = double.infinity;
    for (final node in layout.nodes.values) {
      if (node.id != startNode.id && !node.isControlPoint) {
        final dist = math.sqrt(math.pow(node.x - targetWorldX, 2) + math.pow(node.z - targetWorldZ, 2));
        if (dist <= 5.0 && dist < minNodeDist) {
          minNodeDist = dist;
          closestExistingNode = node;
        }
      }
    }

    if (closestExistingNode != null) {
      handleAddEdgeTap(closestExistingNode.id);
      return closestExistingNode.id;
    }

    // Alignment snap to existing poles on X/Z axis
    double snappedX = targetWorldX;
    double snappedZ = targetWorldZ;
    for (final node in layout.nodes.values) {
      if (!node.isControlPoint) {
        if ((node.x - targetWorldX).abs() <= 3.0) snappedX = node.x;
        if ((node.z - targetWorldZ).abs() <= 3.0) snappedZ = node.z;
      }
    }

    final dx = snappedX - startNode.x;
    final dz = snappedZ - startNode.z;
    if (dx.abs() < 0.05 && dz.abs() < 0.05) {
      return null;
    }

    final step = subGridSize > 0 ? subGridSize : (standardTrussPieceSize > 0 ? standardTrussPieceSize : 25.0);
    final isHorizontal = dx.abs() >= dz.abs();
    double endX;
    double endZ;

    if (isHorizontal) {
      endZ = startNode.z;
      if ((snappedX - plotWidth).abs() <= step) {
        endX = plotWidth;
      } else if ((snappedX - 0.0).abs() <= step) {
        endX = 0.0;
      } else {
        endX = snappedX;
      }
    } else {
      endX = startNode.x;
      if ((snappedZ - plotDepth).abs() <= step) {
        endZ = plotDepth;
      } else if ((snappedZ - 0.0).abs() <= step) {
        endZ = 0.0;
      } else {
        endZ = snappedZ;
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
          NodeId effectiveEndNodeId = tappedNodeId;

          if (!isPillar) {
            final dx = (endNode.x - startNode.x).abs();
            final dz = (endNode.z - startNode.z).abs();
            if (dx > 0.05 && dz > 0.05) {
              final targetX = (dx >= dz) ? endNode.x : startNode.x;
              final targetZ = (dx >= dz) ? startNode.z : endNode.z;
              effectiveEndNodeId = getOrCreateNodeAt(targetX, targetZ, elevation: startNode.elevation);
            }
          }

          addOrSubdivideEdge(
            pendingEdgeStartNodeId!,
            effectiveEndNodeId,
            role: isPillar ? TrussMemberRole.tower : TrussMemberRole.upper,
            profile: EdgeProfile.box,
          );
        }
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

  void cancelPenDrawing({bool resetMode = false}) {
    if (resetMode) {
      _mode = EditorMode.view;
    }
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
  void deleteEdge(EdgeId edgeId, {double? worldX, double? worldZ}) => _deleteEdge(edgeId, worldX: worldX, worldZ: worldZ);
  void deleteEdgeAt(EdgeId edgeId, {double? worldX, double? worldZ}) => _deleteEdge(edgeId, worldX: worldX, worldZ: worldZ);

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

    MandapEdge? mergedEdge;
    if (connected.length == 2) {
      final e1 = connected[0];
      final e2 = connected[1];
      final o1Id = e1.startNodeId == nodeId ? e1.endNodeId : e1.startNodeId;
      final o2Id = e2.startNodeId == nodeId ? e2.endNodeId : e2.startNodeId;
      final o1 = layout.getNode(o1Id);
      final o2 = layout.getNode(o2Id);
      if (o1 != null && o2 != null && o1Id != o2Id) {
        final v1x = node.x - o1.x;
        final v1z = node.z - o1.z;
        final v2x = o2.x - node.x;
        final v2z = o2.z - node.z;
        final cross = (v1x * v2z - v1z * v2x).abs();
        final dot = v1x * v2x + v1z * v2z;
        if (cross < 0.1 && dot > 0) {
          mergedEdge = MandapEdge(
            id: EdgeId('e_mrg_${o1Id.value}_${o2Id.value}_${DateTime.now().millisecondsSinceEpoch}'),
            startNodeId: o1Id,
            endNodeId: o2Id,
            profile: e1.profile,
            role: e1.role,
          );
        }
      }
    }

    NodeId? parallelNodeId;
    MandapNode? parallelNodeSnapshot;
    List<MandapEdge>? parallelConnectedEdgeSnapshots;
    MandapEdge? parallelMergedEdge;

    for (final candidate in layout.nodes.values) {
      if (candidate.id != node.id &&
          !candidate.isControlPoint &&
          candidate.type != NodeType.controlPoint) {
        final isParallelX = (candidate.x - node.x).abs() < 0.5 && (candidate.z - node.z).abs() > 5.0;
        final isParallelZ = (candidate.z - node.z).abs() < 0.5 && (candidate.x - node.x).abs() > 5.0;
        if (isParallelX || isParallelZ) {
          final pConnected = layout.edges.values.where((e) => e.startNodeId == candidate.id || e.endNodeId == candidate.id).toList();
          if (pConnected.length == 2) {
            final pe1 = pConnected[0];
            final pe2 = pConnected[1];
            final po1Id = pe1.startNodeId == candidate.id ? pe1.endNodeId : pe1.startNodeId;
            final po2Id = pe2.startNodeId == candidate.id ? pe2.endNodeId : pe2.startNodeId;
            final po1 = layout.getNode(po1Id);
            final po2 = layout.getNode(po2Id);
            if (po1 != null && po2 != null && po1Id != po2Id) {
              final pv1x = candidate.x - po1.x;
              final pv1z = candidate.z - po1.z;
              final pv2x = po2.x - candidate.x;
              final pv2z = po2.z - candidate.z;
              final pcross = (pv1x * pv2z - pv1z * pv2x).abs();
              final pdot = pv1x * pv2x + pv1z * pv2z;
              if (pcross < 0.1 && pdot > 0) {
                parallelNodeId = candidate.id;
                parallelNodeSnapshot = candidate;
                parallelConnectedEdgeSnapshots = pConnected;
                parallelMergedEdge = MandapEdge(
                  id: EdgeId('e_pmrg_${po1Id.value}_${po2Id.value}_${DateTime.now().millisecondsSinceEpoch}'),
                  startNodeId: po1Id,
                  endNodeId: po2Id,
                  profile: pe1.profile,
                  role: pe1.role,
                );
                break;
              }
            }
          }
        }
      }
    }

    executeCommand(DeleteNodeCommand(
      nodeId: nodeId,
      nodeSnapshot: node,
      connectedEdgeSnapshots: connected,
      mergedEdge: mergedEdge,
      parallelNodeId: parallelNodeId,
      parallelNodeSnapshot: parallelNodeSnapshot,
      parallelConnectedEdgeSnapshots: parallelConnectedEdgeSnapshots,
      parallelMergedEdge: parallelMergedEdge,
    ));

    if (selectedNodeId == nodeId) selectedNodeId = null;
  }

  ({List<MandapEdge> createdEdges, MandapEdge? targetedEdge}) _subdivideEdgeForInteraction(
    EdgeId edgeId, {
    double? worldX,
    double? worldZ,
  }) {
    final edge = layout.edges[edgeId];
    if (edge == null) return (createdEdges: [], targetedEdge: null);

    final startNode = layout.getNode(edge.startNodeId);
    final endNode = layout.getNode(edge.endNodeId);
    if (startNode == null || endNode == null) return (createdEdges: [edge], targetedEdge: edge);

    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final length = math.sqrt(dx * dx + dz * dz);
    if (length < 0.1) return (createdEdges: [edge], targetedEdge: edge);

    final pointsWithT = <({double t, NodeId nodeId})>[
      (t: 0.0, nodeId: startNode.id),
      (t: 1.0, nodeId: endNode.id),
    ];

    // Gather existing intermediate nodes in layout
    for (final node in layout.nodes.values) {
      if (node.id == edge.startNodeId || node.id == edge.endNodeId || node.isControlPoint) continue;
      final px = node.x - startNode.x;
      final pz = node.z - startNode.z;
      final dot = (dx.abs() >= dz.abs()) ? (dx != 0 ? px / dx : 0.0) : (dz != 0 ? pz / dz : 0.0);
      if (dot > 0.01 && dot < 0.99) {
        final projX = startNode.x + dot * dx;
        final projZ = startNode.z + dot * dz;
        final distSq = (node.x - projX) * (node.x - projX) + (node.z - projZ) * (node.z - projZ);
        if (distSq < 0.25) {
          pointsWithT.add((t: dot, nodeId: node.id));
        }
      }
    }

    // Gather support poles from result.poles
    if (result != null) {
      for (final pole in result.poles) {
        final px = pole.x - startNode.x;
        final pz = pole.z - startNode.z;
        final dot = (dx.abs() >= dz.abs()) ? (dx != 0 ? px / dx : 0.0) : (dz != 0 ? pz / dz : 0.0);
        if (dot > 0.01 && dot < 0.99) {
          final projX = startNode.x + dot * dx;
          final projZ = startNode.z + dot * dz;
          final distSq = (pole.x - projX) * (pole.x - projX) + (pole.z - projZ) * (pole.z - projZ);
          if (distSq < 0.25) {
            final poleNodeId = getOrCreateNodeAt(pole.x, pole.z, elevation: startNode.elevation, support: NodeSupport.pole);
            if (!pointsWithT.any((p) => (p.t - dot).abs() < 0.001 || p.nodeId == poleNodeId)) {
              pointsWithT.add((t: dot, nodeId: poleNodeId));
            }
          }
        }
      }
    }

    // If edge is long (> 40.0ft) and has no intermediate nodes yet, create 30ft step division nodes
    if (length > 40.0 + 0.05 && pointsWithT.length == 2) {
      final step = standardTrussPieceSize > 0 ? standardTrussPieceSize : 30.0;
      final numSteps = (length / step).round();
      if (numSteps > 1) {
        final stepT = 1.0 / numSteps;
        for (int i = 1; i < numSteps; i++) {
          final t = i * stepT;
          final subX = startNode.x + t * dx;
          final subZ = startNode.z + t * dz;
          final subNodeId = getOrCreateNodeAt(subX, subZ, elevation: startNode.elevation, support: NodeSupport.pole);
          if (!pointsWithT.any((p) => (p.t - t).abs() < 0.001 || p.nodeId == subNodeId)) {
            pointsWithT.add((t: t, nodeId: subNodeId));
          }
        }
      }
    }

    pointsWithT.sort((a, b) => a.t.compareTo(b.t));

    final uniquePoints = <({double t, NodeId nodeId})>[];
    for (final p in pointsWithT) {
      if (uniquePoints.isEmpty || (p.t - uniquePoints.last.t).abs() > 0.005) {
        uniquePoints.add(p);
      }
    }

    if (uniquePoints.length <= 2) {
      return (createdEdges: [edge], targetedEdge: edge);
    }

    // Determine target t based on worldX, worldZ
    double targetT = 0.95;
    if (worldX != null && worldZ != null) {
      final px = worldX - startNode.x;
      final pz = worldZ - startNode.z;
      targetT = (dx.abs() >= dz.abs()) ? (dx != 0 ? px / dx : 0.0) : (dz != 0 ? pz / dz : 0.0);
      targetT = targetT.clamp(0.0, 1.0);
    }

    int targetK = uniquePoints.length - 2;
    for (int i = 0; i < uniquePoints.length - 1; i++) {
      if (targetT >= uniquePoints[i].t - 0.01 && targetT <= uniquePoints[i + 1].t + 0.01) {
        targetK = i;
        break;
      }
    }

    // Delete the original long edge
    executeCommand(DeleteEdgeCommand(edgeId: edgeId, snapshot: edge));

    final createdEdges = <MandapEdge>[];
    MandapEdge? targetedEdge;

    for (int i = 0; i < uniquePoints.length - 1; i++) {
      final sId = uniquePoints[i].nodeId;
      final eId = uniquePoints[i + 1].nodeId;
      if (sId == eId) continue;

      final subEdge = MandapEdge(
        id: EdgeId('e_sub_${DateTime.now().microsecondsSinceEpoch}_${_nodeSequence++}_$i'),
        startNodeId: sId,
        endNodeId: eId,
        role: edge.role,
        profile: edge.profile,
      );
      executeCommand(CreateTrussMemberCommand(newEdge: subEdge));
      createdEdges.add(subEdge);

      if (i == targetK) {
        targetedEdge = subEdge;
      }
    }

    return (createdEdges: createdEdges, targetedEdge: targetedEdge ?? createdEdges.last);
  }

  void _deleteEdge(EdgeId edgeId, {double? worldX, double? worldZ}) {
    final edge = layout.edges[edgeId];
    if (edge == null) return;

    if (worldX != null && worldZ != null) {
      final subResult = _subdivideEdgeForInteraction(edgeId, worldX: worldX, worldZ: worldZ);
      if (subResult.createdEdges.isNotEmpty) {
        if (subResult.createdEdges.length == 1) {
          executeCommand(DeleteEdgeCommand(
            edgeId: edgeId,
            snapshot: edge,
          ));
        } else if (subResult.targetedEdge != null) {
          executeCommand(DeleteEdgeCommand(
            edgeId: subResult.targetedEdge!.id,
            snapshot: subResult.targetedEdge!,
          ));
        }

        if (selectedEdgeId == edgeId || (subResult.targetedEdge != null && selectedEdgeId == subResult.targetedEdge!.id)) {
          selectedEdgeId = null;
        }
        notifyListeners();
        return;
      }
    }

    executeCommand(DeleteEdgeCommand(
      edgeId: edgeId,
      snapshot: edge,
    ));

    if (selectedEdgeId == edgeId) selectedEdgeId = null;
    notifyListeners();
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
