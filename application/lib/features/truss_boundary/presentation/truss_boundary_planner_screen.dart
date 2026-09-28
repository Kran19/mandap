import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/entities/boundary_pole.dart';
import '../domain/entities/truss_size.dart';
import '../application/truss_boundary_controller.dart';
import 'widgets/truss_boundary_2d_painter.dart';
import 'widgets/truss_boundary_3d_view.dart';
import '../../mandap/presentation/wizard/create_truss_dialog.dart';

class TrussBoundaryPlannerScreen extends StatefulWidget {
  final dynamic initialTrussSize;
  final double? initialPlotWidth;
  final double? initialPlotLength;
  final double? plotWidth;
  final double? plotDepth;
  final String? projectId;

  const TrussBoundaryPlannerScreen({
    super.key,
    this.initialTrussSize,
    this.initialPlotWidth,
    this.initialPlotLength,
    this.plotWidth,
    this.plotDepth,
    this.projectId,
  });

  @override
  State<TrussBoundaryPlannerScreen> createState() => _TrussBoundaryPlannerScreenState();
}

class _TrussBoundaryPlannerScreenState extends State<TrussBoundaryPlannerScreen> {
  late TrussBoundaryController _controller;
  final String _selectedSideId = 'north';
  bool _showSaveToast = false;

  @override
  void initState() {
    super.initState();
    final width = widget.plotWidth ?? widget.initialPlotWidth ?? 100.0;
    final depth = widget.plotDepth ?? widget.initialPlotLength ?? 100.0;

    TrussSize size = TrussSize.thirty;
    double? customSpan;
    if (widget.initialTrussSize is TrussSize) {
      size = widget.initialTrussSize as TrussSize;
      customSpan = size.spanInFeet > 0 ? size.spanInFeet : null;
    } else if (widget.initialTrussSize is num) {
      final numVal = (widget.initialTrussSize as num).toDouble();
      size = TrussSize.fromLength(numVal);
      customSpan = numVal;
    }

    _controller = TrussBoundaryController(
      plotWidth: width,
      plotDepth: depth,
      trussSize: size,
      customTrussSpan: customSpan,
    );
  }

  Future<void> _handleEditDimensions() async {
    final params = await CreateTrussDialog.show(
      context,
      initialLength: _controller.plotDepth,
      initialWidth: _controller.plotWidth,
      initialTrussSize: _controller.customTrussSpan ?? _controller.initialTrussSize.spanInFeet,
    );
    if (params != null && mounted) {
      _controller.updateDimensions(
        plotWidth: params.plotWidth,
        plotDepth: params.plotLength,
        customTrussSpan: params.trussSize,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildWhiteHeaderBar(),
          body: Stack(
            children: [
              // 1. Full-Screen Interactive CAD Canvas (2D / 3D)
              Positioned.fill(
                child: _controller.viewMode == BoundaryViewMode.mode2D
                    ? GestureDetector(
                        onTapUp: (details) => _handleCanvasTap(details),
                        child: Container(
                          color: const Color(0xFF142416), // CAD Engineering Green
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: TrussBoundary2dPainter(
                              fourSides: _controller.fourSides,
                              centerRuns: _controller.centerRuns,
                              uniquePoles: _controller.uniquePoles,
                              plotWidth: _controller.plotWidth,
                              plotDepth: _controller.plotDepth,
                              activeTool: _controller.activeTool,
                              selectedSideId: _selectedSideId,
                              isCenterCrossActive: _controller.isCenterCrossActive,
                            ),
                          ),
                        ),
                      )
                    : TrussBoundary3dView(
                        fourSides: _controller.fourSides,
                        centerRuns: _controller.centerRuns,
                        uniquePoles: _controller.uniquePoles,
                        plotWidth: _controller.plotWidth,
                        plotDepth: _controller.plotDepth,
                        isCenterCrossActive: _controller.isCenterCrossActive,
                      ),
              ),

              // 2. Floating Top Plot Info Pill (Matching Image 3)
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildFloatingPlotPill(),
                ),
              ),

              // 3. Floating Left Tool Rail (White capsule matching Image 3)
              Positioned(
                left: 14,
                top: 24,
                child: _buildFloatingToolRail(),
              ),

              // 4. Save Success Toast (Matching Image 3 green bar)
              if (_showSaveToast)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildSaveToastBar(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// White Top Header Bar matching Image 3
  PreferredSizeWidget _buildWhiteHeaderBar() {
    final is2D = _controller.viewMode == BoundaryViewMode.mode2D;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      leadingWidth: 44,
      leading: IconButton(
        icon: const Icon(Icons.meeting_room_outlined, color: Colors.black87, size: 22),
        tooltip: 'Exit',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Red MANDAP Logo Badge (matching Image 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC02626),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.crop_square_outlined, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'MANDAP\nBUILDER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Undo / Redo buttons
          IconButton(
            icon: Icon(Icons.undo, color: _controller.canUndo ? Colors.black87 : Colors.black26, size: 20),
            tooltip: 'Undo',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
            onPressed: _controller.canUndo ? () => _controller.undo() : null,
          ),
          IconButton(
            icon: Icon(Icons.redo, color: _controller.canRedo ? Colors.black87 : Colors.black26, size: 20),
            tooltip: 'Redo',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
            onPressed: _controller.canRedo ? () => _controller.redo() : null,
          ),
          const SizedBox(width: 6),

          // Project Title Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Truss ...',
                  style: TextStyle(color: Colors.black87, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 4),
                Icon(Icons.edit, size: 12, color: Colors.black54),
              ],
            ),
          ),

          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87, size: 20),
            tooltip: 'History',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30),
            onPressed: () {},
          ),
        ],
      ),
      actions: [
        // Blue Save Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.save, size: 15),
          label: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          onPressed: _handleSave,
        ),
        const SizedBox(width: 8),

        // 2D / 3D Segmented Toggle
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _controller.setViewMode(BoundaryViewMode.mode2D),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: is2D ? const Color(0xFF2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '2D',
                    style: TextStyle(
                      color: is2D ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _controller.setViewMode(BoundaryViewMode.mode3D),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: !is2D ? const Color(0xFF2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '3D',
                    style: TextStyle(
                      color: !is2D ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Floating Top Center Plot Pill matching Image 3
  Widget _buildFloatingPlotPill() {
    return GestureDetector(
      onTap: _handleEditDimensions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0F263B), // Dark cyan/navy container
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF06B6D4), width: 1.5), // Cyan glowing border
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.crop_free, color: Color(0xFF06B6D4), size: 16),
            const SizedBox(width: 8),
            Text(
              'Plot Size: ${_controller.plotWidth.round()} × ${_controller.plotDepth.round()} ft • ${_controller.displayTrussLabel} Truss',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit, color: Color(0xFF06B6D4), size: 15),
          ],
        ),
      ),
    );
  }

  /// Floating Left Tool Rail (White capsule with shadow matching Image 3)
  Widget _buildFloatingToolRail() {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(2, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pencil
          _toolIcon(
            tool: EditingTool.pencil,
            icon: Icons.edit,
            tooltip: 'Pencil',
          ),
          const SizedBox(height: 8),

          // Eraser / Modify
          _toolIcon(
            tool: EditingTool.eraser,
            icon: Icons.cleaning_services_rounded,
            tooltip: 'Eraser',
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE2E8F0), height: 1, indent: 8, endIndent: 8),
          const SizedBox(height: 8),

          // Undo
          IconButton(
            icon: Icon(Icons.undo, color: _controller.canUndo ? Colors.black87 : Colors.black26, size: 18),
            tooltip: 'Undo',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _controller.canUndo ? () => _controller.undo() : null,
          ),
          const SizedBox(height: 4),

          // Redo
          IconButton(
            icon: Icon(Icons.redo, color: _controller.canRedo ? Colors.black87 : Colors.black26, size: 18),
            tooltip: 'Redo',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _controller.canRedo ? () => _controller.redo() : null,
          ),
        ],
      ),
    );
  }

  Widget _toolIcon({required EditingTool tool, required IconData icon, required String tooltip}) {
    final isActive = _controller.activeTool == tool;
    return GestureDetector(
      onTap: () => _controller.setActiveTool(tool),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.black87,
          size: 18,
        ),
      ),
    );
  }

  /// Green Toast Bar matching Image 3
  Widget _buildSaveToastBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF16A34A), // Vibrant green bar
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text(
            'Project saved successfully!',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    setState(() => _showSaveToast = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSaveToast = false);
      }
    });
  }

  void _handleCanvasTap(TapUpDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = details.localPosition;
    final size = renderBox.size;
    const margin = 40.0;
    final availWidth = size.width - margin * 2;
    final availHeight = size.height - margin * 2;
    if (availWidth <= 0 || availHeight <= 0) return;

    final scaleX = availWidth / _controller.plotWidth;
    final scaleZ = availHeight / _controller.plotDepth;
    final scale = math.min(scaleX, scaleZ);

    final offsetX = margin + (availWidth - _controller.plotWidth * scale) / 2;
    final offsetZ = margin + (availHeight - _controller.plotDepth * scale) / 2;

    Offset toCanvas(double x, double z) {
      return Offset(offsetX + x * scale, offsetZ + z * scale);
    }

    // 1. Center Light target tap
    final centerPole = _controller.uniquePoles.firstWhere(
      (p) => p.connectedSideIds.contains('center'),
      orElse: () => BoundaryPole(
        id: 'fallback_center',
        x: _controller.plotWidth / 2.0,
        z: _controller.plotDepth / 2.0,
        isCorner: false,
        isSupportPole: true,
      ),
    );
    final centerPt = toCanvas(centerPole.x, centerPole.z);
    if ((localPos - centerPt).distance <= 30.0) {
      _controller.handleCenterLightTap();
      return;
    }

    // 2. Eraser Tool: Tap intermediate joint pole to merge adjacent runs, or tap center run
    if (_controller.activeTool == EditingTool.eraser) {
      // Check center runs
      for (final run in _controller.centerRuns) {
        final p1Pole = _controller.uniquePoles.firstWhere((p) => p.id == run.startNodeId, orElse: () => centerPole);
        final p2Pole = _controller.uniquePoles.firstWhere((p) => p.id == run.endNodeId, orElse: () => centerPole);
        final pt1 = toCanvas(p1Pole.x, p1Pole.z);
        final pt2 = toCanvas(p2Pole.x, p2Pole.z);
        if (_distanceToSegment(localPos, pt1, pt2) <= 20.0) {
          _controller.handleEraserCenterRunTap(run.id);
          return;
        }
      }

      // Check perimeter joint poles OR direct run segment taps to merge adjacent runs (e.g. 30 ft + 10 ft -> 40 ft)
      for (final entry in _controller.fourSides.entries) {
        final sideId = entry.key;
        final side = entry.value;
        if (side.runs.length < 2) continue;

        // A. Check joint poles
        double accumulated = 0.0;
        for (int i = 0; i < side.runs.length - 1; i++) {
          final runA = side.runs[i];
          final runB = side.runs[i + 1];
          accumulated += runA.geometricSpan;

          double poleX = 0, poleZ = 0;
          switch (sideId) {
            case 'north':
              poleX = accumulated;
              poleZ = 0;
              break;
            case 'east':
              poleX = _controller.plotWidth;
              poleZ = accumulated;
              break;
            case 'south':
              poleX = accumulated;
              poleZ = _controller.plotDepth;
              break;
            case 'west':
              poleX = 0;
              poleZ = accumulated;
              break;
          }

          final jointPt = toCanvas(poleX, poleZ);
          if ((localPos - jointPt).distance <= 32.0) {
            _controller.handleEraserTap(
              sideId: sideId,
              runIdA: runA.id,
              runIdB: runB.id,
            );
            return;
          }
        }

        // B. Check direct taps on truss run segments with Eraser
        accumulated = 0.0;
        for (int i = 0; i < side.runs.length; i++) {
          final run = side.runs[i];
          final startDist = accumulated;
          final endDist = accumulated + run.geometricSpan;
          accumulated += run.geometricSpan;

          Offset pt1, pt2;
          switch (sideId) {
            case 'north':
              pt1 = toCanvas(startDist, 0);
              pt2 = toCanvas(endDist, 0);
              break;
            case 'east':
              pt1 = toCanvas(_controller.plotWidth, startDist);
              pt2 = toCanvas(_controller.plotWidth, endDist);
              break;
            case 'south':
              pt1 = toCanvas(startDist, _controller.plotDepth);
              pt2 = toCanvas(endDist, _controller.plotDepth);
              break;
            case 'west':
              pt1 = toCanvas(0, startDist);
              pt2 = toCanvas(0, endDist);
              break;
            default:
              pt1 = Offset.zero;
              pt2 = Offset.zero;
          }

          if (_distanceToSegment(localPos, pt1, pt2) <= 24.0) {
            final runA = i > 0 ? side.runs[i - 1] : side.runs[0];
            final runB = i > 0 ? side.runs[i] : side.runs[1];
            _controller.handleEraserTap(
              sideId: sideId,
              runIdA: runA.id,
              runIdB: runB.id,
            );
            return;
          }
        }
      }
    }

    // 3. Pencil Tool: Tap perimeter truss run to split it into two sections
    if (_controller.activeTool == EditingTool.pencil) {
      for (final entry in _controller.fourSides.entries) {
        final sideId = entry.key;
        final side = entry.value;

        double accumulated = 0.0;
        for (final run in side.runs) {
          final startDist = accumulated;
          final endDist = accumulated + run.geometricSpan;
          accumulated += run.geometricSpan;

          Offset pt1, pt2;
          switch (sideId) {
            case 'north':
              pt1 = toCanvas(startDist, 0);
              pt2 = toCanvas(endDist, 0);
              break;
            case 'east':
              pt1 = toCanvas(_controller.plotWidth, startDist);
              pt2 = toCanvas(_controller.plotWidth, endDist);
              break;
            case 'south':
              pt1 = toCanvas(startDist, _controller.plotDepth);
              pt2 = toCanvas(endDist, _controller.plotDepth);
              break;
            case 'west':
              pt1 = toCanvas(0, startDist);
              pt2 = toCanvas(0, endDist);
              break;
            default:
              pt1 = Offset.zero;
              pt2 = Offset.zero;
          }

          final distToLine = _distanceToSegment(localPos, pt1, pt2);
          if (distToLine <= 22.0) {
            double tapRatio = 0.5;
            final lineVec = pt2 - pt1;
            final lineLenSq = lineVec.dx * lineVec.dx + lineVec.dy * lineVec.dy;
            if (lineLenSq > 0) {
              final tapVec = localPos - pt1;
              tapRatio = ((tapVec.dx * lineVec.dx + tapVec.dy * lineVec.dy) / lineLenSq).clamp(0.1, 0.9);
            }
            final splitOffset = (run.geometricSpan * tapRatio).roundToDouble();
            if (splitOffset > 0 && splitOffset < run.geometricSpan) {
              _controller.handlePencilTap(
                sideId: sideId,
                targetRunId: run.id,
                splitOffset: splitOffset,
              );
              return;
            }
          }
        }
      }
    }
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2).clamp(0.0, 1.0);
    final projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - projection).distance;
  }

  /// Modal Bottom Sheet showing the full Support Pole Logic Table, Project Summary, Legend & BOM
  void _showSupportLogicSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSupportPoleLogicTable(),
                const SizedBox(height: 16),
                _buildProjectSummaryCard(_controller),
                const SizedBox(height: 16),
                _buildLegendCard(),
                const SizedBox(height: 16),
                _buildHowCalculatedCard(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSupportPoleLogicTable() {
    final rows = [
      ('10 ft', '3 truss, then 1 pole', _controller.initialTrussSize == TrussSize.ten),
      ('20 ft', '2 truss, then 1 pole', _controller.initialTrussSize == TrussSize.twenty),
      ('25 ft', '2 truss, then 1 pole', _controller.initialTrussSize == TrussSize.twentyFive),
      ('30 ft', '2 truss, then 1 pole', _controller.initialTrussSize == TrussSize.thirty),
      ('40 ft', '1 truss, then 1 pole', _controller.initialTrussSize == TrussSize.forty),
      ('50 ft', '1 truss, then 1 pole', _controller.initialTrussSize == TrussSize.fifty),
      ('Custom', 'Use any combination\n(10, 20, 25, 30, 40, 50 ft)', _controller.initialTrussSize == TrussSize.custom),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Truss Support Pole Logic',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: const Color(0xFF1E293B), width: 1),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF1E3A5F)),
                children: [
                  _tableCell('Truss Size', isHeader: true),
                  _tableCell('Pole After (Consecutive Truss)', isHeader: true),
                ],
              ),
              ...rows.map((r) => TableRow(
                decoration: BoxDecoration(
                  color: r.$3 ? const Color(0xFF3B1E4A) : Colors.transparent,
                ),
                children: [
                  _tableCell(r.$1, isHighlight: r.$3),
                  _tableCell(r.$2, isHighlight: r.$3),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? const Color(0xFF38BDF8) : (isHighlight ? const Color(0xFFE879F9) : Colors.white),
          fontSize: 11,
          fontWeight: isHeader || isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProjectSummaryCard(TrussBoundaryController controller) {
    final breakdown = <String, int>{};
    for (final reqs in controller.materialRequirements.values) {
      for (final r in reqs) {
        final label = r.stockType != null ? r.stockType!.label : '${r.requiredLength.round()} ft (Custom)';
        breakdown[label] = (breakdown[label] ?? 0) + 1;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Summary', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _summaryRow('Plot Size', '${controller.plotWidth.round()} × ${controller.plotDepth.round()} ft'),
          _summaryRow('Truss Size', controller.initialTrussSize.label),
          _summaryRow('Poles Required', '${controller.requiredPolesCount}'),
          _summaryRow('Actual Poles', '${controller.actualPolesCount}'),
          _summaryRow('Structural Nodes', '${controller.structuralNodesCount}'),
          _summaryRow('Geometric Runs', '${controller.totalGeometricRunsCount}'),
          _summaryRow(
            'Material Pieces',
            breakdown.entries.map((e) => '${e.key} × ${e.value}').join('\n'),
          ),
          _summaryRow('Total Boundary', '${controller.totalBoundaryLength.round()} ft'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Legend', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _legendItem(
            marker: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
            label: 'Support Pole (physical support column)',
          ),
          const SizedBox(height: 8),
          _legendItem(
            marker: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5))),
            label: 'Structural Joint (connection point)',
          ),
          const SizedBox(height: 8),
          _legendItem(
            marker: Container(width: 24, height: 8, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            label: 'Truss',
          ),
          const SizedBox(height: 8),
          _legendItem(
            marker: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF38BDF8), width: 1.5))),
            label: 'Center Light (tap to create cross)',
          ),
        ],
      ),
    );
  }

  Widget _legendItem({required Widget marker, required String label}) {
    return Row(
      children: [
        marker,
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
      ],
    );
  }

  Widget _buildHowCalculatedCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 16),
              SizedBox(width: 6),
              Text('How Support Poles are Calculated?', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('• Based on selected truss sizes and the rule table.', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
          SizedBox(height: 4),
          Text('• Example: 3 × 10 ft → 1 pole, 2 × 30 ft → 1 pole.', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
          SizedBox(height: 4),
          Text('• Custom sizes can be mixed (e.g. 50 + 30 + 20).', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
          SizedBox(height: 4),
          Text('• Poles are shown as red nodes, no text on canvas.', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
        ],
      ),
    );
  }
}
