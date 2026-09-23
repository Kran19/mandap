import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Configuration data returned by [CreatePoleDialog].
class PoleConfigurationParams {
  final double plotLength;
  final double plotWidth;
  final double pipeSize;

  const PoleConfigurationParams({
    required this.plotLength,
    required this.plotWidth,
    required this.pipeSize,
  });
}

/// Authoritative configuration record returned by [CreatePoleDialog].
typedef CreatePoleConfig = PoleConfigurationParams;

/// Single configuration popup dialog for creating a new Pipe/Pole architecture.
/// Features a single combined input box for Plot Size (Length / Width) and Pipe Size.
class CreatePoleDialog extends StatefulWidget {
  final double initialLength;
  final double initialWidth;
  final double initialPipeSize;

  const CreatePoleDialog({
    super.key,
    this.initialLength = 100.0,
    this.initialWidth = 100.0,
    this.initialPipeSize = 15.0,
  });

  /// Static helper to display the dialog and return the user-entered configuration.
  static Future<CreatePoleConfig?> show(
    BuildContext context, {
    double initialLength = 100.0,
    double initialWidth = 100.0,
    double initialPipeSize = 15.0,
  }) {
    return showDialog<CreatePoleConfig>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CreatePoleDialog(
        initialLength: initialLength,
        initialWidth: initialWidth,
        initialPipeSize: initialPipeSize,
      ),
    );
  }

  @override
  State<CreatePoleDialog> createState() => _CreatePoleDialogState();
}

class _CreatePoleDialogState extends State<CreatePoleDialog> {
  late TextEditingController _plotSizeController;
  late TextEditingController _pipeSizeController;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final lenStr = widget.initialLength.toStringAsFixed(0);
    final widthStr = widget.initialWidth.toStringAsFixed(0);
    _plotSizeController = TextEditingController(text: '$lenStr / $widthStr');
    _pipeSizeController = TextEditingController(text: widget.initialPipeSize.toStringAsFixed(0));
    if (widget.initialLength == 100.0 && widget.initialWidth == 100.0 && widget.initialPipeSize == 15.0) {
      _loadSavedPreferences();
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLength = prefs.getDouble('pole_last_length');
      final savedWidth = prefs.getDouble('pole_last_width');
      final savedPipeSize = prefs.getDouble('pole_last_pipe_size');

      if (savedLength != null && savedWidth != null && savedLength > 0 && savedWidth > 0 && mounted) {
        final lenStr = savedLength.toStringAsFixed(0);
        final widthStr = savedWidth.toStringAsFixed(0);
        final psStr = (savedPipeSize ?? widget.initialPipeSize).toStringAsFixed(0);
        setState(() {
          _plotSizeController.text = '$lenStr / $widthStr';
          _pipeSizeController.text = psStr;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _plotSizeController.dispose();
    _pipeSizeController.dispose();
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

  void _handleGenerate() {
    final plotSize = _parsePlotSize(_plotSizeController.text);
    final sizeText = _pipeSizeController.text.trim();
    final pipeSize = double.tryParse(sizeText);

    if (plotSize == null) {
      setState(() => _errorMessage = 'Please enter a valid Plot Size (e.g. 100 / 100 or 100 x 100).');
      return;
    }

    if (pipeSize == null || !pipeSize.isFinite || pipeSize <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive Pipe Size in ft (e.g. 15).');
      return;
    }

    if (pipeSize > plotSize.length || pipeSize > plotSize.width) {
      setState(() => _errorMessage = 'Pipe Size cannot exceed Plot dimensions.');
      return;
    }

    setState(() => _errorMessage = null);

    // Persist user-entered values immediately
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setDouble('pole_last_length', plotSize.length);
        prefs.setDouble('pole_last_width', plotSize.width);
        prefs.setDouble('pole_last_pipe_size', pipeSize);
      });
    } catch (_) {}

    Navigator.of(context).pop(
      PoleConfigurationParams(
        plotLength: plotSize.length,
        plotWidth: plotSize.width,
        pipeSize: pipeSize,
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
                    color: AppColors.poleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.view_column_rounded,
                    color: AppColors.polePrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.createPipeStructure.toUpperCase() ?? 'CREATE PIPE STRUCTURE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.enterPlotAndPipeSpec ?? 'Enter plot & pipe size specifications',
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

            // Section 2: PIPE SIZE Box
            _buildInputField(
              label: l10n?.pipeSizeLabel ?? 'PIPE SIZE',
              hint: '15 ft',
              controller: _pipeSizeController,
              icon: Icons.straighten_rounded,
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

            // Action Button: GENERATE POLE STRUCTURE
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.polePrimary,
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
                        l10n?.generatePipeStructure ?? 'GENERATE PIPE STRUCTURE',
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: AppColors.polePrimary, size: 20),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondaryText),
            filled: true,
            fillColor: AppColors.appBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.headerBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.polePrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
