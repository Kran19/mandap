import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../application/editor_mode.dart';
import '../application/mandap_editor_controller.dart';
import '../domain/entities/edge_id.dart';
import '../domain/entities/mandap_preset.dart';
import '../domain/entities/node_id.dart';
import '../domain/entities/mandap_zone.dart';
import '../domain/entities/mandap_node.dart';
import '../domain/entities/mandap_layout.dart';
import 'top_view_2d/mandap_2d_interactive_painter.dart';
import 'viewport_transform.dart';
import 'widgets/3d/mandap_3d_controller.dart';
import 'widgets/3d/mandap_3d_view.dart';
import 'widgets/bom_panel.dart';
import 'widgets/editor_mode_bar.dart';
import 'widgets/selection_sheet.dart';
import '../../auth/application/bootstrap_coordinator.dart';
import '../../projects/infrastructure/projects_repository.dart';
import '../../projects/infrastructure/project_version_repository.dart';
import '../../projects/infrastructure/local_project_store.dart';
import '../../projects/application/project_sync_service.dart';
import '../../projects/domain/sync_state.dart';
import '../../projects/domain/local_project_sync_metadata.dart';
import '../../mandap/infrastructure/layout_serializer.dart';
import '../../../core/errors/api_exceptions.dart';

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
  final String projectId;
  const MandapEditorScreen({super.key, required this.projectId});

  @override
  State<MandapEditorScreen> createState() => MandapEditorScreenState();
}

class MandapEditorScreenState extends State<MandapEditorScreen> {
  late MandapEditorController controller;
  late Mandap3DController controller3D;
  _ViewMode _viewMode = _ViewMode.topView2D;

  String? _projectName;
  bool _isLoading = true;
  bool _isSaving = false;
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
    
    // Defer the fetch until after init so we can use context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjectData();
    });
  }

  Future<void> _loadProjectData() async {
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

      // ── Step 1: Always fetch the latest version from the server ──────────
      // This is the source of truth. Both laptop and phone must show the same
      // design. Local cache is only a fallback for offline/no-versions cases.
      try {
        final versions = await versionRepo.getVersions(orgId, widget.projectId);
        final latestRemote = versions.isNotEmpty ? versions.first : null;

        if (latestRemote != null && latestRemote.layoutData != null) {
          // Server has data — always use it, overwriting any stale local cache
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
      } on RateLimitedException {
        // 429: Too many requests. Fall back to local cache so the user can still
        // work. The sync service will handle saving when they hit Save.
        print('[Editor] Rate limited loading versions — using local cache');
        final localLayout = await store.getLayout(widget.projectId);
        if (localLayout != null) controller.layout = localLayout;
      } catch (fetchErr) {
        // Any other network failure — still try local cache
        print('[Editor] Failed to fetch remote layout: $fetchErr — using local cache');
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
          _projectName = 'Err: ${e.toString().split('\n').first}';
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
          controller.deleteNode(hitNode);
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
      final worldGrab = _transform.screenToWorld(details.localPosition);
      final targetX = worldGrab.x - (_dragOffsetWorld?.x ?? 0.0);
      final targetZ = worldGrab.z - (_dragOffsetWorld?.z ?? 0.0);
      
      final snapped = _transform.snapToGrid(targetX, targetZ, gridSpacing: _getDynamicSnapGrid());
      setState(() {
        _snapCursor = snapped;
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
      _dragOffsetWorld = null;
      _zoneDragStartWorld = null;
      _zoneDragEndWorld = null;
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        controller.selectedEdgeId != null || controller.selectedNodeId != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted) context.go('/projects');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
            children: [
              _buildResponsiveHeader(),
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
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: _viewMode == _ViewMode.view3D &&
                              controller.mode != EditorMode.view,
                          child: BomPanel(controller: controller),
                        ),
                      ),

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
                pendingNodeType: controller.pendingNodeType,
                projectId: widget.projectId,
                onModeChanged: (m) {
                  controller.setMode(m);
                  setState(() => _snapCursor = null);
                },
                onNodeTypeChanged: (t) {
                  controller.setPendingNodeType(t);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  final shouldLeave = await _onWillPop();
                  if (shouldLeave && mounted) context.go('/projects');
                },
                tooltip: 'Exit to Dashboard',
              ),
              const Icon(Icons.architecture, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              if (_isLoading)
                SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
              else
                Expanded(
                  child: Text(
                    _projectName ?? 'Unknown Project',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                _buildSyncIndicator(),
                const SizedBox(width: 8),
                const Text('v: latest', style: TextStyle(fontSize: 11, color: Colors.white54)),
              ],
              if (!isMobile) Expanded(child: _buildToolbarActions()),
              if (isMobile) const SizedBox(width: 8),
              if (isMobile) _buildSyncIndicator(),
              if (isMobile) const SizedBox(width: 16),
            ],
          ),
          if (isMobile)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: _buildToolbarActions(),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    if (_syncService == null) return const SizedBox.shrink();
    return ValueListenableBuilder<SyncState>(
      valueListenable: _syncService!.syncState,
      builder: (context, state, child) {
        final color = switch (state) {
          SyncState.CLEAN => Colors.green,
          SyncState.DIRTY => Colors.orange,
          SyncState.SYNCING => Colors.blue,
          SyncState.CONFLICT => Colors.red,
          SyncState.ERROR => Colors.red,
          SyncState.AUTH_BLOCKED => Colors.red,
          SyncState.OFFLINE => Colors.grey,
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Text(state.name, style: TextStyle(fontSize: 11, color: color)),
        );
      },
    );
  }

  Widget _buildToolbarActions() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout, size: 20, color: Colors.white70),
                  tooltip: 'Logout',
                  onPressed: () => context.read<BootstrapCoordinator>().logout(),
                ),
                IconButton(
                  icon: const Icon(Icons.grid_4x4, size: 20, color: Colors.white70),
                  tooltip: 'Grid Settings',
                  onPressed: _showGridSettings,
                ),
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
                const SizedBox(width: 4),
                _ViewToggle(
                  current: _viewMode,
                  onChanged: (m) => setState(() => _viewMode = m),
                ),
                IconButton(
                  icon: const Icon(Icons.undo, size: 20, color: Colors.white70),
                  tooltip: 'Undo',
                  onPressed: controller.history.canUndo
                      ? () => controller.undo()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo, size: 20, color: Colors.white70),
                  tooltip: 'Redo',
                  onPressed: controller.history.canRedo
                      ? () => controller.redo()
                      : null,
                ),
              ],
            ),
          ),
        ),
        // Pin the Save button to the right
        if (_syncService != null)
          ValueListenableBuilder<SyncState>(
            valueListenable: _syncService!.syncState,
            builder: (context, state, _) {
              final isDirty = state == SyncState.DIRTY || state == SyncState.ERROR;
              final isConflict = state == SyncState.CONFLICT;
              final showActiveSave = isDirty || isConflict;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 4, right: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConflict ? Colors.red : (showActiveSave ? const Color(0xFF2563EB) : const Color(0xFF1E293B)),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: showActiveSave ? 4 : 0,
                  ),
                  icon: _isSaving
                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(isConflict ? Icons.warning : (showActiveSave ? Icons.save : Icons.check), size: 16),
                  label: Text(
                    _isSaving ? 'Saving…' : (isConflict ? 'Force Save' : (showActiveSave ? 'Save' : 'Saved')),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSaving 
                    ? null 
                    : (isConflict 
                        ? () async {
                            // Resolve conflict by forcing local changes onto server
                            final repo = context.read<ProjectVersionRepository>();
                            final versions = await repo.getVersions(context.read<BootstrapCoordinator>().current.user!.organizationId!, widget.projectId);
                            if (versions.isNotEmpty) {
                              await _syncService?.resolveConflictKeepLocal(versions.first.id);
                              await _saveNow();
                            }
                          }
                        : (isDirty ? _saveNow : null)),
                ),
              );
            },
          ),
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
        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent && controller.mode == EditorMode.view) {
              final zoomDelta = pointerSignal.scrollDelta.dy > 0 ? 0.9 : 1.1;
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
