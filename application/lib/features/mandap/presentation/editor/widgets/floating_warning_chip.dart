import 'package:flutter/material.dart';
import '../../../domain/value_objects/structural_analysis_report.dart';

/// Floating, compact warning chip pinned below the header.
/// Rendered in light SaaS style per master visual spec.
class FloatingWarningChip extends StatelessWidget {
  final StructuralAnalysisReport? report;
  final VoidCallback onTap;

  const FloatingWarningChip({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (report == null || report!.isClean || report!.warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstWarning = report!.warnings.first;
    final remainingCount = report!.warnings.length - 1;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Light orange background per spec
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDBA74), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.08),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      firstWarning.replaceAll('⚠️ ', ''),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9A3412), // Dark orange text per spec
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (remainingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+$remainingCount more',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFEA580C)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
