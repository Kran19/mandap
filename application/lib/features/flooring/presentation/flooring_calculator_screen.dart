import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'flooring_calculator_controller.dart';
import 'widgets/create_flooring_dialog.dart';
import 'widgets/flooring_summary_dialog.dart';
import 'widgets/flooring_2d_painter.dart';
import 'widgets/flooring_3d_painter.dart';
import '../../projects/infrastructure/local_project_store.dart';

class FlooringCalculatorScreen extends StatelessWidget {
  final String? projectId;
  final double? initialLength;
  final double? initialWidth;
  final double? initialCarpetLength;
  final double? initialCarpetWidth;

  const FlooringCalculatorScreen({
    super.key,
    this.projectId,
    this.initialLength,
    this.initialWidth,
    this.initialCarpetLength,
    this.initialCarpetWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FlooringCalculatorController(
        initialLength: initialLength ?? 100.0,
        initialWidth: initialWidth ?? 60.0,
        initialCarpetLength: initialCarpetLength ?? 15.0,
        initialCarpetWidth: initialCarpetWidth ?? 30.0,
      ),
      child: _FlooringCalculatorScreenContent(projectId: projectId),
    );
  }
}

class _FlooringCalculatorScreenContent extends StatefulWidget {
  final String? projectId;
  const _FlooringCalculatorScreenContent({this.projectId});

  @override
  State<_FlooringCalculatorScreenContent> createState() => _FlooringCalculatorScreenContentState();
}

class _FlooringCalculatorScreenContentState extends State<_FlooringCalculatorScreenContent>
    with SingleTickerProviderStateMixin {
  bool _showSavedBanner = false;
  String _activeTool = 'pencil'; // 'pencil' or 'eraser'
  int _pointerCount = 0;
  Timer? _saveTimer;
  late AnimationController _animController;
  late Animation<double> _animProgress;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _animProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleEditDimensions(BuildContext context, FlooringCalculatorController controller) async {
    final params = await CreateFlooringDialog.show(
      context,
      initialPlotLength: controller.plotLength,
      initialPlotWidth: controller.plotWidth,
      initialCarpetLength: controller.carpetLength,
      initialCarpetWidth: controller.carpetWidth,
    );
    if (params != null && mounted) {
      controller.updateDimensions(
        params.plotLength,
        params.plotWidth,
        carpetLength: params.carpetLength,
        carpetWidth: params.carpetWidth,
      );
      _animController.forward(from: 0.0);
    }
  }

  Future<void> _handleSave(BuildContext context, FlooringCalculatorController controller) async {
    setState(() => _showSavedBanner = true);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSavedBanner = false);
    });

    final id = widget.projectId ?? 'flooring_${DateTime.now().millisecondsSinceEpoch}';
    final store = LocalProjectStore();
    await store.saveProjectRecord(
      MandapSavedProject(
        id: id,
        title: 'Flooring ${controller.plotWidth.toInt()} × ${controller.plotLength.toInt()} ft',
        moduleType: 'flooring',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parameters: {
          'width': controller.plotWidth,
          'length': controller.plotLength,
          'carpetLength': controller.carpetLength,
          'carpetWidth': controller.carpetWidth,
          'totalSheets': controller.result?.totalCarpets ?? 0,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FlooringCalculatorController>();
    final result = controller.result;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.mounted) {
          context.go('/modules');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top CAD Header Bar (matches Truss, Pole, & Stage CadHeaderBar architecture)
              _buildHeaderBar(context, controller),

              // 2. Main 3D / 2D Viewport Stack (full-screen CAD model)
              Expanded(
                child: Stack(
                  children: [
                    // A. Interactive Canvas (3D Model / 2D Blueprint)
                    Positioned.fill(
                      child: result == null
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.flooringPrimary),
                            )
                          : controller.viewMode == FlooringViewMode.mode2D
                              ? CustomPaint(painter: Flooring2DPainter(result: result))
                              : Listener(
                                  onPointerDown: (_) => setState(() => _pointerCount++),
                                  onPointerUp: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
                                  onPointerCancel: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onScaleStart: (_) => controller.onScaleStart(),
                                    onScaleUpdate: (details) {
                                      controller.onScaleUpdate(
                                        details.scale,
                                        details.focalPointDelta,
                                        pointerCount: _pointerCount,
                                      );
                                    },
                                    child: AnimatedBuilder(
                                      animation: _animProgress,
                                      builder: (context, _) => CustomPaint(
                                        painter: Flooring3DPainter(
                                          result: result,
                                          controller: controller,
                                          animationProgress: _animProgress.value,
                                          l10n: AppLocalizations.of(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                    ),

                    // B. Top-Center In-Model Dimension Badge
                    if (result != null)
                      Positioned(
                        top: 14,
                        left: 56,
                        right: 80,
                        child: Center(
                          child: _buildInModelDimensionBadge(context, controller, result),
                        ),
                      ),

                    // C. Left Floating Tool Rail (Pencil, Eraser, and Swap)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _buildSimplifiedToolRail(context, controller),
                    ),

                    // C2. Top-Right Floating OK Button
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => FlooringSummaryDialog.show(context, controller: controller),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA78BFA), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)?.ok ?? 'OK',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // D. Bottom-Left Live Status Info Chip (100 × 60 ft · 85 carpets · Covered: 102 × 60 ft)
                    if (result != null)
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: _buildBottomStatusChip(context, controller, result),
                      ),

                    // E. Project Saved Notification Banner
                    if (_showSavedBanner)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          color: const Color(0xFF16A34A),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Project saved successfully!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, FlooringCalculatorController controller) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Exit to menu
          IconButton(
            icon: const Icon(Icons.meeting_room_outlined, color: AppColors.primaryText, size: 22),
            tooltip: 'Exit to Menu',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => context.go('/modules'),
          ),
          const SizedBox(width: 6),

          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/logo.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.flooringLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.grid_on_rounded, color: AppColors.flooringPrimary, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Undo / Redo buttons right in navbar beside logo
          IconButton(
            icon: Icon(
              Icons.undo_rounded,
              color: controller.canUndo ? AppColors.primaryText : AppColors.secondaryText.withValues(alpha: 0.35),
              size: 20,
            ),
            tooltip: l10n?.undo ?? 'Previous (Undo)',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: controller.canUndo ? () => controller.undo() : null,
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(
              Icons.redo_rounded,
              color: controller.canRedo ? AppColors.primaryText : AppColors.secondaryText.withValues(alpha: 0.35),
              size: 20,
            ),
            tooltip: l10n?.redo ?? 'Next (Redo)',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: controller.canRedo ? () => controller.redo() : null,
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primaryText,
              size: 20,
            ),
            tooltip: 'Swap Length & Width (L ⇄ W)',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () {
              controller.swapDimensions();
              _animController.forward(from: 0.0);
            },
          ),

          // Right-aligned actions wrapped in SingleChildScrollView to prevent any overflow on small screens
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Project Name Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.appBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.headerBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 55),
                            child: Text(
                              l10n?.flooring ?? 'Flooring',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.edit, size: 10, color: AppColors.secondaryText),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Save Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleSave(context, controller),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.flooringPrimary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.flooringPrimary.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.save_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                l10n?.save ?? 'Save',
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
                    const SizedBox(width: 4),

                    // 2D / 3D Switcher
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.appBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.headerBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewToggleItem(
                            label: l10n?.view2D ?? '2D',
                            isSelected: controller.viewMode == FlooringViewMode.mode2D,
                            onTap: () => controller.setViewMode(FlooringViewMode.mode2D),
                          ),
                          _buildViewToggleItem(
                            label: l10n?.view3D ?? '3D',
                            isSelected: controller.viewMode == FlooringViewMode.mode3D,
                            onTap: () => controller.setViewMode(FlooringViewMode.mode3D),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Language Selector
                    IconButton(
                      icon: const Icon(Icons.language_rounded, color: AppColors.primaryText, size: 18),
                      tooltip: 'Language',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () => LanguageSelectorDialog.show(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.flooringPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInModelDimensionBadge(
    BuildContext context,
    FlooringCalculatorController controller,
    dynamic result,
  ) {
    final lenStr = controller.plotLength.toStringAsFixed(0);
    final widStr = controller.plotWidth.toStringAsFixed(0);

    final excessL = math.max(0.0, result.coveredLength - result.plotLength);
    final excessW = math.max(0.0, result.coveredWidth - result.plotWidth);
    final hasExcess = excessL > 0.01 || excessW > 0.01;
    final excessVal = excessL > 0.01 ? excessL : excessW;
    final excessValStr = excessVal % 1 == 0 ? excessVal.toStringAsFixed(0) : excessVal.toStringAsFixed(1);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasExcess ? const Color(0xFF1E1B18) : const Color(0xFF0F172A).withValues(alpha: 0.90),
          gradient: hasExcess
              ? const LinearGradient(
                  colors: [
                    Color(0xFF451A03),
                    Color(0xFF2E1002),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasExcess ? const Color(0xFFF59E0B) : AppColors.flooringPrimary.withValues(alpha: 0.6),
            width: hasExcess ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: hasExcess
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: hasExcess ? 14 : 8,
              spreadRadius: hasExcess ? 1.0 : 0.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _handleEditDimensions(context, controller),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasExcess ? Icons.warning_amber_rounded : Icons.grid_on_rounded,
                    color: hasExcess ? const Color(0xFFFBBF24) : AppColors.flooringPrimary,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$lenStr/$widStr ft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.75),
                          blurRadius: 10,
                          spreadRadius: 1.2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, color: Color(0xFF00E5FF), size: 15),
                        const SizedBox(width: 5),
                        Text(
                          '${result.totalCarpets} ${AppLocalizations.of(context)?.carpets ?? "Carpets"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.edit_rounded, color: hasExcess ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8), size: 12),
                ],
              ),
            ),
            if (hasExcess) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.40),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '$excessValStr ft ${AppLocalizations.of(context)?.extra ?? "Extra"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedToolRail(BuildContext context, FlooringCalculatorController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolButton(
            toolId: 'pencil',
            icon: Icons.edit_rounded,
            tooltip: 'Pencil Tool',
            onTap: () => setState(() => _activeTool = 'pencil'),
          ),
          const SizedBox(height: 5),
          _buildToolButton(
            toolId: 'eraser',
            icon: Icons.cleaning_services_rounded,
            tooltip: 'Eraser Tool',
            onTap: () => setState(() => _activeTool = 'eraser'),
          ),
          const SizedBox(height: 5),
          const Divider(height: 1, color: Color(0xFF334155), indent: 2, endIndent: 2),
          const SizedBox(height: 5),
          // Swap Button in Left Tool Rail
          Tooltip(
            message: 'Swap Layout (L ⇄ W)',
            child: InkWell(
              onTap: () {
                controller.swapDimensions();
                _animController.forward(from: 0.0);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: controller.isRotated ? AppColors.flooringPrimary.withValues(alpha: 0.3) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.isRotated ? AppColors.flooringPrimary : const Color(0xFF334155),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: controller.isRotated ? AppColors.flooringPrimary : const Color(0xFFE2E8F0),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required String toolId,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final isSelected = _activeTool == toolId;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.flooringPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            size: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStatusChip(BuildContext context, FlooringCalculatorController controller, dynamic result) {
    final lenStr = result.plotLength.toStringAsFixed(0);
    final widStr = result.plotWidth.toStringAsFixed(0);
    final cLenStr = result.coveredLength.toStringAsFixed(0);
    final cWidStr = result.coveredWidth.toStringAsFixed(0);

    final excessL = math.max(0.0, result.coveredLength - result.plotLength);
    final excessW = math.max(0.0, result.coveredWidth - result.plotWidth);
    final hasExcess = excessL > 0.01 || excessW > 0.01;
    final extraSqFt = (result.coveredArea - result.plotArea).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Dimension Info Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.flooringPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$lenStr × $widStr ft',
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.75),
                      blurRadius: 10,
                      spreadRadius: 1.2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.layers_rounded, color: Color(0xFF00E5FF), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${result.totalCarpets} ${AppLocalizations.of(context)?.carpets ?? "carpets"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${AppLocalizations.of(context)?.covered ?? "Covered"}: $cLenStr × $cWidStr ft',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Prominent Alert Chip showing exact measurement going out of plot
        if (hasExcess) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF7C2D12).withValues(alpha: 0.95), // Deep Amber/Orange alert
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF97316), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFDBA74), size: 14),
                const SizedBox(width: 6),
                Text(
                  '⚠ ${AppLocalizations.of(context)?.extra ?? "Extra"}: ${excessL > 0.01 ? '${excessL % 1 == 0 ? excessL.toStringAsFixed(0) : excessL.toStringAsFixed(1)} ft Length ' : ''}${excessW > 0.01 ? '${excessW % 1 == 0 ? excessW.toStringAsFixed(0) : excessW.toStringAsFixed(1)} ft Width ' : ''}($extraSqFt sq ft)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
