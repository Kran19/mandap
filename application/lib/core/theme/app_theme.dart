import 'package:flutter/material.dart';

class AppColors {
  // App Shell Colors
  static const Color appBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color headerBackground = Color(0xFFFFFFFF);
  static const Color headerBorder = Color(0xFFE2E8F0);
  static const Color dividerBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color primaryText = Color(0xFF172033);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);

  // Form Controls
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color inputFocusBorder = Color(0xFF2563EB);

  // CAD Canvas (Dark Viewport)
  static const Color cadCanvasBackground = Color(0xFF0F172A);
  static const Color cadGridColor = Color(0xFF263449);
  static const Color cadBorder = Color(0xFF334155);

  // 🔵 TRUSS Module Accent
  static const Color trussPrimary = Color(0xFF2563EB);
  static const Color trussLight = Color(0xFFEFF6FF);
  static const Color trussSoft = Color(0xFFDBEAFE);

  // 🟠 POLE Module Accent
  static const Color polePrimary = Color(0xFFF97316);
  static const Color poleLight = Color(0xFFFFF7ED);
  static const Color poleSoft = Color(0xFFFFEDD5);

  // 🔴 STAGE Module Accent
  static const Color stagePrimary = Color(0xFFDC2626);
  static const Color stageLight = Color(0xFFFEF2F2);
  static const Color stageSoft = Color(0xFFFEE2E2);

  // 🟢 FLOORING Module Accent
  static const Color flooringPrimary = Color(0xFF059669);
  static const Color flooringLight = Color(0xFFECFDF5);
  static const Color flooringSoft = Color(0xFFD1FAE5);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}

class AppShadows {
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.06),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.12),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
