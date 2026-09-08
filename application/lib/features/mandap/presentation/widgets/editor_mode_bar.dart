import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../application/editor_mode.dart';
import '../../domain/entities/mandap_node.dart';

/// Bottom toolbar showing only the [Delete] mode toggle and [Add Component] button.
class EditorModeBar extends StatelessWidget {
  final EditorMode currentMode;
  final NodeType pendingNodeType;
  final ValueChanged<EditorMode> onModeChanged;
  final ValueChanged<NodeType>? onNodeTypeChanged;
  final String? projectId;

  const EditorModeBar({
    super.key,
    required this.currentMode,
    required this.pendingNodeType,
    required this.onModeChanged,
    this.onNodeTypeChanged,
    this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final isDelete = currentMode == EditorMode.delete;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Delete Mode Button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (isDelete) {
                      onModeChanged(EditorMode.select);
                    } else {
                      onModeChanged(EditorMode.delete);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDelete
                          ? const Color(0xFFDC2626).withValues(alpha: 0.22)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDelete
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF334155),
                        width: isDelete ? 1.8 : 1.0,
                      ),
                      boxShadow: isDelete
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFFDC2626).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDelete
                              ? Icons.delete_forever_rounded
                              : Icons.delete_outline_rounded,
                          color: isDelete
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF87171),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDelete ? 'Delete (Active)' : 'Delete',
                          style: TextStyle(
                            color: isDelete
                                ? const Color(0xFFEF4444)
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Add Component Button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (projectId != null && projectId!.isNotEmpty) {
                      context.go('/component-wizard?projectId=$projectId');
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
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
