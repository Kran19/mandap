import 'package:flutter/foundation.dart';

import '../domain/entities/edge_id.dart';
import '../domain/entities/mandap_layout.dart';
import '../domain/entities/mandap_node.dart';
import '../domain/entities/node_id.dart';
import '../domain/entities/mandap_preset.dart';
import '../domain/entities/truss_catalog.dart';
import '../domain/entities/truss_inventory.dart';
import '../domain/services/mandap_calculation_engine.dart';
import '../domain/value_objects/mandap_calculation_result.dart';
import '../domain/entities/mandap_zone.dart';
import 'commands/add_edge_command.dart';
import 'commands/add_node_command.dart';
import 'commands/command_history.dart';
import 'commands/delete_edge_command.dart';
import 'commands/delete_node_command.dart';
import 'commands/mandap_command.dart';
import 'commands/move_node_command.dart';
import 'commands/update_node_dimensions_command.dart';
import 'commands/resize_edge_command.dart';
import 'editor_mode.dart';
import '../domain/value_objects/grid_settings.dart';

/// Central application controller for managing Mandap layout state, editor mode,
/// calculations, presets, and undo/redo history.
class MandapEditorController extends ChangeNotifier {
  final MandapCalculationEngine engine;
  late TrussCatalog catalog;
  late TrussInventory inventory;
  late MandapLayout layout;
  late MandapCalculationResult result;
  final CommandHistory history = CommandHistory();

  MandapPreset currentPreset = MandapPreset.rectangle40x30();
  EdgeId? selectedEdgeId;
  NodeId? selectedNodeId;
  bool isShortageTestMode = false;
  bool isCustomLayout = false;

  EditorMode _mode = EditorMode.view;
  EditorMode get mode => _mode;

  /// In addEdge mode: the first tapped node awaiting a second tap.
  NodeId? pendingEdgeStartNodeId;

  // ── Grid Settings ──────────────────────────────────────────────────────────
  GridSettings gridSettings = const GridSettings(majorSpacing: 10.0, minorSpacing: 0.5);
  
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

  MandapEditorController({this.engine = const MandapCalculationEngine()}) {
    catalog = TrussCatalog.sample1To20Ft();
    _initLayout();
  }

  void _initLayout() {
    layout = currentPreset.createLayout();
    _recalculate();
  }

  void _recalculate() {
    isCustomLayout = history.canUndo;
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
    notifyListeners();
  }

  // ── Mode management ────────────────────────────────────────────────────────

  NodeType pendingNodeType = NodeType.corner;

  /// Switches the editor to [newMode] and clears any pending state.
  void setMode(EditorMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    pendingEdgeStartNodeId = null;
    // Deselect on mode change unless switching to move/select
    if (newMode != EditorMode.select && newMode != EditorMode.move) {
      selectedEdgeId = null;
      selectedNodeId = null;
    }
    notifyListeners();
  }

  void setPendingNodeType(NodeType type) {
    pendingNodeType = type;
    notifyListeners();
  }

  // ── Preset management ──────────────────────────────────────────────────────

  /// Loads a new Mandap layout preset, resetting history and selection.
  void loadPreset(MandapPreset preset) {
    currentPreset = preset;
    isCustomLayout = false;
    layout = preset.createLayout();
    selectedEdgeId = null;
    selectedNodeId = null;
    pendingEdgeStartNodeId = null;
    history.clear();
    _recalculate();
  }

  /// Loads a custom layout directly (used for live preview during drag gestures).
  void loadCustomLayout(MandapLayout newLayout) {
    layout = newLayout;
    isCustomLayout = true;
    _recalculate();
  }

  /// Executes a [MandapCommand] onto the command history.
  void executeCommand(MandapCommand cmd) {
    layout = history.executeCommand(cmd, layout);
    _recalculate();
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  /// Selects or deselects an edge.
  void selectEdge(EdgeId? edgeId) {
    selectedEdgeId = edgeId;
    selectedNodeId = null;
    notifyListeners();
  }

  /// Selects or deselects a node.
  void selectNode(NodeId? nodeId) {
    selectedNodeId = nodeId;
    selectedEdgeId = null;
    notifyListeners();
  }

  /// Clears all selection.
  void clearSelection() {
    selectedEdgeId = null;
    selectedNodeId = null;
    pendingEdgeStartNodeId = null;
    notifyListeners();
  }

  // ── Geometry mutations (all via CommandHistory) ────────────────────────────

  /// Resizes an edge by moving [movingNodeId] to ([newX], [newZ]).
  void resizeEdge({
    required EdgeId edgeId,
    required NodeId movingNodeId,
    required double newX,
    required double newZ,
  }) {
    final node = layout.getNode(movingNodeId);
    if (node == null) return;

    final cmd = ResizeEdgeCommand(
      edgeId: edgeId,
      movingNodeId: movingNodeId,
      oldX: node.x,
      oldZ: node.z,
      newX: newX,
      newZ: newZ,
    );

    layout = history.executeCommand(cmd, layout);
    _recalculate();
  }

  /// Translates a node to ([newX], [newZ]).
  void moveNode({
    required NodeId nodeId,
    required double newX,
    required double newZ,
  }) {
    final node = layout.getNode(nodeId);
    if (node == null) return;

    final cmd = MoveNodeCommand(
      nodeId: nodeId,
      oldX: node.x,
      oldZ: node.z,
      newX: newX,
      newZ: newZ,
    );

    layout = history.executeCommand(cmd, layout);
    _recalculate();
  }

  /// Updates node physical dimensions.
  void updateNodeDimensions({
    required NodeId nodeId,
    double? newWidth,
    double? newDepth,
    double? newHeight,
    required double newRotation,
    required double newElevation,
  }) {
    final node = layout.getNode(nodeId);
    if (node == null) return;

    final cmd = UpdateNodeDimensionsCommand(
      nodeId: nodeId,
      oldWidth: node.width,
      oldDepth: node.depth,
      oldHeight: node.height,
      oldRotation: node.rotation,
      oldElevation: node.elevation,
      newWidth: newWidth,
      newDepth: newDepth,
      newHeight: newHeight,
      newRotation: newRotation,
      newElevation: newElevation,
    );

    layout = history.executeCommand(cmd, layout);
    _recalculate();
  }

  NodeId addNode({required double x, required double z, NodeType type = NodeType.corner}) {
    final node = createNode(x: x, z: z, type: type);
    final cmd = AddNodeCommand(node: node);
    layout = history.executeCommand(cmd, layout);
    _recalculate();
    return node.id;
  }


  /// Adds an edge between [startNodeId] and [endNodeId].
  /// Returns false if either node does not exist.
  bool addEdge({required NodeId startNodeId, required NodeId endNodeId}) {
    if (layout.getNode(startNodeId) == null) return false;
    if (layout.getNode(endNodeId) == null) return false;
    if (startNodeId == endNodeId) return false;

    final edgeId = generateEdgeId();
    final cmd = AddEdgeCommand(
      edgeId: edgeId,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
    layout = history.executeCommand(cmd, layout);
    _recalculate();
    return true;
  }

  /// Handles the addEdge polyline/chain drawing workflow.
  /// First tap sets [pendingEdgeStartNodeId]; second tap creates an edge and
  /// sets [pendingEdgeStartNodeId] to the target node so user can continuously
  /// draw connected segments (A→B, B→C, C→D...). Tapping the same node stops the chain.
  void handleAddEdgeTap(NodeId tappedNodeId) {
    if (pendingEdgeStartNodeId == null) {
      pendingEdgeStartNodeId = tappedNodeId;
      notifyListeners();
    } else if (pendingEdgeStartNodeId == tappedNodeId) {
      // Tapping same node cancels/completes current chain
      pendingEdgeStartNodeId = null;
      notifyListeners();
    } else {
      final success = addEdge(
        startNodeId: pendingEdgeStartNodeId!,
        endNodeId: tappedNodeId,
      );
      if (success) {
        pendingEdgeStartNodeId = tappedNodeId; // Continue chain drawing
      } else {
        pendingEdgeStartNodeId = null;
      }
      notifyListeners();
    }
  }

  /// Deletes the currently selected node (and its connected edges) or edge.
  void deleteSelected() {
    if (selectedNodeId != null) {
      _deleteNode(selectedNodeId!);
    } else if (selectedEdgeId != null) {
      _deleteEdge(selectedEdgeId!);
    }
  }

  /// Deletes a specific node by ID.
  void deleteNode(NodeId nodeId) => _deleteNode(nodeId);

  /// Deletes a specific edge by ID.
  void deleteEdge(EdgeId edgeId) => _deleteEdge(edgeId);


  void _deleteNode(NodeId nodeId) {
    final node = layout.getNode(nodeId);
    if (node == null) return;

    final connectedEdges = layout.edges.values
        .where((e) => e.startNodeId == nodeId || e.endNodeId == nodeId)
        .toList();

    final cmd = DeleteNodeCommand(
      nodeId: nodeId,
      nodeSnapshot: node,
      connectedEdgeSnapshots: connectedEdges,
    );

    layout = history.executeCommand(cmd, layout);
    selectedNodeId = null;
    selectedEdgeId = null;
    _recalculate();
  }

  void _deleteEdge(EdgeId edgeId) {
    final edge = layout.getEdge(edgeId);
    if (edge == null) return;

    final cmd = DeleteEdgeCommand(edgeId: edgeId, snapshot: edge);
    layout = history.executeCommand(cmd, layout);
    selectedEdgeId = null;
    _recalculate();
  }

  // ── Inventory scenario ─────────────────────────────────────────────────────

  /// Toggles stock shortage test scenario.
  void toggleShortageMode(bool enableShortage) {
    isShortageTestMode = enableShortage;
    _recalculate();
  }

  // ── Undo / Redo ────────────────────────────────────────────────────────────

  /// Undoes last command if available.
  void undo() {
    if (!history.canUndo) return;
    layout = history.undo(layout);
    selectedEdgeId = null;
    selectedNodeId = null;
    _recalculate();
  }

  /// Redoes last undone command if available.
  void redo() {
    if (!history.canRedo) return;
    layout = history.redo(layout);
    _recalculate();
  }
}
