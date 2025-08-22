import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

/// 语言切换器组件
class LanguageSwitcher extends ConsumerWidget {
  final bool showLabel;
  final bool isCompact;
  
  const LanguageSwitcher({
    Key? key,
    this.showLabel = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(localizationServiceProvider);
    final strings = ref.watch(appStringsProvider);
    
    if (isCompact) {
      return _buildCompactSwitcher(context, ref, currentLanguage, strings);
    } else {
      return _buildFullSwitcher(context, ref, currentLanguage, strings);
    }
  }
  
  /// 完整版语言切换器
  Widget _buildFullSwitcher(
    BuildContext context, 
    WidgetRef ref, 
    SupportedLanguage currentLanguage,
    AppStringsBase strings,
  ) {
    return Container(
      padding: const EdgeInsets.all(DynamicTokens.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              ref.watch(appStringsProvider).labelLanguage,
              style: TextStyle(
                fontSize: DynamicTokens.fontSizeBodyMedium,
                fontWeight: DynamicTokens.fontWeightSemiBold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DynamicTokens.spacingSm),
          ],
          
          // 语言选项列表
          ...SupportedLanguage.values.map((language) {
            final isSelected = language == currentLanguage;
            
            return InkWell(
              onTap: () => _changeLanguage(context, ref, language),
              borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: DynamicTokens.spacingMd,
                  vertical: DynamicTokens.spacingSm,
                ),
                margin: const EdgeInsets.only(bottom: DynamicTokens.spacingXs),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
                  border: isSelected 
                    ? Border.all(color: Theme.of(context).colorScheme.primary)
                    : null,
                ),
                child: Row(
                  children: [
                    // 语言标识
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getLanguageColor(language),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          _getLanguageFlag(language),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: DynamicTokens.spacingSm),
                    
                    // 语言名称
                    Expanded(
                      child: Text(
                        language.displayName,
                        style: TextStyle(
                          fontSize: DynamicTokens.fontSizeBodyMedium,
                          fontWeight: isSelected 
                            ? DynamicTokens.fontWeightSemiBold 
                            : DynamicTokens.fontWeightRegular,
                          color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    
                    // 选中标识
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  /// 紧凑版语言切换器（下拉菜单）
  Widget _buildCompactSwitcher(
    BuildContext context, 
    WidgetRef ref, 
    SupportedLanguage currentLanguage,
    AppStringsBase strings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DynamicTokens.spacingSm),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
      ),
      child: DropdownButton<SupportedLanguage>(
        value: currentLanguage,
        underline: const SizedBox(),
        icon: const Icon(Icons.language, size: 20),
        items: SupportedLanguage.values.map((language) {
          return DropdownMenuItem(
            value: language,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getLanguageFlag(language),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  language.displayName,
                  style: TextStyle(
                    fontSize: DynamicTokens.fontSizeBodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (language) {
          if (language != null) {
            _changeLanguage(context, ref, language);
          }
        },
      ),
    );
  }
  
  /// 切换语言
  void _changeLanguage(BuildContext context, WidgetRef ref, SupportedLanguage language) {
    ref.read(localizationServiceProvider.notifier).changeLanguage(language);
    
    // 显示切换成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ref.watch(appStringsProvider).messageLanguageSwitched} ${language.displayName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// 获取语言对应的旗帜 Emoji
  String _getLanguageFlag(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.japanese:
        return '🇯🇵';
      case SupportedLanguage.english:
        return '🇺🇸';
      case SupportedLanguage.chineseSimplified:
        return '🇨🇳';
      case SupportedLanguage.chineseTraditional:
        return '🇹🇼';
    }
  }
  
  /// 获取语言对应的主题色
  Color _getLanguageColor(SupportedLanguage language) {
    switch (language) {
      case SupportedLanguage.japanese:
        return Colors.red.withOpacity(0.1);
      case SupportedLanguage.english:
        return Colors.blue.withOpacity(0.1);
      case SupportedLanguage.chineseSimplified:
        return Colors.red.withOpacity(0.1);
      case SupportedLanguage.chineseTraditional:
        return Colors.orange.withOpacity(0.1);
    }
  }
}