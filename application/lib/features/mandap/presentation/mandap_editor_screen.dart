import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../application/editor_mode.dart';
import '../application/mandap_editor_controller.dart';
import '../domain/entities/edge_id.dart';
import '../domain/generators/base_truss_architecture_generator.dart';
import '../domain/entities/mandap_preset.dart';
import '../domain/entities/node_id.dart';
import '../domain/entities/mandap_node.dart';
import '../domain/entities/mandap_layout.dart';
import 'top_view_2d/mandap_2d_interactive_painter.dart';
import 'viewport_transform.dart';
import 'widgets/3d/mandap_3d_controller.dart';
import 'widgets/3d/mandap_3d_view.dart';
import '../../auth/application/bootstrap_coordinator.dart';
import '../../projects/infrastructure/projects_repository.dart';
import '../../projects/infrastructure/project_version_repository.dart';
import '../../projects/infrastructure/local_project_store.dart';
import '../../projects/application/project_sync_service.dart';
import '../../projects/domain/sync_state.dart';
import '../../projects/domain/local_project_sync_metadata.dart';
import '../../mandap/infrastructure/layout_serializer.dart';
import '../application/commands/add_external_structure_command.dart';
import '../domain/value_objects/structural_analysis_report.dart';
import '../../../core/errors/api_exceptions.dart';
import 'editor/widgets/cad_header_bar.dart';
import 'editor/widgets/tool_rail_widget.dart';
import 'editor/widgets/floating_warning_chip.dart';
import 'editor/widgets/inspector_bom_panel.dart';

enum ViewMode { topView2D, view3D }

/// Primary Mandap Layout Editor screen.
/// CAD-Grade Event Structure Design Canvas
class MandapEditorScreen extends StatefulWidget {
  final String projectId;
  const MandapEditorScreen({super.key, required this.projectId});

  @override
  State<MandapEditorScreen> createState() => MandapEditorScreenState();
}

class MandapEditorScreenState extends State<MandapEditorScreen> {
  late MandapEditorController controller;
  late Mandap3DController controller3D;
  ViewMode _viewMode = ViewMode.topView2D;

  String? _projectName;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isMobileInspectorOpen = false;
  bool _isToolRailOpen = true;
  bool _isMeasuring = false;
  bool _isOrthographic = false;
  ProjectSyncService? _syncService;
  MandapLayout? _lastNotifiedLayout;

  // 2D viewport transform state
  ViewportTransform _transform = ViewportTransform.defaultTransform();

  // Snap cursor for addNode / move modes
  ({double x, double z})? _snapCursor;

  // Canvas size captured from the 2D viewport's LayoutBuilder
  Size _canvasSize = const Size(360, 600);

  // Drag tracking for node move
  Offset? _dragStartScreen;
  ({double x, double z})? _dragOffsetWorld;

  // Zone drawing state
  ({double x, double z})? _zoneDragStartWorld;
  ({double x, double z})? _zoneDragEndWorld;

  @override
  void initState() {
    super.initState();
    controller = MandapEditorController();
    controller3D = Mandap3DController();
    controller.addListener(_onControllerUpdate);
    controller3D.fitCamera(controller.layout);
    
    // Fast path: Immediately load local layout cache so screen renders instantly (<5ms)
    _loadLocalLayoutFast();

    // Defer network sync until after init so we can use context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjectData();
    });
  }

  Future<void> _loadLocalLayoutFast() async {
    try {
      final store = LocalProjectStore();
      final local = await store.getLayout(widget.projectId);
      if (local != null && mounted) {
        setState(() {
          controller.layout = local;
          _lastNotifiedLayout = local;
          _isLoading = false;
        });
        controller3D.fitCamera(local);
      }
    } catch (_) {}
  }

  Future<void> _loadProjectData() async {
    if (widget.projectId == 'new' || widget.projectId.isEmpty) {
      if (mounted) {
        setState(() {
          _projectName = 'New Project';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final coordinator = context.read<BootstrapCoordinator>();
      final repo = context.read<ProjectsRepository>();
      final versionRepo = context.read<ProjectVersionRepository>();

      final orgId = coordinator.current.user!.organizationId!;
      final project = await repo.getProject(orgId, widget.projectId);

      if (project.status != 'ACTIVE') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot edit an archived project.')),
          );
          context.go('/projects');
        }
        return;
      }

      final store = LocalProjectStore();
      final existingMeta = await store.getMetadata(widget.projectId);
      final isLocallyDirty = existingMeta?.dirty == true;

      // ── Step 1: Fetch remote versions if not locally dirty ──────────
      try {
        if (!isLocallyDirty) {
          final versions = await versionRepo.getVersions(orgId, widget.projectId);
          final latestRemote = versions.isNotEmpty ? versions.first : null;

          if (latestRemote != null && latestRemote.layoutData != null) {
            // Server has data — use it
            controller.layout = LayoutSerializer.fromJson(latestRemote.layoutData!);
            _lastNotifiedLayout = controller.layout;
            await store.saveLayout(widget.projectId, controller.layout);
            final meta = LocalProjectSyncMetadata(
              projectId: widget.projectId,
              baseVersionId: latestRemote.id,
              syncState: SyncState.CLEAN,
              dirty: false,
              lastSyncedAt: DateTime.now(),
            );
            await store.saveMetadata(meta);
          } else {
            // No remote version yet (brand-new project) — fall back to local cache
            final localLayout = await store.getLayout(widget.projectId);
            if (localLayout != null) {
              controller.layout = localLayout;
              _lastNotifiedLayout = localLayout;
            }
          }
        } else {
          // Project has pending local changes (e.g. freshly created from wizard)
          final localLayout = await store.getLayout(widget.projectId);
          if (localLayout != null) {
            controller.layout = localLayout;
            _lastNotifiedLayout = localLayout;
          }
        }
      } on RateLimitedException {
        print('[Editor] Rate limited loading versions — using local cache');
        final localLayout = await store.getLayout(widget.projectId);
        if (localLayout != null) controller.layout = localLayout;
      } catch (fetchErr) {
        print('[Editor] Remote layout check: $fetchErr — using local cache');
        final localLayout = await store.getLayout(widget.projectId);
        if (localLayout != null) {
          controller.layout = localLayout;
          _lastNotifiedLayout = localLayout;
        }
      }

      // ── Step 2: Set up sync service AFTER loading layout ─────────────────
      _syncService = ProjectSyncService(
        organizationId: orgId,
        projectId: widget.projectId,
        store: store,
        versionRepo: versionRepo,
      );
      await _syncService!.initialize();
      _syncService!.syncState.addListener(_onSyncStateChanged);

      if (mounted) {
        setState(() {
          _projectName = project.name;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      print('Error loading project: $e\n$s');
      if (mounted) {
        setState(() {
          _projectName = _projectName ?? 'Project';
          _isLoading = false;
        });
      }
    }
  }


  void _onSyncStateChanged() {
    if (mounted) setState(() {});
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
    
    // Trigger sync on layout changes (debounce handled in service)
    // Only if not loading and we have a sync service
    if (!_isLoading && _syncService != null) {
       // Prevent marking as modified for non-layout changes (e.g., selection clicks)
       if (_lastNotifiedLayout != controller.layout) {
         _lastNotifiedLayout = controller.layout;
         _syncService!.store.getMetadata(widget.projectId).then((meta) {
           _syncService!.onLayoutModified(controller.layout, meta?.baseVersionId ?? '');
         });
       }
    }
  }

  double _getDynamicSnapGrid() {
    if (!controller.gridSettings.snapEnabled) return 0.001; // effectively no snap
    if (_transform.scale > 15.0) return controller.gridSettings.minorSpacing;
    return controller.gridSettings.majorSpacing;
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
        final snapped = _transform.snapToGrid(world.x, world.z, gridSpacing: _getDynamicSnapGrid());
        controller.addNode(x: snapped.x, z: snapped.z, type: NodeType.corner);

      case EditorMode.addPole:
        final snapped = _transform.snapToGrid(world.x, world.z, gridSpacing: _getDynamicSnapGrid());
        controller.addNode(x: snapped.x, z: snapped.z, type: NodeType.pole);

      case EditorMode.addEdge:
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          controller.handleAddEdgeTap(hitNode);
        } else {
          // Tap on empty space in addEdge: place a new node then start edge from it
          final snapped = _transform.snapToGrid(world.x, world.z, gridSpacing: _getDynamicSnapGrid());
          final newNodeId = controller.addNode(x: snapped.x, z: snapped.z);
          controller.handleAddEdgeTap(newNodeId);
        }

      case EditorMode.delete:
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          final node = controller.layout.getNode(hitNode);
          if (node != null && node.hasPole) {
            _showNodeEraserOptions(node);
          } else {
            controller.deleteNode(hitNode);
          }
        } else {
          final hitEdge = _hitTestEdge(screenPos);
          if (hitEdge != null) {
            controller.deleteEdge(hitEdge);
          }
        }
        
      case EditorMode.addFlooring:
      case EditorMode.addStage:
        break;
    }
  }

  void _onPanStart(DragStartDetails details) {
    // If grabbing a node in select or move mode, immediately begin drag
    final hitNode = _hitTestNode(details.localPosition);
    if (hitNode != null &&
        (controller.mode == EditorMode.select || controller.mode == EditorMode.move)) {
      controller.selectNode(hitNode);
      _dragStartScreen = details.localPosition;
      final node = controller.layout.getNode(hitNode);
      if (node != null) {
        final worldGrab = _transform.screenToWorld(details.localPosition);
        _dragOffsetWorld = (x: worldGrab.x - node.x, z: worldGrab.z - node.z);
      }
      return;
    }

    if (controller.mode == EditorMode.move &&
        controller.selectedNodeId != null) {
      _dragStartScreen = details.localPosition;
      final node = controller.layout.getNode(controller.selectedNodeId!);
      if (node != null) {
        final worldGrab = _transform.screenToWorld(details.localPosition);
        _dragOffsetWorld = (x: worldGrab.x - node.x, z: worldGrab.z - node.z);
      }
    } else if (controller.mode == EditorMode.addFlooring || controller.mode == EditorMode.addStage) {
      final worldGrab = _transform.screenToWorld(details.localPosition);
      final snapped = _transform.snapToGrid(worldGrab.x, worldGrab.z, gridSpacing: _getDynamicSnapGrid());
      setState(() {
        _zoneDragStartWorld = snapped;
        _zoneDragEndWorld = snapped;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if ((controller.mode == EditorMode.move || controller.mode == EditorMode.select) &&
        controller.selectedNodeId != null &&
        _dragStartScreen != null) {
      // Preview snap cursor
      final worldGrab = _transform.screenToWorld(details.localPosition);
      final targetX = worldGrab.x - (_dragOffsetWorld?.x ?? 0.0);
      final targetZ = worldGrab.z - (_dragOffsetWorld?.z ?? 0.0);
      
      final snapped = _transform.snapToGrid(targetX, targetZ, gridSpacing: _getDynamicSnapGrid());
      setState(() {
        _snapCursor = snapped;
      });
      return;
    }

    if (controller.mode == EditorMode.view || controller.mode == EditorMode.select) {
      // Pan the viewport
      setState(() {
        _transform = _transform.pan(details.delta.dx, details.delta.dy);
      });
      return;
    }

    if (controller.mode == EditorMode.addNode || controller.mode == EditorMode.addPole) {
      final world = _transform.screenToWorld(details.localPosition);
      final snapped = _transform.snapToGrid(world.x, world.z, gridSpacing: _getDynamicSnapGrid());
      setState(() {
        _snapCursor = snapped;
      });
    } else if (controller.mode == EditorMode.addFlooring || controller.mode == EditorMode.addStage) {
      if (_zoneDragStartWorld != null) {
        final world = _transform.screenToWorld(details.localPosition);
        final snapped = _transform.snapToGrid(world.x, world.z, gridSpacing: _getDynamicSnapGrid());
        setState(() {
          _zoneDragEndWorld = snapped;
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if ((controller.mode == EditorMode.move || controller.mode == EditorMode.select) &&
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
      _dragOffsetWorld = null;
      _zoneDragStartWorld = null;
      _zoneDragEndWorld = null;
    });
  }

  double _lastScale = 1.0;

  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1 && details.scale != 1.0) {
      // Pinch to zoom: compute incremental frame-to-frame delta to avoid exponential runaway
      final double currentScale = details.scale;
      final double scaleDelta = (_lastScale > 0.0) ? (currentScale / _lastScale) : 1.0;
      _lastScale = currentScale;

      // Low sensitivity factor (0.4) prevents wild jumps, giving smooth, controllable zooming
      const double zoomSensitivity = 0.40;
      final double dampedFactor = 1.0 + (scaleDelta - 1.0) * zoomSensitivity;

      if (dampedFactor > 0.0 && (dampedFactor - 1.0).abs() > 0.0001) {
        setState(() {
          _transform = _transform.zoom(dampedFactor, details.localFocalPoint);
          _transform = _transform.pan(
            details.focalPointDelta.dx,
            details.focalPointDelta.dy,
          );
        });
      } else if (details.focalPointDelta != Offset.zero) {
        setState(() {
          _transform = _transform.pan(
            details.focalPointDelta.dx,
            details.focalPointDelta.dy,
          );
        });
      }
    } else {
      // Single-finger pan: reset scale baseline so pinch starts smoothly
      _lastScale = details.scale;
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

  void _onScaleEnd(ScaleEndDetails details) {
    _lastScale = 1.0;
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
      if (_viewMode == ViewMode.view3D) {
        controller3D.fitCamera(controller.layout);
      } else {
        _transform = ViewportTransform.fitToLayout(
          layout: controller.layout,
          canvasSize: canvasSize,
        );
      }
    });
  }

  void _resetView() {
    setState(() {
      if (_viewMode == ViewMode.view3D) {
        controller3D.fitCamera(controller.layout);
      } else {
        _transform = ViewportTransform.defaultTransform();
      }
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveNow() async {
    if (_syncService == null || _isSaving) return;
    setState(() => _isSaving = true);
    await _syncService!.saveNow();
    if (mounted) setState(() => _isSaving = false);
  }

  bool get _hasDirtyChanges =>
      _syncService != null &&
      _syncService!.syncState.value == SyncState.DIRTY;

  Future<bool> _onWillPop() async {
    if (!_hasDirtyChanges) return true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 10),
            Text('Unsaved Changes', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save & Leave'),
            onPressed: () => Navigator.of(ctx).pop('save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveNow();
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false; // cancel
  }

  void _handleDeletePressed() {
    final hasSelection =
        controller.selectedEdgeId != null || controller.selectedNodeId != null;
    if (hasSelection) {
      controller.deleteSelected();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // If already in delete mode, toggle off to view mode
    if (controller.mode == EditorMode.delete) {
      controller.setMode(EditorMode.view);
      return;
    }

    final hasItems = controller.layout.nodes.isNotEmpty ||
        controller.layout.edges.isNotEmpty ||
        controller.layout.zones.isNotEmpty;

    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Canvas is empty — nothing to delete'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Delete Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.touch_app_rounded, color: Color(0xFFEF4444)),
                ),
                title: const Text(
                  'Tap to Delete Elements',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tap any pillar, beam, or flooring to delete it',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.setMode(EditorMode.delete);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete Mode: Tap any element to delete it'),
                      duration: Duration(seconds: 3),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                ),
                title: const Text(
                  'Clear All Components',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Remove all pillars, beams, and zones from canvas',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: const Text('Clear Entire Design?', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'All pillars, beams, and flooring will be removed.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    controller.clearAll();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Canvas cleared'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted) context.go('/modules');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19), // Dark blueprint background
        body: SafeArea(
          child: Column(
            children: [
              // Top CAD Header Bar
              CadHeaderBar(
                controller: controller,
                projectName: _projectName ?? 'Project 01',
                onProjectNameChanged: (val) => setState(() => _projectName = val),
                syncService: _syncService,
                onSave: _saveNow,
                viewMode: _viewMode,
                onViewModeChanged: (m) => setState(() => _viewMode = m),
              ),

              // Main Workspace Canvas + Left Tool Rail + Right Inspector/BOM
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 820;

                    final canvasStack = Stack(
                      children: [
                        // Viewport (2D / 3D)
                        Positioned.fill(child: _buildViewport()),

                        // Left Floating Tool Rail (Collapsible)
                        if (_isToolRailOpen)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: ToolRailWidget(
                              controller: controller,
                              onGridSettings: _showGridSettings,
                              onEditorSettings: _showTrussSizeDialog,
                              isMeasuring: _isMeasuring,
                              onToggleMeasure: () => setState(() => _isMeasuring = !_isMeasuring),
                              onConfigureDimensions: _showDimensionsDialog,
                              onToggleCollapse: () => setState(() => _isToolRailOpen = false),
                            ),
                          )
                        else
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1523).withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF1E293B)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF60A5FA), size: 22),
                                tooltip: 'Show Tools',
                                onPressed: () => setState(() => _isToolRailOpen = true),
                              ),
                            ),
                          ),

                        // Floating Warning Chip (pinned top-center)
                        Positioned(
                          top: 12,
                          left: 90,
                          right: isWide ? 90 : 64,
                          child: FloatingWarningChip(
                            report: controller.structuralReport,
                            onTap: () => _showStructuralReportSheet(controller.structuralReport),
                          ),
                        ),

                        // Bottom-Right Viewport controls (Fit Screen, Reset View)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFitButton(),
                              const SizedBox(width: 8),
                              _buildResetButton(),
                            ],
                          ),
                        ),

                        // Mobile Inspector / BOM toggle button
                        if (!isWide)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _buildMobileInspectorToggle(),
                          ),

                        // Mobile sliding drawer for Inspector / BOM
                        if (!isWide && _isMobileInspectorOpen)
                          Positioned(
                            top: 0,
                            right: 0,
                            bottom: 0,
                            width: 300,
                            child: Material(
                              elevation: 16,
                              color: const Color(0xFF0F1523),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: InspectorBomPanel(
                                      controller: controller,
                                      viewMode: _viewMode,
                                      onViewModeChanged: (m) => setState(() => _viewMode = m),
                                      onFitToScreen: () => _fitView(_canvasSize),
                                      onResetView: _resetView,
                                      onToggleOrthographic: () => setState(() => _isOrthographic = !_isOrthographic),
                                      isOrthographic: _isOrthographic,
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white70),
                                      onPressed: () => setState(() => _isMobileInspectorOpen = false),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: canvasStack),
                          InspectorBomPanel(
                            controller: controller,
                            viewMode: _viewMode,
                            onViewModeChanged: (m) => setState(() => _viewMode = m),
                            onFitToScreen: () => _fitView(_canvasSize),
                            onResetView: _resetView,
                            onToggleOrthographic: () => setState(() => _isOrthographic = !_isOrthographic),
                            isOrthographic: _isOrthographic,
                          ),
                        ],
                      );
                    }

                    return canvasStack;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _resetView,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1523).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF94A3B8)),
            SizedBox(width: 4),
            Text('Reset', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileInspectorToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isMobileInspectorOpen = !_isMobileInspectorOpen),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
      ),
    );
  }
  Widget _buildViewport() {
    if (_viewMode == ViewMode.view3D) {
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
        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent && controller.mode == EditorMode.view) {
              final zoomDelta = pointerSignal.scrollDelta.dy > 0 ? 0.95 : 1.05;
              setState(() {
                _transform = _transform.zoom(zoomDelta, pointerSignal.localPosition);
              });
            }
          },
          child: GestureDetector(
            onTapUp: _onTapUp,
            onPanStart: (controller.mode == EditorMode.move || controller.mode == EditorMode.addFlooring || controller.mode == EditorMode.addStage) ? _onPanStart : null,
            onPanUpdate:
                (controller.mode == EditorMode.move ||
                    controller.mode == EditorMode.addNode ||
                    controller.mode == EditorMode.addPole ||
                    controller.mode == EditorMode.addFlooring || 
                    controller.mode == EditorMode.addStage)
                ? _onPanUpdate
                : null,
            onPanEnd: (controller.mode == EditorMode.move || controller.mode == EditorMode.addFlooring || controller.mode == EditorMode.addStage) ? _onPanEnd : null,
            onScaleStart: controller.mode == EditorMode.view ? _onScaleStart : null,
            onScaleUpdate: controller.mode == EditorMode.view ? _onScaleUpdate : null,
            onScaleEnd: controller.mode == EditorMode.view ? _onScaleEnd : null,
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
                zoneDragStartWorld: _zoneDragStartWorld,
                zoneDragEndWorld: _zoneDragEndWorld,
                gridSettings: controller.gridSettings,
              ),
              size: canvasSize,
            ),
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
          color: const Color(0xFF0D2818).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fit_screen, size: 14, color: Color(0xFF34D399)),
            SizedBox(width: 4),
            Text('Fit', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
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
      case EditorMode.addPole:
        hint = 'Tap to place a node';
      case EditorMode.addEdge:
        hint = controller.pendingEdgeStartNodeId == null
            ? 'Tap source node (or empty space)'
            : 'Tap target node to complete edge';
      case EditorMode.delete:
        hint = 'Tap node or edge to delete';
      case EditorMode.addFlooring:
      case EditorMode.addStage:
        hint = 'Drag to create area';
    }
    return _infoChip(hint);
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFFD1FAE5), fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showGridSettings() {
    double tempMajor = controller.gridSettings.majorSpacing;
    double tempMinor = controller.gridSettings.minorSpacing;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Grid Settings', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: tempMajor.toString(),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Major Grid Size (e.g. 10.0)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => tempMajor = double.tryParse(v) ?? tempMajor,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: tempMinor.toString(),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Minor Snap Grid Size (e.g. 0.5)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => tempMinor = double.tryParse(v) ?? tempMinor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                controller.updateGridSettings(tempMajor, tempMinor);
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );
  }

  void _showTrussSizeDialog() {
    double tempSize = controller.standardTrussPieceSize;
    final textController = TextEditingController(
      text: tempSize.truncateToDouble() == tempSize 
          ? tempSize.toInt().toString() 
          : tempSize.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final totalFt = controller.totalLinearTrussFt;
            final requiredPieces = tempSize > 0 ? (totalFt / tempSize).ceil() : 0;
            const quickSizes = [10.0, 15.0, 20.0, 25.0, 30.0, 40.0];

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.straighten_rounded, color: Color(0xFF3B82F6), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Truss Piece Size',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose standard stock piece size (feet):',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickSizes.map((size) {
                        final isSelected = (tempSize - size).abs() < 0.01;
                        final label = '${size.toInt()} ft';
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                tempSize = size;
                                textController.text = size.toInt().toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Custom Truss Size (feet)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixText: 'ft',
                        suffixStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setDialogState(() {
                            tempSize = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Live Calculation Preview Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calculate_outlined, color: Color(0xFF60A5FA), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'CALCULATION PREVIEW',
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Design Truss:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(
                                '${totalFt.toStringAsFixed(1)} ft',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Stock Piece Size:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(
                                '${tempSize.toStringAsFixed(tempSize.truncateToDouble() == tempSize ? 0 : 1)} ft',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Trusses Required:',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$requiredPieces pcs',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (tempSize > 0 && totalFt > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              '(${totalFt.toStringAsFixed(0)} ft ÷ ${tempSize.toStringAsFixed(0)} ft = $requiredPieces trusses required)',
                              style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (tempSize > 0) {
                      controller.setStandardTrussPieceSize(tempSize);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Size'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDimensionsDialog() {
    double currentX = 0;
    double currentZ = 0;
    for (final node in controller.layout.nodes.values) {
      if (node.x > currentX) currentX = node.x;
      if (node.z > currentZ) currentZ = node.z;
    }
    double width = currentX > 0 ? currentX : 100.0;
    double depth = currentZ > 0 ? currentZ : 100.0;
    double spacing = controller.standardTrussPieceSize > 0 ? controller.standardTrussPieceSize : 30.0;
    double height = controller3D.mandapHeight > 0 ? controller3D.mandapHeight : 20.0;
    bool includeCenter = controller.layout.nodes.values.any((n) => n.isControlPoint);

    final widthController = TextEditingController(text: width.toStringAsFixed(0));
    final depthController = TextEditingController(text: depth.toStringAsFixed(0));
    final spacingController = TextEditingController(text: spacing.toStringAsFixed(0));
    final heightController = TextEditingController(text: height.toStringAsFixed(0));

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F1523),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF1E293B)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.aspect_ratio_rounded, color: Color(0xFF60A5FA), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Plot Dimensions & Setup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set your event structure measurements directly on the canvas:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),

                      // Length & Width
                      Row(
                        children: [
                          Expanded(
                            child: _buildDimInputField(
                              label: 'Length X (ft)',
                              controller: widthController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDimInputField(
                              label: 'Width Z (ft)',
                              controller: depthController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pole Spacing & Height
                      Row(
                        children: [
                          Expanded(
                            child: _buildDimInputField(
                              label: 'Pole Spacing (ft)',
                              controller: spacingController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDimInputField(
                              label: 'Pole Height (ft)',
                              controller: heightController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Center Structure Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0F19),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Center Structure (Cross)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            Switch(
                              value: includeCenter,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (val) => setDlgState(() => includeCenter = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final newW = double.tryParse(widthController.text.trim()) ?? 100.0;
                    final newD = double.tryParse(depthController.text.trim()) ?? 100.0;
                    final newSpacing = double.tryParse(spacingController.text.trim()) ?? 30.0;
                    final newH = double.tryParse(heightController.text.trim()) ?? 20.0;

                    final params = BaseTrussGenerationParams(
                      plotWidth: newW > 0 ? newW : 100.0,
                      plotDepth: newD > 0 ? newD : 100.0,
                      preferredPoleSpacing: newSpacing > 0 ? newSpacing : 30.0,
                      poleHeight: newH > 0 ? newH : 20.0,
                      includeCenterControlPoint: includeCenter,
                      availableTrussSizes: const [30.0, 20.0, 10.0, 5.0],
                    );

                    final generatedLayout = BaseTrussArchitectureGenerator.generate(params);
                    controller.setLayout(generatedLayout);
                    controller3D.setMandapHeight(newH);
                    controller.setStandardTrussPieceSize(newSpacing);
                    controller3D.fitCamera(generatedLayout);
                    _fitView(_canvasSize);

                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Dimensions'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDimInputField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F19),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── Structural Intelligence & Live Status ───────────────────────────────────

  Widget _buildStructuralStatusBar() {
    final report = controller.structuralReport;
    final hasWarn = report.hasWarnings;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasWarn
            ? const Color(0xFF78350F).withValues(alpha: 0.85) // Warm amber
            : const Color(0xFF064E3B).withValues(alpha: 0.85), // Forest emerald
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasWarn ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showStructuralReportSheet(report),
        child: Row(
          children: [
            Icon(
              hasWarn ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              size: 18,
              color: hasWarn ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasWarn
                    ? report.warnings.first
                    : 'Structure Connected & Supported (${report.componentCount} component${report.componentCount == 1 ? '' : 's'})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasWarn && report.warnings.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${report.warnings.length - 1} more',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.info_outline, size: 15, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  void _showStructuralReportSheet(StructuralAnalysisReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      report.hasWarnings ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      color: report.hasWarnings ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Structural Intelligence & Diagnostics',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _reportRow('Structural Components', '${report.componentCount} independent structure(s)'),
                      _reportRow('Unsupported Endpoints', '${report.unsupportedEndpoints.length}'),
                      _reportRow('Isolated Poles', '${report.isolatedNodes.length}'),
                      _reportRow('Long Spans (>30ft)', '${report.longSpans.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (report.hasWarnings) ...[
                  const Text('Active Structural Notices:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...report.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.amber)),
                        Expanded(child: Text(w, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
                Text(
                  'ℹ MANDAP provides real-time structural intelligence without restricting your freedom to draw, move, or modify geometry.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showNodeEraserOptions(MandapNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Erase Point ${node.id.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose whether to remove only the vertical pole support (keeping connected trusses intact) or delete the node and connected members.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.vertical_align_bottom_rounded, color: Colors.amber),
                  label: const Text('Remove Pole Support (Keep Truss)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.removePoleSupport(node.id);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  label: const Text('Delete Node & Connected Members'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.15),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.deleteNode(node.id);
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEntranceDialog() {
    var selectedSide = EntranceSide.northA;
    final widthCtrl = TextEditingController(text: '10');
    final projCtrl = TextEditingController(text: '30');
    final offsetCtrl = TextEditingController(text: '45');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.meeting_room_outlined, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Attach External Entrance', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select target side of main structure:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EntranceSide>(
                  value: selectedSide,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: EntranceSide.northA, child: Text('Side A — North / Back (+Z)')),
                    DropdownMenuItem(value: EntranceSide.eastB, child: Text('Side B — East / Right (+X)')),
                    DropdownMenuItem(value: EntranceSide.southC, child: Text('Side C — South / Front (-Z)')),
                    DropdownMenuItem(value: EntranceSide.westD, child: Text('Side D — West / Left (-X)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSide = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widthCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Entrance Width (ft)',
                    labelStyle: TextStyle(color: Colors.white70),
                    suffixText: 'ft',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: projCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Projection Outward (ft)',
                    labelStyle: TextStyle(color: Colors.white70),
                    suffixText: 'ft',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: offsetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Position Offset along side (ft)',
                    labelStyle: TextStyle(color: Colors.white70),
                    suffixText: 'ft',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                final w = double.tryParse(widthCtrl.text) ?? 10.0;
                final p = double.tryParse(projCtrl.text) ?? 30.0;
                final off = double.tryParse(offsetCtrl.text) ?? 45.0;
                Navigator.pop(ctx);
                final sId = 'entrance_${DateTime.now().millisecondsSinceEpoch % 10000}';
                controller.addExternalStructure(
                  structureId: sId,
                  side: selectedSide,
                  width: w,
                  projection: p,
                  offset: off,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Attached entrance (${w.toInt()}×${p.toInt()} ft on ${selectedSide.name})'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Attach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2D/3D toggle button ────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final ViewMode current;
  final ValueChanged<ViewMode> onChanged;

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
            isActive: current == ViewMode.topView2D,
            onTap: () => onChanged(ViewMode.topView2D),
          ),
          const SizedBox(width: 4),
          _Chip(
            label: '3D',
            isActive: current == ViewMode.view3D,
            onTap: () => onChanged(ViewMode.view3D),
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
    final activeColor = label == '3D' ? const Color(0xFF10B981) : const Color(0xFF2563EB);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFF1E293B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF334155),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
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
