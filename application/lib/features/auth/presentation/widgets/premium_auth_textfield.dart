import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumAuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const PremiumAuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<PremiumAuthTextField> createState() => _PremiumAuthTextFieldState();
}

class _PremiumAuthTextFieldState extends State<PremiumAuthTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _isObscured,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: Colors.white.withValues(alpha: 0.5), size: 20)
              : null,
          // Show eye toggle only when obscureText is enabled
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                  tooltip: _isObscured ? 'Show password' : 'Hide password',
                )
              : null,
          border: InputBorder.none,
          counterText: '',
          // Reduced vertical padding to make fields shorter
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }
}
