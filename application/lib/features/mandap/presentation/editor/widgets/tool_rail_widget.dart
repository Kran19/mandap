import 'package:flutter/material.dart';
import 'package:mandap/core/theme/app_theme.dart';
import '../../../application/editor_mode.dart';
import '../../../application/mandap_editor_controller.dart';

/// Left vertical floating tool rail for the CAD editor.
/// Rendered as a clean white SaaS card per master spec.
class ToolRailWidget extends StatelessWidget {
  final MandapEditorController controller;
  final VoidCallback onGridSettings;
  final VoidCallback onEditorSettings;
  final bool isMeasuring;
  final VoidCallback onToggleMeasure;
  final VoidCallback? onConfigureDimensions;
  final VoidCallback? onToggleCollapse;

  const ToolRailWidget({
    super.key,
    required this.controller,
    required this.onGridSettings,
    required this.onEditorSettings,
    this.isMeasuring = false,
    required this.onToggleMeasure,
    this.onConfigureDimensions,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final canUndo = controller.history.canUndo;
    final canRedo = controller.history.canRedo;

    return Container(
      width: 64,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.headerBorder),
        boxShadow: AppShadows.floatingShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleCollapse != null) ...[
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.secondaryText),
                tooltip: 'Hide Tools',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
                onPressed: onToggleCollapse,
              ),
            ] else
              const SizedBox(height: 8),

            // Select Tool
            _buildToolItem(
              icon: Icons.near_me_outlined,
              label: 'Select',
              tooltip: 'Select Elements (↖)',
              isActive: controller.mode == EditorMode.select && !isMeasuring,
              onTap: () {
                if (isMeasuring) onToggleMeasure();
                controller.setMode(EditorMode.select);
              },
            ),

            // Move Tool
            _buildToolItem(
              icon: Icons.open_with_rounded,
              label: 'Move',
              tooltip: 'Move Selected (✣)',
              isActive: controller.mode == EditorMode.move && !isMeasuring,
              onTap: () {
                if (isMeasuring) onToggleMeasure();
                controller.setMode(EditorMode.move);
              },
            ),

            // Pencil Tool (Truss continuous polyline drawing)
            _buildToolItem(
              icon: Icons.edit_rounded,
              label: 'Pencil',
              tooltip: 'Pencil / Draw Truss (✎)',
              isActive: controller.mode == EditorMode.addEdge && !isMeasuring,
              onTap: () {
                if (isMeasuring) onToggleMeasure();
                controller.setMode(EditorMode.addEdge);
              },
            ),

            // Add Pole Tool
            _buildToolItem(
              icon: Icons.view_column_rounded,
              label: 'Pole',
              tooltip: 'Add Support Pole (│)',
              isActive: controller.mode == EditorMode.addNode && !isMeasuring,
              onTap: () {
                if (isMeasuring) onToggleMeasure();
                controller.setMode(EditorMode.addNode);
              },
            ),

            // Eraser Tool
            _buildToolItem(
              icon: Icons.cleaning_services_rounded,
              label: 'Eraser',
              tooltip: 'Delete Selected (◇)',
              isActive: controller.mode == EditorMode.delete && !isMeasuring,
              onTap: () {
                if (isMeasuring) onToggleMeasure();
                controller.setMode(EditorMode.delete);
              },
            ),

            // Configure Dimensions (Size) Tool
            if (onConfigureDimensions != null)
              _buildToolItem(
                icon: Icons.straighten_rounded,
                label: 'Size',
                tooltip: 'Configure Dimensions',
                isActive: false,
                onTap: onConfigureDimensions!,
              ),

            // Measure Tool
            _buildToolItem(
              icon: Icons.square_foot_rounded,
              label: 'Measure',
              tooltip: 'Distance Measuring Tool (╱)',
              isActive: isMeasuring,
              onTap: onToggleMeasure,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Divider(height: 1, color: AppColors.headerBorder),
            ),

            // Grid Toggle / Snap Settings Tool
            _buildToolItem(
              icon: Icons.grid_4x4_rounded,
              label: 'Grid',
              tooltip: 'Grid & Snap Settings (▦)',
              isActive: false,
              onTap: onGridSettings,
            ),

            // Settings Tool
            _buildToolItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              tooltip: 'Editor Settings (⚙)',
              isActive: false,
              onTap: onEditorSettings,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Divider(height: 1, color: AppColors.headerBorder),
            ),

            // Undo
            IconButton(
              icon: Icon(
                Icons.undo,
                size: 20,
                color: canUndo ? AppColors.primaryText : AppColors.mutedText,
              ),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: canUndo ? () => controller.undo() : null,
            ),

            // Redo
            IconButton(
              icon: Icon(
                Icons.redo,
                size: 20,
                color: canRedo ? AppColors.primaryText : AppColors.mutedText,
              ),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: canRedo ? () => controller.redo() : null,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.trussLight : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? AppColors.trussPrimary : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.trussPrimary : AppColors.secondaryText,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? AppColors.trussPrimary : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
