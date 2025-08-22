import 'package:flutter/material.dart';
import '../../themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

class AppTheme {
  // 使用统一的设计令牌
  // Colors - 从 DesignTokens 引用
  static Color get primaryColor => DesignTokens.primaryColor;
  static Color get secondaryColor => DesignTokens.primaryColor; // 兼容旧用法
  static Color get accentColor => DesignTokens.primaryColor;    // 兼容旧用法
  static Color get errorColor => const Color(0xFFFF6B6B);       // 兼容旧用法
  static Color get backgroundColor => DesignTokens.backgroundColor;
  static Color get surfaceColor => DesignTokens.surfaceColor;
  static Color get textPrimary => DesignTokens.textPrimary;
  static Color get textSecondary => DesignTokens.textSecondary;
  static Color get textTertiary => DesignTokens.textTertiary;
  static Color get borderColor => DesignTokens.borderColor;
  
  // Typography - 使用更新的字体尺寸
  static String get fontFamilyHeadline => DesignTokens.fontFamilyHeadline;
  static String get fontFamilyBody => DesignTokens.fontFamilyBody;
  static double get fontSizeHeadlineLarge => DesignTokens.fontSizeHeadlineLarge;  // 32.0
  static double get fontSizeHeadlineMedium => DesignTokens.fontSizeHeadlineMedium; // 24.0 (更新)
  static double get fontSizeTitleLarge => DesignTokens.fontSizeTitleLarge;        // 20.0 (新增)
  static double get fontSizeBodyLarge => DesignTokens.fontSizeBodyLarge;          // 16.0
  static double get fontSizeBodyMedium => DesignTokens.fontSizeBodyMedium;        // 14.0
  static double get fontSizeBodySmall => DesignTokens.fontSizeBodySmall;          // 12.0
  
  // Spacing - 使用统一的设计令牌
  static double get spacingXs => DesignTokens.spacingXs;    // 4.0
  static double get spacingSm => DesignTokens.spacingSm;    // 8.0
  static double get spacingMd => DesignTokens.spacingMd;    // 16.0
  static double get spacingLg => DesignTokens.spacingLg;    // 24.0
  static double get spacingXl => DesignTokens.spacingXl;    // 32.0
  static double get spacingXxl => DesignTokens.spacingXxl;  // 48.0
  
  // Border Radius - 使用统一的设计令牌
  static double get radiusXs => DesignTokens.radiusXs;      // 4.0
  static double get radiusSm => DesignTokens.radiusSm;      // 8.0
  static double get radiusMd => DesignTokens.radiusMd;      // 16.0
  static double get radiusLg => DesignTokens.radiusLg;      // 24.0
  
  // Shadows - 使用统一的设计令牌
  static List<BoxShadow> get shadowCard => DesignTokens.shadowCard;
  // 兼容旧命名
  static List<BoxShadow> get cardShadow => shadowCard;
  static double get spacingS => spacingSm;
  static double get spacingM => spacingMd;
  static double get spacingL => spacingLg;
  static double get radiusS => radiusSm;
  static double get radiusM => radiusMd;
  static double get fontSizeSmall => fontSizeBodySmall;
  static double get fontSizeMedium => fontSizeBodyLarge;
  
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamilyBody,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: fontSizeHeadlineLarge,
          fontWeight: DynamicTokens.fontWeightBold,
          fontFamily: fontFamilyHeadline,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeHeadlineMedium,
          fontWeight: DynamicTokens.fontWeightSemiBold,
          fontFamily: fontFamilyHeadline,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeTitleLarge,
          fontWeight: DynamicTokens.fontWeightSemiBold,
          fontFamily: fontFamilyHeadline,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBodyLarge,
          fontFamily: fontFamilyBody,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBodyMedium,
          fontFamily: fontFamilyBody,
          color: textSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamilyBody,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
        shadowColor: Colors.black26,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: fontSizeHeadlineLarge,
          fontWeight: DynamicTokens.fontWeightBold,
          fontFamily: fontFamilyHeadline,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeHeadlineMedium,
          fontWeight: DynamicTokens.fontWeightSemiBold,
          fontFamily: fontFamilyHeadline,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeTitleLarge,
          fontWeight: DynamicTokens.fontWeightSemiBold,
          fontFamily: fontFamilyHeadline,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBodyLarge,
          fontFamily: fontFamilyBody,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBodyMedium,
          fontFamily: fontFamilyBody,
          color: textSecondary,
        ),
      ),
    );
  }
} 