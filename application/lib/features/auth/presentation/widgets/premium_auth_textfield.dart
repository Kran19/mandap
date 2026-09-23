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
  final Color? fillColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const PremiumAuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.maxLength,
    this.inputFormatters,
    this.fillColor,
    this.borderColor,
    this.contentPadding,
    this.borderRadius = 16,
    this.boxShadow,
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
        color: widget.fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.borderColor != null ? Border.all(color: widget.borderColor!) : null,
        boxShadow: widget.boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _isObscured,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: const Color(0xFF64748B), size: 20)
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                  tooltip: _isObscured ? 'Show password' : 'Hide password',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              : null,
          border: InputBorder.none,
          counterText: '',
          contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}
