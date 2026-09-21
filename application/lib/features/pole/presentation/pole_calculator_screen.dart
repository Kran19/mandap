import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'pole_calculator_controller.dart';
import '../domain/models/pole_calculation_result.dart';
import 'widgets/create_pole_dialog.dart';
import 'widgets/pole_summary_dialog.dart';
import 'widgets/pole_2d_painter.dart';
import 'widgets/pole_3d_painter.dart';
import '../../projects/infrastructure/local_project_store.dart';

class PoleCalculatorScreen extends StatelessWidget {
  final String? projectId;
  final double? initialLength;
  final double? initialWidth;
  final double? initialPipeSize;

  const PoleCalculatorScreen({
    super.key,
    this.projectId,
    this.initialLength,
    this.initialWidth,
    this.initialPipeSize,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PoleCalculatorController(
        initialLength: initialLength ?? 100.0,
        initialWidth: initialWidth ?? 100.0,
        initialPoleSize: initialPipeSize ?? 15.0,
      ),
      child: _PoleCalculatorScreenContent(projectId: projectId),
    );
  }
}

class _PoleCalculatorScreenContent extends StatefulWidget {
  final String? projectId;
  const _PoleCalculatorScreenContent({this.projectId});

  @override
  State<_PoleCalculatorScreenContent> createState() => _PoleCalculatorScreenContentState();
}

class _PoleCalculatorScreenContentState extends State<_PoleCalculatorScreenContent>
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

  Future<void> _handleEditDimensions(BuildContext context, PoleCalculatorController controller) async {
    final params = await CreatePoleDialog.show(
      context,
      initialLength: controller.length,
      initialWidth: controller.width,
      initialPipeSize: controller.poleSize,
    );
    if (params != null && mounted) {
      controller.updateDimensions(params.plotLength, params.plotWidth, params.pipeSize);
      controller.calculate();
      _animController.forward(from: 0.0);
    }
  }

  Future<void> _handleSave(BuildContext context, PoleCalculatorController controller) async {
    setState(() => _showSavedBanner = true);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSavedBanner = false);
    });

    final id = widget.projectId ?? 'pole_${DateTime.now().millisecondsSinceEpoch}';
    final store = LocalProjectStore();
    await store.saveProjectRecord(
      MandapSavedProject(
        id: id,
        title: 'Pipe ${controller.width.toInt()} × ${controller.length.toInt()} ft',
        moduleType: 'pole',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parameters: {
          'width': controller.width,
          'length': controller.length,
          'pipeSize': controller.poleSize,
          'totalPoles': controller.result?.totalVerticalPoles ?? 0,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PoleCalculatorController>();
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
              // 1. Top CAD Header Bar (matches Truss CadHeaderBar architecture)
              _buildHeaderBar(context, controller),

              // 2. Main 3D / 2D Viewport Stack (full-screen CAD model)
              Expanded(
                child: Stack(
                  children: [
                    // A. Interactive Canvas (3D Model / 2D Blueprint)
                    Positioned.fill(
                      child: result == null
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.polePrimary),
                            )
                          : controller.viewMode == PoleViewMode.mode2D
                              ? CustomPaint(painter: Pole2DPainter(result: result))
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
                                        painter: Pole3DPainter(
                                          result: result,
                                          controller: controller,
                                          animationProgress: _animProgress.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                    ),

                    // B. Top-Center Controls (Dimension Badge + Pipes Breakdown Badge in Green Marked Box)
                    Positioned(
                      top: 14,
                      left: 12,
                      right: 12,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildInModelDimensionBadge(context, controller),
                            if (result != null) ...[
                              const SizedBox(height: 8),
                              _buildPipesBreakdownBadge(controller, result),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // C. Left Floating Tool Rail (Compact Pencil & Eraser)
                    Positioned(
                      left: 14,
                      top: 108,
                      child: _buildSimplifiedToolRail(context, controller),
                    ),

                    // C2. Top-Right Floating OK Button
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => PoleSummaryDialog.show(context, controller: controller),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'OK',
                                  style: TextStyle(
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

                    // D. Bottom-Left Live Status Info Chip (100 × 100 ft · 64 poles · 112 pipes)
                    if (result != null)
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: _buildBottomStatusChip(controller, result),
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

  Widget _buildHeaderBar(BuildContext context, PoleCalculatorController controller) {
    final isCompact = MediaQuery.of(context).size.width < 600;
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
              errorBuilder: (_, __, ___) => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.poleLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.architecture_rounded, color: AppColors.polePrimary, size: 16),
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
            tooltip: 'Previous (Undo)',
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
            tooltip: 'Next (Redo)',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: controller.canRedo ? () => controller.redo() : null,
          ),

          // Right-aligned actions wrapped in SingleChildScrollView to prevent any overflow
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
                              AppLocalizations.of(context)?.pipe ?? 'Pipe',
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Save',
                                style: TextStyle(
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
                          InkWell(
                            onTap: () => controller.setViewMode(PoleViewMode.mode2D),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: controller.viewMode == PoleViewMode.mode2D ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              ),
                              child: Text(
                                '2D',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: controller.viewMode == PoleViewMode.mode2D ? Colors.white : AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => controller.setViewMode(PoleViewMode.mode3D),
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: controller.viewMode == PoleViewMode.mode3D ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              ),
                              child: Text(
                                '3D',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: controller.viewMode == PoleViewMode.mode3D ? Colors.white : AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Retrieve (History) Button
                    IconButton(
                      icon: const Icon(Icons.history_rounded, size: 17, color: AppColors.primaryText),
                      tooltip: 'Retrieve Layout',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        controller.resetCamera();
                      },
                    ),
                    const SizedBox(width: 2),

                    // Language button (tablet/desktop)
                    if (!isCompact)
                      IconButton(
                        icon: const Icon(Icons.language_rounded, color: AppColors.primaryText, size: 17),
                        tooltip: 'Language / भाषा',
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

  Widget _buildInModelDimensionBadge(BuildContext context, PoleCalculatorController controller) {
    final len = controller.length.toInt();
    final wid = controller.width.toInt();
    final pipe = controller.poleSize.toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleEditDimensions(context, controller),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.aspect_ratio_rounded, size: 15, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                '$len/$wid ft · $pipe ft',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit_rounded, size: 13, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipesBreakdownBadge(PoleCalculatorController controller, PoleCalculationResult result) {
    final polesCount = result.totalVerticalPoles;
    final upperCount = result.totalHorizontalPipes;
    final totalCount = result.totalPipesUsed;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Pipes used as Poles (Vertical Poles) with Pole Logo
            _buildPipeStatItem(
              imagePath: 'assets/images/straight.png',
              icon: Icons.view_column_rounded,
              iconColor: const Color(0xFF38BDF8), // Cyan
              count: polesCount,
              label: 'Poles',
            ),
            _buildVerticalSeparator(),

            // 2. Pipes used in Upper Side (Roof/Horizontal Pipes) with Upper Logo
            _buildPipeStatItem(
              imagePath: 'assets/images/straight2.png',
              icon: Icons.roofing_rounded,
              iconColor: const Color(0xFFF59E0B), // Amber
              count: upperCount,
              label: 'Upper Pipes',
            ),
            _buildVerticalSeparator(),

            // 3. Total Pipes Used in Structure with Total Logo
            _buildPipeStatItem(
              icon: Icons.all_inbox_rounded,
              iconColor: const Color(0xFF10B981), // Emerald
              count: totalCount,
              label: 'Total Pipes',
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipeStatItem({
    String? imagePath,
    IconData? icon,
    required Color iconColor,
    required int count,
    required String label,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: imagePath != null ? Colors.white : iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(imagePath != null ? 2 : 4),
          child: Center(
            child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        icon ?? Icons.circle,
                        size: 13,
                        color: iconColor,
                      ),
                    ),
                  )
                : Icon(icon, size: 13, color: iconColor),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? const Color(0xFF34D399) : Colors.white,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isHighlighted ? const Color(0xFFA7F3D0) : const Color(0xFF94A3B8),
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalSeparator() {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF334155),
    );
  }

  Widget _buildSimplifiedToolRail(BuildContext context, PoleCalculatorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pencil Tool
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              color: _activeTool == 'pencil' ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
              size: 17,
            ),
            tooltip: 'Pen / Draw',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _activeTool = 'pencil'),
          ),
          const SizedBox(height: 5),
          const Divider(height: 1, indent: 2, endIndent: 2, color: Color(0xFF334155)),
          const SizedBox(height: 5),

          // Eraser Tool
          IconButton(
            icon: Icon(
              Icons.cleaning_services_rounded,
              color: _activeTool == 'eraser' ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
              size: 17,
            ),
            tooltip: 'Eraser',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _activeTool = 'eraser'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatusChip(PoleCalculatorController controller, dynamic result) {
    final len = controller.length.toInt();
    final wid = controller.width.toInt();
    final poles = result.totalVerticalPoles;
    final pipes = result.totalHorizontalPipes;
    final pipeSize = result.poleSize.toInt();

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 28,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.view_column_rounded, size: 14, color: Color(0xFF38BDF8)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$len × $wid ft · $poles poles · $pipes pipes (${pipeSize}ft)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
