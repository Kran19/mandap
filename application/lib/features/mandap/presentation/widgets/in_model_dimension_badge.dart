import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/mandap_editor_controller.dart';
import '../wizard/create_truss_dialog.dart';

/// In-3D Model Dimension Badge & Quick-Edit Overlay.
/// Compact floating overlay pinned top-center of 3D scene.
class InModelDimensionBadge extends StatelessWidget {
  final MandapEditorController controller;
  final VoidCallback onDimensionUpdated;

  const InModelDimensionBadge({
    super.key,
    required this.controller,
    required this.onDimensionUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final widthVal = controller.plotWidth.round();
    final lenVal = controller.plotDepth.round();
    final lenStr = lenVal == 0 ? 100 : lenVal;
    final widthStr = widthVal == 0 ? 100 : widthVal;
    final sizeVal = controller.standardTrussPieceSize.round();
    final sizeStr = sizeVal == 0 ? 30 : sizeVal;

    final lPadded = lenStr.toString().padLeft(2, '0');
    final wPadded = widthStr.toString().padLeft(2, '0');
    final sPadded = sizeStr.toString().padLeft(2, '0');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final params = await CreateTrussDialog.show(
            context,
            initialLength: lenVal > 0 ? lenVal.toDouble() : 100.0,
            initialWidth: widthVal > 0 ? widthVal.toDouble() : 100.0,
            initialTrussSize: controller.standardTrussPieceSize > 0 ? controller.standardTrussPieceSize : 30.0,
            initialCalculationUnitSize: controller.trussCalculationUnitSize > 0 ? controller.trussCalculationUnitSize : 10.0,
          );
          if (params == null) return;

          controller.reconfigureTrussDimensions(
            plotLength: params.plotLength,
            plotWidth: params.plotWidth,
            trussSize: params.trussSize,
            poleHeight: 20.0,
            includeTowers: true,
          );
          if (params.calculationUnitSize > 0) {
            controller.setTrussCalculationUnitSize(params.calculationUnitSize);
          }
          onDimensionUpdated();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.7), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.aspect_ratio_rounded, color: Color(0xFF00E5FF), size: 15),
                const SizedBox(width: 7),
                // Length / Breadth (00/00 ft)
                Text(
                  '$lPadded/$wPadded ft',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
                // Prominent Box Size Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF7DD3FC), width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${l10n?.box ?? "Box"}: $sPadded/$sPadded ft',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded, color: Color(0xFF94A3B8), size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
