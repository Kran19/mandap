import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Configuration data returned by [CreateStageDialog].
class StageConfigurationParams {
  final double stageLength;
  final double stageWidth;
  final double tableLength;
  final double tableWidth;

  const StageConfigurationParams({
    required this.stageLength,
    required this.stageWidth,
    this.tableLength = 8.0,
    this.tableWidth = 4.0,
  });
}

typedef CreateStageConfig = StageConfigurationParams;

/// Single configuration popup dialog for creating or re-specifying Stage dimensions.
/// Prompts only for Stage Size (Length / Width) and Table Size (Length / Width).
/// Stage height is explicitly excluded per user specification.
class CreateStageDialog extends StatefulWidget {
  final double initialStageLength;
  final double initialStageWidth;
  final double initialTableLength;
  final double initialTableWidth;

  const CreateStageDialog({
    super.key,
    this.initialStageLength = 32.0,
    this.initialStageWidth = 20.0,
    this.initialTableLength = 8.0,
    this.initialTableWidth = 4.0,
  });

  /// Static helper to display the dialog and return the user-entered configuration.
  static Future<CreateStageConfig?> show(
    BuildContext context, {
    double initialStageLength = 32.0,
    double initialStageWidth = 20.0,
    double initialTableLength = 8.0,
    double initialTableWidth = 4.0,
  }) {
    return showDialog<CreateStageConfig>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CreateStageDialog(
        initialStageLength: initialStageLength,
        initialStageWidth: initialStageWidth,
        initialTableLength: initialTableLength,
        initialTableWidth: initialTableWidth,
      ),
    );
  }

  @override
  State<CreateStageDialog> createState() => _CreateStageDialogState();
}

class _CreateStageDialogState extends State<CreateStageDialog> {
  late TextEditingController _stageSizeController;
  late TextEditingController _tableSizeController;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final slStr = widget.initialStageLength.toStringAsFixed(0);
    final swStr = widget.initialStageWidth.toStringAsFixed(0);
    final tlStr = widget.initialTableLength.toStringAsFixed(0);
    final twStr = widget.initialTableWidth.toStringAsFixed(0);

    _stageSizeController = TextEditingController(text: '$slStr / $swStr');
    _tableSizeController = TextEditingController(text: '$tlStr / $twStr');

    // If initial dimensions are default (32/20), check if user had previously saved custom dimensions
    if (widget.initialStageLength == 32.0 && widget.initialStageWidth == 20.0) {
      _loadSavedPreferences();
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLength = prefs.getDouble('stage_last_length');
      final savedWidth = prefs.getDouble('stage_last_width');
      final savedTableLength = prefs.getDouble('stage_last_table_length');
      final savedTableWidth = prefs.getDouble('stage_last_table_width');

      if (savedLength != null && savedWidth != null && savedLength > 0 && savedWidth > 0 && mounted) {
        final slStr = savedLength == savedLength.roundToDouble() ? savedLength.toInt().toString() : savedLength.toString();
        final swStr = savedWidth == savedWidth.roundToDouble() ? savedWidth.toInt().toString() : savedWidth.toString();
        final tl = savedTableLength ?? widget.initialTableLength;
        final tw = savedTableWidth ?? widget.initialTableWidth;
        final tlStr = tl == tl.roundToDouble() ? tl.toInt().toString() : tl.toString();
        final twStr = tw == tw.roundToDouble() ? tw.toInt().toString() : tw.toString();

        setState(() {
          _stageSizeController.text = '$slStr / $swStr';
          _tableSizeController.text = '$tlStr / $twStr';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stageSizeController.dispose();
    _tableSizeController.dispose();
    super.dispose();
  }

  /// Parses inputs formatted as "32 / 20", "32 x 20", "32*20", "32, 20", "32 ft", or single number "32".
  ({double length, double width})? _parseDimensions(String raw) {
    final clean = raw
        .trim()
        .toLowerCase()
        .replaceAll("'", '')
        .replaceAll('"', '')
        .replaceAll('ft', '')
        .replaceAll('feet', '')
        .replaceAll('m', '')
        .trim();
    if (clean.isEmpty) return null;

    final parts = clean.split(RegExp(r'[/x,*\s\-]+')).where((p) => p.isNotEmpty).toList();
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

  void _swapStageDimensions() {
    final dims = _parseDimensions(_stageSizeController.text);
    if (dims != null) {
      setState(() {
        final lStr = dims.width == dims.width.roundToDouble() ? dims.width.toInt().toString() : dims.width.toString();
        final wStr = dims.length == dims.length.roundToDouble() ? dims.length.toInt().toString() : dims.length.toString();
        _stageSizeController.text = '$lStr / $wStr';
        _errorMessage = null;
      });
    }
  }

  void _swapTableDimensions() {
    final dims = _parseDimensions(_tableSizeController.text);
    if (dims != null) {
      setState(() {
        final lStr = dims.width == dims.width.roundToDouble() ? dims.width.toInt().toString() : dims.width.toString();
        final wStr = dims.length == dims.length.roundToDouble() ? dims.length.toInt().toString() : dims.length.toString();
        _tableSizeController.text = '$lStr / $wStr';
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleGenerate() async {
    final stageSize = _parseDimensions(_stageSizeController.text);
    final tableSize = _parseDimensions(_tableSizeController.text) ?? (length: 4.0, width: 8.0);

    if (stageSize == null) {
      setState(() => _errorMessage = 'Please enter a valid Stage Size (e.g. 32 / 20 or 30 x 20 ft or 40).');
      return;
    }

    if (tableSize.length <= 0 || tableSize.width <= 0) {
      setState(() => _errorMessage = 'Please enter valid positive Table Dimensions (e.g. 4 / 8 ft).');
      return;
    }

    setState(() => _errorMessage = null);

    // Persist user-entered values immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('stage_last_length', stageSize.length);
      await prefs.setDouble('stage_last_width', stageSize.width);
      await prefs.setDouble('stage_last_table_length', tableSize.length);
      await prefs.setDouble('stage_last_table_width', tableSize.width);
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pop(
      StageConfigurationParams(
        stageLength: stageSize.length,
        stageWidth: stageSize.width,
        tableLength: tableSize.length,
        tableWidth: tableSize.width,
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
                    color: AppColors.stageLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.theater_comedy_rounded,
                    color: AppColors.stagePrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.createStageStructure ?? 'CREATE STAGE STRUCTURE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n?.enterStageDimensionsAndTable ?? 'Enter stage dimensions & table layout',
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

            // Section 1: Combined STAGE SIZE Box (Length / Width)
            _buildInputField(
              label: l10n?.stageSizeLengthWidth ?? 'STAGE SIZE (Length / Width)',
              hint: '32 / 20 ft',
              controller: _stageSizeController,
              icon: Icons.aspect_ratio_rounded,
              onSwap: _swapStageDimensions,
            ),

            const SizedBox(height: 18),

            // Section 2: TABLE SIZE Box (Length / Width)
            _buildInputField(
              label: l10n?.stageTableSizeLengthWidth ?? 'STAGE TABLE SIZE (Length / Width)',
              hint: '4 / 8 ft',
              controller: _tableSizeController,
              icon: Icons.table_restaurant_rounded,
              onSwap: _swapTableDimensions,
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

            // Action Button: GENERATE STAGE STRUCTURE
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.stagePrimary,
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
                        l10n?.generateStageStructure ?? 'GENERATE STAGE STRUCTURE',
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
                    color: AppColors.stagePrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.stagePrimary),
                      SizedBox(width: 3),
                      Text(
                        'Swap L ⇄ W',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.stagePrimary,
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
            prefixIcon: Icon(icon, color: AppColors.stagePrimary, size: 20),
            suffixIcon: onSwap != null
                ? Tooltip(
                    message: 'Swap Length & Width (L ⇄ W)',
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.stagePrimary, size: 20),
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
              borderSide: const BorderSide(color: AppColors.stagePrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
