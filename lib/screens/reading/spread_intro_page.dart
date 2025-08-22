import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/providers/ad_reward_provider.dart';
import 'package:mystic_tarot_jp/providers/ad_watched_provider.dart';
import 'package:mystic_tarot_jp/providers/subscription_provider.dart';
import 'package:mystic_tarot_jp/widgets/subscription_purchase_dialog.dart';

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
                        child: Text(
                          '説明',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                            '質問のポイント',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    child: const Text('次へ'),
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: dynamicTokens.primaryColor),
            const SizedBox(width: 8),
            const Text('占いサービス'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'スプレッドをご利用いただくには、以下の方法をお選びください：',
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
                      '広告を視聴して無料でご利用\n（1日最大3回まで）',
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
                        const Text(
                          'プレミアム会員で無制限利用',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '広告なし',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
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
            child: const Text('キャンセル'),
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
      builder: (context) => SubscriptionPurchaseDialog(
        ref: ref,
        onPurchaseSuccess: () async {
          // 订阅成功后，标记广告已观看并跳转提问页
          final readingFormat = ref.read(readingFormatProvider);
          ref.read(adWatchedProvider.notifier).setWatched(readingFormat);
          if (mounted) {
            context.go('/reading/question');
          }
        },
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


