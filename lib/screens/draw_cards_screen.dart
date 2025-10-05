import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/core/theme/app_theme.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/widgets/tarot_card_widget.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'dart:math';
import 'package:mystic_tarot_jp/core/theme/dynamic_tokens.dart';

// 抽牌流程状态枚举
enum CardDrawState { initial, shuffling, cutting, drawing, revealed }

class DrawCardsScreen extends ConsumerStatefulWidget {
  const DrawCardsScreen({super.key});

  @override
  ConsumerState<DrawCardsScreen> createState() => _DrawCardsScreenState();
}

class _DrawCardsScreenState extends ConsumerState<DrawCardsScreen>
    with TickerProviderStateMixin {
  // ───────────── 设定区 ─────────────
  static const String backPath = 'assets/images/back.jpeg';
  static const double cardW = 120;
  static const int deckSize = 78;

  // ───────────── 状态 ─────────────
  List<TarotCard> _allCards = [];
  List<TarotCard> _deck = [];
  List<Offset> _offsets = [];
  List<double> _angles = [];
  int _splitIndex = 0;
  
  CardDrawState _currentState = CardDrawState.initial;
  
  int _selectedCardCount = 1;
  final List<TarotCard> _drawnCards = [];
  
  final Random _rand = Random();
  
  // 动画控制器
  late final AnimationController _shuffleController;
  late final AnimationController _cutController;
  late final AnimationController _drawController;
  
  // 抽牌动画
  late Animation<Offset> _drawAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeCards();
    _resetDeck();
    
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shuffleController.reset();
          setState(() {
            _currentState = CardDrawState.cutting;
          });
        }
      });

    _cutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _cutController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _currentState = CardDrawState.drawing;
          });
        }
      });

    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _initializeCards() async {
    try {
      final cards = await DataService.getAllTarotCards();
      setState(() {
        _allCards = cards;
        _deck = List.from(cards);
        _offsets = List.filled(cards.length, Offset.zero);
        _angles = List.filled(cards.length, 0);
      });
    } catch (e) {
      print('Error loading cards: $e');
      // 如果加载失败，初始化为空列表
      setState(() {
        _allCards = [];
        _deck = [];
        _offsets = [];
        _angles = [];
      });
    }
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _cutController.dispose();
    _drawController.dispose();
    super.dispose();
  }

  // 初始化 / 重新洗牌前调用
  void _resetDeck() {
    if (_allCards.isEmpty) {
      _initializeCards();
      return;
    }
    
    _deck = List.from(_allCards);
    _offsets = List.filled(_deck.length, Offset.zero);
    _angles = List.filled(_deck.length, 0);
    _drawnCards.clear();
    setState(() {
      _currentState = CardDrawState.initial;
    });
  }

  // ① シャッフル (Fisher-Yates 打乱)
  void _onShuffle() {
    setState(() {
      _currentState = CardDrawState.shuffling;
    });
    
    // Fisher-Yates 打乱
    for (int i = _deck.length - 1; i > 0; i--) {
      final j = _rand.nextInt(i + 1);
      final tmp = _deck[i];
      _deck[i] = _deck[j];
      _deck[j] = tmp;
    }
    
    // 随机偏移 & 角度
    for (int i = 0; i < _deck.length; i++) {
      _offsets[i] = Offset(
        _rand.nextDouble() * 40 - 20,
        _rand.nextDouble() * -60 - 20,
      );
      _angles[i] = _rand.nextDouble() * 40 - 20;
    }
    
    _shuffleController.forward();
  }

  // ② カット
  void _onCut() {
    if (_deck.length < 2) return;
    _splitIndex = _rand.nextInt(_deck.length ~/ 2) + _deck.length ~/ 4;
    _cutController.forward();
  }

  // ③ カードを引く
  void _onDraw() {
    if (_deck.isEmpty || _drawnCards.length >= _selectedCardCount) return;
    
    final topCard = _deck.removeLast();
    _drawnCards.add(topCard);
    
    // 为抽出的牌生成从牌堆中心 → 画面上方偏移的动画
    _drawController.reset();
    _drawAnimation = Tween(
      begin: Offset.zero,
      end: const Offset(0, -250),
    ).animate(CurvedAnimation(parent: _drawController, curve: Curves.easeOut));
    
    _drawController.forward().then((_) {
      if (_drawnCards.length >= _selectedCardCount) {
        setState(() {
          _currentState = CardDrawState.revealed;
        });
      }
    });
  }

  // 重置游戏
  void _resetGame() {
    _resetDeck();
    _shuffleController.reset();
    _cutController.reset();
    _drawController.reset();
    setState(() {});
  }

  // 单张牌的 Transform（堆内）
  Matrix4 _transformInDeck(int i) {
    final t = _shuffleController.value;
    final c = _cutController.value;
    final dx = _offsets[i].dx * (1 - t);
    final dy = _offsets[i].dy * (1 - t);
    final angleRad = _angles[i] * (1 - t) * pi / 180;

    double extraDy = 0;
    if (i < _splitIndex) {
      extraDy = -120 * c;
    }
    
    return Matrix4.identity()
      ..translate(dx, dy + extraDy)
      ..rotateZ(angleRad);
  }

  // 绘制一张牌（堆内 / 抽出）
  Widget _buildCard(int deckIdx, {required bool isDrawn, int drawnOrder = 0}) {
    final img = AspectRatio(
      aspectRatio: 670 / 1197,
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(backPath), 
            fit: BoxFit.cover
          ),
          borderRadius: BorderRadius.circular(8),
          // no box shadows
        ),
      ),
    );

    // 抽出的牌：根据 _drawController 的偏移叠放
    if (isDrawn) {
      return AnimatedBuilder(
        animation: _drawController,
        builder: (_, child) {
          final off = _drawAnimation.value + Offset(0, drawnOrder * -15);
          return Positioned(
            left: 0,
            right: 0,
            top: off.dy,
            child: Center(
              child: Transform.scale(
                scale: 1.0,
                child: child,
              ),
            ),
          );
        },
        child: SizedBox(width: cardW, child: img),
      );
    }

    // 牌堆里的 Transform
    final z = deckIdx / (_deck.length + 1);
    return Transform(
      alignment: Alignment.center,
      transform: _transformInDeck(deckIdx),
      child: Opacity(
        opacity: 1 - z * 0.02,
        child: SizedBox(width: cardW, child: img),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('占い'),
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
          child: Column(
            children: [
              // 选择卡片数量
              if (_currentState == CardDrawState.initial)
                _buildCardCountSelector(),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // 卡片显示区域
              Expanded(
                child: _buildGameArea(),
              ),
              
              // 控制按钮
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardCountSelector() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: DynamicTokens.textBlack87.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Text(
            'カードの枚数を選択',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DynamicTokens.textWhite,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3].map((count) {
              return GestureDetector(
                onTap: () => setState(() => _selectedCardCount = count),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _selectedCardCount == count
                        ? AppTheme.primaryColor
                        : DynamicTokens.textWhite54,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: _selectedCardCount == count
                            ? DynamicTokens.textWhite
                            : DynamicTokens.textWhite70,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    if (_currentState == CardDrawState.revealed) {
      return _buildRevealedCards();
    }
    
    final deckWidgets = <Widget>[
      // 未抽走的牌
      for (int i = 0; i < _deck.length; i++)
        _buildCard(i, isDrawn: false),
      // 抽出的牌（按顺序往上叠）
      for (int i = 0; i < _drawnCards.length; i++)
        _buildCard(i, isDrawn: true, drawnOrder: i),
    ];

    return Center(
      child: SizedBox(
        width: cardW + 4,
        height: cardW * 1197 / 670 + 260,
        child: Stack(
          alignment: Alignment.center,
          children: deckWidgets,
        ),
      ),
    );
  }

  Widget _buildRevealedCards() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _selectedCardCount <= 2 ? 1 : 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: AppTheme.spacingM,
        mainAxisSpacing: AppTheme.spacingM,
      ),
      itemCount: _drawnCards.length,
      itemBuilder: (context, index) {
        final card = _drawnCards[index];
        return TarotCardWidget(
          card: card,
          isRevealed: true,
          showDetails: true,
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // シャッフル / カット / カードを引く 按钮
            if (_currentState == CardDrawState.initial)
              Expanded(
                child: ElevatedButton(
                  onPressed: _onShuffle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('シャッフル'),
                ),
              ),
            
            if (_currentState == CardDrawState.cutting)
              Expanded(
                child: ElevatedButton(
                  onPressed: _onCut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('カット'),
                ),
              ),
            
            if (_currentState == CardDrawState.drawing)
              Expanded(
                child: ElevatedButton(
                  onPressed: _drawnCards.length < _selectedCardCount ? _onDraw : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('カードを引く'),
                ),
              ),
            
            // 重置按钮
            if (_currentState == CardDrawState.revealed) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('もう一度'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 