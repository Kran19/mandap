import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Ultra-premium CAD-grade modal popup indicating that 4 supporting poles
/// are required on all perimeter sides before creating a Center Cross (+) structure.
class CenterCrossSupportRequiredDialog extends StatelessWidget {
  final List<String> missingDirections;

  const CenterCrossSupportRequiredDialog({
    super.key,
    required this.missingDirections,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> missingDirections,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CenterCrossSupportRequiredDialog(
        missingDirections: missingDirections,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allDirs = [
      {'id': 'Forward (North)', 'label': 'North', 'sub': 'Top Wall', 'icon': Icons.north_rounded},
      {'id': 'Backward (South)', 'label': 'South', 'sub': 'Bottom Wall', 'icon': Icons.south_rounded},
      {'id': 'Left (West)', 'label': 'West', 'sub': 'Left Wall', 'icon': Icons.west_rounded},
      {'id': 'Right (East)', 'label': 'East', 'sub': 'Right Wall', 'icon': Icons.east_rounded},
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Warning Shield Badge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF78350F).withValues(alpha: 0.35),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              l10n?.centerCrossSupportRequired.toUpperCase() ?? '4 SUPPORT POLES REQUIRED',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Explanation
            Text(
              l10n?.centerCrossSupportDesc ?? 'Center Cross (+) structure cannot be formed because you do not have supporting poles on all 4 sides.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // 4-Direction Status Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: allDirs.map((d) {
                final isMissing = missingDirections.contains(d['id']);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMissing
                        ? const Color(0xFF451A03).withValues(alpha: 0.7)
                        : const Color(0xFF064E3B).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMissing
                          ? const Color(0xFFEF4444).withValues(alpha: 0.7)
                          : const Color(0xFF10B981).withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMissing ? Icons.cancel_rounded : Icons.check_circle_rounded,
                        size: 18,
                        color: isMissing ? const Color(0xFFF87171) : const Color(0xFF34D399),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['label'] as String,
                              style: TextStyle(
                                color: isMissing ? const Color(0xFFFED7AA) : const Color(0xFFD1FAE5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isMissing ? (l10n?.offline ?? 'Missing Pole') : (l10n?.saved ?? 'Pole Ready'),
                              style: TextStyle(
                                color: isMissing ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                ),
                child: Text(
                  l10n?.okDone ?? 'GOT IT',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
