import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pole_calculator_controller.dart';
import '../../domain/models/pole_calculation_result.dart';

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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Poles Setup Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Poles & Pipes Summary',
                            style: TextStyle(
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
                                  const Row(
                                    children: [
                                      Icon(Icons.all_inbox_rounded, color: Color(0xFF059669), size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Total Pipes',
                                        style: TextStyle(
                                          color: Color(0xFF065F46),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$totalPipes Pipes',
                                    style: const TextStyle(
                                      color: Color(0xFF064E3B),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${totalPipeFeet.toStringAsFixed(0)} ft total length',
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
                                  const Row(
                                    children: [
                                      Icon(Icons.grid_4x4_rounded, color: Color(0xFF2563EB), size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Plot Grid',
                                        style: TextStyle(
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
                                    '${poleSize.toStringAsFixed(0)} ft Pipe Units',
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

                      const Text(
                        'DETAILS',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildRow('Unit Pipe Size', '${poleSize.toStringAsFixed(0)} ft Pipe'),
                      _buildRow('Vertical Standing Poles', '$verticalPoles Poles'),
                      if (horizontalPipes > 0)
                        _buildRow('Horizontal Runners', '$horizontalPipes Pipes'),
                      if (ceilingSections > 0)
                        _buildRow('Ceiling Sections', '$ceilingSections Sections'),
                      _buildRow('Grand Total Pipes', '$totalPipes Pipes', isHighlighted: true),
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
                      label: const Text(
                        'Copy',
                        style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
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
                          const SnackBar(
                            content: Text('Pipes summary copied!'),
                            backgroundColor: Color(0xFF059669),
                            duration: Duration(seconds: 2),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('OK / Done', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
