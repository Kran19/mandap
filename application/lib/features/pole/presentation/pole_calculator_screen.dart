import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'pole_calculator_controller.dart';
import 'widgets/pole_2d_painter.dart';
import 'widgets/pole_3d_painter.dart';

class PoleCalculatorScreen extends StatelessWidget {
  const PoleCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PoleCalculatorController(),
      child: const _PoleCalculatorScreenContent(),
    );
  }
}

class _PoleCalculatorScreenContent extends StatefulWidget {
  const _PoleCalculatorScreenContent();

  @override
  State<_PoleCalculatorScreenContent> createState() => _PoleCalculatorScreenContentState();
}

class _PoleCalculatorScreenContentState extends State<_PoleCalculatorScreenContent> {
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _poleSizeController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<PoleCalculatorController>();
    _lengthController = TextEditingController(text: ctrl.length.toString());
    _widthController = TextEditingController(text: ctrl.width.toString());
    _poleSizeController = TextEditingController(text: ctrl.poleSize.toString());
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _poleSizeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputsChanged(PoleCalculatorController controller) {
    final l = double.tryParse(_lengthController.text) ?? controller.length;
    final w = double.tryParse(_widthController.text) ?? controller.width;
    final s = double.tryParse(_poleSizeController.text) ?? controller.poleSize;

    controller.updateDimensions(l, w, s);
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
    final controller = context.watch<PoleCalculatorController>();
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
                              color: AppColors.poleLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.architecture_rounded, color: AppColors.polePrimary, size: 16),
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

  Widget _buildInputPanel(BuildContext context, PoleCalculatorController controller) {
    final l10n = AppLocalizations.of(context);
    final titleText = l10n?.poleCalculatorTitle ?? 'Pole Calculator';
    final subtitleText = l10n?.poleCalculatorSubtitle ?? 'Calculate vertical poles & horizontal pipes required for plot.';
    final plotSizeText = l10n?.enterPlotSize ?? '1. Enter Plot Size';
    final lengthLabel = l10n?.lengthFt ?? 'Length (ft)';
    final widthLabel = l10n?.widthFt ?? 'Width (ft)';
    final gridLabel = l10n?.gridSizeFt ?? 'Grid Size (ft)';
    final calculateBtnText = l10n?.calculatePoles ?? 'CALCULATE POLES';

    return Container(
      color: AppColors.appBackground,
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_column_rounded, color: AppColors.polePrimary, size: 20),
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

          // Plot Size Section
          Text(
            plotSizeText,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DimensionInput(
                  label: lengthLabel,
                  controller: _lengthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DimensionInput(
                  label: widthLabel,
                  controller: _widthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DimensionInput(
                  label: gridLabel,
                  controller: _poleSizeController,
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
                backgroundColor: AppColors.polePrimary,
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
    final poleReqText = l10n?.poleRequirement ?? 'POLE REQUIREMENT';
    final vertPolesText = l10n?.verticalPoles ?? 'VERTICAL POLES';
    final horizPipesText = l10n?.horizontalPipes ?? 'HORIZONTAL PIPES';
    final ceilingSecText = l10n?.ceilingSections ?? 'CEILING SECTIONS';
    final gridBreakdownText = l10n?.gridBreakdown ?? 'Grid Breakdown';
    final gridUnitText = l10n?.gridPoleUnit ?? 'Grid Pole Unit';
    final lengthBaysText = l10n?.lengthBays ?? 'Length Bays';
    final widthBaysText = l10n?.widthBays ?? 'Width Bays';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pole Requirement Container Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.poleLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.poleSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poleReqText,
                style: const TextStyle(color: AppColors.polePrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              _ResultRow(value: result.totalVerticalPoles.toString(), label: vertPolesText, color: AppColors.polePrimary),
              const SizedBox(height: 12),
              _ResultRow(value: result.totalHorizontalPipes.toString(), label: horizPipesText, color: AppColors.primaryText),
              const SizedBox(height: 12),
              _ResultRow(value: result.totalCeilingSections.toString(), label: ceilingSecText, color: AppColors.secondaryText),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grid Details Card
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
                gridBreakdownText,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20, color: AppColors.headerBorder),
              _DetailRow(label: gridUnitText, value: '${result.poleSize} ft'),
              _DetailRow(label: lengthBaysText, value: '${result.grid.lengthBays}'),
              _DetailRow(label: widthBaysText, value: '${result.grid.widthBays}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualization(BuildContext context, PoleCalculatorController controller) {
    return Stack(
      children: [
        if (controller.result != null)
          Positioned.fill(
            child: ClipRect(
              child: controller.viewMode == PoleViewMode.mode2D
                  ? CustomPaint(painter: Pole2DPainter(result: controller.result!))
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (_) => controller.onScaleStart(),
                      onScaleUpdate: (details) => controller.onScaleUpdate(details.scale, details.focalPointDelta),
                      child: Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: double.infinity,
                        child: CustomPaint(
                          painter: Pole3DPainter(
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
                  isSelected: controller.viewMode == PoleViewMode.mode2D,
                  onTap: () => controller.setViewMode(PoleViewMode.mode2D),
                ),
                _ViewModeButton(
                  label: '3D',
                  isSelected: controller.viewMode == PoleViewMode.mode3D,
                  onTap: () => controller.setViewMode(PoleViewMode.mode3D),
                ),
              ],
            ),
          ),
        ),
        if (controller.viewMode == PoleViewMode.mode3D && controller.result != null)
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
              borderSide: const BorderSide(color: AppColors.polePrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ResultRow({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
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
          color: isSelected ? AppColors.polePrimary.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFDBA74) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
