import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'flooring_calculator_controller.dart';
import 'widgets/flooring_2d_painter.dart';
import 'widgets/flooring_3d_painter.dart';

class FlooringCalculatorScreen extends StatelessWidget {
  const FlooringCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FlooringCalculatorController(),
      child: const _FlooringCalculatorScreenContent(),
    );
  }
}

class _FlooringCalculatorScreenContent extends StatefulWidget {
  const _FlooringCalculatorScreenContent();

  @override
  State<_FlooringCalculatorScreenContent> createState() => _FlooringCalculatorScreenContentState();
}

class _FlooringCalculatorScreenContentState extends State<_FlooringCalculatorScreenContent> {
  late TextEditingController _plotLengthController;
  late TextEditingController _plotWidthController;
  late TextEditingController _carpetLengthController;
  late TextEditingController _carpetWidthController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<FlooringCalculatorController>();
    _plotLengthController = TextEditingController(text: ctrl.plotLength.toString());
    _plotWidthController = TextEditingController(text: ctrl.plotWidth.toString());
    _carpetLengthController = TextEditingController(text: ctrl.carpetLength.toString());
    _carpetWidthController = TextEditingController(text: ctrl.carpetWidth.toString());
  }

  @override
  void dispose() {
    _plotLengthController.dispose();
    _plotWidthController.dispose();
    _carpetLengthController.dispose();
    _carpetWidthController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputsChanged(FlooringCalculatorController controller) {
    final pl = double.tryParse(_plotLengthController.text) ?? controller.plotLength;
    final pw = double.tryParse(_plotWidthController.text) ?? controller.plotWidth;
    final cl = double.tryParse(_carpetLengthController.text) ?? controller.carpetLength;
    final cw = double.tryParse(_carpetWidthController.text) ?? controller.carpetWidth;

    controller.updateInputs(
      plotLength: pl,
      plotWidth: pw,
      carpetLength: cl,
      carpetWidth: cw,
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
    final controller = context.watch<FlooringCalculatorController>();
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
                              color: AppColors.flooringLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.architecture_rounded, color: AppColors.flooringPrimary, size: 16),
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
                    width: 360,
                    child: SingleChildScrollView(child: _buildInputPanel(context, controller)),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.dividerBorder),
                  Expanded(child: _buildVisualization(context, controller)),
                ],
              ),
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context, FlooringCalculatorController controller) {
    final l10n = AppLocalizations.of(context);
    final titleText = l10n?.flooringCalculatorTitle ?? 'Flooring Calculator';
    final subtitleText = l10n?.flooringCalculatorSubtitle ?? 'Calculate total carpet requirement for your plot size.';
    final enterPlotText = l10n?.enterPlotSize ?? '1. Enter Plot Size';
    final lengthLabel = l10n?.lengthFt ?? 'Length (ft)';
    final widthLabel = l10n?.widthFt ?? 'Width (ft)';
    final enterCarpetText = l10n?.enterCarpetSize ?? '2. Enter Carpet Size';
    final carpetLengthLabel = l10n?.carpetLengthFt ?? 'Carpet Length (ft)';
    final carpetWidthLabel = l10n?.carpetWidthFt ?? 'Carpet Width (ft)';
    final calculateBtnText = l10n?.calculateFlooring ?? 'CALCULATE FLOORING';

    return Container(
      color: AppColors.appBackground,
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_on_rounded, color: AppColors.flooringPrimary, size: 20),
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

          // Section 1: Enter Plot Size
          Text(
            enterPlotText,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DimensionInput(
                  label: lengthLabel,
                  controller: _plotLengthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DimensionInput(
                  label: widthLabel,
                  controller: _plotWidthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Enter Carpet Size
          Text(
            enterCarpetText,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DimensionInput(
                  label: carpetLengthLabel,
                  controller: _carpetLengthController,
                  onChanged: (_) => _onInputsChanged(controller),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DimensionInput(
                  label: carpetWidthLabel,
                  controller: _carpetWidthController,
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
                backgroundColor: AppColors.flooringPrimary,
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
    final totalReqLabel = l10n?.totalCarpetsRequired ?? 'Total Carpets Required';
    final detailsLabel = l10n?.calculationDetails ?? 'Calculation Details';
    final plotDimLabel = l10n?.plotDimensions ?? 'Plot Dimensions';
    final plotAreaLabel = l10n?.plotArea ?? 'Plot Area';
    final carpetDimLabel = l10n?.carpetDimensions ?? 'Carpet Dimensions';
    final carpetAreaLabel = l10n?.carpetArea ?? 'Carpet Area';
    final lengthCarpetsLabel = l10n?.carpetsAlongLength ?? 'Carpets Along Length';
    final widthCarpetsLabel = l10n?.carpetsAlongWidth ?? 'Carpets Along Width';
    final totalCarpetsLabel = l10n?.totalCarpets ?? 'Total Carpets';
    final totalCovLabel = l10n?.totalCoverage ?? 'Total Coverage';
    final extraCovLabel = l10n?.extraCoverage ?? 'Extra Coverage';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Carpets Required Prominent Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.flooringLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.flooringSoft),
          ),
          child: Column(
            children: [
              Text(
                totalReqLabel,
                style: const TextStyle(
                  color: AppColors.flooringPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.totalCarpets.toString(),
                style: const TextStyle(
                  color: AppColors.flooringPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Orientation: ${result.orientedCarpetLength} × ${result.orientedCarpetWidth} ft',
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Calculation Details Card
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
                detailsLabel,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20, color: AppColors.headerBorder),
              _DetailRow(label: plotDimLabel, value: '${result.plotLength} × ${result.plotWidth} ft'),
              _DetailRow(label: plotAreaLabel, value: '${result.plotArea.toStringAsFixed(0)} sq ft'),
              _DetailRow(label: carpetDimLabel, value: '${result.carpetLength} × ${result.carpetWidth} ft'),
              _DetailRow(label: carpetAreaLabel, value: '${result.carpetArea.toStringAsFixed(0)} sq ft'),
              _DetailRow(label: lengthCarpetsLabel, value: '${result.carpetsAlongLength}'),
              _DetailRow(label: widthCarpetsLabel, value: '${result.carpetsAlongWidth}'),
              _DetailRow(label: totalCarpetsLabel, value: '${result.carpetsAlongLength} × ${result.carpetsAlongWidth} = ${result.totalCarpets}'),
              _DetailRow(label: totalCovLabel, value: '${result.coveredLength} × ${result.coveredWidth} ft (${result.coveredArea.toStringAsFixed(0)} sq ft)'),
              _DetailRow(
                label: extraCovLabel,
                value: '${result.extraCoverage.toStringAsFixed(0)} sq ft (${result.extraCoveragePercent.toStringAsFixed(1)}%)',
                highlightColor: result.extraCoverage > 0 ? AppColors.warning : AppColors.secondaryText,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Success Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Layout calculated successfully!',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total ${result.totalCarpets} carpets required for ${result.plotLength} × ${result.plotWidth} ft plot using ${result.carpetLength} × ${result.carpetWidth} ft carpets.\nTotal coverage: ${result.coveredArea.toStringAsFixed(0)} sq ft (Extra: ${result.extraCoverage.toStringAsFixed(0)} sq ft).',
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tip Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Carpets are arranged in straight rows to cover the complete plot. The calculator automatically evaluates both carpet orientations to minimize the total carpets required.',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualization(BuildContext context, FlooringCalculatorController controller) {
    return Stack(
      children: [
        if (controller.result != null)
          Positioned.fill(
            child: ClipRect(
              child: controller.viewMode == FlooringViewMode.mode2D
                  ? CustomPaint(painter: Flooring2DPainter(result: controller.result!))
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (_) => controller.onScaleStart(),
                      onScaleUpdate: (details) => controller.onScaleUpdate(details.scale, details.focalPointDelta),
                      child: Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: double.infinity,
                        child: CustomPaint(
                          painter: Flooring3DPainter(
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
                  isSelected: controller.viewMode == FlooringViewMode.mode2D,
                  onTap: () => controller.setViewMode(FlooringViewMode.mode2D),
                ),
                _ViewModeButton(
                  label: '3D',
                  isSelected: controller.viewMode == FlooringViewMode.mode3D,
                  onTap: () => controller.setViewMode(FlooringViewMode.mode3D),
                ),
              ],
            ),
          ),
        ),
        if (controller.viewMode == FlooringViewMode.mode3D && controller.result != null)
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
              borderSide: const BorderSide(color: AppColors.flooringPrimary, width: 2),
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
  final Color? highlightColor;

  const _DetailRow({required this.label, required this.value, this.highlightColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: highlightColor ?? AppColors.primaryText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          color: isSelected ? AppColors.flooringPrimary.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
