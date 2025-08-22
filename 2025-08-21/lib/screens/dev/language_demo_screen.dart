import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/widgets/language_switcher.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

/// 语言演示页面 - 用于测试多语言功能
class LanguageDemoScreen extends ConsumerWidget {
  const LanguageDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final currentLanguage = ref.watch(localizationServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(appStringsProvider).labelLanguageDemo),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DynamicTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前语言信息
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DynamicTokens.spacingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.watch(appStringsProvider).labelCurrentLanguage,
                    style: TextStyle(
                      fontSize: DynamicTokens.fontSizeBodySmall,
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentLanguage.displayName} (${currentLanguage.languageCode}-${currentLanguage.countryCode})',
                    style: TextStyle(
                      fontSize: DynamicTokens.fontSizeTitleMedium,
                      fontWeight: DynamicTokens.fontWeightBold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: DynamicTokens.spacingLg),
            
            // 语言切换器
            const LanguageSwitcher(),
            
            const SizedBox(height: DynamicTokens.spacingLg),
            
            // 文本演示区域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DynamicTokens.spacingMd),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.watch(appStringsProvider).labelTextDemo,
                    style: TextStyle(
                      fontSize: DynamicTokens.fontSizeTitleMedium,
                      fontWeight: DynamicTokens.fontWeightBold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  
                  const SizedBox(height: DynamicTokens.spacingMd),
                  
                  // 应用标题
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelAppName,
                    strings.createMainTitle(strings.appName),
                  ),
                  
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelAppSubtitle,
                    strings.createCaptionText(strings.appSubtitle),
                  ),
                  
                  // 首页相关
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelDailyCardTitle,
                    strings.createSubTitle(strings.homeDailyCard),
                  ),
                  
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelTarotCalendar,
                    strings.createSubTitle(strings.homeTarotCalendar),
                  ),
                  
                  // 按钮文字
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelButtonExamples,
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: strings.createButtonText(strings.buttonComplete),
                        ),
                        const SizedBox(width: DynamicTokens.spacingSm),
                        OutlinedButton(
                          onPressed: () {},
                          child: strings.createButtonText(strings.buttonCancel),
                        ),
                      ],
                    ),
                  ),
                  
                  // 状态消息
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelLoadingMessages,
                    strings.createCaptionText(strings.messageLoading),
                  ),
                  
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelErrorMessages,
                    strings.createErrorText(strings.messageError),
                  ),
                  
                  // 设置相关
                  _buildDemoItem(
                    ref.watch(appStringsProvider).labelSettingsOptions,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        strings.createSmallTitle(strings.settingsDeckSelection),
                        const SizedBox(height: 4),
                        strings.createBodyText(strings.settingsSelectDeck),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: DynamicTokens.spacingLg),
            
            // 紧凑版语言切换器演示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DynamicTokens.spacingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.watch(appStringsProvider).labelCompactLanguageSwitcher,
                    style: TextStyle(
                      fontSize: DynamicTokens.fontSizeBodyMedium,
                      fontWeight: DynamicTokens.fontWeightSemiBold,
                    ),
                  ),
                  const SizedBox(height: DynamicTokens.spacingSm),
                  const LanguageSwitcher(
                    isCompact: true,
                    showLabel: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDemoItem(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DynamicTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: DynamicTokens.fontSizeBodySmall,
              color: Colors.grey[600],
              fontWeight: DynamicTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(height: 4),
          content,
        ],
      ),
    );
  }
}
