import 'package:flutter/material.dart';
import '../../application/editor_mode.dart';
import '../../domain/entities/mandap_node.dart';

/// Engineering toolbar with direct access to Select, Move, Pencil, Pole, and Erase tools.
class EditorModeBar extends StatelessWidget {
  final EditorMode currentMode;
  final NodeType pendingNodeType;
  final ValueChanged<EditorMode> onModeChanged;
  final ValueChanged<NodeType>? onNodeTypeChanged;
  final String? projectId;
  final VoidCallback? onDeletePressed;

  const EditorModeBar({
    super.key,
    required this.currentMode,
    required this.pendingNodeType,
    required this.onModeChanged,
    this.onNodeTypeChanged,
    this.projectId,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 1. Select Tool
            _buildToolItem(
              icon: Icons.touch_app_rounded,
              label: 'Select',
              isActive: currentMode == EditorMode.select,
              activeColor: const Color(0xFF3B82F6),
              onTap: () {
                onModeChanged(
                  currentMode == EditorMode.select
                      ? EditorMode.view
                      : EditorMode.select,
                );
              },
            ),

            const SizedBox(width: 6),

            // 2. Move / Spread Tool
            _buildToolItem(
              icon: Icons.open_with_rounded,
              label: 'Move',
              isActive: currentMode == EditorMode.move,
              activeColor: const Color(0xFFA855F7),
              onTap: () {
                onModeChanged(
                  currentMode == EditorMode.move
                      ? EditorMode.select
                      : EditorMode.move,
                );
              },
            ),

            const SizedBox(width: 6),

            // 3. Pencil / Draw Truss Tool
            _buildToolItem(
              icon: Icons.edit_rounded,
              label: 'Pencil',
              isActive: currentMode == EditorMode.addEdge,
              activeColor: const Color(0xFF06B6D4),
              onTap: () {
                onModeChanged(
                  currentMode == EditorMode.addEdge
                      ? EditorMode.select
                      : EditorMode.addEdge,
                );
              },
            ),

            const SizedBox(width: 6),

            // 4. Pole Tool
            _buildToolItem(
              icon: Icons.view_column_rounded,
              label: 'Pole',
              isActive: currentMode == EditorMode.addPole,
              activeColor: const Color(0xFF10B981),
              onTap: () {
                onModeChanged(
                  currentMode == EditorMode.addPole
                      ? EditorMode.select
                      : EditorMode.addPole,
                );
              },
            ),

            const SizedBox(width: 6),

            // 5. Erase / Delete Tool
            _buildToolItem(
              icon: Icons.delete_outline_rounded,
              label: 'Erase',
              isActive: currentMode == EditorMode.delete,
              activeColor: const Color(0xFFEF4444),
              onTap: () {
                if (onDeletePressed != null) {
                  onDeletePressed!();
                } else {
                  onModeChanged(
                    currentMode == EditorMode.delete
                        ? EditorMode.select
                        : EditorMode.delete,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.18)
                  : const Color(0xFF1E293B).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? activeColor : const Color(0xFF334155),
                width: isActive ? 1.6 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : Colors.white70,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : Colors.white70,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
