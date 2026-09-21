import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/locale_notifier.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/bootstrap_coordinator.dart';
import '../../mandap/domain/generators/base_truss_architecture_generator.dart';
import '../../mandap/presentation/wizard/create_truss_dialog.dart';
import '../../pole/presentation/widgets/create_pole_dialog.dart';
import '../../stage/presentation/widgets/create_stage_dialog.dart';
import '../../flooring/presentation/widgets/create_flooring_dialog.dart';
import '../../projects/infrastructure/local_project_store.dart';
import '../../projects/presentation/widgets/my_projects_section.dart';

/// Module Selection Screen
/// Displays the 4 independent structural modules of MANDAP using custom high-res logo assets:
/// 🔵 TRUSS -> assets/images/truss.png
/// 🟠 POLE -> assets/images/poles.png
/// 🔴 STAGE -> assets/images/stage.png
/// 🟢 FLOORING -> assets/images/florring.png
class ModuleSelectionScreen extends StatefulWidget {
  final int initialTabIndex;
  const ModuleSelectionScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ModuleSelectionScreen> createState() => _ModuleSelectionScreenState();
}

class _ModuleSelectionScreenState extends State<ModuleSelectionScreen> {
  late int _selectedTabIndex;
  Key _projectsKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

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
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF334155), width: 1),
            ),
            title: Text(
              l10n?.exitApp ?? 'Exit MANDAP?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            content: Text(
              l10n?.confirmExit ?? 'Are you sure you want to exit the application?',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  l10n?.cancel ?? 'Cancel',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
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
        body: Stack(
          children: [
            // Photorealistic outdoor event plaza background
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Elegant frosted glass gradient overlay for high contrast and readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.65),
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),
            // Foreground Content
            SafeArea(
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
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          border: const Border(bottom: BorderSide(color: AppColors.headerBorder)),
                        ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
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
                              'MANDAP BUILDER',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
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
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                            constraints: BoxConstraints(maxWidth: isCompact ? 50 : 85),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Segmented Switcher: Design Modules | My Projects
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.headerBorder, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedTabIndex = 0),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 0 ? AppColors.trussPrimary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.dashboard_rounded,
                                        size: 18,
                                        color: _selectedTabIndex == 0 ? Colors.white : AppColors.secondaryText,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Design Modules',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _selectedTabIndex == 0 ? Colors.white : AppColors.primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() {
                                _selectedTabIndex = 1;
                                _projectsKey = UniqueKey();
                              }),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 1 ? AppColors.trussPrimary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.folder_special_rounded,
                                        size: 18,
                                        color: _selectedTabIndex == 1 ? Colors.white : AppColors.secondaryText,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'My Projects',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _selectedTabIndex == 1 ? Colors.white : AppColors.primaryText,
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
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: _selectedTabIndex == 1
                          ? MyProjectsSection(
                              key: _projectsKey,
                              onCreateTrussTap: () => _handleTrussModuleTap(context),
                              onCreatePoleTap: () => _handlePoleModuleTap(context),
                              onCreateStageTap: () => _handleStageModuleTap(context),
                              onCreateFlooringTap: () => _handleFlooringModuleTap(context),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  l10n?.chooseWhatToDesign ?? 'Choose what to design',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n?.selectModuleSubtitle ?? 'Select an independent structural module to begin your event layout',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                    shadows: [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),

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
                                          onTap: () => _handleTrussModuleTap(context),
                                        ),

                                        // 🟠 PIPE
                                        _buildModuleCard(
                                          context: context,
                                          title: l10n?.pipe.toUpperCase() ?? 'PIPE',
                                          subtitle: l10n?.modulePipeSubtitle ?? 'Pipe Calculator',
                                          badge: l10n?.active ?? 'ACTIVE',
                                          openText: l10n?.open ?? 'OPEN',
                                          imagePath: 'assets/images/poles.png',
                                          accentColor: AppColors.polePrimary,
                                          lightBg: AppColors.poleLight,
                                          onTap: () => _handlePoleModuleTap(context),
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
                                          onTap: () => _handleStageModuleTap(context),
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
                                          onTap: () => _handleFlooringModuleTap(context),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Quick shortcut to My Projects
                                InkWell(
                                  onTap: () => setState(() {
                                    _selectedTabIndex = 1;
                                    _projectsKey = UniqueKey();
                                  }),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.headerBorder),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.folder_special_rounded, color: AppColors.trussPrimary, size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            'View all saved layouts in My Projects',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, color: AppColors.trussPrimary, size: 16),
                                        ],
                                      ),
                                    ),
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
      ],
    ),
  ),
);
}

  Future<void> _handleTrussModuleTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLen = prefs.getDouble('truss_last_length') ?? 100.0;
    final savedWid = prefs.getDouble('truss_last_width') ?? 100.0;
    final savedSize = prefs.getDouble('truss_last_size') ?? 30.0;

    if (!context.mounted) return;
    final params = await CreateTrussDialog.show(
      context,
      initialLength: savedLen,
      initialWidth: savedWid,
      initialTrussSize: savedSize,
    );
    if (params == null || !context.mounted) return;

    final projectId = 'truss_${DateTime.now().millisecondsSinceEpoch}';
    final store = LocalProjectStore();
    await store.saveProjectRecord(
      MandapSavedProject(
        id: projectId,
        title: 'Truss ${params.plotWidth.toStringAsFixed(0)} × ${params.plotLength.toStringAsFixed(0)} ft',
        moduleType: 'truss',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parameters: {
          'width': params.plotWidth,
          'length': params.plotLength,
          'trussSize': params.trussSize,
        },
      ),
    );

    if (context.mounted) {
      await context.push(
        '/editor?projectId=$projectId&trussSize=${params.trussSize}&width=${params.plotWidth}&length=${params.plotLength}',
      );
      if (mounted) setState(() => _projectsKey = UniqueKey());
    }
  }

  Future<void> _handlePoleModuleTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLen = prefs.getDouble('pole_last_length') ?? 100.0;
    final savedWid = prefs.getDouble('pole_last_width') ?? 100.0;
    final savedSize = prefs.getDouble('pole_last_pipe_size') ?? 15.0;

    if (!context.mounted) return;
    final params = await CreatePoleDialog.show(
      context,
      initialLength: savedLen,
      initialWidth: savedWid,
      initialPipeSize: savedSize,
    );
    if (params == null || !context.mounted) return;

    final projectId = 'pole_${DateTime.now().millisecondsSinceEpoch}';
    final store = LocalProjectStore();
    await store.saveProjectRecord(
      MandapSavedProject(
        id: projectId,
        title: 'Pipe ${params.plotWidth.toStringAsFixed(0)} × ${params.plotLength.toStringAsFixed(0)} ft',
        moduleType: 'pole',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parameters: {
          'width': params.plotWidth,
          'length': params.plotLength,
          'pipeSize': params.pipeSize,
        },
      ),
    );

    if (context.mounted) {
      await context.push(
        '/pole?projectId=$projectId&length=${params.plotLength}&width=${params.plotWidth}&pipeSize=${params.pipeSize}',
      );
      if (mounted) setState(() => _projectsKey = UniqueKey());
    }
  }

  Future<void> _handleStageModuleTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLen = prefs.getDouble('stage_last_length') ?? 32.0;
    final savedWid = prefs.getDouble('stage_last_width') ?? 20.0;
    final savedTL = prefs.getDouble('stage_last_table_length') ?? 4.0;
    final savedTW = prefs.getDouble('stage_last_table_width') ?? 8.0;

    if (!context.mounted) return;
    final params = await CreateStageDialog.show(
      context,
      initialStageLength: savedLen,
      initialStageWidth: savedWid,
      initialTableLength: savedTL,
      initialTableWidth: savedTW,
    );
    if (params == null || !context.mounted) return;

    final projectId = 'stage_${DateTime.now().millisecondsSinceEpoch}';
    final store = LocalProjectStore();
    await store.saveProjectRecord(
      MandapSavedProject(
        id: projectId,
        title: 'Stage ${params.stageWidth.toStringAsFixed(0)} × ${params.stageLength.toStringAsFixed(0)} ft',
        moduleType: 'stage',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parameters: {
          'width': params.stageWidth,
          'length': params.stageLength,
          'tableLength': params.tableLength,
          'tableWidth': params.tableWidth,
        },
      ),
    );

    if (context.mounted) {
      await context.push(
        '/stage?projectId=$projectId&length=${params.stageLength}&width=${params.stageWidth}&tableLength=${params.tableLength}&tableWidth=${params.tableWidth}',
      );
      if (mounted) setState(() => _projectsKey = UniqueKey());
    }
  }

  Future<void> _handleFlooringModuleTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPL = prefs.getDouble('flooring_last_plot_length') ?? 100.0;
    final savedPW = prefs.getDouble('flooring_last_plot_width') ?? 60.0;
    final savedCL = prefs.getDouble('flooring_last_carpet_length') ?? 15.0;
    final savedCW = prefs.getDouble('flooring_last_carpet_width') ?? 30.0;

    if (!context.mounted) return;
    final params = await CreateFlooringDialog.show(
      context,
      initialPlotLength: savedPL,
      initialPlotWidth: savedPW,
      initialCarpetLength: savedCL,
      initialCarpetWidth: savedCW,
    );
    if (params == null || !context.mounted) return;

    final projectId = 'flooring_${DateTime.now().millisecondsSinceEpoch}';
    final store = LocalProjectStore();
    await store.saveProjectRecord(
      MandapSavedProject(
        id: projectId,
        title: 'Flooring ${params.plotWidth.toStringAsFixed(0)} × ${params.plotLength.toStringAsFixed(0)} ft',
        moduleType: 'flooring',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parameters: {
          'width': params.plotWidth,
          'length': params.plotLength,
          'carpetLength': params.carpetLength,
          'carpetWidth': params.carpetWidth,
        },
      ),
    );

    if (context.mounted) {
      await context.push(
        '/flooring?projectId=$projectId&length=${params.plotLength}&width=${params.plotWidth}&carpetLength=${params.carpetLength}&carpetWidth=${params.carpetWidth}',
      );
      if (mounted) setState(() => _projectsKey = UniqueKey());
    }
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
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
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

