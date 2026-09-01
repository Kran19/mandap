import 'package:flutter/material.dart';
import '../../application/editor_mode.dart';

/// Bottom toolbar showing the active [EditorMode] and allowing mode switching.
///
/// Designed for Android-phone widths (360–412 dp). Uses icon+label buttons
/// in a horizontal scroll so text is never truncated.
class EditorModeBar extends StatelessWidget {
  final EditorMode currentMode;
  final ValueChanged<EditorMode> onModeChanged;

  const EditorModeBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  static const _modes = [
    EditorMode.view,
    EditorMode.select,
    EditorMode.move,
    EditorMode.addNode,
    EditorMode.addEdge,
    EditorMode.delete,
  ];

  static const _icons = {
    EditorMode.view: Icons.pan_tool_alt_outlined,
    EditorMode.select: Icons.touch_app_outlined,
    EditorMode.move: Icons.open_with,
    EditorMode.addNode: Icons.add_location_alt_outlined,
    EditorMode.addEdge: Icons.timeline,
    EditorMode.delete: Icons.delete_outline,
  };

  static const _colors = {
    EditorMode.view: Color(0xFF475569),
    EditorMode.select: Color(0xFF2563EB),
    EditorMode.move: Color(0xFF7C3AED),
    EditorMode.addNode: Color(0xFF16A34A),
    EditorMode.addEdge: Color(0xFF0891B2),
    EditorMode.delete: Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: _modes
              .map(
                (mode) => _ModeButton(
                  mode: mode,
                  isActive: mode == currentMode,
                  icon: _icons[mode]!,
                  activeColor: _colors[mode]!,
                  onTap: () => onModeChanged(mode),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final EditorMode mode;
  final bool isActive;
  final IconData icon;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.mode,
    required this.isActive,
    required this.icon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF334155),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? activeColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              mode.shortLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? activeColor : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
