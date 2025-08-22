import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mystic_tarot_jp/providers/ai_reading_provider.dart';
import 'package:mystic_tarot_jp/providers/ad_reward_provider.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';

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
                  Icons.auto_awesome,
                  color: dynamicTokens.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  ref.watch(appStringsProvider).tabAI,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: DynamicTokens.fontWeightBold,
                    color: dynamicTokens.primaryColor,
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
        return _buildCompletedState(context, aiReading.result, dynamicTokens);
      case AIReadingState.error:
        return _buildErrorState(context, aiReading.error ?? ref.read(appStringsProvider).messageError);
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
            Icons.auto_awesome,
            size: 48,
            color: dynamicTokens.primaryColor.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Consumer(builder: (context, ref, _) {
            return Text(
              ref.watch(appStringsProvider).tabAI,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dynamicTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            );
          }),
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
              Icons.auto_awesome,
              size: 48,
              color: dynamicTokens.primaryColor.withOpacity(0.5),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Consumer(builder: (context, ref, _) {
              return Text(
                ref.watch(appStringsProvider).waitingAIPreparing,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: DynamicTokens.fontWeightMedium,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, String result, DynamicTokens dynamicTokens) {
    final content = _buildFormattedResult(context, result, dynamicTokens);
    if (compact) {
      return FadeInUp(child: content);
    }
    return FadeInUp(
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

  static const _headerEmojis = [
    '📖', '🌟', '💖', // daily
    '🃏', '💡', '🌙', // one
    '🅰️', '🅱️', '⚖️', '💭', // two
    '⏳', '🕰️', '🔮', // three
  ];

  Widget _buildFormattedResult(BuildContext context, String text, DynamicTokens dynamicTokens) {
    final theme = Theme.of(context).textTheme;
    final primary = dynamicTokens.primaryColor;
    final lines = text.split('\n');

    // 1) 分段：以Emoji标题作为分隔
    final List<_AISection> sections = [];
    _AISection? current;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final isHeader = _headerEmojis.any((e) => line.startsWith(e));
      if (isHeader) {
        current = _AISection(header: line, body: []);
        sections.add(current);
      } else {
        current ??= _AISection(header: '', body: []);
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
                style: theme.titleMedium?.copyWith(
                  fontWeight: DynamicTokens.fontWeightExtraBold,
                  height: 1.4,
                  color: primary,
                ),
              ),
            ),
          if (s.body.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: primary.withOpacity(0.3), width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < s.body.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _buildBodyLine(theme, s.body[i], isLead: i == 0),
                    ),
                ],
              ),
            ),
        ]
      ],
    );
  }

  Widget _buildBodyLine(TextTheme theme, String line, {bool isLead = false}) {
    // 列表行：以「・」「-」「—」开头
    final trimmed = line.trimLeft();
    final isBullet = trimmed.startsWith('・') || trimmed.startsWith('-') || trimmed.startsWith('—');
    final content = isBullet ? trimmed.substring(1).trimLeft() : line;
    final style = (isLead
            ? theme.bodyLarge?.copyWith(fontWeight: DynamicTokens.fontWeightSemiBold)
            : theme.bodyMedium)
        ?.copyWith(height: 1.6, fontSize: 15);
    if (!isBullet) return Text(content, style: style);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(fontSize: 16, height: 1.6)),
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
            color: Colors.red[400],
          ),
          const SizedBox(height: 12),
          Text(
            ref.watch(appStringsProvider).messageAIFailed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[700],
              fontWeight: DynamicTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
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
            this.text = ref.watch(appStringsProvider).buttonGetAIReading,
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
            : const Icon(Icons.auto_awesome),
        label: Text(isLoading ? ref.read(appStringsProvider).waitingAIPreparing : text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: dynamicTokens.primaryColor,
          foregroundColor: Colors.white,
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
          label: Text(ref.read(appStringsProvider).waitingAIPreparing),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: dynamicTokens.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return remainingCountAsync.when(
      loading: () => _buildLoadingButton(ref, dynamicTokens),
      error: (error, _) => _buildErrorButton(context, ref, error.toString(), dynamicTokens),
      data: (remainingCount) => _buildAdButton(
        context,
        ref,
        adReward,
        remainingCount,
        dynamicTokens,
      ),
    );
  }

  Widget _buildLoadingButton(WidgetRef ref, DynamicTokens dynamicTokens) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(ref.watch(appStringsProvider).messageLoading),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorButton(BuildContext context, WidgetRef ref, String error, DynamicTokens dynamicTokens) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.error_outline),
        label: Text(ref.watch(appStringsProvider).messageError),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
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
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
      label = ref.read(appStringsProvider).waitingAIPreparing;
      backgroundColor = dynamicTokens.primaryColor;
      onPressedCallback = null;
    } else if (isLimitReached) {
      icon = const Icon(Icons.block);
      label = ref.read(appStringsProvider).dialogPleaseWaitTillDay;
      backgroundColor = Colors.grey;
      onPressedCallback = null;
    } else {
      icon = const Icon(Icons.play_circle_outline);
      label = ref.read(appStringsProvider).adRequiredTitle;
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
              foregroundColor: Colors.white,
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
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adReward.error!,
                      style: TextStyle(
                        color: Colors.red[700],
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
            ref.read(appStringsProvider).subscriptionBenefits,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dynamicTokens.textSecondary,
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
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(ref.read(appStringsProvider).waitingAIPreparing),
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
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(ref.read(appStringsProvider).subscriptionBenefits),
        content: Text(ref.read(appStringsProvider).tabAI),
        actions: [
          TextButton(
            onPressed: onContinue,
            child: Text(ref.read(appStringsProvider).commonOk),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: Text(ref.read(appStringsProvider).messageError),
        content: Text(ref.read(appStringsProvider).adRequiredTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ref.read(appStringsProvider).commonClose),
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