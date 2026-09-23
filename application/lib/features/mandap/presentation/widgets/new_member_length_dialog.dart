import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Modal dialog presented when user finishes selecting a straight segment with Pen.
///
/// Prompts for the exact length in feet along the dominant axis.
/// Rejects non-numeric, zero, negative, NaN, and Infinite inputs.
class NewMemberLengthDialog extends StatefulWidget {
  final String directionAxis; // 'X' or 'Z'
  final double previewLength;

  const NewMemberLengthDialog({
    super.key,
    required this.directionAxis,
    required this.previewLength,
  });

  static Future<double?> show(
    BuildContext context, {
    required String directionAxis,
    required double previewLength,
  }) {
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NewMemberLengthDialog(
        directionAxis: directionAxis,
        previewLength: previewLength,
      ),
    );
  }

  @override
  State<NewMemberLengthDialog> createState() => _NewMemberLengthDialogState();
}

class _NewMemberLengthDialogState extends State<NewMemberLengthDialog> {
  late final TextEditingController _lengthController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate with rounded preview length or default standard piece
    final initialVal = widget.previewLength > 0
        ? widget.previewLength.toStringAsFixed(widget.previewLength.truncateToDouble() == widget.previewLength ? 0 : 1)
        : '10';
    _lengthController = TextEditingController(text: initialVal);
  }

  @override
  void dispose() {
    _lengthController.dispose();
    super.dispose();
  }

  void _handleApply() {
    final text = _lengthController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid length in feet.');
      return;
    }

    final val = double.tryParse(text);
    if (val == null || !val.isFinite || val <= 0) {
      setState(() => _errorMessage = 'Length must be a positive number greater than 0.');
      return;
    }

    if (val > 500) {
      setState(() => _errorMessage = 'Length cannot exceed 500 feet.');
      return;
    }

    setState(() => _errorMessage = null);
    Navigator.of(context).pop(val);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(null);
      },
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A), // Dark slate CAD background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.trussLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.architecture_rounded,
                      color: AppColors.trussPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n?.addMember.toUpperCase() ?? 'NEW TRUSS MEMBER',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Specs Summary Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Direction',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.directionAxis}-Axis',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Distance',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.previewLength.toStringAsFixed(1)} ft',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Length Input Field
              Text(
                l10n?.lengthFt ?? 'Length (feet)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _lengthController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  suffixText: 'ft',
                  suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.trussPrimary, width: 2),
                  ),
                ),
                onSubmitted: (_) => _handleApply(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Cancel & Apply Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(l10n?.cancel.toUpperCase() ?? 'CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.trussPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      l10n?.okDone ?? 'APPLY',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
