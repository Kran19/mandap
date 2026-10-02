import 'dart:math' as math;
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
import '../domain/entities/truss_bay.dart';
import 'top_view_2d/mandap_2d_interactive_painter.dart';
import 'viewport_transform.dart';
import 'widgets/3d/mandap_3d_controller.dart';
import 'widgets/3d/mandap_3d_view.dart';
import '../../auth/application/bootstrap_coordinator.dart';
import '../../projects/infrastructure/projects_repository.dart';
import '../../projects/infrastructure/project_version_repository.dart';
import '../../projects/domain/project_version.dart';
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
import 'package:mandap/features/mandap/presentation/editor/widgets/truss_inspector_panel.dart';
import 'widgets/simplified_truss_rail.dart';
import 'widgets/truss_ready_hint_banner.dart';
import 'widgets/in_model_dimension_badge.dart';
import 'widgets/truss_member_length_sheet.dart';
import 'widgets/center_control_sheet.dart';
import 'widgets/edit_bay_size_sheet.dart';
import 'widgets/modular_truss_control_bar.dart';
import 'widgets/mandap_summary_dialog.dart';
import 'widgets/center_cross_support_required_dialog.dart';
import '../../truss_boundary/application/truss_boundary_controller.dart';
import '../../truss_boundary/domain/entities/truss_size.dart';
import '../../truss_boundary/presentation/truss_boundary_planner_screen.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../l10n/app_localizations.dart';

enum ViewMode { topView2D, view3D }

/// Primary Mandap Layout Editor screen.
/// CAD-Grade Event Structure Design Canvas
class MandapEditorScreen extends StatefulWidget {
  final String projectId;
  final double? initialTrussSize;
  final double? initialCalculationUnitSize;
  final double? initialPlotWidth;
  final double? initialPlotLength;

  const MandapEditorScreen({
    super.key,
    required this.projectId,
    this.initialTrussSize,
    this.initialCalculationUnitSize,
    this.initialPlotWidth,
    this.initialPlotLength,
  });

  @override
  State<MandapEditorScreen> createState() => MandapEditorScreenState();
}

class MandapEditorScreenState extends State<MandapEditorScreen> {
  late MandapEditorController controller;
  late Mandap3DController controller3D;
  ViewMode _viewMode = ViewMode.view3D;

  String? _projectName;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAnimating3D = true;
  ProjectSyncService? _syncService;
  MandapLayout? _lastNotifiedLayout;
  bool _isHandlingPop = false;

  // 2D viewport transform state
  ViewportTransform _transform = ViewportTransform.defaultTransform();

  // Snap cursor for addNode / move modes
  ({double x, double z})? _snapCursor;

  // Canvas size captured from the 2D viewport's LayoutBuilder
  Size _canvasSize = const Size(360, 600);

  // Drag tracking for node move
  Offset? _dragStartScreen;
  ({double x, double z})? _dragOffsetWorld;
  NodeId? _draggedCenterNodeId;

  // Zone drawing state
  ({double x, double z})? _zoneDragStartWorld;
  ({double x, double z})? _zoneDragEndWorld;

  @override
  void initState() {
    super.initState();
    final effectiveW = (widget.initialPlotWidth != null && widget.initialPlotWidth! > 0)
        ? widget.initialPlotWidth!
        : 100.0;
    final effectiveD = (widget.initialPlotLength != null && widget.initialPlotLength! > 0)
        ? widget.initialPlotLength!
        : 100.0;
    final effectiveTruss = (widget.initialTrussSize != null && widget.initialTrussSize! > 0)
        ? widget.initialTrussSize!
        : 30.0;

    controller = MandapEditorController(
      initialWidth: effectiveW,
      initialDepth: effectiveD,
      initialTrussSize: effectiveTruss,
      initialCalculationUnitSize: widget.initialCalculationUnitSize,
    );
    controller.setMode(EditorMode.view);
    controller3D = Mandap3DController();
    controller.addListener(_onControllerUpdate);
    controller3D.fitCamera(controller.layout);

    // Load cached layout if available (for existing projects only)
    _loadLocalLayoutFast();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjectData();
      _fitView(_canvasSize);
    });
  }

  void _applyLoadedLayout(MandapLayout loadedLayout) {
    if (loadedLayout.edges.isEmpty) return;
    controller.loadCustomLayout(loadedLayout);
    _lastNotifiedLayout = loadedLayout;

    if (loadedLayout.nodes.isNotEmpty) {
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minZ = double.infinity;
      double maxZ = -double.infinity;
      double maxElev = 0.0;

      for (final n in loadedLayout.nodes.values) {
        if (n.x < minX) minX = n.x;
        if (n.x > maxX) maxX = n.x;
        if (n.z < minZ) minZ = n.z;
        if (n.z > maxZ) maxZ = n.z;
        if (n.elevation > maxElev) maxElev = n.elevation;
      }

      final w = maxX - minX;
      final d = maxZ - minZ;
      if (w > 0) controller.plotWidth = w;
      if (d > 0) controller.plotDepth = d;
      if (maxElev > 0) {
        controller3D.setMandapHeight(maxElev);
      }
    }

    controller3D.fitCamera(loadedLayout);
    controller3D.syncScene(loadedLayout, controller.result);
  }

  Future<void> _loadLocalLayoutFast() async {
    if (widget.projectId == 'new' || widget.projectId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final store = LocalProjectStore();
      final local = await store.getLayout(widget.projectId);
      if (local != null && local.edges.isNotEmpty && mounted) {
        setState(() {
          _applyLoadedLayout(local);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      final store = LocalProjectStore();
      final localRecord = await store.getProjectRecord(widget.projectId);
      if (localRecord != null && mounted) {
        setState(() {
          _projectName = localRecord.title;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    controller3D.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      controller3D.syncScene(controller.layout, controller.result);
      setState(() {});
    }
  }

  void _fitView(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final w = controller.plotWidth > 0 ? controller.plotWidth : 100.0;
    final d = controller.plotDepth > 0 ? controller.plotDepth : 100.0;

    // Generous padding so all rails, header badges, and bottom banners leave structure fully visible
    final scaleX = (size.width - 200) / w;
    final scaleZ = (size.height - 240) / d;
    final scale = math.min(scaleX, scaleZ).clamp(1.0, 30.0);

    final panX = (size.width - w * scale) / 2.0;
    final panZ = (size.height - d * scale) / 2.0;

    setState(() {
      _transform = ViewportTransform(
        panX: panX,
        panY: panZ,
        scale: scale,
      );
    });
  }

  void _resetView() {
    _fitView(_canvasSize);
  }

  void _onTapUp(TapUpDetails details) {
    final screenPos = details.localPosition;
    final world = _transform.screenToWorld(screenPos);

    // Check if tap hit the center dot to create Center Cross (+)
    final centerNode = controller.centerControlNode;
    final cX = centerNode?.x ?? (controller.plotWidth / 2.0);
    final cZ = centerNode?.z ?? (controller.plotDepth / 2.0);
    final centerScreen = _transform.worldToScreen(cX, cZ);
    final distToCenterScreen = (screenPos - centerScreen).distance;

    final hasCrossEdges = controller.layout.edges.values.any((e) => e.id.value.contains('cross') || e.id.value.contains('mid'));

    if (distToCenterScreen < 32.0 && !hasCrossEdges) {
      final supportCheck = controller.checkCenterCrossSupport();
      if (!supportCheck.canActivate) {
        _showCenterCrossSupportRequiredDialog(context, supportCheck.missingDirections);
        return;
      }

      controller.toggleCenterCross();
      controller3D.fitCamera(controller.layout);
      controller3D.syncScene(controller.layout, controller.result);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Center Cross (+) created successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      return;
    }

    switch (controller.mode) {
      case EditorMode.view:
      case EditorMode.select:
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          controller.selectNode(hitNode);
          controller.deselectBay();
        } else {
          final hitEdge = _hitTestEdge(screenPos);
          if (hitEdge != null) {
            controller.selectEdge(hitEdge, worldX: world.x, worldZ: world.z);
            controller.deselectBay();
          } else {
            final hitBay = _hitTestBay(world.x, world.z);
            if (hitBay != null) {
              controller.selectBay(hitBay.id);
            } else {
              controller.clearSelection();
            }
          }
        }
        break;

      case EditorMode.addPole:
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          controller.setNodeSupport(hitNode, NodeSupport.pole);
          final didConnect = controller.autoConnectUnconnectedPoles();
          controller3D.syncScene(controller.layout, controller.result);
          _saveNow();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                didConnect
                    ? '✓ 4 poles connected with perimeter trusses!'
                    : '✓ Support pole added to node!',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        } else {
          final hitEdge = _hitTestEdge(screenPos);
          if (hitEdge != null) {
            final worldPos = _transform.screenToWorld(screenPos);
            final poleNodeId = controller.splitEdgeWithPole(
              hitEdge,
              x: worldPos.x,
              z: worldPos.z,
              elevation: controller.mandapHeight,
            );
            if (poleNodeId != null) {
              final didConnect = controller.autoConnectUnconnectedPoles();
              controller3D.syncScene(controller.layout, controller.result);
              _saveNow();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    didConnect
                        ? '✓ 4 poles connected with perimeter trusses!'
                        : '✓ Support pole added — Truss split into 2 segments!',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            }
          } else {
            final step = controller.subGridSize > 0 ? controller.subGridSize : (controller.standardTrussPieceSize > 0 ? controller.standardTrussPieceSize : 25.0);
            final snappedX = (world.x / step).round() * step;
            final snappedZ = (world.z / step).round() * step;

            final passingEdgeId = controller.findEdgePassingThrough(snappedX, snappedZ);
            if (passingEdgeId != null) {
              final poleNodeId = controller.splitEdgeWithPole(
                passingEdgeId,
                x: snappedX,
                z: snappedZ,
                elevation: controller.mandapHeight,
              );
              if (poleNodeId != null) {
                final didConnect = controller.autoConnectUnconnectedPoles();
                controller3D.syncScene(controller.layout, controller.result);
                _saveNow();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      didConnect
                          ? '✓ 4 poles connected with perimeter trusses!'
                          : '✓ Support pole added — Truss split into 2 segments!',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              }
            } else {
              final newNodeId = controller.getOrCreateNodeAt(
                snappedX,
                snappedZ,
                elevation: controller.mandapHeight,
                support: NodeSupport.pole,
              );
              controller.setNodeSupport(newNodeId, NodeSupport.pole);
              final didConnect = controller.autoConnectUnconnectedPoles();
              controller3D.syncScene(controller.layout, controller.result);
              _saveNow();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    didConnect
                        ? '✓ 4 poles connected with perimeter trusses!'
                        : '✓ Support pole created on grid!',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            }
          }
        }
        break;

      case EditorMode.addEdge:
        final hitNode = _hitTestNode(screenPos);
        if (controller.pendingEdgeStartNodeId == null) {
          if (hitNode != null) {
            controller.handleAddEdgeTap(hitNode);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('First pole selected. Tap another pole or point to draw the full truss.'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF0284C7),
              ),
            );
          } else {
            final hitEdge = _hitTestEdge(screenPos);
            if (hitEdge != null) {
              final worldPos = _transform.screenToWorld(screenPos);
              final newNodeId = controller.addNodeNamed(
                x: worldPos.x,
                z: worldPos.z,
                type: NodeType.junction,
                elevation: controller.mandapHeight,
              );
              if (newNodeId != null) {
                controller.handleAddEdgeTap(newNodeId);
                controller3D.syncScene(controller.layout, controller.result);
                _saveNow();
              }
            } else {
              // Empty space tap (inside or outside square): create start node snapped to standard truss step
              final step = controller.subGridSize > 0 ? controller.subGridSize : (controller.standardTrussPieceSize > 0 ? controller.standardTrussPieceSize : 25.0);
              final snappedX = (world.x / step).round() * step;
              final snappedZ = (world.z / step).round() * step;
              final newNodeId = controller.getOrCreateNodeAt(snappedX, snappedZ, elevation: controller.mandapHeight);
              controller.handleAddEdgeTap(newNodeId);
              controller3D.syncScene(controller.layout, controller.result);
              _saveNow();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Start node created. Tap second pole/point to complete full truss.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF0284C7),
                ),
              );
            }
          }
        } else {
          // Second tap:
          if (hitNode != null) {
            // User explicitly tapped an existing node/pole -> connect directly to it!
            controller.handleAddEdgeTap(hitNode);
            controller3D.syncScene(controller.layout, controller.result);
            _saveNow();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Full truss created successfully!'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
          } else {
            double targetX = world.x;
            double targetZ = world.z;
            final createdNodeId = controller.drawStraightTrussTo(targetX, targetZ);
            if (createdNodeId != null) {
              controller3D.syncScene(controller.layout, controller.result);
              _saveNow();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Full truss created successfully!'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            }
          }
        }
        break;

      case EditorMode.delete:
        final hitEdge = _hitTestEdge(screenPos);
        if (hitEdge != null) {
          controller.deleteEdge(hitEdge, worldX: world.x, worldZ: world.z);
          return;
        }
        final hitNode = _hitTestNode(screenPos);
        if (hitNode != null) {
          controller.deleteNode(hitNode);
        }
        break;

      default:
        break;
    }
  }

  NodeId? _hitTestNode(Offset screenPos) {
    for (final node in controller.layout.nodes.values) {
      final nodeScreen = _transform.worldToScreen(node.x, node.z);
      if ((nodeScreen - screenPos).distance <= 26.0) {
        return node.id;
      }
    }
    return null;
  }

  EdgeId? _hitTestEdge(Offset screenPos) {
    for (final edge in controller.layout.edges.values) {
      final start = controller.layout.getNode(edge.startNodeId);
      final end = controller.layout.getNode(edge.endNodeId);
      if (start == null || end == null) continue;

      final p1 = _transform.worldToScreen(start.x, start.z);
      final p2 = _transform.worldToScreen(end.x, end.z);

      final dist = _distanceToSegment(screenPos, p1, p2);
      if (dist <= 14.0) {
        return edge.id;
      }
    }
    return null;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2).clamp(0.0, 1.0);
    final projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - projection).distance;
  }

  TrussBay? _hitTestBay(double worldX, double worldZ) {
    for (final bay in controller.bays) {
      if (worldX >= bay.minX &&
          worldX <= bay.maxX &&
          worldZ >= bay.minZ &&
          worldZ <= bay.maxZ) {
        return bay;
      }
    }
    return null;
  }

  void _onScaleStart(ScaleStartDetails details) {
    final hitNode = _hitTestNode(details.localFocalPoint);
    if (hitNode != null) {
      final node = controller.layout.getNode(hitNode);
      if (node != null && (node.isControlPoint || node.id.value.contains('center') || node.id.value.contains('mid'))) {
        final hasCrossEdges = controller.layout.edges.values.any((e) => e.id.value.contains('cross') || e.id.value.contains('mid'));
        if (!hasCrossEdges) {
          final supportCheck = controller.checkCenterCrossSupport();
          if (!supportCheck.canActivate) {
            _showCenterCrossSupportRequiredDialog(context, supportCheck.missingDirections);
            return;
          }
        }
        _draggedCenterNodeId = controller.centerControlNode?.id ?? hitNode;
        return;
      }
    } else {
      final hitEdge = _hitTestEdge(details.localFocalPoint);
      if (hitEdge != null && (hitEdge.value.contains('cross') || hitEdge.value.contains('center'))) {
        _draggedCenterNodeId = controller.centerControlNode?.id;
        if (_draggedCenterNodeId != null) return;
      }
    }
    _dragStartScreen = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_draggedCenterNodeId != null) {
      final world = _transform.screenToWorld(details.localFocalPoint);
      final minX = 5.0;
      final maxX = controller.plotWidth > 10.0 ? controller.plotWidth - 5.0 : 95.0;
      final minZ = 5.0;
      final maxZ = controller.plotDepth > 10.0 ? controller.plotDepth - 5.0 : 95.0;
      final step = (controller.subGridSize > 0 && controller.subGridSize <= 1.0) ? controller.subGridSize : 0.5;
      final clampedX = (world.x / step).round() * step;
      final clampedZ = (world.z / step).round() * step;
      final finalX = clampedX.clamp(minX, maxX);
      final finalZ = clampedZ.clamp(minZ, maxZ);

      controller.adjustCenterPosition(newX: finalX, newZ: finalZ);
      controller3D.syncScene(controller.layout, controller.result);
      setState(() {});
      return;
    }

    if (details.scale != 1.0) {
      setState(() {
        _transform = _transform.zoom(details.scale, details.localFocalPoint);
      });
    } else {
      setState(() {
        _transform = _transform.pan(details.focalPointDelta.dx, details.focalPointDelta.dy);
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _draggedCenterNodeId = null;
    _dragStartScreen = null;
  }

  Future<void> _saveNow() async {
    setState(() => _isSaving = true);
    try {
      final store = LocalProjectStore();
      await store.saveLayout(widget.projectId, controller.layout);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project saved successfully!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateProjectAfterDimensionChange() async {
    try {
      final store = LocalProjectStore();
      final len = controller.plotDepth.toInt();
      final wid = controller.plotWidth.toInt();
      final title = 'Truss $wid × $len ft';
      if (mounted) setState(() => _projectName = title);
      await store.saveProjectRecord(
        MandapSavedProject(
          id: widget.projectId,
          title: title,
          moduleType: 'truss',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          parameters: {
            'width': controller.plotWidth,
            'length': controller.plotDepth,
            'trussSize': controller.standardTrussPieceSize,
          },
        ),
      );
      await store.saveLayout(widget.projectId, controller.layout);
    } catch (_) {}
  }

  Future<void> _retrieveSavedLayout() async {
    try {
      final store = LocalProjectStore();
      final local = await store.getLayout(widget.projectId);
      if (local != null && local.edges.isNotEmpty && mounted) {
        _applyLoadedLayout(local);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved project retrieved!'),
            backgroundColor: Color(0xFF2563EB),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _showCenterCrossSupportRequiredDialog(BuildContext context, List<String> missingDirections) {
    CenterCrossSupportRequiredDialog.show(
      context,
      missingDirections: missingDirections,
    );
  }

  Future<bool> _onWillPop() async => true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isHandlingPop) return;
        _isHandlingPop = true;
        try {
          final shouldLeave = await _onWillPop();
          if (shouldLeave && mounted) {
            context.go('/modules');
          }
        } finally {
          _isHandlingPop = false;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
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
                onRetrieve: _retrieveSavedLayout,
                isSaving: _isSaving,
                viewMode: _viewMode,
                onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              ),

              // Main Workspace Canvas + Left Tool Rail + Right Inspector/BOM
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;

                    final canvasStack = SizedBox.expand(
                      child: Stack(
                        children: [
                          // Viewport (2D / 3D)
                          Positioned.fill(child: _buildViewport()),

                          // Primary Tool Rail (PENCIL, ERASER, and CONFIG)
                          Positioned(
                            left: 12,
                            top: 52,
                            child: SimplifiedTrussRail(
                              controller: controller,
                              onPencilTap: () {
                                if (_viewMode == ViewMode.view3D) {
                                  controller3D.setTopDownView(
                                    layout: controller.layout,
                                    viewportSize: _canvasSize,
                                  );
                                } else {
                                  _fitView(_canvasSize);
                                }
                              },
                              onConfigTap: () {
                                ModularTrussControlBar.showPlotSizeDialog(
                                  context,
                                  controller: controller,
                                  onStructureGenerated: () {
                                    controller3D.fitCamera(controller.layout);
                                    controller3D.syncScene(controller.layout, controller.result);
                                    _saveNow();
                                    _fitView(_canvasSize);
                                    setState(() {
                                      _viewMode = ViewMode.view3D;
                                    });
                                  },
                                );
                              },
                            ),
                          ),

                          // Top-Center In-Model Dimension Badge (Length/Breadth · Box Size)
                          Positioned(
                            top: 12,
                            left: 56,
                            right: 80,
                            child: Center(
                              child: InModelDimensionBadge(
                                controller: controller,
                                onDimensionUpdated: () {
                                  controller3D.fitCamera(controller.layout);
                                  controller3D.syncScene(controller.layout, controller.result);
                                  _fitView(_canvasSize);
                                  _updateProjectAfterDimensionChange();
                                  if (mounted) {
                                    setState(() {
                                      _viewMode = ViewMode.view3D;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          // Floating OK Button on Top-Right (Clean, bright, highly accessible)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => MandapSummaryDialog.show(context, controller: controller),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n?.ok ?? 'OK',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Floating 2D / 3D Mode Toggle on Top-Right (Under OK button)
                          Positioned(
                            top: 52,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF334155), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildModeSegmentButton(
                                    label: '2D',
                                    isSelected: _viewMode == ViewMode.topView2D,
                                    onTap: () {
                                      if (_viewMode != ViewMode.topView2D) {
                                        setState(() => _viewMode = ViewMode.topView2D);
                                        _fitView(_canvasSize);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 2),
                                  _buildModeSegmentButton(
                                    label: '3D',
                                    isSelected: _viewMode == ViewMode.view3D,
                                    onTap: () {
                                      if (_viewMode != ViewMode.view3D) {
                                        setState(() => _viewMode = ViewMode.view3D);
                                        controller3D.fitCamera(controller.layout);
                                        controller3D.syncScene(controller.layout, controller.result);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom-Right Viewport controls (Fit Screen, Reset View - 2D only)
                          if (_viewMode == ViewMode.topView2D)
                            Positioned(
                              bottom: 60,
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

                          // Floating Truss Member Length Sheet (when an edge is selected)
                          ListenableBuilder(
                            listenable: controller,
                            builder: (context, _) {
                              if (controller.selectedEdgeId != null) {
                                return Positioned(
                                  bottom: 60,
                                  right: 16,
                                  child: TrussMemberLengthSheet(
                                    controller: controller,
                                    edgeId: controller.selectedEdgeId!,
                                    onClose: () => controller.clearSelection(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          // Floating Edit Bay Size Sheet (when a bay is selected in 2D or 3D)
                          ListenableBuilder(
                            listenable: controller,
                            builder: (context, _) {
                              if (controller.selectedBayId != null && controller.selectedBay != null) {
                                return Positioned(
                                  bottom: 60,
                                  right: 16,
                                  child: EditBaySizeSheet(
                                    controller: controller,
                                    bay: controller.selectedBay!,
                                    onClose: () => controller.deselectBay(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          // Bottom Info Banner (Matching Image 1 & 2)
                          Positioned(
                            bottom: 12,
                            left: 80,
                            right: 20,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_rounded, size: 16, color: Color(0xFF00E5FF)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n?.trussEditorHint ?? 'Use Pencil to draw or split truss. Use Eraser to remove truss. Tap center dot to create center cross.',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: canvasStack),
                          TrussInspectorPanel(
                            controller: controller,
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
          color: const Color(0xFF0F172A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF94A3B8)),
            SizedBox(width: 4),
            Text(
              'Reset View',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewport() {
    if (_viewMode == ViewMode.view3D) {
      return Mandap3DView(
        controller: controller,
        controller3D: controller3D,
        runAnimationOnLoad: _isAnimating3D,
        onAnimationCompleted: () {
          if (mounted && _isAnimating3D) {
            setState(() {
              _isAnimating3D = false;
            });
          }
        },
      );
    }

    // 2D interactive CAD viewport
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_canvasSize != canvasSize) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (mounted) {
                setState(() => _canvasSize = canvasSize);
                _fitView(canvasSize);
              }
            },
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
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
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
                displayNumbering: controller.displayNumbering,
                bays: controller.bays,
                selectedBayId: controller.selectedBayId,
                plotWidth: controller.plotWidth,
                plotDepth: controller.plotDepth,
                showMarkings: controller.showMarkings,
              ),
              size: canvasSize,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
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
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fit_screen_rounded, size: 14, color: Color(0xFF34D399)),
            SizedBox(width: 4),
            Text(
              'Fit View',
              style: TextStyle(
                color: Color(0xFF34D399),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
