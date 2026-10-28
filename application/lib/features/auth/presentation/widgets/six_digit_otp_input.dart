import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium 6-box OTP input widget with automatic focus advance,
/// backspace retreat, paste support, and sleek luxury styling.
class SixDigitOtpInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final String? initialValue;

  const SixDigitOtpInput({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.initialValue,
  });

  @override
  State<SixDigitOtpInput> createState() => _SixDigitOtpInputState();
}

class _SixDigitOtpInputState extends State<SixDigitOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (i) => TextEditingController());
    _focusNodes = List.generate(6, (i) => FocusNode());

    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      final chars = widget.initialValue!.split('');
      for (int i = 0; i < chars.length && i < 6; i++) {
        _controllers[i].text = chars[i];
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // User pasted multiple characters
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6; i++) {
        final digit = (i < digits.length) ? digits[i] : '';
        _controllers[i].text = digit;
      }
      final newOtp = _currentOtp;
      widget.onChanged(newOtp);
      if (newOtp.length == 6) {
        _focusNodes[5].unfocus();
        widget.onCompleted?.call(newOtp);
      } else {
        final nextEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
        if (nextEmpty != -1) {
          _focusNodes[nextEmpty].requestFocus();
        }
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final newOtp = _currentOtp;
    widget.onChanged(newOtp);
    if (newOtp.length == 6) {
      widget.onCompleted?.call(newOtp);
    }
  }

  void _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        widget.onChanged(_currentOtp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) => _onKey(index, event),
          child: Container(
            width: 48,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focusNodes[index].hasFocus
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: _focusNodes[index].hasFocus ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => _onDigitChanged(index, val),
              ),
            ),
          ),
        );
      }),
    );
  }
}
