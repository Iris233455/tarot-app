import 'package:flutter/material.dart';

class DesignTokens {
  // Colors
  static const Color primaryColor = Color(0xFFBFA2FF);
  static const Color backgroundColor = Color(0xFFFFF7FB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF4A4A4A);
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color borderColor = Color(0xFFE0E0E0); // 边框颜色
  
  // Border Radius
  static const double radiusLg = 24.0;
  static const double radiusMd = 16.0;
  static const double radiusSm = 8.0;
  static const double radiusXs = 4.0; // 更小的圆角，用于牌面等元素
  
  // Shadows
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x14000000), // opacity 0.08
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  
  // Typography
  static const String fontFamilyHeadline = 'NotoSerifJP';
  static const String fontFamilyBody = 'NotoSansJP';
  
  // Animation
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeOutCubic;
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
} 