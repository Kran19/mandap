import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../stage_calculator_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// Clean, bright, simple Stage summary dialog.
class StageSummaryDialog extends StatelessWidget {
  final StageCalculatorController controller;

  const StageSummaryDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, {required StageCalculatorController controller}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => StageSummaryDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = controller.result;
    final stageLen = controller.stageLength;
    final stageWid = controller.stageWidth;
    final tableLen = controller.tableLength;
    final tableWid = controller.tableWidth;

    final totalTables = result?.totalTables ?? ((stageLen / tableLen).ceil() * (stageWid / tableWid).ceil());
    final coveredL = result?.coveredLength ?? stageLen;
    final coveredW = result?.coveredWidth ?? stageWid;
    final stageArea = stageLen * stageWid;
    final coveredArea = coveredL * coveredW;
    final excessArea = math.max(0.0, coveredArea - stageArea);
    final totalLegs = totalTables * 4;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFEA580C), // Bright orange
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.stageComplete ?? 'Stage Complete',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n?.stageTablesSummary ?? 'Stage Tables Summary',
                            style: const TextStyle(
                              color: Color(0xFFFFEDD5),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2 Hero Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.table_restaurant_rounded, color: Color(0xFFEA580C), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n?.totalStageTables ?? 'Total Tables',
                                        style: const TextStyle(
                                          color: Color(0xFF9A3412),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$totalTables ${l10n?.tables ?? "Tables"}',
                                    style: const TextStyle(
                                      color: Color(0xFF7C2D12),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tableWid.toStringAsFixed(0)} × ${tableLen.toStringAsFixed(0)} ft',
                                    style: const TextStyle(
                                      color: Color(0xFFEA580C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.crop_free_rounded, color: Color(0xFF2563EB), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n?.plotDimensions ?? 'Stage Size',
                                        style: const TextStyle(
                                          color: Color(0xFF1E40AF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${stageLen.toStringAsFixed(0)}×${stageWid.toStringAsFixed(0)} ft',
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stageArea.toStringAsFixed(0)} sq ft',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        l10n?.calculationDetails ?? 'DETAILS',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildRow(l10n?.tableDimensions ?? 'Table Size', '${tableWid.toStringAsFixed(0)} ft × ${tableLen.toStringAsFixed(0)} ft'),
                      _buildRow(l10n?.totalStageTables ?? 'Total Tables Used', '$totalTables ${l10n?.tables ?? "Tables"}', isHighlighted: true),
                      _buildRow(l10n?.coveredArea ?? 'Covered Platform', '${coveredL.toStringAsFixed(0)} ft × ${coveredW.toStringAsFixed(0)} ft (${coveredArea.toStringAsFixed(0)} sq ft)'),
                      _buildRow(l10n?.totalSupportLegs ?? 'Support Legs', '$totalLegs ${l10n?.legs ?? "Legs"}'),
                      if (excessArea > 0.1)
                        _buildRow(l10n?.extraCoverage ?? 'Extra Overhang', '+${excessArea.toStringAsFixed(0)} sq ft', isAlert: true),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0F172A)),
                      label: Text(
                        l10n?.copy ?? 'Copy',
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        final buffer = StringBuffer();
                        buffer.writeln('=== STAGE SUMMARY ===');
                        buffer.writeln('Stage Size: ${stageLen.toStringAsFixed(0)} × ${stageWid.toStringAsFixed(0)} ft (${stageArea.toStringAsFixed(0)} sq ft)');
                        buffer.writeln('Table Size: ${tableWid.toStringAsFixed(0)} × ${tableLen.toStringAsFixed(0)} ft');
                        buffer.writeln('Total Tables: $totalTables Tables');
                        buffer.writeln('Covered Size: ${coveredL.toStringAsFixed(0)} × ${coveredW.toStringAsFixed(0)} ft');
                        buffer.writeln('Support Legs: $totalLegs Legs');
                        Clipboard.setData(ClipboardData(text: buffer.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n?.summaryCopied ?? 'Stage summary copied!'),
                            backgroundColor: const Color(0xFFEA580C),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(l10n?.okDone ?? 'OK / Done', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlighted = false, bool isAlert = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert
            ? const Color(0xFFFEF3C7)
            : (isHighlighted ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFFCD34D)
              : (isHighlighted ? const Color(0xFFFDBA74) : const Color(0xFFCBD5E1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isAlert ? const Color(0xFF92400E) : const Color(0xFF475569),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isAlert ? const Color(0xFF92400E) : const Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
