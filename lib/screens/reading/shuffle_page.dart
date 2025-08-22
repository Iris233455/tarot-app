import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/services/card_back_service.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'dart:math';

// 抽牌流程状态
enum ShuffleState { initial, shuffling, cutting, drawing, revealed }

class ShufflePage extends ConsumerStatefulWidget {
  const ShufflePage({super.key});

  @override
  ConsumerState<ShufflePage> createState() => _ShufflePageState();
}

class _ShufflePageState extends ConsumerState<ShufflePage>
    with TickerProviderStateMixin {
  
  // 状态管理
  ShuffleState _currentState = ShuffleState.initial;
  List<TarotCard> _allCards = [];
  List<TarotCard> _deck = [];
  List<Offset> _offsets = [];
  List<double> _angles = [];
  int _splitIndex = 0;
  
  // 抽牌结果
  List<TarotCard> _drawnCards = [];
  List<bool> _cardOrientations = [];
  
  final Random _random = Random();
  
  // 动画控制器
  late AnimationController _shuffleController;
  late AnimationController _cutController;
  late AnimationController _drawController;
  
  // 动画
  late Animation<double> _scaleAnimation;
  late Animation<double> _cutAnimation;
  late Animation<Offset> _drawAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeCards();
    _initializeAnimations();
  }
  
  void _initializeCards() async {
    try {
      final allCards = await DataService.getAllTarotCards();
      final readingType = ref.read(readingFormatProvider);
      
      // 根据抽牌类型筛选卡牌
      List<TarotCard> selectedCards;
      if (readingType == 'ワンオラクル' || readingType == 'one') {
        // ワンオラクル只使用大阿尔卡纳牌
        selectedCards = allCards.where((card) => card.id.startsWith('major_')).toList();
      } else {
        // 其他抽牌方式使用全部卡牌
        selectedCards = allCards;
      }
      
      setState(() {
        _allCards = selectedCards;
        _deck = List.from(selectedCards);
        _offsets = List.filled(selectedCards.length, Offset.zero);
        _angles = List.filled(selectedCards.length, 0.0);
      });
    } catch (e) {
      print('カード読み込みエラー: $e');
    }
  }
  
  void _initializeAnimations() {
    _shuffleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cutController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _shuffleController,
      curve: Curves.easeInOut,
    ));
    
    _cutAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cutController,
      curve: Curves.easeInOut,
    ));
    
    _drawAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2),
    ).animate(CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _shuffleController.dispose();
    _cutController.dispose();
    _drawController.dispose();
    super.dispose();
  }
  
  int _getCardCount() {
    final readingType = ref.read(readingFormatProvider);
    switch (readingType) {
      case 'one':
      case 'ワンオラクル':
        return 1;
      case 'yesno':
      case 'ツーカード':
        return 2;
      case 'three':
      case 'スリーカード':
        return 3;
      default:
        return 1;
    }
  }

  List<String> _getCardLabels() {
    final readingType = ref.read(readingFormatProvider);
    switch (readingType) {
      case 'one':
      case 'ワンオラクル':
        return [''];
      case 'yesno':
      case 'ツーカード':
        return ['選択A', '選択B'];
      case 'three':
      case 'スリーカード':
        return ['過去', '現在', '未来'];
      default:
        return [''];
    }
  }

  String _getTitle() {
    switch (_currentState) {
      case ShuffleState.initial:
        return 'カードを準備します';
      case ShuffleState.shuffling:
        return 'カードをシャッフル中';
      case ShuffleState.cutting:
        return 'カードをカット中';
      case ShuffleState.drawing:
        return 'カードを引いてください';
      case ShuffleState.revealed:
        return '占い結果';
      default:
        return 'カードを準備します';
    }
  }

  String _getSubtitle() {
    switch (_currentState) {
      case ShuffleState.initial:
        return 'カードを準備します';
      case ShuffleState.shuffling:
        return 'カードをシャッフル中...';
      case ShuffleState.cutting:
        return 'カードをカット中...';
      case ShuffleState.drawing:
        return 'カードを引いてください';
      case ShuffleState.revealed:
        return '占い完了';
      default:
        return 'カードを準備します';
    }
  }

  String _getButtonText() {
    switch (_currentState) {
      case ShuffleState.initial:
        return 'シャッフル';
      case ShuffleState.shuffling:
        return 'シャッフル中...';
      case ShuffleState.cutting:
        return 'シャッフル中...';
      case ShuffleState.drawing:
        return 'カードを引く';
      case ShuffleState.revealed:
        return '結果を見る';
      default:
        return 'シャッフル';
    }
  }

  // Fisher-Yates洗牌算法
  void _shuffleDeck() {
    final deck = List<TarotCard>.from(_deck);
    for (int i = deck.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }
    _deck = deck;
    
    // 为洗牌动画生成随机偏移和角度
    for (int i = 0; i < _offsets.length; i++) {
      _offsets[i] = Offset(
        _random.nextDouble() * 60 - 30,
        _random.nextDouble() * 60 - 30,
      );
      _angles[i] = _random.nextDouble() * 0.4 - 0.2;
    }
  }

  // 切牌操作
  void _cutDeck() {
    _splitIndex = _random.nextInt(_deck.length ~/ 2) + _deck.length ~/ 4;
    final topHalf = _deck.sublist(0, _splitIndex);
    final bottomHalf = _deck.sublist(_splitIndex);
    _deck = [...bottomHalf, ...topHalf];
  }

  // 抽牌操作
  void _drawCards() {
    final cardCount = _getCardCount();
    _drawnCards = _deck.take(cardCount).toList();
    _cardOrientations = List.generate(cardCount, (index) => _random.nextBool());
  }

  // 执行洗牌
  void _onShuffle() async {
    if (_currentState != ShuffleState.initial) return;
    
    setState(() {
      _currentState = ShuffleState.shuffling;
    });
    
    HapticFeedback.mediumImpact();
    _shuffleDeck();
    _shuffleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 自動的にカット工程へ進む
    setState(() {
      _currentState = ShuffleState.cutting;
    });
    
    _shuffleController.reset();
    HapticFeedback.selectionClick();
    _cutDeck();
    _cutController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _cutController.reverse();
    
    // カット完了後、ユーザーは「カードを引く」を押すだけ
    setState(() {
      _currentState = ShuffleState.drawing;
    });
  }

  // 旧的カット操作は自動化されたため未使用（保留）

  // 执行抽牌
  void _onDraw() async {
    if (_currentState != ShuffleState.drawing) return;
    
    HapticFeedback.mediumImpact();
    _drawCards();
    _drawController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // 保存抽牌结果并导航到结果页面
    try {
      final readingType = ref.read(readingFormatProvider);
      final question = ref.read(readingQuestionProvider);
      
      await ref.read(performReadingProvider({
        'type': readingType,
        'question': question,
        'cards': _drawnCards,
        'orientations': _cardOrientations,
      }).future);
      
      if (mounted) {
        context.go('/reading/result');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('抽牌失敗: $e')),
        );
      }
    }
  }

  // 构建牌组显示
  Widget _buildDeckArea() {
    return Container(
      width: 200,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 多张牌堆叠效果
          for (int i = 0; i < 8; i++)
            Positioned(
              left: i * 2.0,
              top: i * 2.0,
              child: _buildSingleCard(i),
            ),
          
          // 抽出的牌
          if (_currentState == ShuffleState.drawing && _drawnCards.isNotEmpty)
            ..._buildDrawnCards(),
        ],
      ),
    );
  }

  // 构建单张牌
  Widget _buildSingleCard(int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shuffleController, _cutController]),
      builder: (context, child) {
        double scale = 1.0;
        Offset offset = Offset.zero;
        double angle = 0.0;
        
        if (_currentState == ShuffleState.shuffling) {
          scale = _scaleAnimation.value;
          if (index < _offsets.length) {
            offset = _offsets[index] * _shuffleController.value;
            angle = _angles[index] * _shuffleController.value;
          }
        } else if (_currentState == ShuffleState.cutting) {
          if (index < _splitIndex) {
            offset = Offset(0, -20 * _cutAnimation.value);
          }
        }
        
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: FutureBuilder<String>(
                future: CardBackService.getCurrentBackImageUrl(),
                builder: (context, snapshot) {
                  final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
                  return Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.black.withOpacity(0.35),
                                    Colors.black.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Image.asset(backUrl, fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建抽出的牌
  List<Widget> _buildDrawnCards() {
    final labels = _getCardLabels();
    return _drawnCards.asMap().entries.map((entry) {
      final index = entry.key;
      final card = entry.value;
      final label = index < labels.length ? labels[index] : '';
      
      return AnimatedBuilder(
        animation: _drawController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              (index - _drawnCards.length / 2 + 0.5) * 140 * _drawController.value,
              -200 * _drawController.value,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                FutureBuilder<String>(
                  future: CardBackService.getCurrentBackImageUrl(),
                  builder: (context, snapshot) {
                    final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
                    return Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // 神秘感：暗色渐变+发光
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.black.withOpacity(0.35),
                                      Colors.black.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Image.asset(
                                backUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // 轻微光斑动画（静态实现）
                            Positioned(
                              top: 6,
                              left: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.25),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    }).toList();
  }

  // 构建控制按钮（一步“シャッフル”自动包含カット；然后“カードを引く”）
  Widget _buildControlButton() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final isEnabled = _currentState != ShuffleState.shuffling && _allCards.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? () {
          switch (_currentState) {
            case ShuffleState.initial:
              _onShuffle();
              break;
            case ShuffleState.drawing:
              _onDraw();
              break;
            default:
              break;
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: dynamicTokens.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DynamicTokens.radiusLg),
          ),
          elevation: 4,
        ),
        child: Text(
          _getButtonText(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: DynamicTokens.spacingMd,
        right: DynamicTokens.spacingMd,
        top: DynamicTokens.spacingMd, // 添加顶部间距
      ),
      child: Column(
        children: [
          // 标题
          FadeInDown(
            duration: DynamicTokens.animationDuration,
            child: Text(
              _getTitle(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: DynamicTokens.spacingSm),
          
          const SizedBox(height: DynamicTokens.spacingMd),
          
          // 牌组区域
          Expanded(
            child: Center(
              child: FadeInUp(
                duration: DynamicTokens.animationDuration,
                delay: const Duration(milliseconds: 100),
                child: _buildDeckArea(),
              ),
            ),
          ),
          
          // 控制按钮
          FadeInUp(
            duration: DynamicTokens.animationDuration,
            delay: const Duration(milliseconds: 150),
            child: _buildControlButton(),
          ),
          
          const SizedBox(height: DynamicTokens.spacingLg),
        ],
      ),
    );
  }
}

class CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制装饰性边框
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRect(rect, paint);
    
    // 绘制内部装饰线
    final innerRect = Rect.fromLTWH(20, 20, size.width - 40, size.height - 40);
    canvas.drawRect(innerRect, paint);
    
    // 绘制对角线
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 