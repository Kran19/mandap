import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_selector_dialog.dart';
import 'stage_calculator_controller.dart';
import 'widgets/create_stage_dialog.dart';
import 'widgets/stage_summary_dialog.dart';
import 'widgets/stage_2d_painter.dart';
import 'widgets/stage_3d_painter.dart';
import '../domain/models/stage_calculation_result.dart';
import '../../projects/infrastructure/local_project_store.dart';

class StageCalculatorScreen extends StatelessWidget {
  final String? projectId;
  final double? initialLength;
  final double? initialWidth;
  final double? initialTableLength;
  final double? initialTableWidth;

  const StageCalculatorScreen({
    super.key,
    this.projectId,
    this.initialLength,
    this.initialWidth,
    this.initialTableLength,
    this.initialTableWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StageCalculatorController(
        initialLength: initialLength ?? 32.0,
        initialWidth: initialWidth ?? 20.0,
        initialTableLength: initialTableLength ?? 4.0,
        initialTableWidth: initialTableWidth ?? 8.0,
      ),
      child: _StageCalculatorScreenContent(projectId: projectId),
    );
  }
}

class _StageCalculatorScreenContent extends StatefulWidget {
  final String? projectId;
  const _StageCalculatorScreenContent({this.projectId});

  @override
  State<_StageCalculatorScreenContent> createState() => _StageCalculatorScreenContentState();
}

class _StageCalculatorScreenContentState extends State<_StageCalculatorScreenContent>
    with SingleTickerProviderStateMixin {
  bool _showSavedBanner = false;
  String _activeTool = 'pencil';
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

  Future<void> _handleEditDimensions(BuildContext context, StageCalculatorController controller) async {
    final params = await CreateStageDialog.show(
      context,
      initialStageLength: controller.stageLength,
      initialStageWidth: controller.stageWidth,
      initialTableLength: controller.tableLength,
      initialTableWidth: controller.tableWidth,
    );
    if (params != null && mounted) {
      controller.updateDimensions(
        params.stageLength,
        params.stageWidth,
        tableLength: params.tableLength,
        tableWidth: params.tableWidth,
      );
      _animController.forward(from: 0.0);
    }
  }

  Future<void> _handleSave(BuildContext context, StageCalculatorController controller) async {
    setState(() => _showSavedBanner = true);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSavedBanner = false);
    });

    final id = widget.projectId ?? 'stage_${DateTime.now().millisecondsSinceEpoch}';
    final store = LocalProjectStore();
    await store.saveProjectRecord(
      MandapSavedProject(
        id: id,
        title: 'Stage ${controller.stageWidth.toInt()} × ${controller.stageLength.toInt()} ft',
        moduleType: 'stage',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parameters: {
          'width': controller.stageWidth,
          'length': controller.stageLength,
          'tableLength': controller.tableLength,
          'tableWidth': controller.tableWidth,
          'totalTables': controller.result?.totalTables ?? 0,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StageCalculatorController>();
    final result = controller.result;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
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
              // 1. Top CAD Header Bar
              _buildHeaderBar(context, controller),

              // 2. Main 3D / 2D Viewport Stack (full-screen CAD model)
              Expanded(
                child: Stack(
                  children: [
                    // A. Interactive Canvas (3D Model / 2D Blueprint)
                    Positioned.fill(
                      child: result == null
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.stagePrimary),
                            )
                          : controller.viewMode == StageViewMode.mode2D
                              ? CustomPaint(painter: Stage2DPainter(result: result))
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
                                        painter: Stage3DPainter(
                                          result: result,
                                          controller: controller,
                                          animationProgress: _animProgress.value,
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
                          onTap: () => StageSummaryDialog.show(context, controller: controller),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFB923C), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEA580C).withValues(alpha: 0.4),
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

                    // D. Bottom-Left Live Status Info Chip (32 × 20 ft · 20 tables (8×4 ft) · Covered: 32 × 20 ft)
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

  Widget _buildHeaderBar(BuildContext context, StageCalculatorController controller) {
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
              'assets/images/stage.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.stageLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.layers_rounded, color: AppColors.stagePrimary, size: 16),
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

          // Right-aligned actions wrapped in SingleChildScrollView to prevent overflow
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
                            child: const Text(
                              'Stage',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
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
                            color: AppColors.stagePrimary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.stagePrimary.withValues(alpha: 0.35),
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
                          _buildViewToggleItem(
                            label: '2D',
                            isSelected: controller.viewMode == StageViewMode.mode2D,
                            onTap: () => controller.setViewMode(StageViewMode.mode2D),
                          ),
                          _buildViewToggleItem(
                            label: '3D',
                            isSelected: controller.viewMode == StageViewMode.mode3D,
                            onTap: () => controller.setViewMode(StageViewMode.mode3D),
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
          color: isSelected ? AppColors.stagePrimary : Colors.transparent,
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
    StageCalculatorController controller,
    StageCalculationResult result,
  ) {
    final lenStr = controller.stageLength.toStringAsFixed(0);
    final widStr = controller.stageWidth.toStringAsFixed(0);
    final tLenStr = controller.tableLength.toStringAsFixed(0);
    final tWidStr = controller.tableWidth.toStringAsFixed(0);

    final excessL = math.max(0.0, result.coveredLength - result.stageLength);
    final excessW = math.max(0.0, result.coveredWidth - result.stageWidth);
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
            color: hasExcess ? const Color(0xFFF59E0B) : AppColors.stagePrimary.withValues(alpha: 0.6),
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
                    hasExcess ? Icons.warning_amber_rounded : Icons.layers_rounded,
                    color: hasExcess ? const Color(0xFFFBBF24) : AppColors.stagePrimary,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$lenStr/$widStr ft · ${result.totalTables} Tables ($tWidStr×$tLenStr ft)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_rounded, color: hasExcess ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8), size: 12),
                ],
              ),
            ),
            if (hasExcess) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.40),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFF1E1B18), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '$excessValStr ft Extra',
                      style: const TextStyle(
                        color: Color(0xFF1E1B18),
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

  Widget _buildSimplifiedToolRail(BuildContext context, StageCalculatorController controller) {
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
            tooltip: 'Edit Stage Dimensions',
            onTap: () {
              setState(() => _activeTool = 'pencil');
              _handleEditDimensions(context, controller);
            },
          ),
          const SizedBox(height: 5),
          _buildToolButton(
            toolId: 'eraser',
            icon: Icons.cleaning_services_rounded,
            tooltip: 'Clear / Reset Stage',
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
                  color: controller.isRotated ? AppColors.stagePrimary.withValues(alpha: 0.3) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.isRotated ? AppColors.stagePrimary : const Color(0xFF334155),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: controller.isRotated ? AppColors.stagePrimary : const Color(0xFFE2E8F0),
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
            color: isSelected ? AppColors.stagePrimary : Colors.transparent,
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

  Widget _buildBottomStatusChip(StageCalculatorController controller, StageCalculationResult result) {
    final lenStr = result.stageLength.toStringAsFixed(0);
    final widStr = result.stageWidth.toStringAsFixed(0);
    final cLenStr = result.coveredLength.toStringAsFixed(0);
    final cWidStr = result.coveredWidth.toStringAsFixed(0);
    final tLenStr = controller.tableLength.toStringAsFixed(0);
    final tWidStr = controller.tableWidth.toStringAsFixed(0);

    final excessL = math.max(0.0, result.coveredLength - result.stageLength);
    final excessW = math.max(0.0, result.coveredWidth - result.stageWidth);
    final hasExcess = excessL > 0.01 || excessW > 0.01;
    final extraSqFt = (result.coveredArea - result.stageArea).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Dimension Info Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
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
                  color: AppColors.stagePrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$lenStr × $widStr ft · ${result.totalTables} tables ($tWidStr×$tLenStr ft) · Covered: $cLenStr × $cWidStr ft',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // Live Warning Overhang Chip
        if (hasExcess) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
            decoration: BoxDecoration(
              color: const Color(0xFF78350F).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 14),
                const SizedBox(width: 5),
                Text(
                  '+$extraSqFt sq ft Extra Overhang',
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
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
