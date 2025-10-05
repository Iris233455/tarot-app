import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mystic_tarot_jp/core/ui/animations.dart';
import 'package:mystic_tarot_jp/providers/ai_reading_provider.dart';
import 'package:mystic_tarot_jp/providers/ad_reward_provider.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';

/// AI解読結果表示ウィジェット
class AIReadingWidget extends ConsumerWidget {
  final String readingType;
  final bool compact;
  
  const AIReadingWidget({
    super.key,
    required this.readingType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiReading = ref.watch(aiReadingProvider(readingType));
    final dynamicTokens = ref.watch(dynamicTokensProvider);

    final content = _buildContent(context, ref, aiReading, dynamicTokens);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: content,
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  AppIcons.autoAwesome,
                  color: dynamicTokens.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI タロット解読',
                  style: TextStyle(
                    fontSize: DynamicTokens.fontSizeTitleLarge,
                    fontWeight: FontWeight.w600,
                    color: DynamicTokens.textBlack87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AIReadingData aiReading, DynamicTokens dynamicTokens) {
    switch (aiReading.state) {
      case AIReadingState.idle:
        return _buildIdleState(context, dynamicTokens);
      case AIReadingState.loading:
        return _buildLoadingState(context, dynamicTokens);
      case AIReadingState.completed:
        return _buildCompletedState(context, ref, aiReading.result, dynamicTokens);
      case AIReadingState.error:
        return _buildErrorState(context, aiReading.error ?? '不明なエラー');
    }
  }

  Widget _buildIdleState(BuildContext context, DynamicTokens dynamicTokens) {
    if (compact) {
      return _buildLoadingState(context, dynamicTokens);
    }
    return FadeIn(
      child: Column(
        children: [
          Icon(
            AppIcons.autoAwesome,
            size: 48,
            color: dynamicTokens.primaryColor.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'ここにAI診断の結果が表示されます',
            style: TextStyle(
              fontSize: DynamicTokens.fontSizeBodyMedium,
              color: DynamicTokens.textBlack87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, DynamicTokens dynamicTokens) {
    return FadeIn(
      child: Column(
        children: [
          SpinPerfect(
            infinite: true,
            duration: const Duration(seconds: 1),
            child: Icon(
              AppIcons.autoAwesome,
              size: 48,
              color: dynamicTokens.primaryColor.withOpacity(0.5),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              'AI診断を生成中...',
              style: TextStyle(
                fontSize: DynamicTokens.fontSizeBodyLarge,
                fontWeight: FontWeight.w500,
                color: DynamicTokens.textBlack87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, WidgetRef ref, String result, DynamicTokens dynamicTokens) {
    final content = _buildFormattedResult(context, result, dynamicTokens);
    if (compact) {
      return wrapAiTextAnimation(child: content, ref: ref);
    }
    return wrapAiTextAnimation(
      ref: ref,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dynamicTokens.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dynamicTokens.primaryColor.withOpacity(0.15)),
        ),
        child: content,
      ),
    );
  }

  // 仅用于解析 AI 文本中可能包含的 emoji 作为分段标题标识（不直接展示图标）
  static const _headerEmojis = [
    '📖', '🌟', '💖',
    '🃏', '💡', '🌙',
    '🅰️', '🅱️', '⚖️', '💭',
    '⏳', '🕰️', '🔮',
  ];

  // 过滤正文中的 emoji（用户可见区域不显示 emoji）
  static String _stripEmojis(String input) {
    final emojiRegex = RegExp(
      r"[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}"
      r"\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{FE0F}\u{200D}]",
      unicode: true,
    );
    return input.replaceAll(emojiRegex, '');
  }

  Widget _buildFormattedResult(BuildContext context, String text, DynamicTokens dynamicTokens) {
    // 使用 Design Tokens 渲染文本
    final accent = dynamicTokens.primaryColor;
    final lines = text.split('\n');

    // 1) 分段：以Emoji标题作为分隔
    final List<_AISection> sections = [];
    _AISection? current;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final isHeader = _headerEmojis.any((e) => line.startsWith(e));
      if (isHeader) {
        String headerTitle = line;
        for (final e in _headerEmojis) {
          if (headerTitle.startsWith(e)) {
            headerTitle = headerTitle.substring(e.length).trimLeft();
            break;
          }
        }
        current = _AISection(header: _stripEmojis(headerTitle), body: []);
        sections.add(current);
      } else {
        current ??= _AISection(header: '', body: []);
        // 正文允许包含 emoji，不做过滤
        current.body.add(line);
      }
    }

    // 2) 渲染：标题加粗加大、左边彩色边线；首段作为lead半粗
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in sections) ...[
          if (s.header.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                s.header,
                style: TextStyle(
                  fontSize: DynamicTokens.fontSizeTitleMedium,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: DynamicTokens.textBlack87,
                ),
              ),
            ),
          if (s.body.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < s.body.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _buildBodyLine(context, dynamicTokens, s.body[i], isLead: i == 0),
                  ),
                const SizedBox(height: 8),
              ],
            ),
        ]
      ],
    );
  }

  Widget _buildBodyLine(BuildContext context, DynamicTokens dynamicTokens, String line, {bool isLead = false}) {
    // 列表行：以「・」「-」「—」开头
    final String trimmed = line.trimLeft();
    final bool isBullet = trimmed.startsWith('・') || trimmed.startsWith('-') || trimmed.startsWith('—');
    final String content = isBullet ? trimmed.substring(1).trimLeft() : line;
    // 统一为全局正文样式（bodyMedium: 14/w400）
    final TextStyle style = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6) ?? const TextStyle(fontSize: 14, height: 1.6);
    if (!isBullet) return Text(content, style: style);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6) ?? const TextStyle(fontSize: 14, height: 1.6)),
        Expanded(child: Text(content, style: style)),
      ],
    );
  }

  // 简单段落模型（见文件末尾顶层定义）

  Widget _buildErrorState(BuildContext context, String error) {
    return FadeIn(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: DynamicTokens.textError,
          ),
          const SizedBox(height: 12),
          Text(
            'AI解読の取得に失敗しました',
            style: TextStyle(
              fontSize: DynamicTokens.fontSizeTitleMedium,
              color: DynamicTokens.textError,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DynamicTokens.textError.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DynamicTokens.textError.withOpacity(0.3)),
            ),
            child: Text(
              error,
              style: TextStyle(
                fontSize: DynamicTokens.fontSizeBodySmall,
                color: DynamicTokens.textError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI解読取得ボタン（広告サポート付き）
class AIReadingButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final String text;
  final bool enabled;
  final String readingType;

  const AIReadingButton({
    super.key,
    required this.onPressed,
    required this.readingType,
    this.text = 'AI解読を取得',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 每日抽牌免费，其他类型需要广告
    final isFreeReading = readingType == 'daily';
    
    if (isFreeReading) {
      return _buildFreeButton(context, ref);
    } else {
      return _buildAdSupportedButton(context, ref);
    }
  }

  Widget _buildFreeButton(BuildContext context, WidgetRef ref) {
    final aiReading = ref.watch(aiReadingProvider(readingType));
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final isLoading = aiReading.state == AIReadingState.loading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(AppIcons.autoAwesome),
        label: Text(isLoading ? '解読生成中...' : text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: dynamicTokens.primaryColor,
          foregroundColor: DynamicTokens.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAdSupportedButton(BuildContext context, WidgetRef ref) {
    final aiReading = ref.watch(aiReadingProvider(readingType));
    final adReward = ref.watch(adRewardProvider);
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final remainingCountAsync = ref.watch(remainingAdCountProvider);
    
    // 如果AI正在生成，显示生成状态
    if (aiReading.state == AIReadingState.loading) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('解読生成中...'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: dynamicTokens.primaryColor,
            foregroundColor: DynamicTokens.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return remainingCountAsync.when(
      loading: () => _buildLoadingButton(dynamicTokens),
      error: (error, _) => _buildErrorButton(context, error.toString(), dynamicTokens),
      data: (remainingCount) => _buildAdButton(
        context,
        ref,
        adReward,
        remainingCount,
        dynamicTokens,
      ),
    );
  }

  Widget _buildLoadingButton(DynamicTokens dynamicTokens) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('読み込み中...'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: DynamicTokens.textGrey600,
          foregroundColor: DynamicTokens.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorButton(BuildContext context, String error, DynamicTokens dynamicTokens) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(AppIcons.errorOutline),
        label: const Text('エラーが発生しました'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: DynamicTokens.textError,
          foregroundColor: DynamicTokens.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAdButton(
    BuildContext context,
    WidgetRef ref,
    AdRewardData adReward,
    int remainingCount,
    DynamicTokens dynamicTokens,
  ) {
    final isLoading = adReward.state == AdRewardState.watching || adReward.state == AdRewardState.loading;
    final isLimitReached = remainingCount <= 0;

    // 根据状态选择按钮内容
    Widget icon;
    String label;
    Color backgroundColor;
    VoidCallback? onPressedCallback;

    if (isLoading) {
      icon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: DynamicTokens.textWhite),
      );
      label = adReward.state == AdRewardState.watching ? '広告視聴中...' : '準備中...';
      backgroundColor = dynamicTokens.primaryColor;
      onPressedCallback = null;
    } else if (isLimitReached) {
      icon = const Icon(AppIcons.block);
      label = '本日の上限に達しました (3回)';
      backgroundColor = DynamicTokens.textGrey600;
      onPressedCallback = null;
    } else {
      icon = const Icon(AppIcons.playCircleOutline);
      label = '広告を見て$text ($remainingCount回残り)';
      backgroundColor = dynamicTokens.primaryColor;
      onPressedCallback = enabled ? () => _handleAdWatch(context, ref) : null;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressedCallback,
            icon: icon,
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: backgroundColor,
              foregroundColor: DynamicTokens.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (adReward.error != null && adReward.state == AdRewardState.failed) ...[
          const SizedBox(height: 8),
          FadeIn(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DynamicTokens.textError.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DynamicTokens.textError.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.warningAmber, color: DynamicTokens.textError, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adReward.error!,
                      style: TextStyle(
                        color: DynamicTokens.textError,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (!isLimitReached && remainingCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '毎日最大3回まで広告視聴でAI解読が利用できます',
            style: TextStyle(
              fontSize: DynamicTokens.fontSizeCaption,
              color: DynamicTokens.textBlack87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Future<void> _handleAdWatch(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(adRewardProvider.notifier);
    
    // 显示准备广告的对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('広告を準備中...'),
          ],
        ),
      ),
    );

    try {
      final success = await notifier.showRewardedAd();
      
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // 广告观看成功，执行解读
        if (context.mounted) {
          _showSuccessDialog(context, () {
            Navigator.of(context).pop();
            onPressed(); // 执行原始的解读回调
          });
        }
      } else {
        // 广告观看失败，显示错误
        if (context.mounted) {
          _showFailureDialog(context);
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        _showFailureDialog(context);
      }
    }
  }

  void _showSuccessDialog(BuildContext context, VoidCallback onContinue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(AppIcons.checkCircle, color: DynamicTokens.textSuccess, size: 48),
        title: const Text('広告視聴完了！'),
        content: const Text('AI解読を開始します。'),
        actions: [
          TextButton(
            onPressed: onContinue,
            child: const Text('続ける'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(AppIcons.errorOutline, color: DynamicTokens.textError, size: 48),
        title: const Text('広告視聴に失敗'),
        content: const Text('広告を最後まで視聴していただく必要があります。もう一度お試しください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// 顶层：AI文本分段模型
class _AISection {
  _AISection({required this.header, required this.body});
  final String header;
  final List<String> body;
}