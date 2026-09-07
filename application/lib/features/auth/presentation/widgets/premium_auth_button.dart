import 'package:flutter/material.dart';

class PremiumAuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PremiumAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PremiumAuthButton> createState() => _PremiumAuthButtonState();
}

class _PremiumAuthButtonState extends State<PremiumAuthButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

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
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isDisabled
                  ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.1)]
                  : [
                      const Color(0xFF6366F1), // Indigo 500
                      const Color(0xFF8B5CF6), // Violet 500
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: _isHovered && !isDisabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.text,
                  style: TextStyle(
                    color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
