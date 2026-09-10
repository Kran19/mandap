import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../application/mandap_editor_controller.dart';
import '../../application/editor_mode.dart';

class EditorToolbar extends StatelessWidget {
  final MandapEditorController controller;

  const EditorToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // We observe the controller for selection/mode changes to dynamically update the toolbar
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasSelection = controller.selectedNodeId != null || controller.selectedEdgeId != null;
        final hasEdgeSelected = controller.selectedEdgeId != null;
        
        return Card(
          elevation: 6,
          color: const Color(0xFF1E293B), // High contrast dark
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTool(
                  icon: Icons.pan_tool,
                  label: l10n.select,
                  isActive: controller.mode == EditorMode.view,
                  onTap: () => controller.setMode(EditorMode.view),
                ),
                _buildTool(
                  icon: Icons.touch_app,
                  label: l10n.pen,
                  isActive: controller.mode == EditorMode.select || controller.mode == EditorMode.move,
                  onTap: () => controller.setMode(EditorMode.select),
                ),
                _buildTool(
                  icon: Icons.draw,
                  label: l10n.addMember,
                  isActive: controller.mode == EditorMode.addEdge,
                  onTap: () => controller.setMode(EditorMode.addEdge),
                ),
                
                // Contextual Stretch
                if (hasEdgeSelected) ...[
                  Container(width: 1, height: 24, color: Colors.grey[600], margin: const EdgeInsets.symmetric(horizontal: 8)),
                  _buildTool(
                    icon: Icons.straighten,
                    label: l10n.stretch,
                    isActive: false,
                    onTap: () {
                      // Stretch is intrinsically handled by moving nodes, 
                      // but tapping this could highlight the endpoints or switch to move mode.
                      controller.setMode(EditorMode.select);
                    },
                    color: const Color(0xFF3B82F6), // Accent color
                  ),
                ],

                Container(width: 1, height: 24, color: Colors.grey[600], margin: const EdgeInsets.symmetric(horizontal: 8)),

                // Actions
                _buildActionButton(
                  icon: Icons.undo,
                  tooltip: l10n.undo,
                  onPressed: controller.history.canUndo ? controller.undo : null,
                ),
                _buildActionButton(
                  icon: Icons.redo,
                  tooltip: l10n.redo,
                  onPressed: controller.history.canRedo ? controller.redo : null,
                ),
                
                _buildActionButton(
                  icon: Icons.delete,
                  tooltip: l10n.delete,
                  color: Colors.redAccent,
                  onPressed: hasSelection ? controller.deleteSelected : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTool({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isActive ? Colors.white : (color ?? Colors.grey[400])),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : (color ?? Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: color ?? Colors.white,
      disabledColor: Colors.grey[700],
      onPressed: onPressed,
      iconSize: 20,
    );
  }
}
