import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/providers/theme_provider.dart';

// 动态设计令牌类
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
  
  // 固定颜色（不随主题变化）
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // 向后兼容的静态文字颜色（用于不能访问动态主题的地方）
  static const Color textPrimaryStatic = Color(0xFF4A4A4A);
  static const Color textSecondaryStatic = Color(0xFF7A7A7A);
  
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
  
  static const String fontFamilyHeadline = 'NotoSerifJP';
  static const String fontFamilyBody = 'NotoSansJP';
  
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