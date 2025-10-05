import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/core/theme/app_theme.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/widgets/tarot_card_widget.dart';
import 'package:mystic_tarot_jp/core/theme/dynamic_tokens.dart';

class CardDetailScreen extends ConsumerWidget {
  final String cardId;
  
  const CardDetailScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(cardDetailsProvider(cardId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('カード詳細'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: cardAsync.when(
            data: (card) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 卡片图像
                  Center(
                    child: Container(
                      width: 200,
                      height: 350,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        // no box shadows
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        child: Image.asset(
                          card.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.surfaceColor,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: DynamicTokens.textWhite54,
                                size: 64,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // 卡片名称
                  Text(
                    card.nameJa,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    card.nameEn,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: DynamicTokens.textWhite70,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 故事
                  _buildStorySection(context, card.story),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 基本含义
                  _buildMeaningSection(
                    context,
                    '正位置',
                    card.meaningUpright,
                    card.uprightKeywordsList,
                    Icons.keyboard_arrow_up,
                    AppTheme.primaryColor,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 逆位含义
                  _buildMeaningSection(
                    context,
                    '逆位置',
                    card.meaningReversed,
                    card.reversedKeywordsList,
                    Icons.keyboard_arrow_down,
                    AppTheme.errorColor,
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // 各种主题解读
                  _buildThemeSection(context, '恋愛', card.themeLoveUpright, card.themeLoveReversed),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  _buildThemeSection(context, '仕事・キャリア', card.themeCareerUpright, card.themeCareerReversed),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  _buildThemeSection(context, '金運', card.themeMoneyUpright, card.themeMoneyReversed),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  _buildThemeSection(context, '人間関係', card.themeInterpersonalUpright, card.themeInterpersonalReversed),
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // 時間軸別メッセージ
                  _buildMessageSection(context, '過去・現在・未来', 
                    card.messagePastPresentFutureUpright, 
                    card.messagePastPresentFutureReversed),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  _buildMessageSection(context, '感情・意識', 
                    card.messageEmotionConsciousnessUpright, 
                    card.messageEmotionConsciousnessReversed),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  _buildMessageSection(context, '原因・解決策', 
                    card.messageCauseSolutionUpright, 
                    card.messageCauseSolutionReversed),
                ],
              ),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 64,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  ElevatedButton(
                    onPressed: () => ref.refresh(cardDetailsProvider(cardId)),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _parseKeywords(String keywordsString) {
    if (keywordsString.isEmpty) return [];
    
    // 去掉方括号和引号，然后分割
    String cleaned = keywordsString
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .replaceAll('【', '')
        .replaceAll('】', '');
    
    // 分割并清理每个关键词
    return cleaned
        .split(',')
        .map((keyword) => keyword.trim())
        .where((keyword) => keyword.isNotEmpty)
        .toList();
  }

  // 解析文本的第一行和剩余内容
  Map<String, String> _parseTextContent(String text) {
    if (text.isEmpty) return {'title': '', 'content': ''};
    
    final lines = text.split('\n');
    if (lines.isEmpty) return {'title': '', 'content': ''};
    
    final firstLine = lines.first.trim();
    final remainingLines = lines.length > 1 ? lines.skip(1).join('\n').trim() : '';
    
    return {
      'title': firstLine,
      'content': remainingLines,
    };
  }

  Widget _buildStorySection(BuildContext context, String story) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: DynamicTokens.textBlack87.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_stories,
                color: AppTheme.accentColor.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                '物語り',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor.withOpacity(0.7),
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Builder(
            builder: (context) {
              final parsed = _parseTextContent(story);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parsed['title']!.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        parsed['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: DynamicTokens.textWhite,
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
                    ),
                    if (parsed['content']!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        parsed['content']!,
                        style: const TextStyle(
                          color: DynamicTokens.textWhite,
                          fontSize: AppTheme.fontSizeMedium,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      story,
                      style: const TextStyle(
                        color: DynamicTokens.textWhite,
                        fontSize: AppTheme.fontSizeMedium,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningSection(BuildContext context, String title, String meaning, List<String> keywords, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: DynamicTokens.textBlack87.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Builder(
            builder: (context) {
              final parsed = _parseTextContent(meaning);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parsed['title']!.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        parsed['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: DynamicTokens.textWhite,
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (parsed['content']!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        parsed['content']!,
                        style: const TextStyle(
                          color: DynamicTokens.textWhite,
                          fontSize: AppTheme.fontSizeMedium,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      meaning,
                      style: const TextStyle(
                        color: DynamicTokens.textWhite,
                        fontSize: AppTheme.fontSizeMedium,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Keywords标签
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 移除キーワード标题，直接显示标签
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: keywords.map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        keyword,
                        style: TextStyle(
                          color: color,
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, String theme, String uprightMeaning, String reversedMeaning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: DynamicTokens.textBlack87.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            theme,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // 正位
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      '正位',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  uprightMeaning,
                  style: const TextStyle(
                    color: DynamicTokens.textWhite,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          // 逆位
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(
                color: AppTheme.errorColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      '逆位',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  reversedMeaning,
                  style: const TextStyle(
                    color: DynamicTokens.textWhite,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection(BuildContext context, String title, String uprightMessage, String reversedMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: DynamicTokens.textBlack87.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // 正位メッセージ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正位',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  uprightMessage,
                  style: const TextStyle(
                    color: DynamicTokens.textWhite,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          // 逆位メッセージ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '逆位',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  reversedMessage,
                  style: const TextStyle(
                    color: DynamicTokens.textWhite,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(content),
        const SizedBox(height: 16),
      ],
    );
  }
} 