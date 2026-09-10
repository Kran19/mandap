import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/locale_notifier.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/bootstrap_coordinator.dart';

/// Module Selection Screen
/// Displays the 4 independent structural modules of MANDAP using custom high-res logo assets:
/// 🔵 TRUSS -> assets/images/truss.png
/// 🟠 POLE -> assets/images/poles.png
/// 🔴 STAGE -> assets/images/stage.png
/// 🟢 FLOORING -> assets/images/florring.png
class ModuleSelectionScreen extends StatelessWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<BootstrapCoordinator>();
    final user = coordinator.current.user;
    final l10n = AppLocalizations.of(context);
    final localeNotifier = context.watch<LocaleNotifier>();
    final currentLang = localeNotifier.currentLanguage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              l10n?.exitApp ?? 'Exit MANDAP?',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
            content: Text(
              l10n?.confirmExit ?? 'Are you sure you want to exit the application?',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n?.cancel ?? 'Cancel', style: const TextStyle(color: AppColors.secondaryText)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.trussPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n?.exit ?? 'Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Top App Bar / Header
              LayoutBuilder(
                builder: (context, headerConstraints) {
                  final isCompact = headerConstraints.maxWidth < 600;
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 24,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.headerBackground,
                      border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.trussLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.architecture_rounded, color: AppColors.trussPrimary, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MANDAP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.primaryText,
                              ),
                            ),
                            if (!isCompact)
                              const Text(
                                'EVENT STRUCTURE DESIGNER',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        // Language Selector Pill
                        InkWell(
                          onTap: () => LanguageSelectorDialog.show(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(currentLang.flag, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: isCompact ? 55 : 85),
                                  child: Text(
                                    currentLang.nativeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.secondaryText),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (user != null)
                          Builder(
                            builder: (context) {
                              final u = user;
                              final displayName = '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();
                              final displayInitials = displayName.isNotEmpty
                                  ? displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase()
                                  : (u.email.isNotEmpty ? u.email.substring(0, 2).toUpperCase() : 'U');
                              final effectiveName = displayName.isNotEmpty ? displayName : (u.email.isNotEmpty ? u.email : 'Designer');
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.inputBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 11,
                                      backgroundColor: AppColors.trussPrimary,
                                      child: Text(
                                        displayInitials,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    if (!isCompact) ...[
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 90),
                                        child: Text(
                                          effectiveName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: AppColors.primaryText, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.logout_rounded, color: AppColors.secondaryText, size: 18),
                          tooltip: l10n?.logout ?? 'Logout',
                          onPressed: () => context.read<BootstrapCoordinator>().logout(),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Content Area
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n?.chooseWhatToDesign ?? 'Choose what to design',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n?.selectModuleSubtitle ?? 'Select an independent structural module to begin your event layout',
                            style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 36),

                          // 2x2 Grid of Modules
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: isMobile ? 1 : 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: isMobile ? 2.0 : 1.35,
                                children: [
                                  // 🔵 TRUSS
                                  _buildModuleCard(
                                    context: context,
                                    title: l10n?.truss.toUpperCase() ?? 'TRUSS',
                                    subtitle: l10n?.moduleTrussSubtitle ?? 'Structural Truss Design',
                                    badge: l10n?.active ?? 'ACTIVE',
                                    openText: l10n?.open ?? 'OPEN',
                                    imagePath: 'assets/images/truss.png',
                                    accentColor: AppColors.trussPrimary,
                                    lightBg: AppColors.trussLight,
                                    onTap: () => context.go('/editor'),
                                  ),

                                  // 🟠 POLE
                                  _buildModuleCard(
                                    context: context,
                                    title: l10n?.pole.toUpperCase() ?? 'POLE',
                                    subtitle: l10n?.modulePoleSubtitle ?? 'Pole Calculator',
                                    badge: l10n?.active ?? 'ACTIVE',
                                    openText: l10n?.open ?? 'OPEN',
                                    imagePath: 'assets/images/poles.png',
                                    accentColor: AppColors.polePrimary,
                                    lightBg: AppColors.poleLight,
                                    onTap: () => context.go('/pole'),
                                  ),

                                  // 🔴 STAGE
                                  _buildModuleCard(
                                    context: context,
                                    title: l10n?.stage.toUpperCase() ?? 'STAGE',
                                    subtitle: l10n?.moduleStageSubtitle ?? 'Stage Calculator',
                                    badge: l10n?.active ?? 'ACTIVE',
                                    openText: l10n?.open ?? 'OPEN',
                                    imagePath: 'assets/images/stage.png',
                                    accentColor: AppColors.stagePrimary,
                                    lightBg: AppColors.stageLight,
                                    onTap: () => context.go('/stage'),
                                  ),

                                  // 🟢 FLOORING
                                  _buildModuleCard(
                                    context: context,
                                    title: l10n?.flooring.toUpperCase() ?? 'FLOORING',
                                    subtitle: l10n?.moduleFlooringSubtitle ?? 'Carpet & Flooring Calculator',
                                    badge: l10n?.active ?? 'ACTIVE',
                                    openText: l10n?.open ?? 'OPEN',
                                    imagePath: 'assets/images/florring.png',
                                    accentColor: AppColors.flooringPrimary,
                                    lightBg: AppColors.flooringLight,
                                    onTap: () => context.go('/flooring'),
                                  ),
                                ],
                              );
                            },
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
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required String openText,
    required String imagePath,
    required Color accentColor,
    required Color lightBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.headerBorder, width: 1.0),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Custom Module Logo Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.apps_rounded, color: accentColor, size: 28),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          openText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, color: accentColor, size: 14),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

