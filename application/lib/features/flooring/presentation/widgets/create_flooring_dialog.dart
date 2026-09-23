import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Configuration data returned by [CreateFlooringDialog].
class FlooringConfigurationParams {
  final double plotLength;
  final double plotWidth;
  final double carpetLength;
  final double carpetWidth;

  const FlooringConfigurationParams({
    required this.plotLength,
    required this.plotWidth,
    required this.carpetLength,
    required this.carpetWidth,
  });
}

/// Authoritative configuration record returned by [CreateFlooringDialog].
typedef CreateFlooringConfig = FlooringConfigurationParams;

/// Single configuration popup dialog for creating a new Flooring layout.
/// Prompts for Plot Size (Length / Width) and Carpet Dimensions (Length / Width).
class CreateFlooringDialog extends StatefulWidget {
  final double initialPlotLength;
  final double initialPlotWidth;
  final double initialCarpetLength;
  final double initialCarpetWidth;

  const CreateFlooringDialog({
    super.key,
    this.initialPlotLength = 100.0,
    this.initialPlotWidth = 60.0,
    this.initialCarpetLength = 15.0,
    this.initialCarpetWidth = 30.0,
  });

  /// Static helper to display the dialog and return the user-entered configuration.
  static Future<CreateFlooringConfig?> show(
    BuildContext context, {
    double initialPlotLength = 100.0,
    double initialPlotWidth = 60.0,
    double initialCarpetLength = 15.0,
    double initialCarpetWidth = 30.0,
  }) {
    return showDialog<CreateFlooringConfig>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CreateFlooringDialog(
        initialPlotLength: initialPlotLength,
        initialPlotWidth: initialPlotWidth,
        initialCarpetLength: initialCarpetLength,
        initialCarpetWidth: initialCarpetWidth,
      ),
    );
  }

  @override
  State<CreateFlooringDialog> createState() => _CreateFlooringDialogState();
}

class _CreateFlooringDialogState extends State<CreateFlooringDialog> {
  late TextEditingController _plotSizeController;
  late TextEditingController _carpetSizeController;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final plStr = widget.initialPlotLength.toStringAsFixed(0);
    final pwStr = widget.initialPlotWidth.toStringAsFixed(0);
    final clStr = widget.initialCarpetLength.toStringAsFixed(0);
    final cwStr = widget.initialCarpetWidth.toStringAsFixed(0);

    _plotSizeController = TextEditingController(text: '$plStr / $pwStr');
    _carpetSizeController = TextEditingController(text: '$clStr / $cwStr');
    if (widget.initialPlotLength == 100.0 && widget.initialPlotWidth == 60.0) {
      _loadSavedPreferences();
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPL = prefs.getDouble('flooring_last_plot_length');
      final savedPW = prefs.getDouble('flooring_last_plot_width');
      final savedCL = prefs.getDouble('flooring_last_carpet_length');
      final savedCW = prefs.getDouble('flooring_last_carpet_width');

      if (savedPL != null && savedPW != null && savedPL > 0 && savedPW > 0 && mounted) {
        final plStr = savedPL.toStringAsFixed(0);
        final pwStr = savedPW.toStringAsFixed(0);
        final clStr = (savedCL ?? widget.initialCarpetLength).toStringAsFixed(0);
        final cwStr = (savedCW ?? widget.initialCarpetWidth).toStringAsFixed(0);
        setState(() {
          _plotSizeController.text = '$plStr / $pwStr';
          _carpetSizeController.text = '$clStr / $cwStr';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _plotSizeController.dispose();
    _carpetSizeController.dispose();
    super.dispose();
  }

  /// Parses inputs formatted as "100 / 60", "100 x 60", "100*60", "100, 60", or "100".
  ({double length, double width})? _parseDimensions(String raw) {
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

  void _swapPlotDimensions() {
    final dims = _parseDimensions(_plotSizeController.text);
    if (dims != null) {
      setState(() {
        final lStr = dims.width == dims.width.roundToDouble() ? dims.width.toInt().toString() : dims.width.toString();
        final wStr = dims.length == dims.length.roundToDouble() ? dims.length.toInt().toString() : dims.length.toString();
        _plotSizeController.text = '$lStr / $wStr';
        _errorMessage = null;
      });
    }
  }

  void _swapCarpetDimensions() {
    final dims = _parseDimensions(_carpetSizeController.text);
    if (dims != null) {
      setState(() {
        final lStr = dims.width == dims.width.roundToDouble() ? dims.width.toInt().toString() : dims.width.toString();
        final wStr = dims.length == dims.length.roundToDouble() ? dims.length.toInt().toString() : dims.length.toString();
        _carpetSizeController.text = '$lStr / $wStr';
        _errorMessage = null;
      });
    }
  }

  void _handleGenerate() {
    final plotSize = _parseDimensions(_plotSizeController.text);
    final carpetSize = _parseDimensions(_carpetSizeController.text) ?? (length: 12.0, width: 6.0);

    if (plotSize == null) {
      setState(() => _errorMessage = 'Please enter a valid Plot Size (e.g. 100 / 60 or 100 x 60 ft).');
      return;
    }

    if (carpetSize.length <= 0 || carpetSize.width <= 0) {
      setState(() => _errorMessage = 'Please enter valid positive Carpet Dimensions (e.g. 12 / 6 ft).');
      return;
    }

    setState(() => _errorMessage = null);

    // Persist user-entered values immediately
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setDouble('flooring_last_plot_length', plotSize.length);
        prefs.setDouble('flooring_last_plot_width', plotSize.width);
        prefs.setDouble('flooring_last_carpet_length', carpetSize.length);
        prefs.setDouble('flooring_last_carpet_width', carpetSize.width);
      });
    } catch (_) {}

    Navigator.of(context).pop(
      FlooringConfigurationParams(
        plotLength: plotSize.length,
        plotWidth: plotSize.width,
        carpetLength: carpetSize.length,
        carpetWidth: carpetSize.width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 500 ? screenWidth * 0.9 : 420.0;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.flooringLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.grid_on_rounded,
                    color: AppColors.flooringPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.createFlooringLayout ?? 'CREATE FLOORING LAYOUT',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.enterPlotAndCarpetSpec ?? 'Enter plot and carpet roll specifications',
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
              hint: '100 / 60 ft',
              controller: _plotSizeController,
              icon: Icons.aspect_ratio_rounded,
              onSwap: _swapPlotDimensions,
            ),

            const SizedBox(height: 18),

            // Section 2: CARPET SIZE Box (Length / Width)
            _buildInputField(
              label: l10n?.carpetSizeLengthWidth ?? 'CARPET SIZE (Length / Width)',
              hint: '15 / 30 ft',
              controller: _carpetSizeController,
              icon: Icons.straighten_rounded,
              onSwap: _swapCarpetDimensions,
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

            // Action Button: GENERATE FLOORING LAYOUT
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.flooringPrimary,
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
                        l10n?.generateFlooringLayout ?? 'GENERATE FLOORING LAYOUT',
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
  );
}

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    VoidCallback? onSwap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            if (onSwap != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onSwap,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.flooringPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.flooringPrimary),
                      SizedBox(width: 3),
                      Text(
                        'Swap L ⇄ W',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.flooringPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: AppColors.flooringPrimary, size: 20),
            suffixIcon: onSwap != null
                ? Tooltip(
                    message: 'Swap Length & Width (L ⇄ W)',
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.flooringPrimary, size: 20),
                      onPressed: onSwap,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.appBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.headerBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.flooringPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
