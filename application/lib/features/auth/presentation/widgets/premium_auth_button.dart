import 'package:flutter/material.dart';

class PremiumAuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? gradientColors;
  final double borderRadius;

  final double verticalPadding;

  const PremiumAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradientColors,
    this.borderRadius = 14,
    this.verticalPadding = 12,
  });

  @override
  State<PremiumAuthButton> createState() => _PremiumAuthButtonState();
}

class _PremiumAuthButtonState extends State<PremiumAuthButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final colors = widget.gradientColors ?? [
      const Color(0xFF3B82F6), // Blue 500
      const Color(0xFF2563EB), // Blue 600
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: isDisabled
                  ? [const Color(0xFFCBD5E1), const Color(0xFFCBD5E1)]
                  : colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: _isHovered && !isDisabled
                ? [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.text,
                  style: TextStyle(
                    color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
