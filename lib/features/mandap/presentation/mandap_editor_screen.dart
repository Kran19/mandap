import 'package:flutter/material.dart';
import '../application/editor_mode.dart';
import '../application/mandap_editor_controller.dart';
import '../domain/entities/edge_id.dart';
import '../domain/entities/mandap_preset.dart';
import '../domain/entities/node_id.dart';
import 'top_view_2d/mandap_2d_interactive_painter.dart';
import 'viewport_transform.dart';
import 'widgets/3d/mandap_3d_controller.dart';
import 'widgets/3d/mandap_3d_view.dart';
import 'widgets/bom_panel.dart';
import 'widgets/editor_mode_bar.dart';
import 'widgets/selection_sheet.dart';

enum _ViewMode { topView2D, view3D }

/// Primary Mandap Layout Editor screen.
///
/// Layout (phone portrait):
///   AppBar (slim — only logo + undo/redo/preset)
///   ├── Viewport (Expanded — 2D or 3D)
///   │   └── BomPanel overlay (DraggableScrollableSheet)
///   │   └── SelectionSheet (bottom slide-up when selected)
///   └── EditorModeBar (64 dp, fixed bottom)
///
/// The AppBar is deliberately minimal to avoid overflow on 360dp screens.
class MandapEditorScreen extends StatefulWidget {
  const MandapEditorScreen({super.key});

  @override
  State<MandapEditorScreen> createState() => MandapEditorScreenState();
}

class MandapEditorScreenState extends State<MandapEditorScreen> {
  late MandapEditorController controller;
  late Mandap3DController controller3D;
  _ViewMode _viewMode = _ViewMode.topView2D;

  // 2D viewport transform state
  ViewportTransform _transform = ViewportTransform.defaultTransform();

  // Snap cursor for addNode / move modes
  ({double x, double z})? _snapCursor;

  // Canvas size captured from the 2D viewport's LayoutBuilder
  Size _canvasSize = const Size(360, 600);

  // Drag tracking for node move
  Offset? _dragStartScreen;

  @override
  void initState() {
    super.initState();
    controller = MandapEditorController();
    controller3D = Mandap3DController();
    controller.addListener(_onControllerUpdate);
    controller3D.fitCamera(controller.layout);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    controller3D.dispose();
    super.dispose();
  }

  // ── Gesture routing ────────────────────────────────────────────────────────

  void _onTapUp(TapUpDetails details) {
    final screenPos = details.localPosition;
    final world = _transform.screenToWorld(screenPos);

    switch (controller.mode) {
      case EditorMode.view:
        break;

      case EditorMode.select:
        // Priority: nodes first, then edges
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          controller.selectNode(hitNode);
        } else {
          final hitEdge = _hitTestEdge(screenPos);
          if (hitEdge != null) {
            controller.selectEdge(hitEdge);
          } else {
            controller.clearSelection();
          }
        }

      case EditorMode.move:
        // Move is drag-based; tap clears selection
        controller.clearSelection();

      case EditorMode.addNode:
        final snapped = _transform.snapToGrid(world.x, world.z);
        controller.addNode(x: snapped.x, z: snapped.z);

      case EditorMode.addEdge:
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          controller.handleAddEdgeTap(hitNode);
        } else {
          // Tap on empty space in addEdge: place a new node then start edge from it
          final snapped = _transform.snapToGrid(world.x, world.z);
          final newNodeId = controller.addNode(x: snapped.x, z: snapped.z);
          controller.handleAddEdgeTap(newNodeId);
        }

      case EditorMode.delete:
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          controller.deleteNode(hitNode);
        } else {
          final hitEdge = _hitTestEdge(screenPos);
          if (hitEdge != null) controller.deleteEdge(hitEdge);
        }
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (controller.mode == EditorMode.move &&
        controller.selectedNodeId != null) {
      _dragStartScreen = details.localPosition;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (controller.mode == EditorMode.view) {
      // Pan the viewport
      setState(() {
        _transform = _transform.pan(details.delta.dx, details.delta.dy);
      });
      return;
    }

    if (controller.mode == EditorMode.move &&
        controller.selectedNodeId != null &&
        _dragStartScreen != null) {
      // Preview snap cursor
      final world = _transform.screenToWorld(details.localPosition);
      final snapped = _transform.snapToGrid(world.x, world.z);
      setState(() {
        _snapCursor = snapped;
      });
      return;
    }

    if (controller.mode == EditorMode.addNode) {
      final world = _transform.screenToWorld(details.localPosition);
      final snapped = _transform.snapToGrid(world.x, world.z);
      setState(() {
        _snapCursor = snapped;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (controller.mode == EditorMode.move &&
        controller.selectedNodeId != null &&
        _snapCursor != null) {
      controller.moveNode(
        nodeId: controller.selectedNodeId!,
        newX: _snapCursor!.x,
        newZ: _snapCursor!.z,
      );
    }
    setState(() {
      _snapCursor = null;
      _dragStartScreen = null;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      setState(() {
        _transform = _transform.zoom(details.scale, details.localFocalPoint);
      });
    } else {
      // Single-finger pan
      if (controller.mode == EditorMode.view) {
        setState(() {
          _transform = _transform.pan(
            details.focalPointDelta.dx,
            details.focalPointDelta.dy,
          );
        });
      }
    }
  }

  // ── Hit testing ────────────────────────────────────────────────────────────

  NodeId? _hitTestNode(Offset screenPos) {
    for (final node in controller.layout.nodes.values) {
      if (_transform.hitTestNode(screenPos, node.x, node.z)) {
        return node.id;
      }
    }
    return null;
  }

  EdgeId? _hitTestEdge(Offset screenPos) {
    for (final edge in controller.layout.edges.values) {
      final startNode = controller.layout.getNode(edge.startNodeId);
      final endNode = controller.layout.getNode(edge.endNodeId);
      if (startNode == null || endNode == null) continue;
      if (_transform.hitTestEdge(
        screenPos,
        startNode.x,
        startNode.z,
        endNode.x,
        endNode.z,
      )) {
        return edge.id;
      }
    }
    return null;
  }

  // ── Fit view ────────────────────────────────────────────────────────────────

  void _fitView(Size canvasSize) {
    setState(() {
      if (_viewMode == _ViewMode.view3D) {
        controller3D.fitCamera(controller.layout);
      } else {
        _transform = ViewportTransform.fitToLayout(
          layout: controller.layout,
          canvasSize: canvasSize,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        controller.selectedEdgeId != null || controller.selectedNodeId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // ── Viewport ────────────────────────────────────────────────
                Positioned.fill(child: _buildViewport()),

                // ── Fit View FAB ─────────────────────────────────────────────
                Positioned(top: 10, right: 10, child: _buildFitButton()),

                // ── Mode hint banner ─────────────────────────────────────────
                Positioned(top: 10, left: 10, child: _buildModeHint()),

                // ── BOM Panel ────────────────────────────────────────────────
                if (!hasSelection)
                  Positioned.fill(child: BomPanel(controller: controller)),

                // ── Selection sheet ──────────────────────────────────────────
                if (hasSelection)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SelectionSheet(controller: controller),
                  ),
              ],
            ),
          ),

          // ── Mode Bar ───────────────────────────────────────────────────────
          EditorModeBar(
            currentMode: controller.mode,
            onModeChanged: (m) {
              controller.setMode(m);
              setState(() => _snapCursor = null);
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      titleSpacing: 12,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.architecture, size: 18, color: Color(0xFF2563EB)),
            SizedBox(width: 4),
            Text(
              'MANDAP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Preset selector popup menu
        PopupMenuButton<MandapPreset>(
          tooltip: 'Select Layout Preset',
          icon: const Icon(Icons.dashboard_outlined, color: Colors.white70),
          color: const Color(0xFF1E293B),
          onSelected: (p) {
            controller.loadPreset(p);
            setState(() => _snapCursor = null);
          },
          itemBuilder: (context) => MandapPreset.availablePresets().map((p) {
            final isSelected =
                p.id == controller.currentPreset.id &&
                !controller.isCustomLayout;
            return PopupMenuItem(
              value: p,
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        // 2D / 3D toggle
        _ViewToggle(
          current: _viewMode,
          onChanged: (m) => setState(() => _viewMode = m),
        ),
        // Undo
        IconButton(
          icon: const Icon(Icons.undo, size: 20),
          tooltip: 'Undo',
          onPressed: controller.history.canUndo
              ? () => controller.undo()
              : null,
        ),
        // Redo
        IconButton(
          icon: const Icon(Icons.redo, size: 20),
          tooltip: 'Redo',
          onPressed: controller.history.canRedo
              ? () => controller.redo()
              : null,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildViewport() {
    if (_viewMode == _ViewMode.view3D) {
      return Stack(
        children: [
          Mandap3DView(controller: controller, controller3D: controller3D),
          Positioned(
            bottom: 8,
            left: 8,
            child: _infoChip(
              '${controller.isCustomLayout ? "Custom" : controller.currentPreset.name} · ${controller.result.totalPoleCount} poles',
            ),
          ),
        ],
      );
    }

    // 2D interactive viewport
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        // Capture canvas size for fit-view
        if (_canvasSize != canvasSize) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _canvasSize = canvasSize),
          );
        }
        return GestureDetector(
          onTapUp: _onTapUp,
          onPanStart: controller.mode == EditorMode.move ? _onPanStart : null,
          onPanUpdate:
              controller.mode == EditorMode.move ||
                  controller.mode == EditorMode.addNode
              ? _onPanUpdate
              : null,
          onPanEnd: controller.mode == EditorMode.move ? _onPanEnd : null,
          onScaleUpdate: controller.mode == EditorMode.view
              ? _onScaleUpdate
              : null,
          child: CustomPaint(
            painter: Mandap2DInteractivePainter(
              layout: controller.layout,
              result: controller.result,
              transform: _transform,
              mode: controller.mode,
              selectedEdgeId: controller.selectedEdgeId,
              selectedNodeId: controller.selectedNodeId,
              pendingEdgeSourceId: controller.pendingEdgeStartNodeId,
              snapCursor: _snapCursor,
            ),
            size: canvasSize,
          ),
        );
      },
    );
  }

  Widget _buildFitButton() {
    return GestureDetector(
      onTap: () => _fitView(_canvasSize),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fit_screen, size: 14, color: Colors.white70),
            SizedBox(width: 4),
            Text('Fit', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildModeHint() {
    final String hint;
    switch (controller.mode) {
      case EditorMode.view:
        hint = 'Drag to pan · Pinch to zoom';
      case EditorMode.select:
        hint = 'Tap node or edge to select';
      case EditorMode.move:
        hint = controller.selectedNodeId != null
            ? 'Drag node to move'
            : 'Select a node first';
      case EditorMode.addNode:
        hint = 'Tap to place a node';
      case EditorMode.addEdge:
        hint = controller.pendingEdgeStartNodeId == null
            ? 'Tap source node (or empty space)'
            : 'Tap target node to complete edge';
      case EditorMode.delete:
        hint = 'Tap node or edge to delete';
    }
    return _infoChip(hint);
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }
}

// ── 2D/3D toggle button ────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;

  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            label: '2D',
            isActive: current == _ViewMode.topView2D,
            onTap: () => onChanged(_ViewMode.topView2D),
          ),
          const SizedBox(width: 4),
          _Chip(
            label: '3D',
            isActive: current == _ViewMode.view3D,
            onTap: () => onChanged(_ViewMode.view3D),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}
