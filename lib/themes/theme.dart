import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignTokens.primaryColor,
        brightness: Brightness.light,
        primary: DesignTokens.primaryColor,
        background: DesignTokens.backgroundColor,
        surface: DesignTokens.surfaceColor,
        onPrimary: Colors.white,
        onBackground: DesignTokens.textPrimary,
        onSurface: DesignTokens.textPrimary,
        onSurfaceVariant: DesignTokens.textSecondary,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: DesignTokens.fontFamilyHeadline,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: DesignTokens.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: DesignTokens.fontFamilyHeadline,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: DesignTokens.fontFamilyHeadline,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: DesignTokens.fontFamilyBody,
          fontSize: 16,
          color: DesignTokens.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: DesignTokens.fontFamilyBody,
          fontSize: 14,
          color: DesignTokens.textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: DesignTokens.fontFamilyBody,
          fontSize: 12,
          color: DesignTokens.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        shadowColor: Colors.transparent,
        color: DesignTokens.surfaceColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: DesignTokens.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          textStyle: TextStyle(
            fontFamily: DesignTokens.fontFamilyBody,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(DesignTokens.spacingMd),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: null, // 让系统状态栏自适应
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DesignTokens.surfaceColor,
        selectedItemColor: DesignTokens.primaryColor,
        unselectedItemColor: DesignTokens.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
} 