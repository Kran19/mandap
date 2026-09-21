import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// One-time dismissible banner shown after construction animation completes.
class TrussReadyHintBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const TrussReadyHintBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.trussPrimary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppShadows.floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.trussLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.trussPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'TRUSS READY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.primaryText,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.secondaryText),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Use PEN to draw additional Truss anywhere on the plot.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.3),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.trussPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'GOT IT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
