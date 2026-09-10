import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../application/mandap_editor_controller.dart';
import '../../domain/entities/mandap_edge.dart';

class BOMSummarySheet extends StatelessWidget {
  final MandapEditorController controller;

  const BOMSummarySheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layout = controller.layout;
        final result = controller.result;

        double boxLength = 0;
        double tubeLength = 0;

        for (final edge in layout.edges.values) {
          final len = layout.getEdgeLength(edge).ticks / 2.0; // Assuming ticks are half-feet
          if (edge.profile == EdgeProfile.singleTube) {
            tubeLength += len;
          } else {
            boxLength += len;
          }
        }

        final totalLength = boxLength + tubeLength;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n.bom,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 24),

                  // Geometric Length Section
                  _buildSectionHeader('Structural Members (Geometric)'),
                  const SizedBox(height: 12),
                  _buildPropertyRow(l10n.boxTruss, '${boxLength.toStringAsFixed(2)} ft'),
                  _buildPropertyRow(l10n.singleTube, '${tubeLength.toStringAsFixed(2)} ft'),
                  const Divider(),
                  _buildPropertyRow(l10n.totalStructural, '${totalLength.toStringAsFixed(2)} ft', isBold: true),
                  
                  const SizedBox(height: 32),

                  // Inventory Section (Kept Strictly Separate)
                  _buildSectionHeader(l10n.inventoryRequirement),
                  const SizedBox(height: 12),
                  if (result.requiredTrussBySize.isEmpty)
                    const Text('No inventory required.', style: TextStyle(color: Colors.grey))
                  else
                    ...result.requiredTrussBySize.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key.name, style: const TextStyle(color: Colors.black87)),
                            Text('${e.value} pcs', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),

                  if (result.inventoryShortages.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Stock Shortages', color: Colors.red),
                    const SizedBox(height: 12),
                    ...result.inventoryShortages.map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${s.pieceType.name}: Needed ${s.requiredCount}, Available ${s.availableCount} (Shortage: ${s.shortageCount})',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {Color color = const Color(0xFF1E293B)}) {
    return Text(
      title,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildPropertyRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
