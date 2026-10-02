import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Configuration data returned by [CreateTrussDialog].
class TrussConfigurationParams {
  final double plotLength;
  final double plotWidth;
  final double trussSize;
  final double calculationUnitSize;

  const TrussConfigurationParams({
    required this.plotLength,
    required this.plotWidth,
    required this.trussSize,
    this.calculationUnitSize = 10.0,
  });
}

/// Authoritative configuration record returned by [CreateTrussDialog].
typedef CreateTrussConfig = TrussConfigurationParams;

/// Single configuration popup dialog for creating or re-specifying Truss architecture.
/// Features quick preset chips (10, 20, 25, 30, 40, 50 ft, Custom) and a direct custom value input box,
/// plus a dedicated Truss Calculation Size section for piece requirements.
class CreateTrussDialog extends StatefulWidget {
  final double initialLength;
  final double initialWidth;
  final double initialTrussSize;
  final double initialCalculationUnitSize;

  const CreateTrussDialog({
    super.key,
    this.initialLength = 100.0,
    this.initialWidth = 100.0,
    this.initialTrussSize = 30.0,
    this.initialCalculationUnitSize = 10.0,
  });

  /// Static helper to display the dialog and return the user-entered configuration.
  static Future<CreateTrussConfig?> show(
    BuildContext context, {
    double initialLength = 100.0,
    double initialWidth = 100.0,
    double initialTrussSize = 30.0,
    double initialCalculationUnitSize = 10.0,
  }) {
    return showDialog<CreateTrussConfig>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CreateTrussDialog(
        initialLength: initialLength,
        initialWidth: initialWidth,
        initialTrussSize: initialTrussSize,
        initialCalculationUnitSize: initialCalculationUnitSize,
      ),
    );
  }

  @override
  State<CreateTrussDialog> createState() => _CreateTrussDialogState();
}

class _CreateTrussDialogState extends State<CreateTrussDialog> {
  late TextEditingController _plotSizeController;
  late TextEditingController _trussSizeController;
  late TextEditingController _calcSizeController;
  final FocusNode _trussFocusNode = FocusNode();
  final FocusNode _calcFocusNode = FocusNode();

  static const List<double> _standardTrussOptions = [10.0, 20.0, 25.0, 30.0, 40.0, 50.0];
  bool _isCustomSelected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final lenStr = widget.initialLength.toStringAsFixed(0);
    final widthStr = widget.initialWidth.toStringAsFixed(0);
    _plotSizeController = TextEditingController(text: '$lenStr / $widthStr');
    
    final tsStr = widget.initialTrussSize % 1 == 0
        ? widget.initialTrussSize.toInt().toString()
        : widget.initialTrussSize.toStringAsFixed(1);
    _trussSizeController = TextEditingController(text: tsStr);

    final calcStr = widget.initialCalculationUnitSize % 1 == 0
        ? widget.initialCalculationUnitSize.toInt().toString()
        : widget.initialCalculationUnitSize.toStringAsFixed(1);
    _calcSizeController = TextEditingController(text: calcStr);

    _isCustomSelected = !_standardTrussOptions.any((opt) => (opt - widget.initialTrussSize).abs() < 0.01);

    if (widget.initialLength == 100.0 && widget.initialWidth == 100.0 && widget.initialTrussSize == 30.0) {
      _loadSavedPreferences();
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLength = prefs.getDouble('truss_last_length');
      final savedWidth = prefs.getDouble('truss_last_width');
      final savedTrussSize = prefs.getDouble('truss_last_size');
      final savedCalcSize = prefs.getDouble('truss_last_calc_size');

      if (savedLength != null && savedWidth != null && savedLength > 0 && savedWidth > 0 && mounted) {
        final lenStr = savedLength.toStringAsFixed(0);
        final widthStr = savedWidth.toStringAsFixed(0);
        final sizeVal = savedTrussSize ?? widget.initialTrussSize;
        final tsStr = sizeVal % 1 == 0 ? sizeVal.toInt().toString() : sizeVal.toStringAsFixed(1);
        
        setState(() {
          _plotSizeController.text = '$lenStr / $widthStr';
          _trussSizeController.text = tsStr;
          _isCustomSelected = !_standardTrussOptions.any((opt) => (opt - sizeVal).abs() < 0.01);
          if (savedCalcSize != null && savedCalcSize > 0) {
            final calcStr = savedCalcSize % 1 == 0 ? savedCalcSize.toInt().toString() : savedCalcSize.toStringAsFixed(1);
            _calcSizeController.text = calcStr;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _plotSizeController.dispose();
    _trussSizeController.dispose();
    _calcSizeController.dispose();
    _trussFocusNode.dispose();
    _calcFocusNode.dispose();
    super.dispose();
  }

  /// Parses inputs formatted as "100 / 100", "100 x 100", "100*100", "100, 100", or "100".
  ({double length, double width})? _parsePlotSize(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final parts = clean.split(RegExp(r'[/x,*\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      final val = double.tryParse(parts[0]);
      if (val != null && val.isFinite && val > 0) {
        return (length: val, width: val);
      }
    } else if (parts.length >= 2) {
      final len = double.tryParse(parts[0]);
      final wid = double.tryParse(parts[1]);
      if (len != null && wid != null && len.isFinite && wid.isFinite && len > 0 && wid > 0) {
        return (length: len, width: wid);
      }
    }
    return null;
  }

  void _handleSelectPreset(double size) {
    setState(() {
      _isCustomSelected = false;
      _trussSizeController.text = size % 1 == 0 ? size.toInt().toString() : size.toStringAsFixed(1);
      _errorMessage = null;
    });
  }

  void _handleSelectCustom() {
    setState(() {
      _isCustomSelected = true;
      _errorMessage = null;
    });
    Future.microtask(() => _trussFocusNode.requestFocus());
  }

  void _handleGenerate() {
    final plotSize = _parsePlotSize(_plotSizeController.text);
    final sizeText = _trussSizeController.text.trim();
    final trussSize = double.tryParse(sizeText);
    final calcSizeText = _calcSizeController.text.trim();
    final calcSize = double.tryParse(calcSizeText) ?? 10.0;

    if (plotSize == null) {
      setState(() => _errorMessage = 'Please enter a valid Plot Size (e.g. 100 / 100 or 100 x 100).');
      return;
    }

    if (trussSize == null || !trussSize.isFinite || trussSize <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive Truss Size (e.g. 10, 15, 30 ft).');
      return;
    }

    if (calcSize <= 0 || !calcSize.isFinite) {
      setState(() => _errorMessage = 'Please enter a valid positive Truss Calculation Size (e.g. 10, 12, 15 ft).');
      return;
    }

    final maxPlotDim = math.max(plotSize.length, plotSize.width);
    if (trussSize > maxPlotDim) {
      setState(() => _errorMessage = 'Truss Size cannot exceed Plot dimensions.');
      return;
    }

    setState(() => _errorMessage = null);

    // Persist user-entered values immediately
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setDouble('truss_last_length', plotSize.length);
        prefs.setDouble('truss_last_width', plotSize.width);
        prefs.setDouble('truss_last_size', trussSize);
        prefs.setDouble('truss_last_calc_size', calcSize);
      });
    } catch (_) {}

    Navigator.of(context).pop(
      TrussConfigurationParams(
        plotLength: plotSize.length,
        plotWidth: plotSize.width,
        trussSize: trussSize,
        calculationUnitSize: calcSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 500 ? screenWidth * 0.92 : 440.0;
    final currentTrussVal = double.tryParse(_trussSizeController.text.trim());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.architecture_rounded, color: AppColors.trussPrimary, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.createTruss.toUpperCase() ?? 'CREATE TRUSS',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n?.enterPlotAndTrussSpec ?? 'Enter plot & custom truss specifications',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.headerBorder),
                const SizedBox(height: 20),

                // Section 1: Combined PLOT SIZE Box (Length / Width)
                _buildInputField(
                  label: l10n?.plotSizeLengthWidth ?? 'PLOT SIZE (Length / Width)',
                  hint: '100 / 100 ft',
                  controller: _plotSizeController,
                  icon: Icons.aspect_ratio_rounded,
                ),

                const SizedBox(height: 18),

                // Section 2: TRUSS SIZE Selection Header
                Text(
                  l10n?.selectOrWriteTrussSize ?? 'SELECT OR WRITE TRUSS SIZE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Preset Chips + Custom Chip
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ..._standardTrussOptions.map((opt) {
                      final isSelected = !_isCustomSelected &&
                          currentTrussVal != null &&
                          (currentTrussVal - opt).abs() < 0.01;
                      return ChoiceChip(
                        label: Text('${opt.toInt()} ft'),
                        selected: isSelected,
                        selectedColor: AppColors.trussPrimary,
                        backgroundColor: AppColors.inputBackground,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.trussPrimary : AppColors.inputBorder,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (_) => _handleSelectPreset(opt),
                      );
                    }),
                    ChoiceChip(
                      label: Text(l10n?.custom ?? 'Custom'),
                      selected: _isCustomSelected,
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: AppColors.inputBackground,
                      labelStyle: TextStyle(
                        color: _isCustomSelected ? Colors.white : AppColors.primaryText,
                        fontSize: 12,
                        fontWeight: _isCustomSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: _isCustomSelected ? const Color(0xFF0284C7) : AppColors.inputBorder,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onSelected: (_) => _handleSelectCustom(),
                    ),
                  ],
                ),

                // Editable Truss Size Box (only opened when Custom is selected)
                if (_isCustomSelected) ...[
                  const SizedBox(height: 12),
                  _buildInputField(
                    label: l10n?.customTrussSizeWrite ?? 'CUSTOM TRUSS SIZE (Write your value)',
                    hint: 'e.g. 10, 15, 25, 30, 35 ft',
                    controller: _trussSizeController,
                    focusNode: _trussFocusNode,
                    icon: Icons.straighten_rounded,
                    suffix: 'ft',
                  ),
                ],

                const SizedBox(height: 18),

                // Section 3: TRUSS CALCULATION SIZE (Direct Input)
                _buildInputField(
                  label: l10n?.trussCalculationSize ?? 'TRUSS CALCULATION SIZE',
                  hint: 'e.g. 10, 12, 15, 20 ft',
                  controller: _calcSizeController,
                  focusNode: _calcFocusNode,
                  icon: Icons.calculate_outlined,
                  suffix: 'ft',
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.stageLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.stagePrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.stagePrimary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: AppColors.stagePrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Button: GENERATE TRUSS
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.trussPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.generateTrussButton.toUpperCase() ?? 'GENERATE TRUSS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
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
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    FocusNode? focusNode,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: AppColors.inputBackground,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: AppColors.trussPrimary, size: 20),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.bold),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
