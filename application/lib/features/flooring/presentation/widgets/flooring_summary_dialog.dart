import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../flooring_calculator_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// Clean, bright, simple Flooring / Carpet summary dialog.
class FlooringSummaryDialog extends StatelessWidget {
  final FlooringCalculatorController controller;

  const FlooringSummaryDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, {required FlooringCalculatorController controller}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => FlooringSummaryDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = controller.result;
    final plotLen = controller.plotLength;
    final plotWid = controller.plotWidth;
    final carpetLen = controller.carpetLength;
    final carpetWid = controller.carpetWidth;

    final totalCarpets = result?.totalCarpets ?? ((plotLen / carpetLen).ceil() * (plotWid / carpetWid).ceil());
    final coveredL = result?.coveredLength ?? plotLen;
    final coveredW = result?.coveredWidth ?? plotWid;
    final plotArea = plotLen * plotWid;
    final coveredArea = coveredL * coveredW;
    final excessArea = math.max(0.0, coveredArea - plotArea);
    final carpetUnitArea = carpetLen * carpetWid;

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
                  color: Color(0xFF7C3AED), // Vibrant purple
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
                        Icons.grid_on_rounded,
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
                            l10n?.flooringComplete ?? 'Flooring Complete',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n?.carpetsAndFlooringSummary ?? 'Carpets & Flooring Summary',
                            style: const TextStyle(
                              color: Color(0xFFEDE9FE),
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
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.layers_rounded, color: Color(0xFF7C3AED), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n?.carpetRollsUnits ?? 'Total Carpets',
                                        style: const TextStyle(
                                          color: Color(0xFF5B21B6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$totalCarpets ${l10n?.carpets ?? "Carpets"}',
                                    style: const TextStyle(
                                      color: Color(0xFF4C1D95),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${carpetWid.toStringAsFixed(0)} × ${carpetLen.toStringAsFixed(0)} ft',
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
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
                                        l10n?.totalFloorArea ?? 'Floor Size',
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
                                    '${plotArea.toStringAsFixed(0)} sq ft',
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

                      _buildRow(l10n?.carpetDimensions ?? 'Carpet Size', '${carpetWid.toStringAsFixed(0)} ft × ${carpetLen.toStringAsFixed(0)} ft (${carpetUnitArea.toStringAsFixed(0)} sq ft)'),
                      _buildRow(l10n?.totalCarpetsRequired ?? 'Total Carpets Required', '$totalCarpets ${l10n?.carpets ?? "Carpets"}', isHighlighted: true),
                      _buildRow(l10n?.totalCoverage ?? 'Covered Area', '${coveredL.toStringAsFixed(0)} ft × ${coveredW.toStringAsFixed(0)} ft (${coveredArea.toStringAsFixed(0)} sq ft)'),
                      if (excessArea > 0.1)
                        _buildRow(l10n?.extraCoverage ?? 'Extra Overlap', '+${excessArea.toStringAsFixed(0)} sq ft'),
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
                        buffer.writeln('=== FLOORING SUMMARY ===');
                        buffer.writeln('Plot Size: ${plotLen.toStringAsFixed(0)} × ${plotWid.toStringAsFixed(0)} ft (${plotArea.toStringAsFixed(0)} sq ft)');
                        buffer.writeln('Carpet Size: ${carpetWid.toStringAsFixed(0)} × ${carpetLen.toStringAsFixed(0)} ft');
                        buffer.writeln('Total Carpets: $totalCarpets Carpets');
                        buffer.writeln('Covered Size: ${coveredL.toStringAsFixed(0)} × ${coveredW.toStringAsFixed(0)} ft');
                        Clipboard.setData(ClipboardData(text: buffer.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n?.summaryCopied ?? 'Flooring summary copied!'),
                            backgroundColor: const Color(0xFF7C3AED),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
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
        color: isHighlighted ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFDDD6FE) : const Color(0xFFCBD5E1),
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
