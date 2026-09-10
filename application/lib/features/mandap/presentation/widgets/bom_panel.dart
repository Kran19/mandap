import 'package:flutter/material.dart';
import '../../application/mandap_editor_controller.dart';

/// Collapsible BOM / calculation results panel.
///
/// Designed as a [DraggableScrollableSheet] overlay at the bottom of the
/// viewport. Initially shown at 22% height; user can drag to expand.
class BomPanel extends StatelessWidget {
  final MandapEditorController controller;

  const BomPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final layout = controller.layout;

    return DraggableScrollableSheet(
          initialChildSize: 0.08,
          minChildSize: 0.08,
          maxChildSize: 0.75,
          snap: true,
          snapSizes: const [0.08, 0.25, 0.50, 0.75],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(
                  top: 0,
                  left: 12,
                  right: 12,
                  bottom: 16,
                ),
                children: [
                  // Drag handle
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.calculate_outlined,
                        size: 16,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BOM — ${layout.edges.length} edges · ${result.totalPoleCount} poles',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      if (result.inventoryShortages.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Text(
                            '${result.inventoryShortages.length} SHORTAGE',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Calculate Material Summary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showMaterialSummary(context),
                  ),
                  const Divider(height: 16),

                  // Pole summary
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _stat(
                        'Total Poles',
                        '${result.totalPoleCount}',
                        Colors.blue[900]!,
                      ),
                      _stat(
                        'Corner',
                        '${result.cornerPoleCount}',
                        const Color(0xFF1E293B),
                      ),
                      _stat(
                        'Generated',
                        '${result.generatedPoleCount}',
                        Colors.amber[800]!,
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Truss BOM
                  const Text(
                    'AGGREGATED TRUSS BOM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Standard piece summary banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Standard ${controller.standardTrussPieceSize.toStringAsFixed(0)} ft Trusses',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              Text(
                                'Total in design: ${controller.totalLinearTrussFt.toStringAsFixed(0)} ft',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${controller.totalPiecesRequired} pcs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...result.requiredTrussBySize.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key.name, style: const TextStyle(fontSize: 12)),
                          Text(
                            '${e.value} pcs',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (result.inventoryShortages.isNotEmpty) ...[
                    const Divider(height: 16),
                    const Text(
                      'SHORTAGES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...result.inventoryShortages.map(
                      (s) => Text(
                        '• ${s.pieceType.name}: need ${s.requiredCount}, have ${s.availableCount} (-${s.shortageCount})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],

                  if (result.warnings.isNotEmpty) ...[
                    const Divider(height: 16),
                    const Text(
                      'WARNINGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...result.warnings.map(
                      (w) => Text(
                        '• $w',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
  }

  Widget _stat(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
    ],
  );

  void _showMaterialSummary(BuildContext context) {
    final result = controller.result;
    final totalTruss = controller.totalLinearTrussFt;
    final trussSize = controller.standardTrussPieceSize;
    final requiredPieces = controller.totalPiecesRequired;
    
    // Conversions
    final trussM = (totalTruss * 0.3048).toStringAsFixed(1);
    final floorSqM = (result.totalFlooringAreaSqFt * 0.092903).toStringAsFixed(1);
    final stageSqM = (result.totalStageAreaSqFt * 0.092903).toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Material Requirements Summary'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow(
                'Total Truss',
                '${totalTruss.toStringAsFixed(1)} ft',
                '$trussM m',
              ),
              const Divider(),
              _buildSummaryRow(
                'Truss Piece Size',
                '${trussSize.toStringAsFixed(0)} ft',
                '',
              ),
              const Divider(),
              _buildSummaryRow(
                'Trusses Required',
                '$requiredPieces pcs',
                '(${totalTruss.toStringAsFixed(0)} ft ÷ ${trussSize.toStringAsFixed(0)} ft)',
                isHighlighted: true,
              ),
              const Divider(),
              _buildSummaryRow(
                'Flooring Area',
                '${result.totalFlooringAreaSqFt.toStringAsFixed(1)} sq ft',
                '$floorSqM sq m',
              ),
              const Divider(),
              _buildSummaryRow(
                'Stage Area',
                '${result.totalStageAreaSqFt.toStringAsFixed(1)} sq ft',
                '$stageSqM sq m',
              ),
              const Divider(),
              _buildSummaryRow(
                'Total Poles',
                '${result.totalPoleCount} pcs',
                '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String val1,
    String val2, {
    bool isHighlighted = false,
  }) {
    if (isHighlighted) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    val1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (val2.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      val2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val1, style: const TextStyle(fontSize: 14)),
              if (val2.isNotEmpty)
                Text(val2, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}
