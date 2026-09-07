import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../core/geometry/length.dart';
import '../../features/mandap/domain/entities/edge_id.dart';
import '../../features/mandap/domain/entities/mandap_layout.dart';
import '../../features/mandap/domain/entities/mandap_node.dart';
import '../../features/mandap/domain/entities/node_id.dart';
import '../../features/mandap/domain/entities/truss_catalog.dart';
import '../../features/mandap/domain/entities/truss_inventory.dart';
import '../../features/mandap/domain/services/mandap_calculation_engine.dart';
import '../../features/mandap/domain/value_objects/mandap_calculation_result.dart';
import 'mandap_3d_canvas_painter.dart';
import 'resize_edge_command.dart';
import 'vector3d_math.dart';

class Mandap3DSpikeScreen extends StatefulWidget {
  final MandapLayout? layout;
  final MandapCalculationResult? result;

  const Mandap3DSpikeScreen({super.key, this.layout, this.result});

  @override
  State<Mandap3DSpikeScreen> createState() => _Mandap3DSpikeScreenState();
}

class _Mandap3DSpikeScreenState extends State<Mandap3DSpikeScreen> {
  late TrussCatalog catalog;
  late TrussInventory inventory;
  late MandapLayout layout;
  late MandapCalculationEngine engine;
  late MandapCalculationResult result;

  MandapLayout get activeLayout => widget.layout ?? layout;
  MandapCalculationResult get activeResult => widget.result ?? result;

  EdgeId? selectedEdgeId;
  NodeId? activeHandleNodeId;

  // Camera Orbit Parameters
  double cameraAzimuth = 45.0 * math.pi / 180.0;
  double cameraElevation = 35.0 * math.pi / 180.0;
  double cameraDistance = 80.0;

  Offset? _lastPointerPos;
  bool isDraggingHandle = false;
  double? _draggedLengthPreviewFeet;

  // Undo Stack
  final List<ResizeEdgeCommand> _undoStack = [];
  double _dragStartNodeX = 0.0;
  double _dragStartNodeZ = 0.0;

  // Performance Test State
  bool isPerformanceTestMode = false;
  int perfObjectCount = 100;
  int frameCounter = 0;
  double currentFps = 60.0;
  DateTime _lastFpsTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    catalog = TrussCatalog.sample1To20Ft();
    inventory = TrussInventory.sample(catalog, defaultQty: 50);
    engine = const MandapCalculationEngine();

    _resetLayoutToFixture();
  }

  void _resetLayoutToFixture() {
    setState(() {
      layout = MandapLayout.rectangle(
        width: Length.fromFeet(40.0),
        length: Length.fromFeet(30.0),
      );
      selectedEdgeId = const EdgeId('e1');
      _recalculate();
    });
  }

  void _recalculate() {
    result = engine.calculate(
      layout: layout,
      catalog: catalog,
      inventory: inventory,
    );
  }

  void _onPointerDown(PointerDownEvent details, Size canvasSize) {
    _lastPointerPos = details.localPosition;

    // Check hit test against Endpoint Handles first if an edge is selected
    if (selectedEdgeId != null) {
      final edge = layout.getEdge(selectedEdgeId!);
      if (edge != null) {
        final endNode = layout.getNode(edge.endNodeId);
        final startNode = layout.getNode(edge.startNodeId);

        if (endNode != null && startNode != null) {
          // Perform 3D raycast picking for END handle (red sphere)
          final handlePos = v64.Vector3(endNode.x, 10.0, endNode.z);
          final ray = _createCameraRay(details.localPosition, canvasSize);
          final planeIntersection = Vector3DMath.rayHorizontalPlaneIntersection(
            ray,
            10.0,
          );

          if (planeIntersection != null) {
            final distToHandle = (planeIntersection - handlePos).length;
            if (distToHandle <= 6.0) {
              // Touch hit radius tolerance
              setState(() {
                isDraggingHandle = true;
                activeHandleNodeId = endNode.id;
                _dragStartNodeX = endNode.x;
                _dragStartNodeZ = endNode.z;
              });
              return;
            }
          }
        }
      }
    }

    // Otherwise perform 3D Raycast picking against Top Beams
    final ray = _createCameraRay(details.localPosition, canvasSize);
    EdgeId? hitEdgeId;
    double minHitDist = double.infinity;

    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode != null && endNode != null) {
        final p1 = v64.Vector3(startNode.x, 10.0, startNode.z);
        final p2 = v64.Vector3(endNode.x, 10.0, endNode.z);

        final planeIntersection = Vector3DMath.rayHorizontalPlaneIntersection(
          ray,
          10.0,
        );
        if (planeIntersection != null) {
          final distToSegment = Vector3DMath.distanceToSegment(
            planeIntersection,
            p1,
            p2,
          );
          if (distToSegment < 4.0 && distToSegment < minHitDist) {
            minHitDist = distToSegment;
            hitEdgeId = edge.id;
          }
        }
      }
    }

    if (hitEdgeId != null) {
      setState(() {
        selectedEdgeId = hitEdgeId;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent details, Size canvasSize) {
    if (_lastPointerPos == null) return;
    final delta = details.localPosition - _lastPointerPos!;
    _lastPointerPos = details.localPosition;

    if (isDraggingHandle &&
        selectedEdgeId != null &&
        activeHandleNodeId != null) {
      // 3D Constrained Handle Dragging along Edge Axis Vector
      final edge = layout.getEdge(selectedEdgeId!);
      if (edge != null) {
        final startNode = layout.getNode(edge.startNodeId);
        final endNode = layout.getNode(edge.endNodeId);

        if (startNode != null && endNode != null) {
          final ray = _createCameraRay(details.localPosition, canvasSize);
          final intersection = Vector3DMath.rayHorizontalPlaneIntersection(
            ray,
            10.0,
          );

          if (intersection != null) {
            final startPos = v64.Vector3(startNode.x, 10.0, startNode.z);
            final currentEndPos = v64.Vector3(endNode.x, 10.0, endNode.z);
            var axisDir = (currentEndPos - startPos);
            if (axisDir.length < 1e-4) axisDir = v64.Vector3(1.0, 0.0, 0.0);
            axisDir.normalize();

            // Project intersection onto edge axis ray
            final projDist = (intersection - startPos).dot(axisDir);
            final rawFeet = math.max(1.0, projDist); // Minimum 1 ft

            // Snap distance to nearest 0.5 ft (ticks)
            final snappedLength = Length.fromFeet(
              (rawFeet * 2.0).round() / 2.0,
            );

            // Compute new 2D node position
            final newX = startNode.x + axisDir.x * snappedLength.feet;
            final newZ = startNode.z + axisDir.z * snappedLength.feet;

            setState(() {
              _draggedLengthPreviewFeet = snappedLength.feet;

              // Update domain node coordinate directly
              final updatedNodes = Map<NodeId, MandapNode>.from(layout.nodes);
              updatedNodes[activeHandleNodeId!] = endNode.copyWith(
                x: newX,
                z: newZ,
              );
              layout = MandapLayout(nodes: updatedNodes, edges: layout.edges);

              // Live Recalculation
              _recalculate();
            });
          }
        }
      }
    } else {
      // Camera Orbit Drag
      setState(() {
        cameraAzimuth += delta.dx * 0.01;
        cameraElevation = (cameraElevation - delta.dy * 0.01).clamp(
          0.05,
          math.pi / 2 - 0.05,
        );
      });
    }
  }

  void _onPointerUp(PointerUpEvent details) {
    if (isDraggingHandle &&
        selectedEdgeId != null &&
        activeHandleNodeId != null) {
      final endNode = layout.getNode(activeHandleNodeId!);
      if (endNode != null) {
        // Record ResizeEdgeCommand in Undo Stack
        _undoStack.add(
          ResizeEdgeCommand(
            edgeId: selectedEdgeId!,
            movingNodeId: activeHandleNodeId!,
            oldX: _dragStartNodeX,
            oldZ: _dragStartNodeZ,
            newX: endNode.x,
            newZ: endNode.z,
          ),
        );
      }
    }

    setState(() {
      isDraggingHandle = false;
      activeHandleNodeId = null;
      _draggedLengthPreviewFeet = null;
      _lastPointerPos = null;
    });
  }

  v64.Ray _createCameraRay(Offset localPos, Size size) {
    final centerTarget = v64.Vector3(20.0, 5.0, 15.0);
    final cosElev = math.cos(cameraElevation);
    final sinElev = math.sin(cameraElevation);
    final cosAzim = math.cos(cameraAzimuth);
    final sinAzim = math.sin(cameraAzimuth);

    final eyeOffset = v64.Vector3(
      cameraDistance * cosElev * sinAzim,
      cameraDistance * sinElev,
      cameraDistance * cosElev * cosAzim,
    );

    final eyePosition = centerTarget + eyeOffset;
    final viewMatrix = v64.makeViewMatrix(
      eyePosition,
      centerTarget,
      v64.Vector3(0.0, 1.0, 0.0),
    );
    final aspect = size.width / size.height;
    final projectionMatrix = v64.makePerspectiveMatrix(
      45.0 * math.pi / 180.0,
      aspect,
      1.0,
      1000.0,
    );

    return Vector3DMath.screenToRay(
      screenPoint: v64.Vector2(localPos.dx, localPos.dy),
      viewportSize: v64.Vector2(size.width, size.height),
      viewMatrix: viewMatrix,
      projectionMatrix: projectionMatrix,
    );
  }

  void _undoLastCommand() {
    if (_undoStack.isEmpty) return;
    final cmd = _undoStack.removeLast();
    setState(() {
      layout = cmd.undo(layout);
      _recalculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Measure FPS
    frameCounter++;
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastFpsTime).inMilliseconds;
    if (elapsedMs >= 1000) {
      currentFps = (frameCounter * 1000.0) / elapsedMs;
      frameCounter = 0;
      _lastFpsTime = now;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PHASE 2 — 3D RENDERER TECHNICAL SPIKE',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo Last Edge Resize',
            onPressed: _undoStack.isNotEmpty ? _undoLastCommand : null,
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Reset Camera View',
            onPressed: () {
              setState(() {
                cameraAzimuth = 45.0 * math.pi / 180.0;
                cameraElevation = 35.0 * math.pi / 180.0;
                cameraDistance = 80.0;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Fixture (40x30)',
            onPressed: _resetLayoutToFixture,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left Side Panel: Real-time Calculation Sync Debug Panel
          SizedBox(
            width: 350,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: ListView(
                padding: const EdgeInsets.all(12.0),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 8),
                  _buildSelectedEdgeCard(),
                  const SizedBox(height: 8),
                  _build30FtTestCard(),
                  const SizedBox(height: 8),
                  _buildPolesSummaryCard(),
                  const SizedBox(height: 8),
                  _buildBOMCard(),
                  const SizedBox(height: 8),
                  _buildPerfModeCard(),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Right Side: 3D Interactive Viewport
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return Listener(
                      onPointerDown: (d) => _onPointerDown(d, canvasSize),
                      onPointerMove: (d) => _onPointerMove(d, canvasSize),
                      onPointerUp: _onPointerUp,
                      child: CustomPaint(
                        painter: Mandap3DCanvasPainter(
                          layout: activeLayout,
                          result: activeResult,
                          selectedEdgeId: selectedEdgeId,
                          activeHandleNodeId: activeHandleNodeId,
                          cameraAzimuth: cameraAzimuth,
                          cameraElevation: cameraElevation,
                          cameraDistance: cameraDistance,
                          dragPreviewLengthFeet: _draggedLengthPreviewFeet,
                          isPerformanceTestMode: isPerformanceTestMode,
                          performanceObjectCount: perfObjectCount,
                        ),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),
                // Overlay HUD Controls
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '3D Interactive Viewport | FPS: ${currentFps.toStringAsFixed(0)}\n'
                      'Controls: 1-Finger Drag = Orbit | Tap = Select Beam | Red Handle = Drag End',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
                // Camera Zoom Slider HUD
                Positioned(
                  right: 16,
                  top: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      const Icon(Icons.zoom_in, color: Color(0xFF64748B)),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: cameraDistance.clamp(30.0, 200.0),
                            min: 30.0,
                            max: 200.0,
                            onChanged: (val) {
                              setState(() {
                                cameraDistance = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const Icon(Icons.zoom_out, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3D RENDERER SPIKE STATUS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '• World Coordinates: X/Z Ground, Y Height (10ft)\n• Raycasting & Snapping: Active\n• Domain Sync: Real-time',
              style: TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedEdgeCard() {
    final edge = selectedEdgeId != null
        ? layout.getEdge(selectedEdgeId!)
        : null;
    final sol = selectedEdgeId != null
        ? result.edgeSolutions[selectedEdgeId!]
        : null;
    final len = edge != null ? layout.getEdgeLength(edge) : null;

    return Card(
      elevation: 0,
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECTED EDGE: ${selectedEdgeId?.value ?? "None"}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E40AF),
              ),
            ),
            const Divider(color: Color(0xFFBFDBFE)),
            if (sol != null && len != null) ...[
              Text(
                'Length: ${len.toString()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Pieces: ${sol.pieces.map((p) => p.length.toString()).join(" + ")}',
                style: const TextStyle(fontSize: 11),
              ),
              Text(
                'Joints: ${sol.jointCount}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ] else ...[
              const Text(
                'Tap a 3D top beam to select and inspect edge details.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _build30FtTestCard() {
    final edge1 = layout.getEdge(const EdgeId('e1'));
    final len1 = edge1 != null ? layout.getEdgeLength(edge1) : null;

    return Card(
      elevation: 0,
      color: const Color(0xFFFEF3C7),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CRITICAL 30 FT SPAN TEST',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Edge e1 Current Length: ${len1?.toString() ?? "N/A"}\n'
              'Rule: Spans <= 30 ft (0 extra poles). Spans > 30 ft (1+ extra poles generated).',
              style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [29.5, 30.0, 30.5, 31.0].map((testFt) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    final edge = layout.getEdge(const EdgeId('e1'));
                    if (edge != null) {
                      final n1 = layout.getNode(edge.startNodeId)!;
                      final n2 = layout.getNode(edge.endNodeId)!;

                      final updatedNodes = Map<NodeId, MandapNode>.from(
                        layout.nodes,
                      );
                      updatedNodes[n2.id] = n2.copyWith(x: n1.x + testFt);

                      setState(() {
                        layout = MandapLayout(
                          nodes: updatedNodes,
                          edges: layout.edges,
                        );
                        selectedEdgeId = const EdgeId('e1');
                        _recalculate();
                      });
                    }
                  },
                  child: Text(
                    '${testFt}ft',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolesSummaryCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'POLES SUMMARY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Corner: ${result.cornerPoleCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Generated: ${result.generatedPoleCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  'Total: ${result.totalPoleCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBOMCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE TRUSS BOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const Divider(),
            ...result.requiredTrussBySize.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.name, style: const TextStyle(fontSize: 11)),
                    Text(
                      '${e.value} pcs',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfModeCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PERFORMANCE BENCHMARK MODE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            SwitchListTile(
              title: Text(
                'Render $perfObjectCount Objects',
                style: const TextStyle(fontSize: 11),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: isPerformanceTestMode,
              onChanged: (val) {
                setState(() {
                  isPerformanceTestMode = val;
                });
              },
            ),
            if (isPerformanceTestMode)
              Slider(
                value: perfObjectCount.toDouble(),
                min: 100,
                max: 500,
                divisions: 4,
                label: '$perfObjectCount Objects',
                onChanged: (val) {
                  setState(() {
                    perfObjectCount = val.toInt();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
