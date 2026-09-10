import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'stage_calculator_controller.dart';
import 'widgets/stage_2d_painter.dart';
import 'widgets/stage_3d_painter.dart';

class StageCalculatorScreen extends StatelessWidget {
  const StageCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StageCalculatorController(),
      child: const _StageCalculatorScreenContent(),
    );
  }
}

class _StageCalculatorScreenContent extends StatefulWidget {
  const _StageCalculatorScreenContent();

  @override
  State<_StageCalculatorScreenContent> createState() => _StageCalculatorScreenContentState();
}

class _StageCalculatorScreenContentState extends State<_StageCalculatorScreenContent> {
  late TextEditingController _stageLengthController;
  late TextEditingController _stageWidthController;
  late TextEditingController _stageHeightController;
  late TextEditingController _tableLengthController;
  late TextEditingController _tableWidthController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<StageCalculatorController>();
    _stageLengthController = TextEditingController(text: ctrl.stageLength.toString());
    _stageWidthController = TextEditingController(text: ctrl.stageWidth.toString());
    _stageHeightController = TextEditingController(text: ctrl.stageHeight.toString());
    _tableLengthController = TextEditingController(text: ctrl.tableLength.toString());
    _tableWidthController = TextEditingController(text: ctrl.tableWidth.toString());
  }

  @override
  void dispose() {
    _stageLengthController.dispose();
    _stageWidthController.dispose();
    _stageHeightController.dispose();
    _tableLengthController.dispose();
    _tableWidthController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputsChanged(StageCalculatorController controller) {
    final sl = double.tryParse(_stageLengthController.text) ?? controller.stageLength;
    final sw = double.tryParse(_stageWidthController.text) ?? controller.stageWidth;
    final sh = double.tryParse(_stageHeightController.text) ?? controller.stageHeight;
    final tl = double.tryParse(_tableLengthController.text) ?? controller.tableLength;
    final tw = double.tryParse(_tableWidthController.text) ?? controller.tableWidth;

    controller.updateInputs(
      stageLength: sl,
      stageWidth: sw,
      stageHeight: sh,
      tableLength: tl,
      tableWidth: tw,
    );
  }

  void _scrollToPreview() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_previewKey.currentContext != null) {
        Scrollable.ensureVisible(
          _previewKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StageCalculatorController>();
    final isMobile = MediaQuery.of(context).size.width < 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/modules');
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.headerBackground,
              border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SafeArea(
              child: Builder(
                builder: (context) {
                  final isCompactHeader = MediaQuery.of(context).size.width < 600;
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.meeting_room_outlined, color: AppColors.primaryText, size: 24),
                        tooltip: 'Exit to Menu',
                        onPressed: () => context.go('/modules'),
                      ),
                      const SizedBox(width: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.stageLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.architecture_rounded, color: AppColors.stagePrimary, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MANDAP',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if (!isCompactHeader)
                            const Text(
                              'EVENT STRUCTURE DESIGNER',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.language_rounded, color: AppColors.primaryText, size: 20),
                        tooltip: 'Language / भाषा',
                        onPressed: () => LanguageSelectorDialog.show(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        body: isMobile
            ? SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInputPanel(context, controller),
                    const SizedBox(height: 16),
                    Container(
                      key: _previewKey,
                      height: 380,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildVisualization(context, controller),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  SizedBox(
                    width: 350,
                    child: SingleChildScrollView(child: _buildInputPanel(context, controller)),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.dividerBorder),
                  Expanded(child: _buildVisualization(context, controller)),
                ],
              ),
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context, StageCalculatorController controller) {
    final l10n = AppLocalizations.of(context);
    final titleText = l10n?.stageCalculatorTitle ?? 'Stage Calculator';
    final subtitleText = l10n?.stageCalculatorSubtitle ?? 'Calculate stage table requirements & 3D modular setup.';
    final stageDimText = l10n?.stageDimensions ?? '1. Stage Dimensions';
    final lengthLabel = l10n?.lengthFt ?? 'Length (ft)';
    final widthLabel = l10n?.widthFt ?? 'Width (ft)';
    final heightLabel = l10n?.heightFt ?? 'Height (ft)';
    final tableDimText = l10n?.tableDimensions ?? '2. Table Dimensions';
    final calculateBtnText = l10n?.calculateStage ?? 'CALCULATE STAGE';

    return Container(
      color: AppColors.appBackground,
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded, color: AppColors.stagePrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                titleText,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitleText,
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Stage Dimensions Section
          Text(
            stageDimText,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DimensionInput(
                  label: lengthLabel,
                  controller: _stageLengthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DimensionInput(
                  label: widthLabel,
                  controller: _stageWidthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DimensionInput(
                  label: heightLabel,
                  controller: _stageHeightController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Dimensions Section
          Text(
            tableDimText,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DimensionInput(
                  label: lengthLabel,
                  controller: _tableLengthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DimensionInput(
                  label: widthLabel,
                  controller: _tableWidthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stagePrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                controller.calculate();
                _scrollToPreview();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    calculateBtnText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (controller.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(controller.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            )
          else if (controller.result != null)
            _buildResults(context, controller.result!),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, dynamic result) {
    final l10n = AppLocalizations.of(context);
    final reqText = l10n?.stageRequirement ?? 'Stage Requirement';
    final tablesText = l10n?.stageTables ?? 'STAGE TABLES';
    final breakdownText = l10n?.layoutBreakdown ?? 'Layout Breakdown';
    final gridText = l10n?.gridLW ?? 'Grid (L × W)';
    final orientationText = l10n?.tableOrientation ?? 'Table Orientation';
    final coveredAreaText = l10n?.coveredArea ?? 'Covered Area';
    final stageHeightText = l10n?.stageHeight ?? 'Stage Height';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prominent Result Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.stageLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stageSoft),
          ),
          child: Column(
            children: [
              Text(
                reqText,
                style: const TextStyle(
                  color: AppColors.stagePrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.totalTables.toString(),
                style: const TextStyle(
                  color: AppColors.stagePrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                tablesText,
                style: const TextStyle(color: AppColors.stagePrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Layout Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.headerBorder),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                breakdownText,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20, color: AppColors.headerBorder),
              _DetailRow(label: gridText, value: '${result.tablesAlongLength} × ${result.tablesAlongWidth} tables'),
              _DetailRow(label: orientationText, value: '${result.orientedTableLength} ft (L) × ${result.orientedTableWidth} ft (W)'),
              _DetailRow(label: coveredAreaText, value: '${result.coveredLength} ft × ${result.coveredWidth} ft'),
              _DetailRow(label: stageHeightText, value: '${result.stageHeight} ft'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualization(BuildContext context, StageCalculatorController controller) {
    return Stack(
      children: [
        if (controller.result != null)
          Positioned.fill(
            child: ClipRect(
              child: controller.viewMode == StageViewMode.mode2D
                  ? CustomPaint(painter: Stage2DPainter(result: controller.result!))
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (_) => controller.onScaleStart(),
                      onScaleUpdate: (details) => controller.onScaleUpdate(details.scale, details.focalPointDelta),
                      child: Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: double.infinity,
                        child: CustomPaint(
                          painter: Stage3DPainter(
                            result: controller.result!,
                            cameraAzimuth: controller.cameraAzimuth,
                            cameraElevation: controller.cameraElevation,
                            cameraZoom: controller.cameraZoom,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                _ViewModeButton(
                  label: '2D',
                  isSelected: controller.viewMode == StageViewMode.mode2D,
                  onTap: () => controller.setViewMode(StageViewMode.mode2D),
                ),
                _ViewModeButton(
                  label: '3D',
                  isSelected: controller.viewMode == StageViewMode.mode3D,
                  onTap: () => controller.setViewMode(StageViewMode.mode3D),
                ),
              ],
            ),
          ),
        ),
        if (controller.viewMode == StageViewMode.mode3D && controller.result != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              tooltip: 'Reset View',
              onPressed: () => controller.resetCamera(),
              child: const Icon(Icons.refresh),
            ),
          ),
      ],
    );
  }
}

class _DimensionInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DimensionInput({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.stagePrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ModulePill extends StatelessWidget {
  final String label;
  final String icon;
  final bool isActive;
  final Color? activeColor;
  final Color? activeBg;
  final VoidCallback onTap;

  const _ModulePill({
    required this.label,
    required this.icon,
    required this.isActive,
    this.activeColor,
    this.activeBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.stagePrimary.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFF87171) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
