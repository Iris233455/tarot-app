import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 主题数据类
class AppThemeData {
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final String? backgroundImage; // 背景纹理图片
  final bool isDark; // 是否为暗色主题
  final Color textPrimary; // 主要文字颜色
  final Color textSecondary; // 次要文字颜色

  const AppThemeData({
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    this.backgroundImage,
    this.isDark = false,
    this.textPrimary = const Color(0xFF4A4A4A),
    this.textSecondary = const Color(0xFF7A7A7A),
  });
}

// 预定义的主题
class AppThemes {
  static const Map<String, AppThemeData> themes = {

    // --- 新テーマ: 大海（オーシャン） ---
    'オーシャン': AppThemeData(
      name: 'オーシャン',
      primaryColor: Color(0xFF2B6CB0), // 海の藍
      backgroundColor: Color(0xFFF5FAFF), // きわめて淡い水色
      surfaceColor: Color(0xFFEAF3FF), // 柔らかいパネル色
    ),

    // --- 新テーマ: 森林（フォレスト）- 暗色系 ---
    'フォレスト': AppThemeData(
      name: 'フォレスト',
      primaryColor: Color(0xFF22C55E), // 更柔和的森林绿（较深）
      backgroundColor: Color(0xFF0F1419), // 深い森の背景
      surfaceColor: Color(0xFF1A2332), // 暗いパネル色
      backgroundImage: 'assets/images/tarot_forest_bg_warm_1080x1920.png',
      isDark: true,
      textPrimary: Color(0xFFE5E7EB), // 明るいグレー
      textSecondary: Color(0xFFD1D5DB), // 中程度のグレー
    ),

    // --- 新テーマ: 星空（ナイトスカイ） ---
    'ナイトスカイ': AppThemeData(
      name: 'ナイトスカイ',
      primaryColor: Color(0xFF1F2A44), // 夜空の紺
      backgroundColor: Color(0xFFF7F8FC),
      surfaceColor: Color(0xFFEDF0FA),
    ),

    // --- 新テーマ: 月光（ムーンライト/アメジスト） ---
    'ムーンライト': AppThemeData(
      name: 'ムーンライト',
      primaryColor: Color(0xFF6B5BAE), // アメジスト
      backgroundColor: Color(0xFFFBFAFF),
      surfaceColor: Color(0xFFF1EEFB),
    ),

    // --- 追加: クラウド（雲） ---
    'クラウド': AppThemeData(
      name: 'クラウド',
      primaryColor: Color(0xFF9BB9D4), // 淡い雲の青
      backgroundColor: Color(0xFFFAFCFF),
      surfaceColor: Color(0xFFF5F8FF),
      backgroundImage: 'assets/images/tarot_cloud_bg.png',
      isDark: false, // 明亮主题但有背景图
      textPrimary: Color(0xFF2D3748), // 深色文字确保在彩色背景上可读
      textSecondary: Color(0xFF4A5568), // 深色副文字
    ),

    // --- 追加: クリアスカイ（晴空） ---
    'クリアスカイ': AppThemeData(
      name: 'クリアスカイ',
      primaryColor: Color(0xFF5DB0FF), // 明るい空色
      backgroundColor: Color(0xFFF3F9FF),
      surfaceColor: Color(0xFFEAF4FF),
      backgroundImage: 'assets/images/tarot_kawaii_candy_1080x1920.png',
      isDark: false, // 明亮主题但有背景图
      textPrimary: Color(0xFF2D3748), // 深色文字确保在彩色背景上可读
      textSecondary: Color(0xFF4A5568), // 深色副文字
    ),
  };
}

// 主题状态管理器
class ThemeNotifier extends StateNotifier<AppThemeData> {
  ThemeNotifier() : super(AppThemes.themes['ムーンライト']!);

  void setTheme(String themeName) {
    if (AppThemes.themes.containsKey(themeName)) {
      state = AppThemes.themes[themeName]!;
    }
  }

  String get currentThemeName => state.name;
}

// Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeData>((ref) {
  return ThemeNotifier();
});

// 当前主题名称的快捷访问器
final currentThemeNameProvider = Provider<String>((ref) {
  return ref.watch(themeProvider).name;
}); 