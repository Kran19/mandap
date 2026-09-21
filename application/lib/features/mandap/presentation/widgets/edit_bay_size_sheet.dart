import 'package:flutter/material.dart';
import '../../application/mandap_editor_controller.dart';
import '../../domain/entities/truss_bay.dart';

/// Floating card widget matching Reference Image 1 for editing the selected Truss Module / Bay dimensions.
class EditBaySizeSheet extends StatefulWidget {
  final MandapEditorController controller;
  final TrussBay bay;
  final VoidCallback onClose;

  const EditBaySizeSheet({
    super.key,
    required this.controller,
    required this.bay,
    required this.onClose,
  });

  @override
  State<EditBaySizeSheet> createState() => _EditBaySizeSheetState();
}

class _EditBaySizeSheetState extends State<EditBaySizeSheet> {
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant EditBaySizeSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bay.id != widget.bay.id ||
        (oldWidget.bay.lengthFt - widget.bay.lengthFt).abs() > 0.01 ||
        (oldWidget.bay.widthFt - widget.bay.widthFt).abs() > 0.01) {
      _initControllers();
    }
  }

  void _initControllers() {
    final lenStr = widget.bay.lengthFt.toStringAsFixed(
      widget.bay.lengthFt % 1 == 0 ? 0 : 1,
    );
    final widthStr = widget.bay.widthFt.toStringAsFixed(
      widget.bay.widthFt % 1 == 0 ? 0 : 1,
    );
    _lengthController = TextEditingController(text: lenStr);
    _widthController = TextEditingController(text: widthStr);
    _errorMessage = null;
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  void _stepValue(TextEditingController controller, double delta) {
    final current = double.tryParse(controller.text.trim()) ?? 0.0;
    final next = (current + delta).clamp(1.0, 1000.0);
    controller.text = next.toStringAsFixed(next % 1 == 0 ? 0 : 1);
  }

  void _applyChanges() {
    FocusScope.of(context).unfocus();
    final newLength = double.tryParse(_lengthController.text.trim());
    final newWidth = double.tryParse(_widthController.text.trim());

    if (newLength == null || newLength <= 0) {
      setState(() => _errorMessage = 'Please enter a valid length > 0 ft.');
      return;
    }
    if (newWidth == null || newWidth <= 0) {
      setState(() => _errorMessage = 'Please enter a valid width > 0 ft.');
      return;
    }

    try {
      widget.controller.resizeBay(
        widget.bay.id,
        targetWidthFt: newWidth,
        targetLengthFt: newLength,
      );
      setState(() => _errorMessage = null);
      widget.onClose();
    } catch (e) {
      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('ArgumentError: ', '')
            .replaceFirst('StateError: ', '');
      });
    }
  }

  void _resetToDefault() {
    FocusScope.of(context).unfocus();
    try {
      widget.controller.resetBayToDefault(widget.bay.id);
      setState(() => _errorMessage = null);
      widget.onClose();
    } catch (e) {
      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('ArgumentError: ', '')
            .replaceFirst('StateError: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWidthFormatted = widget.bay.widthFt.toStringAsFixed(
      widget.bay.widthFt % 1 == 0 ? 0 : 1,
    );
    final currentLengthFormatted = widget.bay.lengthFt.toStringAsFixed(
      widget.bay.lengthFt % 1 == 0 ? 0 : 1,
    );
    final wPadded = widget.bay.widthFt.toInt().toString().padLeft(2, '0');
    final lPadded = widget.bay.lengthFt.toInt().toString().padLeft(2, '0');
    final badgeFormat = '$wPadded/$lPadded';

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title + Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Bay ($badgeFormat)',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current Size label
          const Text(
            'Current Size (00/00)',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Current Size Pill in 00/00 format
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  badgeFormat,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '$currentWidthFormatted ft × $currentLengthFormatted ft',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Length (ft)
          const Text(
            'Length (ft)',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _buildStepperInput(_lengthController),
          const SizedBox(height: 10),

          // Width (ft)
          const Text(
            'Width (ft)',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _buildStepperInput(_widthController),
          const SizedBox(height: 12),

          // Error Message Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Apply Button
          ElevatedButton(
            onPressed: _applyChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D6AE5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Reset to Default Button
          ElevatedButton(
            onPressed: _resetToDefault,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE2E8F0),
              foregroundColor: const Color(0xFF1D6AE5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset to Default',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperInput(TextEditingController controller) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _applyChanges(),
            ),
          ),
          // Stepper Column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _stepValue(controller, 5.0),
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: () => _stepValue(controller, -5.0),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
