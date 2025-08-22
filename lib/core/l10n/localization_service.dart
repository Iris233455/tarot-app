import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings_base.dart';
import 'app_strings_ja.dart';
import 'app_strings_en.dart';
import 'app_strings_zh.dart';
import 'app_strings_zh_tw.dart';
import 'app_strings_fallback.dart';

/// 支持的语言枚举
enum SupportedLanguage {
  japanese('ja', 'JP', '日本語'),
  english('en', 'US', 'English'),
  chineseSimplified('zh', 'CN', '简体中文'),
  chineseTraditional('zh', 'TW', '繁體中文');

  const SupportedLanguage(this.languageCode, this.countryCode, this.displayName);
  
  final String languageCode;
  final String countryCode;
  final String displayName;
  
  Locale get locale => Locale(languageCode, countryCode);
}

/// 本地化服务 - 管理语言切换和文本获取
class LocalizationService extends StateNotifier<SupportedLanguage> {
  static const String _languageKey = 'selected_language';
  
  LocalizationService() : super(SupportedLanguage.japanese) {
    _loadSavedLanguage();
  }
  
  /// 获取当前语言的文本实例
  AppStringsBase get strings {
    final ja = AppStringsJa();
    switch (state) {
      case SupportedLanguage.japanese:
        return ja;
      case SupportedLanguage.english:
        return FallbackStrings(primary: AppStringsEn(), fallback: ja);
      case SupportedLanguage.chineseSimplified:
        return FallbackStrings(primary: AppStringsZhCN(), fallback: ja);
      case SupportedLanguage.chineseTraditional:
        return FallbackStrings(primary: AppStringsZhTW(), fallback: ja);
    }
  }
  
  /// 切换语言
  Future<void> changeLanguage(SupportedLanguage language) async {
    state = language;
    await _saveLanguage(language);
  }
  
  /// 从本地存储加载保存的语言设置
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      
      if (savedLanguageCode != null) {
        final language = SupportedLanguage.values.firstWhere(
          (lang) => lang.languageCode == savedLanguageCode,
          orElse: () => SupportedLanguage.japanese,
        );
        state = language;
      }
    } catch (e) {
      // ignore
    }
  }
  
  /// 保存语言设置到本地存储
  Future<void> _saveLanguage(SupportedLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.languageCode);
    } catch (e) {
      // ignore
    }
  }
  
  /// 根据系统语言自动选择合适的语言
  void setLanguageFromSystem(Locale systemLocale) {
    final language = SupportedLanguage.values.firstWhere(
      (lang) => lang.languageCode == systemLocale.languageCode,
      orElse: () => SupportedLanguage.japanese, // 默认日文
    );
    changeLanguage(language);
  }
}

/// 本地化服务 Provider
final localizationServiceProvider = StateNotifierProvider<LocalizationService, SupportedLanguage>((ref) {
  return LocalizationService();
});

/// 当前文本实例 Provider
final currentStringsProvider = Provider<AppStringsBase>((ref) {
  // 关键：监听语言状态，确保切换语言时触发重建
  final _ = ref.watch(localizationServiceProvider);
  final svc = ref.read(localizationServiceProvider.notifier);
  return svc.strings;
});

/// 便捷的文本获取 Provider (用于替代原来的 AppStrings)
final appStringsProvider = Provider<AppStringsBase>((ref) {
  // 同样监听语言状态
  final _ = ref.watch(localizationServiceProvider);
  final svc = ref.read(localizationServiceProvider.notifier);
  return svc.strings;
});


