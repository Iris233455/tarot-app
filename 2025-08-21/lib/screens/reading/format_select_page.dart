import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/screens/reading/steps_info_dialog.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';

class FormatSelectPage extends ConsumerStatefulWidget {
  const FormatSelectPage({super.key});

  @override
  ConsumerState<FormatSelectPage> createState() => _FormatSelectPageState();
}

class _FormatSelectPageState extends ConsumerState<FormatSelectPage> {
  int _selectedIndex = -1;
  
  List<Map<String, dynamic>> spreads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpreads();
  }

  Future<void> _loadSpreads() async {
    try {
      final tarotData = await DataService.getTarotData();
      final spreadMeta = await DataService.getSpreadMeta();
      final loadedSpreads = <Map<String, dynamic>>[];
      
      // 将SpreadInfo转换为UI需要的格式，排除每日早晨抽牌（spreads_0）
      tarotData.spreads.forEach((key, spreadInfo) {
        // 跳过每日早晨抽牌，这个功能在"毎日の占い"中
        if (key == 'spreads_0') return;
        
        final meta = spreadMeta[key] ?? const {};
        final displayTitle = (meta['title'] != null && meta['title']!.isNotEmpty)
            ? meta['title']!
            : spreadInfo.name;
        final displayMessage = (meta['message'] ?? '').toString();

        Map<String, dynamic> spreadMap = {
          'id': key,
          'title': displayTitle,
          'description': displayMessage,
          'steps': spreadInfo.steps,
          'image': _getSpreadImage(key),
          'instructionImage': _getInstructionImage(key),
          'detailedInstructions': _getDetailedInstructions(key),
          'cardCount': _getCardCount(key),
          'route': _getRoute(key),
        };
        loadedSpreads.add(spreadMap);
      });
      
      setState(() {
        spreads = loadedSpreads;
        _isLoading = false;
      });
    } catch (e) {
      print('spreads加载失败: $e');
      // 如果加载失败，使用默认数据
      setState(() {
        spreads = _getDefaultSpreads();
        _isLoading = false;
      });
    }
  }

  String _getSpreadImage(String key) {
    switch (key) {
      case 'spreads_0':
      case 'spreads_1':
        return 'assets/images/spreads/eye_tarot1.png';
      case 'spreads_2':
        return 'assets/images/spreads/eye_tarot2.png';
      case 'spreads_3':
        return 'assets/images/spreads/eye_tarot3.png';
      default:
        return 'assets/images/spreads/eye_tarot1.png';
    }
  }

  int _getCardCount(String key) {
    switch (key) {
      case 'spreads_0':
      case 'spreads_1':
        return 1;
      case 'spreads_2':
        return 2;
      case 'spreads_3':
        return 3;
      default:
        return 1;
    }
  }

  String _getRoute(String key) {
    // 跳转到问题输入页面，然后再到shuffle页面
    return '/reading/question';
  }

  String _getInstructionImage(String key) {
    switch (key) {
      case 'spreads_0':
      case 'spreads_1':
        return 'assets/images/spreads/spread_1.png';
      case 'spreads_2':
        return 'assets/images/spreads/spread_2.png';
      case 'spreads_3':
        return 'assets/images/spreads/spread_3.png';
      default:
        return 'assets/images/spreads/spread_1.png';
    }
  }

  String _getDetailedInstructions(String key) {
    switch (key) {
      case 'spreads_0':
      case 'spreads_1':
        return 'まずは大アルカナ22枚から1枚を引いて診断する「ワンオラクル」から始めましょう。1枚だけでは物足りないかもしれませんが、どんな質問にも端的に答えをくれるので、手軽ながら万能な占い方です。';
      case 'spreads_2':
        return 'シンプルに2枚を並べるスプレッドです。異なる2つの要素を設定して、比較検討したい占いに合います。「Aさんと Bさん」「Aの道とBの道」「相手と自分」「行動した場合、しなかった場合」など拮抗するものなら何でも占えます。';
      case 'spreads_3':
        return '時間軸で占うときにぴったりのスプレッドで、左から「過去・現在・未来」とするのが基本です。①は過去の状態や原因、②は現状、③はこのままいくと近い未来にどうなるかという結果を示します。';
      default:
        return '';
    }
  }

  List<Map<String, dynamic>> _getDefaultSpreads() {
    return [
      {
        'id': 'one_card_spread',
        'title': ref.watch(appStringsProvider).labelOneOracle,
        'description': ref.watch(appStringsProvider).labelOneOracleDescription,
        'image': 'assets/images/spreads/eye_tarot1.png',
        'instructionImage': 'assets/images/spreads/spread_1.png',
        'detailedInstructions': 'まずは大アルカナ22枚から1枚を引いて診断する「ワンオラクル」から始めましょう。1枚だけでは物足りないかもしれませんが、どんな質問にも端的に答えをくれるので、手軽ながら万能な占い方です。',
        'cardCount': 1,
        'route': '/reading/question',
      },
      {
        'id': 'two_card_spread',
        'title': ref.watch(appStringsProvider).labelTwoCard,
        'description': ref.watch(appStringsProvider).labelTwoCardDescription,
        'image': 'assets/images/spreads/eye_tarot2.png',
        'instructionImage': 'assets/images/spreads/spread_2.png',
        'detailedInstructions': 'シンプルに2枚を並べるスプレッドです。異なる2つの要素を設定して、比較検討したい占いに合います。「Aさんと Bさん」「Aの道とBの道」「相手と自分」「行動した場合、しなかった場合」など拮抗するものなら何でも占えます。',
        'cardCount': 2,
        'route': '/reading/question',
      },
      {
        'id': 'three_card_spread',
        'title': ref.watch(appStringsProvider).labelThreeCard,
        'description': ref.watch(appStringsProvider).labelThreeCardDescription,
        'image': 'assets/images/spreads/eye_tarot3.png',
        'instructionImage': 'assets/images/spreads/spread_3.png',
        'detailedInstructions': '時間軸で占うときにぴったりのスプレッドで、左から「過去・現在・未来」とするのが基本です。①は過去の状態や原因、②は現状、③はこのままいくと近い未来にどうなるかという結果を示します。',
        'cardCount': 3,
        'route': '/reading/question',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: DynamicTokens.spacingMd), // 只保留左右padding
            itemCount: spreads.length,
            separatorBuilder: (_, __) => const SizedBox(height: DynamicTokens.spacingSm),
            itemBuilder: (context, index) {
              final spread = spreads[index];
              final isSelected = _selectedIndex == index;
              return FadeInUp(
                duration: DynamicTokens.animationDuration,
                delay: Duration(milliseconds: 50 + (index * 30)),
                child: InkWell(
                  onTap: () {
                    // 立即更新选中状态，提供视觉反馈
                    setState(() { _selectedIndex = index; });
                    ref.read(readingFormatProvider.notifier).state = spread['title'] ?? '';
                    
                    // 立即跳转，使用自定义页面切换动画
                    context.go('/reading/intro');
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
                          // 有背景图的主题：使用高透明度白色背景
                          DynamicTokens.textWhite.withOpacity(0.95),
                          DynamicTokens.textWhite.withOpacity(0.90),
                        ] : [
                          // 纯色背景主题：保持原来的surface颜色
                          dynamicTokens.surfaceColor.withOpacity(0.8),
                          dynamicTokens.surfaceColor.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected
                            ? dynamicTokens.primaryColor
                            : ((dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
                                ? dynamicTokens.primaryColor.withOpacity(0.6)
                                : dynamicTokens.primaryColor.withOpacity(0.2)),
                        width: isSelected ? 2 : ((dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 2 : 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                            child: AspectRatio(
                              aspectRatio: 16/9,
                              child: Image.asset(
                                spread['image'],
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: dynamicTokens.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                                    ),
                                    child: Icon(Icons.image, color: dynamicTokens.primaryColor),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: DynamicTokens.spacingSm),
                          Text(
                            spread['title'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: DynamicTokens.fontWeightBold,
                              color: isSelected 
                                ? dynamicTokens.primaryColor 
                                : ((dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? DynamicTokens.textBlack87 : ref.watch(dynamicTokensProvider).textPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((spread['description'] as String).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              spread['description'],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? DynamicTokens.textGrey600 : ref.watch(dynamicTokensProvider).textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
            },
          ),
        ),
      ],
    );
  }
} 