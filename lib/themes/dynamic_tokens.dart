import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/providers/theme_provider.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';

// 动态设计令牌类（增强版，支持完整设计系统）
class DynamicTokens {
  final AppThemeData theme;

  DynamicTokens(this.theme);

  // 动态颜色
  Color get primaryColor => theme.primaryColor;
  Color get backgroundColor => theme.backgroundColor;
  Color get surfaceColor => theme.surfaceColor;
  String? get backgroundImage => theme.backgroundImage;
  bool get isDark => theme.isDark;
  
  // 动态文字颜色（根据主题变化）
  Color get textPrimary => theme.textPrimary;
  Color get textSecondary => theme.textSecondary;
  
  // 扩展的文本颜色层次（基于新的设计令牌）
  Color get textTertiary => const Color(0xFF9E9E9E);
  Color get textInverse => const Color(0xFFFFFFFF);
  
  // 固定颜色（不随主题变化）
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // 向后兼容的静态文字颜色（用于不能访问动态主题的地方）
  static const Color textPrimaryStatic = Color(0xFF1A1A1A);
  static const Color textSecondaryStatic = Color(0xFF4A4A4A);
  static const Color textTertiaryStatic = Color(0xFF9E9E9E);
  
  // 常用文字颜色（静态）
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhite70 = Color(0xB3FFFFFF);
  static const Color textWhite54 = Color(0x8AFFFFFF);
  static const Color textGrey600 = Color(0xFF757575);
  static const Color textGrey500 = Color(0xFF9E9E9E);
  static const Color textBlack87 = Color(0xDE000000);
  
  // 语义化文字颜色（静态版本）
  static const Color textSuccess = Color(0xFF388E3C);
  static const Color textError = Color(0xFFD32F2F);
  static const Color textWarning = Color(0xFFF57C00);
  static const Color textInfo = Color(0xFF1976D2);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  // 动态派生颜色
  Color get primaryColorLight => primaryColor.withOpacity(0.1);
  Color get primaryColorMedium => primaryColor.withOpacity(0.3);
  
  // 静态令牌（不变的设计值）
  static const double radiusLg = 24.0;
  static const double radiusMd = 16.0;
  static const double radiusSm = 8.0;
  static const double radiusXs = 4.0;
  
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  
  // Text Shadows（文字阴影）- 引用 DesignTokens 中的定义
  // 可选：如果 DesignTokens 未提供这些定义，可注释或自定义
  // static List<Shadow> get textShadowNone => DesignTokens.textShadowNone;
  // static List<Shadow> get textShadowSubtle => DesignTokens.textShadowSubtle;
  // static List<Shadow> get textShadowMedium => DesignTokens.textShadowMedium;
  // static List<Shadow> get textShadowStrong => DesignTokens.textShadowStrong;
  // static List<Shadow> get textShadowGlow => DesignTokens.textShadowGlow;
  // static List<Shadow> get textShadowTitle => DesignTokens.textShadowTitle;
  
  static const String fontFamilyHeadline = 'NotoSansJP';
  static const String fontFamilyBody = 'NotoSansJP';
  
  // Font Weights - 引用 DesignTokens
  // 若项目未定义，可用系统字体权重代替
  static FontWeight get fontWeightLight => FontWeight.w300;
  static FontWeight get fontWeightRegular => FontWeight.w400;
  static FontWeight get fontWeightMedium => FontWeight.w500;
  static FontWeight get fontWeightSemiBold => FontWeight.w600;
  static FontWeight get fontWeightBold => FontWeight.w700;
  static FontWeight get fontWeightExtraBold => FontWeight.w800;
  static FontWeight get fontWeightBlack => FontWeight.w900;
  
  // Font Sizes - 引用 DesignTokens
  static double get fontSizeHeadlineLarge => 32.0;
  static double get fontSizeHeadlineMedium => 24.0;
  static double get fontSizeTitleLarge => 20.0;
  static double get fontSizeTitleMedium => 18.0;
  static double get fontSizeBodyLarge => 16.0;
  static double get fontSizeBodyMedium => 14.0;
  static double get fontSizeBodySmall => 12.0;
  static double get fontSizeCaption => 10.0;
  
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeOutCubic;
  
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
}

// Provider for dynamic tokens
final dynamicTokensProvider = Provider<DynamicTokens>((ref) {
  final theme = ref.watch(themeProvider);
  return DynamicTokens(theme);
});