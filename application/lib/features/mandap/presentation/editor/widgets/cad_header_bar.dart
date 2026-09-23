import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mandap/core/theme/app_theme.dart';
import 'package:mandap/core/localization/language_selector_dialog.dart';
import 'package:mandap/l10n/app_localizations.dart';
import '../../../../auth/application/bootstrap_coordinator.dart';
import '../../../../projects/domain/sync_state.dart';
import '../../../../projects/application/project_sync_service.dart';
import '../../../application/mandap_editor_controller.dart';
import '../../mandap_editor_screen.dart';

/// Top CAD-grade header bar for the MANDAP editor.
/// Rendered as a light SaaS header per master spec.
class CadHeaderBar extends StatefulWidget {
  final MandapEditorController controller;
  final String projectName;
  final ValueChanged<String> onProjectNameChanged;
  final ProjectSyncService? syncService;
  final VoidCallback? onSave;
  final VoidCallback? onRetrieve;
  final bool isSaving;
  final ViewMode? viewMode;
  final ValueChanged<ViewMode>? onViewModeChanged;

  const CadHeaderBar({
    super.key,
    required this.controller,
    required this.projectName,
    required this.onProjectNameChanged,
    this.syncService,
    this.onSave,
    this.onRetrieve,
    this.isSaving = false,
    this.viewMode,
    this.onViewModeChanged,
  });

  @override
  State<CadHeaderBar> createState() => _CadHeaderBarState();
}

class _CadHeaderBarState extends State<CadHeaderBar> {
  late TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.projectName);
  }

  @override
  void didUpdateWidget(covariant CadHeaderBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectName != widget.projectName && !_isEditingName) {
      _nameController.text = widget.projectName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<BootstrapCoordinator>();
    final user = coordinator.current.user;
    final displayName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final initials = displayName.isNotEmpty
        ? displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase()
        : ((user?.email.isNotEmpty ?? false)
            ? user!.email.substring(0, 2).toUpperCase()
            : 'RK');

    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 400;
    final isCompact = screenWidth < 900;
    final isFullDesktop = screenWidth >= 1150;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 6 : (isCompact ? 8 : 14)),
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Menu Door Icon Button (Single Door Exit Gateway to 4-Module Menu)
          Tooltip(
            message: 'Exit to Menu',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/modules'),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.meeting_room_outlined, color: AppColors.primaryText, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),

          // Brand Logo & Name
          InkWell(
            onTap: () => context.go('/modules'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.trussLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.architecture_rounded, color: AppColors.trussPrimary, size: 16),
                      ),
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MANDAP BUILDER',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.primaryText,
                          ),
                        ),
                        if (isFullDesktop)
                          const Text(
                            'EVENT STRUCTURE DESIGNER',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.9,
                              color: AppColors.secondaryText,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),



          // Right Controls (Right-aligned, zero-overflow across all viewports)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Project Name Editor
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: _isEditingName
                          ? SizedBox(
                              width: isVeryCompact ? 45 : (screenWidth < 600 ? 55 : 120),
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                style: const TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (val) {
                                  setState(() => _isEditingName = false);
                                  if (val.trim().isNotEmpty) {
                                    widget.onProjectNameChanged(val.trim());
                                  }
                                },
                              ),
                            )
                          : InkWell(
                              onTap: () => setState(() => _isEditingName = true),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: isVeryCompact ? 45 : (screenWidth < 600 ? 55 : 120)),
                                    child: Text(
                                      widget.projectName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.edit_outlined, size: 11, color: AppColors.secondaryText),
                                ],
                              ),
                            ),
                    ),

                    SizedBox(width: isVeryCompact ? 2 : 4),

                    // Retrieve Button
                    if (widget.onRetrieve != null) ...[
                      Tooltip(
                        message: AppLocalizations.of(context)?.retrieveLayout ?? 'Retrieve Saved Design',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onRetrieve,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVeryCompact ? 4 : 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.inputBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.history_rounded, size: 16, color: AppColors.primaryText),
                                  if (screenWidth >= 600) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)?.retrieve ?? 'Retrieve',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isVeryCompact ? 2 : 4),
                    ],

                    // Save Button
                    if (widget.onSave != null) ...[
                      Tooltip(
                        message: AppLocalizations.of(context)?.save ?? 'Save Project',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.isSaving ? null : widget.onSave,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVeryCompact ? 6 : 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.isSaving)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  else
                                    const Icon(Icons.save_rounded, size: 15, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    AppLocalizations.of(context)?.save ?? 'Save',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isVeryCompact ? 2 : 4),
                    ],

                    // Language Selector Button
                    if (!isCompact) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.language_rounded, color: AppColors.primaryText, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        tooltip: 'Language / भाषा',
                        onPressed: () => LanguageSelectorDialog.show(context),
                      ),
                    ],

                    // Profile Initials (Desktop / Tablet view)
                    if (user != null && screenWidth >= 600) ...[
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.trussPrimary,
                        child: Text(
                          initials,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulePill(
    String label,
    String icon,
    bool isActive,
    Color? activeColor,
    Color? activeBg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? (activeBg ?? AppColors.trussLight) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? (activeColor ?? AppColors.trussPrimary) : AppColors.headerBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? (activeColor ?? AppColors.trussPrimary) : AppColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isVeryCompact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 6 : 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.trussPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isVeryCompact ? 10 : 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
