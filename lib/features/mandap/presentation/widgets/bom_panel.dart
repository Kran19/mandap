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
      initialChildSize: 0.22,
      minChildSize: 0.08,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.08, 0.22, 0.50, 0.75],
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
}
