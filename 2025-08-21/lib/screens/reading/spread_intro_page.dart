import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/providers/ad_reward_provider.dart';
import 'package:mystic_tarot_jp/providers/ad_watched_provider.dart';
import 'package:mystic_tarot_jp/providers/subscription_provider.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';

class SpreadIntroPage extends ConsumerStatefulWidget {
  final String? spreadId; // e.g., spreads_1/spreads_2/spreads_3

  const SpreadIntroPage({super.key, this.spreadId});

  @override
  ConsumerState<SpreadIntroPage> createState() => _SpreadIntroPageState();
}

class _SpreadIntroPageState extends ConsumerState<SpreadIntroPage> {
  Map<String, dynamic>? _meta;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final meta = await DataService.getSpreadMeta();
      Map<String, dynamic>? m;
      if (widget.spreadId != null && meta.containsKey(widget.spreadId)) {
        m = meta[widget.spreadId];
      } else {
        // fallback: match by selected title
        final selectedTitle = ref.read(readingFormatProvider);
        try {
          m = meta.values.firstWhere(
            (e) => (e['title'] ?? '') == selectedTitle,
          );
        } catch (_) {}
      }
      setState(() {
        _meta = m;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<String> _getSteps() {
    final stepsText = (_meta?['steps'] as String?)?.trim() ?? '';
    if (stepsText.isNotEmpty) {
      final lines = stepsText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (lines.isNotEmpty) return lines;
    }
    return const [];
  }

  List<String> _getQuestionPoints() {
    return (_meta?['question_points'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
  }

  String _resolveImagePath() {
    final title = (_meta?['title'] as String?) ?? '';
    if (title.contains('ワンオラクル')) return 'assets/images/spreads/spread_1.png';
    if (title.contains('ツーカード')) return 'assets/images/spreads/spread_2.png';
    if (title.contains('スリーカード')) return 'assets/images/spreads/spread_3.png';
    // fallback by id
    final id = widget.spreadId ?? '';
    if (id.endsWith('_1')) return 'assets/images/spreads/spread_1.png';
    if (id.endsWith('_2')) return 'assets/images/spreads/spread_2.png';
    if (id.endsWith('_3')) return 'assets/images/spreads/spread_3.png';
    return 'assets/images/spreads/spread_1.png';
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final strings = ref.watch(appStringsProvider);
    final String title = (_meta?['title'] as String?) ?? ref.watch(readingFormatProvider);
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: DynamicTokens.spacingMd,
              right: DynamicTokens.spacingMd,
              top: DynamicTokens.spacingMd, // 添加顶部间距
            ),
            child: Column(
              children: [
                // image（缩小并完整显示）
                Container(
                  height: 180,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Image.asset(
                    _resolveImagePath(),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: DynamicTokens.spacingLg),
                // steps
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(strings.readingExplanation,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: DynamicTokens.fontWeightBold),
                  ),
                ),
                const SizedBox(height: DynamicTokens.spacingSm),
                ..._getSteps().asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: DynamicTokens.spacingSm),
                      child: Text(e.value, style: Theme.of(context).textTheme.bodyMedium),
                    )),
                const SizedBox(height: DynamicTokens.spacingLg),
                if (_getQuestionPoints().isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.readingQuestion,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: DynamicTokens.fontWeightBold),
                    ),
                  ),
                  const SizedBox(height: DynamicTokens.spacingSm),
                  ..._getQuestionPoints().map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(p, style: Theme.of(context).textTheme.bodyMedium)),
                          ],
                        ),
                      )),
                ],

                const SizedBox(height: DynamicTokens.spacingXl),
                  
                // 次へボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleNextButton(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dynamicTokens.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(strings.buttonConfirm),
                  ),
                ),
              ],
            ),
          );
  }

  /// 处理【次へ】按钮点击
  Future<void> _handleNextButton() async {
    final readingFormat = ref.read(readingFormatProvider);
    final needsAd = _isAdRequiredReading(readingFormat);
    
    if (!needsAd) {
      // 免费解读，直接跳转
      if (mounted) {
        context.go('/reading/question');
      }
      return;
    }
    
    // 检查订阅状态
    final hasActiveSubscription = await ref.read(hasActiveSubscriptionProvider.future);
    
    if (hasActiveSubscription) {
      // 订阅用户，直接跳转
      final adWatchedNotifier = ref.read(adWatchedProvider.notifier);
      adWatchedNotifier.setWatched(readingFormat); // 标记为已观看，避免后续检查
      
      if (mounted) {
        context.go('/reading/question');
      }
      return;
    }
    
    // 需要付费的解读，显示选择对话框
    if (mounted) {
      _showPaymentOptionsDialog();
    }
  }

  /// 检查是否是需要广告的解读类型
  bool _isAdRequiredReading(String readingFormat) {
    switch (readingFormat) {
      case '首日抽牌':
        return false; // 免费
      case 'ワンオラクル':
      case 'ツーカード':
      case 'スリーカード':
        return true; // 需要广告
      default:
        return false;
    }
  }

  /// 显示付费选项对话框
  void _showPaymentOptionsDialog() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final strings = ref.watch(appStringsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: dynamicTokens.primaryColor),
            const SizedBox(width: 8),
            const Text('プレミアム解読'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'このタロット解読をご利用いただくには、以下の方法をお選びください：',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '広告を視聴して無料でご利用\n（毎日最大3回まで）',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'プレミアム購読で無制限利用',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: DynamicTokens.fontWeightBold,
                          ),
                        ),
                        const Text(
                          '広告なし・追加特典付き',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'テスト: ¥1,000/月',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 14,
                            fontWeight: DynamicTokens.fontWeightBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showAdAndProceed();
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('広告をみる'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showSubscriptionPurchaseDialog();
            },
            icon: const Icon(Icons.workspace_premium),
            label: const Text('プレミアムにアップグレード'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示广告并处理结果
  Future<void> _showAdAndProceed() async {
    final adNotifier = ref.read(adRewardProvider.notifier);
    final adWatchedNotifier = ref.read(adWatchedProvider.notifier);
    final readingFormat = ref.read(readingFormatProvider);
    
    // 检查剩余次数
    try {
      final remainingCount = await ref.read(remainingAdCountProvider.future);
      if (remainingCount <= 0) {
        _showDailyLimitDialog();
        return;
      }
    } catch (e) {
      debugPrint('❌ 无法获取剩余次数: $e');
    }
    if (!mounted) return;

    // 先标记为已观看（用户点击了广告按钮，不管广告是否成功都算作一次观看尝试）
    adWatchedNotifier.setWatched(readingFormat);

    try {
      await adNotifier.showRewardedAd();
    } catch (e) {
      debugPrint('❌ 广告流程异常: $e');
    }

    if (mounted) {
      context.go('/reading/question');
    }
  }

  /// 显示每日限制对话框
  void _showDailyLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.block, color: Colors.orange, size: 48),
        title: const Text('本日の上限に達しました'),
        content: const Text(
          '今日の広告視聴回数（3回）に達しました。\n明日再度お試しいただくか、プレミアム購読をご検討ください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSubscriptionPurchaseDialog();
            },
            child: const Text('購読について'),
          ),
        ],
      ),
    );
  }

  // 删除成功和失败对话框，直接跳转

  /// 显示订阅购买对话框
  void _showSubscriptionPurchaseDialog() {
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(ref.watch(appStringsProvider).subscriptionPremiumPlan),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 特典列表
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade50, Colors.orange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.watch(appStringsProvider).subscriptionBenefits,
                      style: TextStyle(
                        fontWeight: DynamicTokens.fontWeightBold,
                        fontSize: 16,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem('広告なしでスムーズな体験', Icons.block),
                    _buildBenefitItem('無制限のタロット解読', Icons.all_inclusive),
                    _buildBenefitItem('プレミアムカードデザイン', Icons.style),
                    _buildBenefitItem('優先サポート', Icons.support_agent),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 价格信息 - 直接显示，与MyPage保持一致
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¥1,000/月',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: DynamicTokens.fontWeightBold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            'いつでもキャンセル可能',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 提示信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'テスト環境について',
                          style: TextStyle(
                            fontWeight: DynamicTokens.fontWeightMedium,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '現在はテスト環境のため、実際の課金は発生しません。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ref.watch(appStringsProvider).buttonCancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _purchaseSubscription();
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('今すぐ購読'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 特典项目组件
  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 购买订阅
  Future<void> _purchaseSubscription() async {
    final notifier = ref.read(subscriptionPurchaseProvider.notifier);
    await notifier.purchaseSubscription();
    
    final state = ref.read(subscriptionPurchaseProvider);
    if (state.isSuccess) {
      _showSuccessSnackBar('プレミアム購読が完了しました！');
      
      // 订阅成功后，标记为已观看广告并跳转
      final readingFormat = ref.read(readingFormatProvider);
      final adWatchedNotifier = ref.read(adWatchedProvider.notifier);
      adWatchedNotifier.setWatched(readingFormat);
      
      if (mounted) {
        context.go('/reading/question');
      }
    } else if (state.error != null) {
      _showErrorSnackBar(state.error!);
    }
  }
  
  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}


