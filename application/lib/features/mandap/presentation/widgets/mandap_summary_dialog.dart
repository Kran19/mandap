import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../application/mandap_editor_controller.dart';
import '../../domain/entities/mandap_layout.dart';
import '../../domain/value_objects/mandap_calculation_result.dart';
import '../../../../l10n/app_localizations.dart';

/// Clean, bright, high-contrast, simple design summary popup for Mandap Truss Structure.
/// Replaces "pieces" with "Truss" and is easy for anyone to understand at a glance.
class MandapSummaryDialog extends StatelessWidget {
  final MandapEditorController controller;

  const MandapSummaryDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, {required MandapEditorController controller}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => MandapSummaryDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layout = controller.layout;
    final result = controller.result;

    // 1. Calculate Truss Breakdown
    final Map<double, int> pieceCounts = {};
    double calculatedTotalFeet = 0;
    int calculatedTotalPieces = 0;

    if (result.requiredTrussBySize.isNotEmpty) {
      for (final entry in result.requiredTrussBySize.entries) {
        final size = entry.key.length.feet;
        final count = entry.value;
        if (count > 0) {
          pieceCounts[size] = (pieceCounts[size] ?? 0) + count;
          calculatedTotalFeet += size * count;
          calculatedTotalPieces += count;
        }
      }
    }

    if (pieceCounts.isEmpty && result.edgeSolutions.isNotEmpty) {
      for (final sol in result.edgeSolutions.values) {
        for (final piece in sol.pieces) {
          final size = piece.length.feet;
          pieceCounts[size] = (pieceCounts[size] ?? 0) + 1;
          calculatedTotalFeet += size;
          calculatedTotalPieces += 1;
        }
      }
    }

    if (pieceCounts.isEmpty && layout.edges.isNotEmpty) {
      final stdSize = controller.standardTrussPieceSize > 0 ? controller.standardTrussPieceSize : 30.0;
      for (final edge in layout.edges.values) {
        final start = layout.getNode(edge.startNodeId);
        final end = layout.getNode(edge.endNodeId);
        if (start != null && end != null) {
          final len = (math.sqrt(math.pow(start.x - end.x, 2) + math.pow(start.z - end.z, 2))).roundToDouble();
          if (len > 0) {
            final fullPieces = (len / stdSize).floor();
            final remainder = len - (fullPieces * stdSize);
            if (fullPieces > 0) {
              pieceCounts[stdSize] = (pieceCounts[stdSize] ?? 0) + fullPieces;
              calculatedTotalFeet += fullPieces * stdSize;
              calculatedTotalPieces += fullPieces;
            }
            if (remainder > 0) {
              pieceCounts[remainder] = (pieceCounts[remainder] ?? 0) + 1;
              calculatedTotalFeet += remainder;
              calculatedTotalPieces += 1;
            }
          }
        }
      }
    }

    // Sorted descending by size
    final sortedSizes = pieceCounts.keys.toList()..sort((a, b) => b.compareTo(a));

    final totalFeet = calculatedTotalFeet > 0 ? calculatedTotalFeet : result.totalTrussLengthFt;
    final totalTrusses = calculatedTotalPieces > 0 ? calculatedTotalPieces : layout.edges.length;

    // Support Poles count
    final totalPoles = result.totalPoleCount > 0 ? result.totalPoleCount : layout.nodes.length;
    final cornerPoles = result.cornerPoleCount > 0 ? result.cornerPoleCount : math.min(4, totalPoles);
    final intermediatePoles = math.max(0, totalPoles - cornerPoles);

    // External Gates count
    final externalStructureIds = layout.nodes.values
        .map((n) => n.structureId)
        .where((id) => id != null && id != 'main')
        .toSet()
        .cast<String>()
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
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
              // 1. Clean Bright Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF059669), // Crisp emerald green
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
                        Icons.check_circle_rounded,
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
                            l10n?.designComplete ?? 'Design Complete',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n?.trussAndPolesSummary ?? 'Truss & Poles Summary',
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

              // 2. Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top 2 Big Hero Cards (Total Trusses & Total Poles)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Total Trusses Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4), // Light Green
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.view_in_ar_rounded, color: Color(0xFF059669), size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              l10n?.totalTrusses ?? 'Total Trusses',
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
                                          '$totalTrusses ${l10n?.truss ?? "Truss"}',
                                          style: const TextStyle(
                                            color: Color(0xFF064E3B),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${totalFeet.toStringAsFixed(0)} ft ${l10n?.totalSpan ?? "Total Span"}',
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Image.asset(
                                        'assets/images/trusssingle.png',
                                        height: 36,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Support Poles Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF), // Light Blue
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.vertical_align_top_rounded, color: Color(0xFF2563EB), size: 18),
                                              const SizedBox(width: 6),
                                              Text(
                                                l10n?.supportPoles ?? 'Support Poles',
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
                                            '$totalPoles ${l10n?.poles ?? "Poles"}',
                                            style: const TextStyle(
                                              color: Color(0xFF1E3A8A),
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$cornerPoles ${l10n?.corner ?? "Corner"} + $intermediatePoles ${l10n?.mid ?? "Mid"}',
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Image.asset(
                                      'assets/images/straight.png',
                                      height: 78,
                                      width: 52,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section Title
                      Text(
                        l10n?.trussSizesUsed ?? 'TRUSS SIZES USED',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Itemized List of Sizes Used (e.g. 50 ft Truss : 4 Truss)
                      if (sortedSizes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              l10n?.noTrussMembersDrawn ?? 'No truss members drawn yet.',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        ...sortedSizes.map((size) {
                          final count = pieceCounts[size] ?? 0;
                          final subtotalFt = size * count;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${size.toStringAsFixed(0)} ft ${l10n?.truss ?? "Truss"}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$count ${l10n?.truss ?? "Truss"}',
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${subtotalFt.toStringAsFixed(0)} ft ${l10n?.totalLength ?? "total length"}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${((subtotalFt / (totalFeet > 0 ? totalFeet : 1)) * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      // Gates section (if any)
                      if (externalStructureIds.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n?.gatesAndEntrances ?? 'GATES & ENTRANCES',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...externalStructureIds.map((structId) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.door_sliding_outlined, color: Color(0xFFD97706), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n?.gateOpening ?? "Gate Opening"} ($structId)',
                                  style: const TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Simple Clean Footer
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
                        buffer.writeln('=== MANDAP TRUSS SUMMARY ===');
                        buffer.writeln('Total Trusses: $totalTrusses Truss (${totalFeet.toStringAsFixed(0)} ft)');
                        buffer.writeln('Support Poles: $totalPoles Poles ($cornerPoles Corner, $intermediatePoles Mid)');
                        buffer.writeln('\n--- TRUSSES BY SIZE ---');
                        for (final size in sortedSizes) {
                          final count = pieceCounts[size] ?? 0;
                          buffer.writeln('${size.toStringAsFixed(0)} ft Truss: $count Truss (${(size * count).toStringAsFixed(0)} ft)');
                        }
                        Clipboard.setData(ClipboardData(text: buffer.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n?.summaryCopied ?? 'Summary copied to clipboard!'),
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
                            Text(
                              l10n?.okDone ?? 'OK / Done',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
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
}
