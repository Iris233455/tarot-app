import 'package:flutter/material.dart';

class DesignTokens {
  // Colors
  static const Color primaryColor = Color(0xFFBFA2FF);
  static const Color backgroundColor = Color(0xFFFFF7FB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE0E0E0); // 边框颜色
  
  // Text Colors (完整的文本颜色层次)
  static const Color textPrimary = Color(0xFF1A1A1A);   // 主文本颜色（深黑）
  static const Color textSecondary = Color(0xFF4A4A4A); // 次文本颜色（中灰）
  static const Color textTertiary = Color(0xFF9E9E9E);  // 弱化文字颜色（浅灰）
  static const Color textInverse = Color(0xFFFFFFFF);   // 深色背景下文字颜色（白）
  
  // Semantic Colors (语义化颜色)
  static const Color textSuccess = Color(0xFF388E3C);   // 成功文字颜色（绿）
  static const Color textError = Color(0xFFD32F2F);     // 错误文字颜色（红）
  static const Color textWarning = Color(0xFFF57C00);   // 警告文字颜色（橙）
  static const Color textInfo = Color(0xFF1976D2);      // 信息文字颜色（蓝）
  static const Color textDisabled = Color(0xFFBDBDBD);  // 禁用文字颜色（灰）
  
  // Common Colors (常用颜色)
  static const Color textWhite = Color(0xFFFFFFFF);     // 白色文字
  static const Color textWhite70 = Color(0xB3FFFFFF);  // 70%透明度白色
  static const Color textWhite54 = Color(0x8AFFFFFF);  // 54%透明度白色
  static const Color textGrey600 = Color(0xFF757575);  // 灰色600
  static const Color textGrey500 = Color(0xFF9E9E9E); // 灰色500
  static const Color textBlack87 = Color(0xDE000000);  // 87%透明度黑色
  
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
  
  // Text Shadows（文字阴影）
  static const List<Shadow> textShadowNone = [];
  
  static const List<Shadow> textShadowSubtle = [
    Shadow(
      color: Color(0x40000000), // black.withOpacity(0.25)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  
  static const List<Shadow> textShadowMedium = [
    Shadow(
      color: Color(0x80000000), // black.withOpacity(0.5)
      offset: Offset(1, 1),
      blurRadius: 3,
    ),
  ];
  
  static const List<Shadow> textShadowStrong = [
    Shadow(
      color: Color(0x80000000), // black.withOpacity(0.5)
      offset: Offset(2, 2),
      blurRadius: 4,
    ),
  ];
  
  static const List<Shadow> textShadowGlow = [
    Shadow(
      color: Color(0xCCFFFFFF), // white.withOpacity(0.8)
      offset: Offset(0, 0),
      blurRadius: 2,
    ),
  ];
  
  static const List<Shadow> textShadowTitle = [
    Shadow(
      color: Color(0xCCFFFFFF), // white.withOpacity(0.8)
      offset: Offset(0, 0),
      blurRadius: 2,
    ),
    Shadow(
      color: Color(0x80000000), // black.withOpacity(0.5)
      offset: Offset(1, 1),
      blurRadius: 4,
    ),
  ];
  
  // Typography - 统一使用 NotoSansJP 无衬线字体
  static const String fontFamilyHeadline = 'NotoSansJP';  // 标题字体（统一使用无衬线）
  static const String fontFamilyBody = 'NotoSansJP';      // 正文字体
  
  // Font Weights (字体粗细)
  static const FontWeight fontWeightLight = FontWeight.w300;    // 细体
  static const FontWeight fontWeightRegular = FontWeight.w400;  // 常规
  static const FontWeight fontWeightMedium = FontWeight.w500;   // 中等
  static const FontWeight fontWeightSemiBold = FontWeight.w600; // 半粗
  static const FontWeight fontWeightBold = FontWeight.w700;     // 粗体
  static const FontWeight fontWeightExtraBold = FontWeight.w800; // 超粗
  static const FontWeight fontWeightBlack = FontWeight.w900;    // 最粗（黑体）
  
  // Font Sizes (完整的字体尺寸系统)
  static const double fontSizeHeadlineLarge = 32.0;   // 大标题
  static const double fontSizeHeadlineMedium = 24.0;  // 中标题
  static const double fontSizeTitleLarge = 20.0;      // 大标题文字
  static const double fontSizeTitleMedium = 18.0;     // 中标题文字（新增）
  static const double fontSizeBodyLarge = 16.0;       // 大正文
  static const double fontSizeBodyMedium = 14.0;      // 中正文
  static const double fontSizeBodySmall = 12.0;       // 小正文
  static const double fontSizeCaption = 10.0;         // 说明文字（新增）
  
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