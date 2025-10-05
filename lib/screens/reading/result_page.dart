import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart' show TarotCard;
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/providers/ai_reading_provider.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/widgets/ai_reading_widget.dart';
import 'package:mystic_tarot_jp/providers/ad_watched_provider.dart';
import 'package:mystic_tarot_jp/providers/subscription_provider.dart';
import 'package:mystic_tarot_jp/widgets/app_tag.dart';

class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({super.key});

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  int _currentTabIndex = 0; // deprecated tabs kept for minimal diff but UI will show single AI診断
  int _selectedCardIndex = 0; // 当前选中的卡片索引
  bool _saveToHistory = true;
  bool _isFavorite = false; // お気に入り状態
  bool _hasBeenSaved = false; // 是否已经保存过
  // 通过build阶段检测AI完成来保存，无需在initState中注册监听
  String? _savedReadingId; // 已保存记录的ID（用于后续更新）
  // 缓存卡面原始宽高比（用来精确绘制选中边框）
  final Map<String, double> _imageAspectRatioCache = {};

  @override
  void initState() {
    super.initState();
    // 页面加载时自动保存占卜记录（如果用户启用了保存）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSaveReading();
    });
  }

  /// 检查并保存占卜记录
  Future<void> _checkAndSaveReading() async {
    if (!_saveToHistory || _hasBeenSaved) return;
    
    final readingResult = ref.read(readingResultProvider);
    if (readingResult == null) return;
    
    // 优先使用AI解读结果进行保存；若尚未生成，监听完成事件后再保存
    final readingTypeKey = _getReadingTypeKey(readingResult.readingType);
    final ai = ref.read(aiReadingProvider(readingTypeKey));
    
    Future<void> doSave(String interpretation) async {
      try {
        if (_savedReadingId == null) {
          _savedReadingId = await _saveReadingToDatabase(readingResult, interpretation: interpretation);
        } else {
          await SupabaseService.updateReadingInterpretation(_savedReadingId!, interpretation);
        }
        if (mounted) {
          setState(() { _hasBeenSaved = true; });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('占卜記録の保存に失敗しました: $e')),
          );
        }
      }
    }
    
    if (ai.state == AIReadingState.completed && ai.result.isNotEmpty) {
      await doSave(ai.result);
      return;
    }
  }

  /// 确保缓存指定资产的原始宽高比（异步解析一次）
  void _ensureImageAspect(String assetPath) {
    if (_imageAspectRatioCache.containsKey(assetPath)) return;
    try {
      final ImageStream stream = AssetImage(assetPath)
          .resolve(createLocalImageConfiguration(context));
      ImageStreamListener? listener;
      listener = ImageStreamListener((ImageInfo info, bool _) {
        final double aspect = info.image.width / info.image.height;
        if (mounted) {
          setState(() {
            _imageAspectRatioCache[assetPath] = aspect;
          });
        }
        stream.removeListener(listener!);
      }, onError: (dynamic _, __) {
        // 失败时忽略，使用默认比值
      });
      stream.addListener(listener);
    } catch (_) {
      // ignore
    }
  }

  /// 生成占卜解读内容
  String _generateInterpretation(ReadingResult readingResult) {
    final cards = readingResult.cards;
    final orientations = readingResult.orientations;
    final question = readingResult.question;
    
    // 构建解读内容
    final buffer = StringBuffer();
    
    // 添加问题（如果有）
    if (question.isNotEmpty) {
      buffer.writeln('【占卜问题】');
      buffer.writeln(question);
      buffer.writeln();
    }
    
    // 添加AI解説标题（保持日语）
    buffer.writeln('【AI解説】');
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final isUpright = orientations[i];
      final position = _getPositionName(i, readingResult.readingType);
      
      buffer.writeln('${position}: ${card.nameJa} (${isUpright ? '正位' : '逆位'})');
      final meaning = isUpright ? card.meaningUpright : card.meaningReversed;
      buffer.writeln(meaning);
      buffer.writeln();
    }
    
    // 添加生成时间
    buffer.writeln('【占卜时间】');
    buffer.writeln('${readingResult.timestamp.year}年${readingResult.timestamp.month}月${readingResult.timestamp.day}日 ${readingResult.timestamp.hour}:${readingResult.timestamp.minute.toString().padLeft(2, '0')}');
    
    return buffer.toString();
  }
  
  /// 获取牌位名称
  String _getPositionName(int index, String readingType) {
    switch (readingType) {
      case 'ワンオラクル':
      case 'one':
        return '今日の運勢';
      case 'ツーカード':
      case 'yesno':
        return index == 0 ? '選択肢A' : '選択肢B';
      case 'スリーカード':
      case 'three':
        switch (index) {
          case 0: return '過去';
          case 1: return '現在';
          case 2: return '未来';
          default: return '位置${index + 1}';
        }
      default:
        return '位置${index + 1}';
    }
  }

  /// 保存占卜记录到数据库
  Future<String> _saveReadingToDatabase(ReadingResult readingResult, {String? interpretation}) async {
    // 构造占卜记录数据
    final cards = readingResult.cards.asMap().entries.map((entry) {
      final index = entry.key;
      final card = entry.value;
      final isUpright = readingResult.orientations[index];
      
      return {
        'card_id': card.id,
        'position': index + 1,
        'is_upright': isUpright,
      };
    }).toList();

    // 根据占卜类型确定spread_id
    String spreadId = 'one'; // 默认
    switch (readingResult.readingType) {
      case 'ワンオラクル':
      case 'one':
        spreadId = 'one';
        break;
      case 'ツーカード':
      case 'yesno':
        spreadId = 'two';
        break;
      case 'スリーカード':
      case 'three':
        spreadId = 'three';
        break;
    }

    // 生成解读内容：优先使用AI结果，其次使用牌面解读作为后备
    final savedInterpretation =
        (interpretation != null && interpretation.isNotEmpty)
            ? interpretation
            : _generateInterpretation(readingResult);

    final id = await SupabaseService.saveReading(
      spreadId: spreadId,
      cards: cards,
      question: readingResult.question.isNotEmpty ? readingResult.question : null,
      interpretation: savedInterpretation,
    );
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final readingResult = ref.watch(readingResultProvider);
    
    // 如果没有结果数据，显示加载或错误状态
    if (readingResult == null) {
      return Scaffold(
        backgroundColor: dynamicTokens.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final cards = readingResult.cards;
    final orientations = readingResult.orientations;
    final cardCount = cards.length;
    
    return Scaffold(
      backgroundColor: dynamicTokens.backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // 卡片展示区域
                Container(
                  height: cardCount == 1 ? 400 : 310, // 微调高度，消除底部多余空白
                  padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                  child: cardCount == 1
                      ? _buildSingleCard(cards[0], orientations[0])
                      : _buildMultipleCards(cards, orientations, readingResult.readingType),
                ),
                
                // 标签栏和内容区域
                Container(
                  color: dynamicTokens.surfaceColor,
                  child: Column(
                    children: [
                      // タブ：AI診断 / カードの解釈
                      Container(
                        height: 68,
                        child: Row(
                          children: [
                            _buildTab(0, 'AI診断', AppIcons.autoAwesome),
                            _buildTab(1, 'カードの解釈', AppIcons.lightbulb),
                          ],
                        ),
                      ),
                      
                      // 内容区域 - 移除固定高度限制
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: DynamicTokens.spacingMd,
                        ),
                        child: _buildTabContent(),
                      ),
                    ],
                  ),
                ),
                  
                // 按钮区域（仅保留「もう一度占う」）
                Padding(
                  padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(clearReadingProvider)();
                        context.go('/reading');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dynamicTokens.primaryColor,
                        foregroundColor: DynamicTokens.textWhite,
                      ),
                      child: const Text('もう一度占う'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 右上角功能图标已移除（お気に入り/履歴保存/シェア）

        ],
      ),
    );
  }

  Widget _buildSingleCard(TarotCard card, bool isUpright) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    _ensureImageAspect(card.imageUrl);
    final double singleAR = _imageAspectRatioCache[card.imageUrl] ?? 0.7;
    
    return FadeIn(
      duration: DynamicTokens.animationDuration,
      child: Center(
        child: AspectRatio(
          aspectRatio: singleAR, // 使用图片真实比例
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DynamicTokens.radiusSm), // 统一使用较小圆角
              boxShadow: DynamicTokens.shadowCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DynamicTokens.radiusSm), // 统一使用较小圆角
              child: Stack(
                children: [
                  // 卡片图像
                  Positioned.fill(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(isUpright ? 0 : 3.14159), // 逆位时旋转180度
                      child: Image.asset(
                        card.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                                          decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    dynamicTokens.primaryColor.withOpacity(0.1),
                    dynamicTokens.primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  AppIcons.autoAwesome,
                  size: 64,
                  color: dynamicTokens.primaryColor.withOpacity(0.3),
                ),
              ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleCards(List<TarotCard> cards, List<bool> orientations, String readingType) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final labels = _getCardLabels(readingType);
    
    return Column(
      children: [
        // 卡片展示区域
        Expanded(
          child: Row(
            children: List.generate(
              cards.length,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FadeIn(
                    duration: DesignTokens.animationDuration,
                    delay: Duration(milliseconds: index * 100),
                    child: Column(
                      children: [
                        // 标签 - 使用与首页一致的 AppTag 样式
                        Builder(builder: (context) {
                          final bool isSelected = _selectedCardIndex == index;
                          return Center(
                            child: AppTag(
                              labels[index],
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              borderRadius: 12,
                              fontSize: 10,
                              useTheme: isSelected,
                              overlay: isSelected,
                            ),
                          );
                        }),
                        
                        const SizedBox(height: DesignTokens.spacingXs),
                        
                        // 卡片 - 只有卡片部分可以点击和选中
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCardIndex = index;
                              });
                            },
                            child: AspectRatio(
                              aspectRatio: (() {
                                final path = cards[index].imageUrl;
                                _ensureImageAspect(path);
                                return _imageAspectRatioCache[path] ?? 0.6;
                              })(), // 使用图片真实比例
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                  boxShadow: DesignTokens.shadowCard,
                                ),
                                child: Stack(
                                  children: [
                                    // 卡片图像容器
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateZ(orientations[index] ? 0 : 3.14159),
                                        child: Image.asset(
                                          cards[index].imageUrl,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                                                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      dynamicTokens.primaryColor.withOpacity(0.1),
                                      dynamicTokens.primaryColor.withOpacity(0.05),
                                    ],
                                      ),
                                ),
                                child: Center(
                                  child: Icon(
                                    AppIcons.autoAwesome,
                                    size: 32,
                                    color: dynamicTokens.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    
                                    // 选中边框 - 直接覆盖容器区域（图片使用 contain 居中显示）
                                    if (_selectedCardIndex == index)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                              border: Border.all(color: dynamicTokens.primaryColor, width: 3),
                                            ),
                                          ),
                                        ),
                                      ),
                                    
                                    // 方向指示器（已移至卡片下方显示）
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 方向指示器放在卡片下方，居中显示，样式与首页一致
                        AppTag(
                          orientations[index] ? '正位置' : '逆位置',
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          borderRadius: 16,
                          fontSize: 10,
                          useTheme: true,
                          overlay: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        

      ],
    );
  }

  List<String> _getCardLabels(String readingType) {
    switch (readingType) {
      case 'yesno':
      case 'ツーカード':
        return ['選択A', '選択B'];
      case 'three':
      case 'スリーカード':
        return ['過去', '現在', '未来'];
      default:
        return [];
    }
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final isSelected = _currentTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                            color: isSelected 
                ? dynamicTokens.primaryColor
                : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? dynamicTokens.primaryColor
                      : ref.watch(dynamicTokensProvider).textSecondary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected 
                        ? dynamicTokens.primaryColor
                        : ref.watch(dynamicTokensProvider).textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildAIReadingTab();
      case 1:
        return _buildInterpretationTab();
      default:
        return _buildAIReadingTab();
    }
  }

  // 新增：診断 tab
  Widget _buildResultTab() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final readingResult = ref.watch(readingResultProvider);
    if (readingResult == null) return const SizedBox();
    
    final cards = readingResult.cards;
    final orientations = readingResult.orientations;
    final firstCard = cards.first;
    final firstOrientation = orientations.first;
    
    // 使用第一张牌的牌意作为診断内容
    final resultText = firstOrientation ? firstCard.meaningUpright : firstCard.meaningReversed;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 牌名
          Text(
            firstCard.nameJa,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DynamicTokens.textBlack87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            firstCard.nameEn,
            style: const TextStyle(
              fontSize: 14,
              color: DynamicTokens.textBlack87,
            ),
          ),
          const SizedBox(height: DynamicTokens.spacingMd),
          
          // 正逆位指示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: firstOrientation ? DynamicTokens.textSuccess.withOpacity(0.1) : DynamicTokens.textError.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: firstOrientation ? DynamicTokens.textSuccess : DynamicTokens.textError,
                width: 1,
              ),
            ),
            child: Text(
              firstOrientation ? '正位置' : '逆位置',
              style: TextStyle(
                color: firstOrientation ? DynamicTokens.textSuccess : DynamicTokens.textError,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: DynamicTokens.spacingMd),
          
          // 診断内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DynamicTokens.spacingMd),
            decoration: BoxDecoration(
              color: DynamicTokens.textGrey600.withOpacity(0.08),
              borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
              border: Border.all(
                color: DynamicTokens.textGrey600.withOpacity(0.25),
              ),
            ),
            child: _buildParsedMeaningContent(resultText),
          ),
        ],
      ),
    );
  }
  
  // meaning内容显示（保留标题解析和加粗居中）
  Widget _buildParsedMeaningContent(String meaningText) {
    final parsed = _parseTextContent(meaningText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parsed['title']!.isNotEmpty) ...[
          Text(
            parsed['title']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DynamicTokens.textBlack87,
              height: 1.4,
            ),
            textAlign: TextAlign.left,
          ),
          if (parsed['content']!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              parsed['content']!,
              style: const TextStyle(
                fontSize: 12,
                color: DynamicTokens.textBlack87,
                height: 1.6,
              ),
            ),
          ],
        ] else ...[
          Text(
            meaningText,
            style: const TextStyle(
              fontSize: 12,
              color: DynamicTokens.textBlack87,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
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

  Widget _buildInterpretationTab() {
    final readingResult = ref.watch(readingResultProvider);
    if (readingResult == null) return const SizedBox();
    
    final cards = readingResult.cards;
    final orientations = readingResult.orientations;
    
    // 如果是单张牌，显示单张牌的解释
    if (cards.length == 1) {
      return _buildSingleCardInterpretation(cards[0], orientations[0]);
    }
    
    // 多张牌时显示选中卡片的解释
    if (_selectedCardIndex < cards.length) {
      final card = cards[_selectedCardIndex];
      final isUpright = orientations[_selectedCardIndex];
      final labels = _getCardLabels(readingResult.readingType);
      
      return _buildMultiCardInterpretation(card, isUpright, labels[_selectedCardIndex]);
    }
    
    return const SizedBox();
  }

  Widget _buildSingleCardInterpretation(TarotCard card, bool isUpright) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片名称
          Text(
            card.nameJa,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ref.watch(dynamicTokensProvider).textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.nameEn,
            style: TextStyle(
              fontSize: 14,
              color: ref.watch(dynamicTokensProvider).textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // 故事（简洁显示，无标题解析）
          _buildStorySection(card.story),

          const SizedBox(height: 12),

          // 正逆位含义
          _buildCompactMeaningSection(
            isUpright ? '正位置' : '逆位置',
            isUpright ? card.meaningUpright : card.meaningReversed,
            isUpright ? card.uprightKeywordsList : card.reversedKeywordsList,
            isUpright ? DynamicTokens.textSuccess : DynamicTokens.textError,
          ),
        ],
      ),
    );
  }
  
  // story专用区块（简洁显示，无标题解析）
  Widget _buildStorySection(String content) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: dynamicTokens.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dynamicTokens.primaryColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '物語り',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: DynamicTokens.textBlack87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: DynamicTokens.textBlack87, height: 1.6),
          ),
        ],
      ),
    );
  }
  
  // 紧凑版的内容区块
  Widget _buildCompactSection(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          _buildCompactParsedContent(content),
        ],
      ),
    );
  }
  
  // 紧凑版的含义区块（包含关键词）
  Widget _buildCompactMeaningSection(String title, String meaning, List<String> keywords, Color color) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: dynamicTokens.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dynamicTokens.primaryColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 位置标签移除，仅展示正文与关键词
          _buildCompactParsedContent(meaning),
          const SizedBox(height: 8),
          // Keywords标签
          if (keywords.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: keywords.take(6).map<Widget>((keyword) {
                return AppTag(
                  keyword,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  borderRadius: 20,
                  fontSize: 10,
                  useTheme: true,
                  overlay: true,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  
  // meaning内容显示（保留标题解析和加粗居中）
  Widget _buildCompactParsedContent(String text) {
    final parsed = _parseTextContent(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parsed['title']!.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: Text(
              parsed['title']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DynamicTokens.textBlack87,
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          if (parsed['content']!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              parsed['content']!,
              style: const TextStyle(
                fontSize: 12,
                color: DynamicTokens.textBlack87,
                height: 1.6,
              ),
            ),
          ],
        ] else ...[
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: DynamicTokens.textBlack87,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMultiCardInterpretation(TarotCard card, bool isUpright, String label) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片名称
          Text(
            card.nameJa,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ref.watch(dynamicTokensProvider).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.nameEn,
            style: TextStyle(
              fontSize: 14,
              color: ref.watch(dynamicTokensProvider).textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // 故事（简洁显示，无标题解析）
          _buildStorySection(card.story),

          const SizedBox(height: 12),

          // 正逆位含义
          _buildCompactMeaningSection(
            isUpright ? '正位置' : '逆位置',
            isUpright ? card.meaningUpright : card.meaningReversed,
            isUpright ? card.uprightKeywordsList : card.reversedKeywordsList,
            isUpright ? DynamicTokens.textSuccess : DynamicTokens.textError,
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordsSection(List<String> keywords) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'キーワード',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ref.watch(dynamicTokensProvider).textPrimary,
          ),
        ),
        const SizedBox(height: DynamicTokens.spacingMd),
        Wrap(
          spacing: DynamicTokens.spacingSm,
          runSpacing: DynamicTokens.spacingSm,
          children: keywords.map((keyword) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DynamicTokens.spacingMd,
                vertical: DynamicTokens.spacingSm,
              ),
              decoration: BoxDecoration(
                color: dynamicTokens.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
              ),
              child: Text(
                keyword,
                style: TextStyle(
                  color: dynamicTokens.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterpretationSection(String meaning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '解釈',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ref.watch(dynamicTokensProvider).textPrimary,
          ),
        ),
        const SizedBox(height: DynamicTokens.spacingMd),
        Text(
          meaning,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: ref.watch(dynamicTokensProvider).textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildShareTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'シェア',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DynamicTokens.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildShareButton(AppIcons.share, 'シェア'),
            _buildShareButton(AppIcons.copy, 'コピー'),
            _buildShareButton(AppIcons.download, '保存'),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton(IconData icon, String label) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: dynamicTokens.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
          ),
          child: Icon(
            icon,
            color: dynamicTokens.primaryColor,
          ),
        ),
        const SizedBox(height: DynamicTokens.spacingSm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? dynamicTokens.primaryColor : ref.watch(dynamicTokensProvider).textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? dynamicTokens.primaryColor : ref.watch(dynamicTokensProvider).textSecondary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('シェア'),
        content: const Text('SNSでシェアしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 実際のシェア機能を実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('シェア機能は近日実装予定です')),
              );
            },
            child: const Text('シェア'),
          ),
        ],
      ),
    );
  }

  /// AI解読タブの構築
  Widget _buildAIReadingTab() {
    final readingResult = ref.watch(readingResultProvider);
    if (readingResult == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI解読ウィジェット
          Builder(builder: (context) {
            final readingTypeKey = _getReadingTypeKey(readingResult.readingType);
            final ai = ref.watch(aiReadingProvider(readingTypeKey));
            final adWatched = ref.watch(adWatchedProvider);
            
            // 检查是否应该自动触发AI解读
            if (ai.state == AIReadingState.idle) {
              final needsAd = _isAdRequiredReading(readingResult.readingType);
              final adWatchedNotifier = ref.read(adWatchedProvider.notifier);
              final hasActiveSubscription = ref.watch(hasActiveSubscriptionProvider);
              
              final shouldAutoStart = !needsAd || // 免费解读
                  adWatchedNotifier.hasWatchedForType(readingResult.readingType) || // 已看广告
                  (hasActiveSubscription.value == true); // 订阅用户
              
              if (shouldAutoStart) {
                // 自动开始AI解读
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await _requestAIReading(readingResult);
                });
              }
            }
            
            // 在build阶段检测到AI已完成但尚未保存时，执行保存
            if (!_hasBeenSaved && ai.state == AIReadingState.completed && ai.result.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await _checkAndSaveReading();
                // 保存完成后刷新履歴Provider，使履歴页面可立即看到最新记录
                try {
                  if (mounted) {
                    // 使用 context 读取 Provider 需要依赖全局 ref，这里跳过；改为在 MyPage/履歴页面进入时自动拉取
                  }
                } catch (_) {}
              });
            }
            
            return Column(
              children: [
                // AI解読結果表示
                AIReadingWidget(
                  readingType: readingTypeKey,
                  compact: true,
                ),
                
                // 显示状态信息（如果需要）
                if (ai.state == AIReadingState.idle) ...[
                  const SizedBox(height: 16),
                  _buildWaitingMessage(readingResult.readingType),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  /// 构建等待消息
  Widget _buildWaitingMessage(String readingType) {
    final needsAd = _isAdRequiredReading(readingType);
    final adWatchedNotifier = ref.read(adWatchedProvider.notifier);
    
    if (!needsAd) {
      // 免费解读
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                child: Text('AI解読を準備中...'),
              ),
            ],
          ),
        ),
      );
    }
    
    final hasActiveSubscription = ref.watch(hasActiveSubscriptionProvider);
    
    if (!adWatchedNotifier.hasWatchedForType(readingType) && 
        hasActiveSubscription.value != true) {
      // 需要广告但未观看，且非订阅用户
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(AppIcons.playCircleOutline, size: 48, color: DynamicTokens.textWarning),
              const SizedBox(height: 8),
              const Text(
                '広告視聴が必要です',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                hasActiveSubscription.value == true 
                    ? 'プレミアム会員として無制限解読をお楽しみいただけます。'
                    : '質問入力画面で広告を視聴するか、プレミアム購読でお楽しみください。',
                style: TextStyle(color: DynamicTokens.textGrey600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // 已观看广告，准备中
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text('AI解読を準備中...'),
            ),
          ],
        ),
      ),
    );
  }

  /// 检查是否是需要广告的解读类型
  bool _isAdRequiredReading(String readingType) {
    switch (readingType) {
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

  /// 解読タイプをキーに変換
  String _getReadingTypeKey(String readingType) {
    switch (readingType) {
      case '首日抽牌':
        return 'daily';
      case 'ワンオラクル':
        return 'one';
      case 'ツーカード':
        return 'two';
      case 'スリーカード':
        return 'three';
      default:
        return 'one'; // デフォルト
    }
  }

  /// AI解読をリクエスト
  Future<void> _requestAIReading(ReadingResult readingResult) async {
    final readingTypeKey = _getReadingTypeKey(readingResult.readingType);
    final aiNotifier = ref.read(aiReadingProvider(readingTypeKey).notifier);
    final cards = readingResult.cards;
    final orientations = readingResult.orientations;
    final question = readingResult.question;
    final readingType = readingResult.readingType;

    // ユーザー情報を構築（実際のユーザー情報があれば使用）
    String userName = 'あなた';
    String? birthdayStr;
    String? jobStr;
    String? relationshipStr;
    try {
      // 1. まずプロフィール情報から name を取得
      try {
        final profile = await SupabaseService.getUserProfile();
        if (profile != null) {
          // 優先順位: name > openid
          if (profile['name'] != null && profile['name'].toString().isNotEmpty) {
            userName = profile['name'].toString();
          } else if (profile['openid'] != null && profile['openid'].toString().isNotEmpty) {
            userName = profile['openid'].toString();
          }
          // 追加：プロフィール詳細を収集
          // Supabaseの列名に合わせて読み取り → モデル側のキーにマップ
          if (profile['birth_date'] != null && profile['birth_date'].toString().isNotEmpty) {
            birthdayStr = profile['birth_date'].toString();
          } else if (profile['birthday'] != null && profile['birthday'].toString().isNotEmpty) {
            birthdayStr = profile['birthday'].toString();
          }
          if (profile['occupation'] != null && profile['occupation'].toString().isNotEmpty) {
            jobStr = profile['occupation'].toString();
          } else if (profile['job'] != null && profile['job'].toString().isNotEmpty) {
            jobStr = profile['job'].toString();
          }
          if (profile['relationship_status'] != null && profile['relationship_status'].toString().isNotEmpty) {
            relationshipStr = profile['relationship_status'].toString();
          } else if (profile['relationship'] != null && profile['relationship'].toString().isNotEmpty) {
            relationshipStr = profile['relationship'].toString();
          }
        }
      } catch (e) {
        // プロフィール取得失敗時は次のステップへ
      }
      
      // 2. プロフィールに名前がない場合、User ID を使用
      if (userName == 'あなた') {
        final user = SupabaseService.currentUser;
        if (user != null) {
          if (user.id.isNotEmpty) {
            userName = user.id;
          } else if (user.email != null && user.email!.isNotEmpty) {
            // 最後の手段としてメールアドレスの@より前の部分を使用
            userName = user.email!.split('@').first;
          }
        }
      }
    } catch (e) {
      // ユーザー情報取得失敗時はデフォルト名を使用
    }

    final userInfo = <String, String>{
      'name': userName,
      if (birthdayStr != null && birthdayStr!.isNotEmpty) 'birthday': birthdayStr!,
      if (jobStr != null && jobStr!.isNotEmpty) 'job': jobStr!,
      if (relationshipStr != null && relationshipStr!.isNotEmpty) 'relationship': relationshipStr!,
    };

    try {
      switch (readingTypeKey) {
        case 'daily':
          await aiNotifier.getDailyReading(
            card: cards[0],
            isUpright: orientations[0],
            userInfo: userInfo,
          );
          break;
          
        case 'one':
          await aiNotifier.getOneCardReading(
            question: question,
            card: cards[0],
            isUpright: orientations[0],
            userInfo: userInfo,
          );
          break;
          
        case 'two':
          if (cards.length >= 2) {
            // 获取保存的選択肢A/B
            final optionA = ref.read(optionAProvider);
            final optionB = ref.read(optionBProvider);
            
            await aiNotifier.getTwoCardsReading(
              question: question,
              cardA: cards[0],
              isUprightA: orientations[0],
              cardB: cards[1],
              isUprightB: orientations[1],
              userInfo: userInfo,
              optionA: optionA.isNotEmpty ? optionA : null,
              optionB: optionB.isNotEmpty ? optionB : null,
            );
          }
          break;
          
        case 'three':
          if (cards.length >= 3) {
            await aiNotifier.getThreeCardsReading(
              question: question,
              pastCard: cards[0],
              isPastUpright: orientations[0],
              presentCard: cards[1],
              isPresentUpright: orientations[1],
              futureCard: cards[2],
              isFutureUpright: orientations[2],
              userInfo: userInfo,
            );
          }
          break;
          
        default:
          // デフォルトでワンオラクルとして処理
          await aiNotifier.getOneCardReading(
            question: question,
            card: cards[0],
            isUpright: orientations[0],
            userInfo: userInfo,
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI解読の取得に失敗しました: $e'),
            backgroundColor: DynamicTokens.textError,
          ),
        );
      }
    }
  }
} 