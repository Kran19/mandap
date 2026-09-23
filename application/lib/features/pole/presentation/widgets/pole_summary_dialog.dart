import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pole_calculator_controller.dart';
import '../../domain/models/pole_calculation_result.dart';
import '../../../../l10n/app_localizations.dart';

/// Clean, bright, simple Pole / Pipe summary dialog.
class PoleSummaryDialog extends StatelessWidget {
  final PoleCalculatorController controller;

  const PoleSummaryDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, {required PoleCalculatorController controller}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => PoleSummaryDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = controller.result;
    final plotLen = controller.length;
    final plotWid = controller.width;
    final poleSize = controller.poleSize;

    final verticalPoles = result?.totalVerticalPoles ?? ((plotLen / poleSize + 1).floor() * (plotWid / poleSize + 1).floor());
    final horizontalPipes = result?.totalHorizontalPipes ?? 0;
    final ceilingSections = result?.totalCeilingSections ?? 0;
    final totalPipes = result?.totalPipesUsed ?? (verticalPoles + horizontalPipes);
    final totalPipeFeet = totalPipes * poleSize;

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
                  color: Color(0xFF059669), // Emerald
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
                        Icons.all_inbox_rounded,
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
                            l10n?.polesSetupComplete ?? 'Poles Setup Complete',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n?.polesAndPipesSummary ?? 'Poles & Pipes Summary',
                            style: const TextStyle(
                              color: Color(0xFFD1FAE5),
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
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.all_inbox_rounded, color: Color(0xFF059669), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n?.totalPipes ?? 'Total Pipes',
                                        style: const TextStyle(
                                          color: Color(0xFF065F46),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$totalPipes ${l10n?.pipe ?? "Pipes"}',
                                    style: const TextStyle(
                                      color: Color(0xFF064E3B),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${totalPipeFeet.toStringAsFixed(0)} ft ${l10n?.totalLength ?? "total length"}',
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
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
                                      const Icon(Icons.grid_4x4_rounded, color: Color(0xFF2563EB), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n?.gridBreakdown ?? 'Plot Grid',
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
                                    '${plotLen.toStringAsFixed(0)}×${plotWid.toStringAsFixed(0)} ft',
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${poleSize.toStringAsFixed(0)} ft ${l10n?.pipe ?? "Pipe"}',
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

                      _buildRow(l10n?.gridPoleUnit ?? 'Unit Pipe Size', '${poleSize.toStringAsFixed(0)} ft ${l10n?.pipe ?? "Pipe"}'),
                      _buildRow(l10n?.totalVerticalPoles ?? 'Vertical Standing Poles', '$verticalPoles ${l10n?.poles ?? "Poles"}'),
                      if (horizontalPipes > 0)
                        _buildRow(l10n?.totalHorizontalPipes ?? 'Horizontal Runners', '$horizontalPipes ${l10n?.pipe ?? "Pipes"}'),
                      if (ceilingSections > 0)
                        _buildRow(l10n?.ceilingSections ?? 'Ceiling Sections', '$ceilingSections'),
                      _buildRow(l10n?.totalPipes ?? 'Grand Total Pipes', '$totalPipes ${l10n?.pipe ?? "Pipes"}', isHighlighted: true),
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
                        buffer.writeln('=== POLES & PIPES SUMMARY ===');
                        buffer.writeln('Plot Size: ${plotLen.toStringAsFixed(0)} × ${plotWid.toStringAsFixed(0)} ft');
                        buffer.writeln('Pipe Grid: ${poleSize.toStringAsFixed(0)} ft');
                        buffer.writeln('Vertical Poles: $verticalPoles Poles');
                        if (horizontalPipes > 0) buffer.writeln('Horizontal Runners: $horizontalPipes Pipes');
                        buffer.writeln('Total Pipes: $totalPipes Pipes (${totalPipeFeet.toStringAsFixed(0)} ft)');
                        Clipboard.setData(ClipboardData(text: buffer.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n?.summaryCopied ?? 'Pipes summary copied!'),
                            backgroundColor: const Color(0xFF059669),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
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

  Widget _buildRow(String label, String value, {bool isHighlighted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
