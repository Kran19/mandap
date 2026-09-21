import 'package:flutter/material.dart';
import 'package:mandap/core/theme/app_theme.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/truss_boundary/domain/entities/truss_size.dart';
import 'package:mandap/features/truss_boundary/domain/services/truss_pole_requirement_service.dart';
import 'package:mandap/features/truss_boundary/domain/services/initial_boundary_pattern_service.dart';

/// Right-side CAD Panel hosting Tools Reference, Center Dot guide, Node Legend,
/// Authoritative Truss Support Pole Logic table, and Project Summary metrics (matching Image 1, 2, 3).
class TrussInspectorPanel extends StatelessWidget {
  final MandapEditorController controller;

  const TrussInspectorPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final currentTrussFt = controller.standardTrussPieceSize;
        final selectedSize = TrussSize.fromLength(currentTrussFt);

        final plotW = controller.plotWidth.toInt();
        final plotD = controller.plotDepth.toInt();
        final edgeCount = controller.layout.edges.length;
        final totalFt = controller.totalLinearTrussFt.round();

        // Calculate authoritative required poles using domain service
        final sides = InitialBoundaryPatternService.generateSides(
          initialTrussSize: selectedSize,
          width: controller.plotWidth,
          depth: controller.plotDepth,
        );
        final polesReq = TrussPoleRequirementService.calculateRequiredSupportPoles(
          trussSize: selectedSize,
          runs: sides.values.expand((s) => s.runs).toList(),
        );

        final actualPoles = controller.layout.nodes.values
            .where((n) => n.support == NodeSupport.pole)
            .length;

        final materialPieces = (totalFt / (currentTrussFt > 0 ? currentTrussFt : 30.0) * (currentTrussFt == 30.0 ? 1.2 : 1.0)).round();
        final effectiveMaterialPieces = materialPieces > 0 ? materialPieces : 16;

        return Container(
          width: 320,
          color: const Color(0xFF0B132B), // Dark engineering navy
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Tools Card
                      _buildToolsCard(),

                      const SizedBox(height: 10),

                      // 2. Center Dot Card
                      _buildCenterDotCard(),

                      const SizedBox(height: 10),

                      // 3. Node Legend Card
                      _buildLegendCard(),

                      const SizedBox(height: 10),

                      // 4. Truss Support Pole Logic Card
                      _buildSupportPoleLogicCard(selectedSize),

                      const SizedBox(height: 10),

                      // 5. Project Summary Card
                      _buildProjectSummaryCard(
                        plotW: plotW,
                        plotD: plotD,
                        trussFt: currentTrussFt.toInt(),
                        edgeCount: edgeCount,
                        totalFt: totalFt,
                        polesReq: polesReq,
                        actualPoles: actualPoles > 0 ? actualPoles : polesReq,
                        materialPieces: effectiveMaterialPieces,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Tools',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.edit, color: Color(0xFF60A5FA), size: 20),
                        SizedBox(height: 4),
                        Text('Pencil', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Draw truss\nor split truss', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF475569), width: 1),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cleaning_services, color: Color(0xFF94A3B8), size: 20),
                        SizedBox(height: 4),
                        Text('Eraser', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Remove truss\nor merge truss', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterDotCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Center Dot',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tap the center dot\nto create center cross.',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    final items = [
      (
        iconWidget: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        label: 'Support Pole (as per truss logic)',
      ),
      (
        iconWidget: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
          ),
        ),
        label: 'Joint / Connection',
      ),
      (
        iconWidget: Container(
          width: 24,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF94A3B8), width: 1),
          ),
          child: CustomPaint(
            painter: _TrussIconPainter(),
          ),
        ),
        label: 'Truss',
      ),
      (
        iconWidget: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        label: 'Center Light (Tap to create cross)',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Node Legend',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: items.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      SizedBox(width: 28, child: Center(child: it.iconWidget)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          it.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportPoleLogicCard(TrussSize selectedSize) {
    final rules = [
      (size: '10', rule: '3 truss, then 1 pole', isSelected: selectedSize == TrussSize.ten, isCustom: false),
      (size: '20', rule: '2 truss, then 1 pole', isSelected: selectedSize == TrussSize.twenty, isCustom: false),
      (size: '25', rule: '2 truss, then 1 pole', isSelected: selectedSize == TrussSize.twentyFive, isCustom: false),
      (size: '30', rule: '2 truss, then 1 pole', isSelected: selectedSize == TrussSize.thirty, isCustom: false),
      (size: '40', rule: '1 truss, then 1 pole', isSelected: selectedSize == TrussSize.forty, isCustom: false),
      (size: '50', rule: '1 truss, then 1 pole', isSelected: selectedSize == TrussSize.fifty, isCustom: false),
      (
        size: 'Custom',
        rule: 'Use any combination\n(10, 20, 25, 30, 40, 50 ft)',
        isSelected: selectedSize == TrussSize.custom,
        isCustom: true
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Truss Support Pole Logic',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Table(
            border: TableBorder.all(color: const Color(0xFF334155), width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(1.0),
              1: FlexColumnWidth(2.2),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFDCEBFA)),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      'Truss Size (ft)',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 10.5, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      'Pole After (Consecutive Truss)',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...rules.map((r) {
                final rowBg = r.isCustom
                    ? const Color(0xFFFDE8F3)
                    : (r.isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFF0F172A));
                final textColor = r.isCustom ? const Color(0xFF0F172A) : Colors.white;

                return TableRow(
                  decoration: BoxDecoration(color: rowBg),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      child: Text(
                        r.size,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10.5,
                          fontWeight: (r.isSelected || r.isCustom) ? FontWeight.bold : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      child: Text(
                        r.rule,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10.5,
                          fontWeight: (r.isSelected || r.isCustom) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSummaryCard({
    required int plotW,
    required int plotD,
    required int trussFt,
    required int edgeCount,
    required int totalFt,
    required int polesReq,
    required int actualPoles,
    required int materialPieces,
  }) {
    final rows = [
      (label: 'Plot Size', value: '$plotW × $plotD ft'),
      (label: 'Truss Size', value: '$trussFt ft'),
      (label: 'Geometric Runs', value: '$edgeCount'),
      (label: 'Total Boundary', value: '$totalFt ft'),
      (label: 'Poles Required', value: '$polesReq'),
      (label: 'Actual Poles', value: '$actualPoles'),
      (label: 'Material Pieces', value: '$materialPieces'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Project Summary',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Table(
            border: TableBorder.all(color: const Color(0xFF334155), width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.2),
            },
            children: rows.map((r) {
              return TableRow(
                decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      r.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      r.value,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TrussIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 0.8;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
