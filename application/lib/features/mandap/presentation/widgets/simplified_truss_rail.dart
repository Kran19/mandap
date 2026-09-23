import 'package:flutter/material.dart';
import 'package:mandap/l10n/app_localizations.dart';
import '../../application/editor_mode.dart';
import '../../application/mandap_editor_controller.dart';

/// Compact left tool rail containing Pencil, Eraser, Config, Undo, and Redo buttons.
class SimplifiedTrussRail extends StatelessWidget {
  final MandapEditorController controller;
  final bool isAnimating;
  final VoidCallback? onConfigTap;
  final VoidCallback? onPencilTap;

  const SimplifiedTrussRail({
    super.key,
    required this.controller,
    this.isAnimating = false,
    this.onConfigTap,
    this.onPencilTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isPencilActive = controller.mode == EditorMode.addEdge;
        final isPoleActive = controller.mode == EditorMode.addPole;
        final isEraserActive = controller.mode == EditorMode.delete;
        final canUndo = controller.history.canUndo;
        final canRedo = controller.history.canRedo;

        return Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. PENCIL Tool (Draw Truss)
              _buildToolButton(
                icon: Icons.edit_rounded,
                tooltip: isPencilActive
                    ? 'Pencil Active (Tap 1st node then 2nd to draw)'
                    : (l10n?.drawTruss ?? 'Draw Truss (Pencil)'),
                isActive: isPencilActive && !isAnimating,
                activeBg: const Color(0xFF0284C7),
                activeBorder: const Color(0xFF00E5FF),
                iconColor: isPencilActive ? Colors.white : const Color(0xFF00E5FF),
                onTap: () {
                  if (isPencilActive) {
                    controller.setMode(EditorMode.view);
                  } else {
                    controller.setMode(EditorMode.addEdge);
                    onPencilTap?.call();
                  }
                },
              ),

              const SizedBox(height: 5),

              // 2. ERASER Tool
              _buildToolButton(
                icon: Icons.cleaning_services_rounded,
                tooltip: isEraserActive
                    ? 'Eraser Active (Tap truss to remove)'
                    : (l10n?.eraserTool ?? 'Eraser Tool'),
                isActive: isEraserActive && !isAnimating,
                activeBg: const Color(0xFFDC2626),
                activeBorder: const Color(0xFFF87171),
                iconColor: isEraserActive ? Colors.white : const Color(0xFFF87171),
                onTap: () {
                  if (isEraserActive) {
                    controller.setMode(EditorMode.view);
                  } else {
                    controller.setMode(EditorMode.delete);
                  }
                },
              ),

              const SizedBox(height: 5),

              // 3. POLE Tool (Place Pole)
              _buildToolButton(
                icon: Icons.view_column_rounded,
                tooltip: isPoleActive
                    ? 'Pole Active (Tap anywhere to place pole)'
                    : (l10n?.addPoleTool ?? 'Add Pole Tool'),
                isActive: isPoleActive && !isAnimating,
                activeBg: const Color(0xFFEA580C),
                activeBorder: const Color(0xFFFB923C),
                iconColor: isPoleActive ? Colors.white : const Color(0xFFFB923C),
                onTap: () {
                  if (isPoleActive) {
                    controller.setMode(EditorMode.view);
                  } else {
                    controller.setMode(EditorMode.addPole);
                  }
                },
              ),

              const SizedBox(height: 5),

              // 4. TRUSS PIECE & GATE CONFIG Tool
              _buildToolButton(
                icon: Icons.tune_rounded,
                tooltip: 'Truss Piece & Gate Configuration',
                isActive: false,
                activeBg: const Color(0xFF6366F1),
                activeBorder: const Color(0xFF818CF8),
                iconColor: const Color(0xFF38BDF8),
                onTap: () {
                  onConfigTap?.call();
                },
              ),

              const SizedBox(height: 4),
              const Divider(height: 1, color: Color(0xFF334155), indent: 2, endIndent: 2),
              const SizedBox(height: 4),

              // 4. UNDO (Backward) Button
              _buildToolButton(
                icon: Icons.undo_rounded,
                tooltip: canUndo ? 'Undo Last Action' : 'Nothing to Undo',
                isActive: false,
                isEnabled: canUndo,
                activeBg: const Color(0xFF1E293B),
                activeBorder: const Color(0xFF475569),
                iconColor: canUndo ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                onTap: canUndo ? controller.undo : () {},
              ),

              const SizedBox(height: 5),

              // 5. REDO (Forward) Button
              _buildToolButton(
                icon: Icons.redo_rounded,
                tooltip: canRedo ? 'Redo Action' : 'Nothing to Redo',
                isActive: false,
                isEnabled: canRedo,
                activeBg: const Color(0xFF1E293B),
                activeBorder: const Color(0xFF475569),
                iconColor: canRedo ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                onTap: canRedo ? controller.redo : () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    bool isEnabled = true,
    required Color activeBg,
    required Color activeBorder,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isActive ? activeBg : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? activeBorder : const Color(0xFF334155),
                width: 1.2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeBorder.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 17,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
