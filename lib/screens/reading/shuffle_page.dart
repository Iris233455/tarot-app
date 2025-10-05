import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/services/card_back_service.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'dart:math';
import 'dart:ui' as ui show lerpDouble;

// 抽牌流程状态
enum ShuffleState { initial, shuffling, cutting, drawing, revealed }

// 抽牌阶段方案（仅保留4-1）
enum DrawingScheme { s4_1CarouselTap }

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
  late AnimationController _fanController;     // 扇形展开
  late AnimationController _flipController;    // 抽中单卡翻转
  
  // 动画
  late Animation<double> _scaleAnimation;
  late Animation<double> _cutAnimation;
  late Animation<Offset> _drawAnimation;

  // --- Wheel deck (半円ホイール) ---
  double _wheelAngle = 0;        // radians
  final double _wheelRadius = 220; // px

  // 扇形与抽取辅助
  bool _fanOpened = false;
  TarotCard? _recentPickedCard;
  bool _isFlipping = false;
  Future<String>? _backUrlFuture;
  bool _autoStarted = false;
  DrawingScheme _drawingScheme = DrawingScheme.s4_1CarouselTap;
  int _carouselIndex = 0;
  int _wheelSelectedIdx = -1;
  ScrollController _carouselController = ScrollController();
  bool _carouselLoopInited = false;
  
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
      // 统一使用全牌库（78张），不再按类型过滤
      final List<TarotCard> selectedCards = allCards;
      
      setState(() {
        _allCards = selectedCards;
        _deck = List.from(selectedCards);
        _offsets = List.filled(selectedCards.length, Offset.zero);
        _angles = List.filled(selectedCards.length, 0.0);
        _backUrlFuture = CardBackService.getCurrentBackImageUrl();
      });
      // 自动开始洗牌 -> 切牌 -> 展开，直接进入可抽取状态
      _autoStartAfterLoad();
    } catch (e) {
      print('カード読み込みエラー: $e');
    }
  }

  void _autoStartAfterLoad() {
    if (_autoStarted) return;
    if (!mounted) return;
    if (_allCards.isEmpty) return;
    _autoStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentState == ShuffleState.initial) {
        _onShuffle();
      }
    });
  }
  
  void _initializeAnimations() {
    // 取消所有动画控制器，仅保留占位，避免引用报错
    _shuffleController = AnimationController(duration: const Duration(milliseconds: 1), vsync: this);
    _cutController = AnimationController(duration: const Duration(milliseconds: 1), vsync: this);
    _drawController = AnimationController(duration: const Duration(milliseconds: 1), vsync: this);
    _fanController = AnimationController(duration: const Duration(milliseconds: 1), vsync: this);
    _flipController = AnimationController(duration: const Duration(milliseconds: 1), vsync: this);
    _scaleAnimation = AlwaysStoppedAnimation(1.0);
    _cutAnimation = AlwaysStoppedAnimation(0.0);
    _drawAnimation = AlwaysStoppedAnimation(Offset.zero);
  }

  void _resetDrawingState() {
    setState(() {
      _deck = List.from(_allCards);
      _drawnCards.clear();
      _cardOrientations.clear();
      _wheelAngle = 0;
      _carouselIndex = 0;
      _carouselController = ScrollController();
      _carouselLoopInited = false;
    });
  }

  void _setDrawingScheme(DrawingScheme scheme) {
    setState(() {
      _drawingScheme = scheme;
    });
    _resetDrawingState();
  }

  Future<void> _onPickNext() async {
    if (_deck.isEmpty) return;
    final picked = _deck.removeAt(0);
    final orientation = _random.nextBool();
    setState(() {
      _recentPickedCard = picked;
      _drawnCards.add(picked);
      _cardOrientations.add(orientation);
    });
    HapticFeedback.selectionClick();
    if (_drawnCards.length >= _getCardCount()) {
      await Future.delayed(const Duration(milliseconds: 150));
      await _finalizeDraw();
    }
  }

  Future<void> _pickDeckIndex(int deckIndex) async {
    if (_deck.isEmpty) return;
    if (deckIndex < 0 || deckIndex >= _deck.length) return;
    final picked = _deck.removeAt(deckIndex);
    final orientation = _random.nextBool();
    setState(() {
      _recentPickedCard = picked;
      _drawnCards.add(picked);
      _cardOrientations.add(orientation);
      if (_deck.isEmpty) {
        _carouselIndex = 0;
      } else {
        _carouselIndex = _carouselIndex % _deck.length;
      }
    });
    HapticFeedback.selectionClick();
    if (_drawnCards.length >= _getCardCount()) {
      await Future.delayed(const Duration(milliseconds: 150));
      await _finalizeDraw();
    }
  }
  
  @override
  void dispose() {
    _shuffleController.dispose();
    _cutController.dispose();
    _drawController.dispose();
    _fanController.dispose();
    _flipController.dispose();
    _carouselController.dispose();
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
    final strings = ref.read(appStringsProvider);
    switch (_currentState) {
      case ShuffleState.initial:
        return strings.readingPreparing;
      case ShuffleState.shuffling:
        return strings.readingShuffling;
      case ShuffleState.cutting:
        return strings.readingCutting;
      case ShuffleState.drawing:
        return strings.readingDrawing;
      case ShuffleState.revealed:
        return strings.readingResultTitle;
      default:
        return strings.readingPreparing;
    }
  }

  String _getSubtitle() {
    final strings = ref.read(appStringsProvider);
    switch (_currentState) {
      case ShuffleState.initial:
        return strings.readingPreparing;
      case ShuffleState.shuffling:
        return strings.readingShuffling;
      case ShuffleState.cutting:
        return strings.readingCutting;
      case ShuffleState.drawing:
        return strings.readingDrawing;
      case ShuffleState.revealed:
        return strings.readingComplete;
      default:
        return strings.readingPreparing;
    }
  }

  String _getButtonText() {
    final strings = ref.read(appStringsProvider);
    switch (_currentState) {
      case ShuffleState.initial:
        return strings.buttonShuffle;
      case ShuffleState.shuffling:
      case ShuffleState.cutting:
        return strings.readingShuffling;
      case ShuffleState.revealed:
        return strings.buttonSeeResult;
      default:
        return strings.buttonShuffle;
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
        _random.nextDouble() * 240 - 120, // 更大位移（横向）
        _random.nextDouble() * 160 - 80,   // 更大位移（纵向）
      );
      _angles[i] = _random.nextDouble() * 0.6 - 0.3; // 更明显旋转
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
    // 直接进入抽牌阶段（取消洗牌动画）
    _shuffleDeck();
    if (!mounted) return;
    setState(() {
      _currentState = ShuffleState.drawing;
      _fanOpened = false;
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
      
      final readingResult = await ref.read(performReadingProvider({
        'type': readingType,
        'question': question,
        'cards': _drawnCards,
        'orientations': _cardOrientations,
      }).future);
      // 写入全局结果，供結果ページ读取
      ref.read(readingResultProvider.notifier).state = readingResult;
      
      if (mounted) {
        context.go('/reading/result');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ref.read(appStringsProvider).errorDrawFailed}: $e')),
        );
      }
    }
  }

  // 选中扇形中的某张牌
  Future<void> _handlePick(int fanIndex) async {
    if (_currentState != ShuffleState.drawing) return;
    if (fanIndex < 0 || fanIndex >= _deck.length) return;

    final card = _deck.removeAt(fanIndex);
    final orientation = _random.nextBool();

    setState(() {
      _recentPickedCard = card;
      _isFlipping = true;
      _drawnCards.add(card);
      _cardOrientations.add(orientation);
    });

    HapticFeedback.selectionClick();
    await _flipController.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _isFlipping = false;
    });

    if (_drawnCards.length >= _getCardCount()) {
      await Future.delayed(const Duration(milliseconds: 150));
      await _finalizeDraw();
    }
  }

  // 完成抽牌并进入结果
  Future<void> _finalizeDraw() async {
    setState(() {
      _currentState = ShuffleState.revealed;
    });
    try {
      final readingType = ref.read(readingFormatProvider);
      final question = ref.read(readingQuestionProvider);
      final readingResult = await ref.read(performReadingProvider({
        'type': readingType,
        'question': question,
        'cards': _drawnCards,
        'orientations': _cardOrientations,
      }).future);
      // 写入全局结果，供結果ページ读取
      ref.read(readingResultProvider.notifier).state = readingResult;
      if (mounted) {
        context.go('/reading/result');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ref.read(appStringsProvider).errorDrawFailed}: $e')),
        );
      }
    }
  }

  // 半円ホイール型デッキ（底部に半円を表示し、横ドラッグで回転・上にドラッグで取り出し）
  Widget _buildWheelDeck() {
    // 最大表示枚数（パフォーマンスと密度のバランス）
    final count = _deck.length.clamp(0, 24);
    if (count == 0) return const SizedBox(height: 260);

    // 角度間隔（半円）
    final double step = pi / (count == 1 ? 1 : (count - 1));

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 上部の不可視 DragTarget：ここにドロップされたらカードを取り出す
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 140, // 上2/3を受け取り領域にする
            child: DragTarget<int>(
              onAccept: (fanIndex) async {
                await _handlePick(fanIndex);
              },
              builder: (context, candidate, rejected) => const SizedBox.expand(),
            ),
          ),

          // ホイール本体（横ドラッグで回転）
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  // X移動に応じて回転（感度は0.006ラジアン/px程度）
                  _wheelAngle += details.delta.dx * 0.006;
                });
              },
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: List.generate(count, (i) {
                  // 角度：-π .. 0 の半円を基準に、_wheelAngle をオフセット
                  final double a = (-pi) + (i * step) + _wheelAngle;
                  final double dx = _wheelRadius * cos(a);
                  final double dy = _wheelRadius * sin(a); // 負の値で上方向

                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Draggable<int>(
                      data: i,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _buildCardBackWidget(),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _buildCardBackWidget(),
                      ),
                      // ドラッグキャンセル時は何もしない（DragTargetに受理されなければ戻る）
                      onDragEnd: (_) {},
                      child: _buildCardBackWidget(),
                    ),
                  );
                }),
              ),
            ),
          ),

          // 下部ガイドテキスト（絵文字なし）
          const Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Text(
              '左右にドラッグして選択 / 上方向にドラッグで取り出し',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: DynamicTokens.textBlack87),
            ),
          ),
        ],
      ),
    );
  }

  // 构建牌组显示
  Widget _buildDeckArea() {
    if (_currentState == ShuffleState.drawing) {
      return _buildDrawingNew();
    }

    final displayCount = min(_deck.length, 18);
    // 方案B：桌面滑推切叠（3秒时间线）
    // 取消洗牌阶段动画：静态堆叠
    if (_currentState == ShuffleState.shuffling) {
      return SizedBox(
        width: 220,
        height: 320,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(displayCount, (i) => Positioned(
            left: i * 2.0,
            top: i * 2.0,
            child: _buildCardBackWidget(),
          )),
        ),
      );
    }

    return Container(
      width: 220,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * 2.0,
              top: i * 2.0,
              child: _buildSingleCard(i),
            ),
          if (_currentState == ShuffleState.drawing && _drawnCards.isNotEmpty)
            ..._buildDrawnCards(),
        ],
      ),
    );
  }

  // 新方案：竖屏友好「上方槽位 + 下方牌堆（上滑抽取）」
  Widget _buildDrawingNew() {
    final cardCount = _getCardCount();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double slotWidth = min(140, constraints.maxWidth / (cardCount == 1 ? 1.6 : cardCount + 0.6));
        final double slotHeight = slotWidth * 1.5;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 槽位区域
            SizedBox(
              height: slotHeight + 32,
              child: Row(
                mainAxisAlignment: cardCount == 1
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceEvenly,
                children: List.generate(cardCount, (i) => _buildSlotTarget(i, slotWidth, slotHeight)),
              ),
            ),
            const SizedBox(height: 16),
            // 中部：根据方案渲染交互区域
            _buildDrawingByScheme(slotWidth, slotHeight, constraints.maxWidth),
          ],
        );
      },
    );
  }

  // 仅保留方案4-1
  Widget _buildDrawingByScheme(double w, double h, double maxW) {
    return _buildCarouselTap(w, h, maxW);
  }

  // 方案4-1：水平轮播（支持全量，点击或长按拖拽取牌）
  Widget _buildCarouselTap(double w, double h, double maxW) {
    final total = _deck.length;
    if (total == 0) return SizedBox(height: h + 60);
    final itemW = w * 0.9;
    return SizedBox(
      height: h + 60,
      child: SizedBox(
        height: h,
        width: maxW,
        child: ListView.builder(
          controller: _carouselController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          primary: false,
          itemCount: total,
          itemBuilder: (context, i) {
            final idx = (_carouselIndex + i) % total;
            final cardChild = Container(
              width: itemW,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildCardBackDecor(rounded: false, fit: BoxFit.contain),
            );
            return LongPressDraggable<int>(
              data: idx,
              feedback: Material(color: Colors.transparent, child: cardChild),
              childWhenDragging: Opacity(opacity: 0.35, child: cardChild),
              dragAnchorStrategy: pointerDragAnchorStrategy,
              child: GestureDetector(onTap: () => _pickDeckIndex(idx), child: cardChild),
            );
          },
        ),
      ),
    );
  }

  //（已移除方案4-2）

  // 方案5：上滑区域（手势上滑取牌）
  Widget _buildSwipeUpZone(double w, double h) {
    final double scale = 0.8;
    final double sw = w * scale;
    final double sh = h * scale;
    return SizedBox(
      height: sh + 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 指示条
          Positioned(
            top: 8,
            child: Text(ref.read(appStringsProvider).hintSwipeUpToPick, style: const TextStyle(fontSize: 12, color: DynamicTokens.textBlack87)),
          ),
          // 顶牌区域
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onVerticalDragEnd: (_) => _onPickNext(),
              child: SizedBox(width: sw, height: sh, child: _buildCardBackDecor()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotTarget(int index, double w, double h) {
    final hasCard = index < _drawnCards.length;
    final card = hasCard ? _drawnCards[index] : null;
    final isUpright = hasCard ? _cardOrientations[index] : true;
    final labels = _getCardLabels();
    final label = index < labels.length ? labels[index] : '';

    final double areaW = w * 0.8;
    final double areaH = h * 0.8;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              width: areaW,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DynamicTokens.textBlack87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        DragTarget<int>(
          onWillAccept: (data) {
            // 仅允许当前应放入的槽位接收
            return _drawnCards.length == index;
          },
          onAccept: (dragIdx) async {
            if (_deck.isEmpty) return;
            final int removeIndex = (dragIdx < 0 || dragIdx >= _deck.length) ? 0 : dragIdx;
            final picked = _deck.removeAt(removeIndex);
            final orientation = _random.nextBool();
            setState(() {
              _recentPickedCard = picked;
              _drawnCards.add(picked);
              _cardOrientations.add(orientation);
            });
            HapticFeedback.selectionClick();
            // 抽满自动结束
            if (_drawnCards.length >= _getCardCount()) {
              await Future.delayed(const Duration(milliseconds: 180));
              await _finalizeDraw();
            }
          },
          builder: (context, candidate, rejected) {
            return Container(
              width: areaW,
              height: areaH,
              decoration: BoxDecoration(
                // 空槽位填充主题色16%；已放置卡片则透明
                color: hasCard
                    ? Colors.transparent
                    : ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: w,
                  height: h,
                  child: hasCard
                      ? Transform(
                          transform: Matrix4.identity()..rotateZ(isUpright ? 0 : 3.14159),
                          alignment: Alignment.center,
                          child: Image.asset(card!.imageUrl, fit: BoxFit.contain),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomDraggableDeck(double w, double h) {
    // 顶牌可拖动到上方槽位；未接受则回位
    final double scale = 0.8;
    final double sw = w * scale;
    final double sh = h * scale;
    return SizedBox(
      height: sh + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景堆叠（静态装饰）
          ...List.generate(min(6, _deck.length), (i) {
            return Positioned(
              top: 20 + i * 3.0,
              child: Opacity(
                opacity: 0.9 - i * 0.1,
                child: SizedBox(width: sw, height: sh, child: _buildCardBackDecor()),
              ),
            );
          }),
          if (_deck.isNotEmpty)
            Draggable<int>(
              data: 0,
              feedback: Material(color: Colors.transparent, child: SizedBox(width: sw, height: sh, child: _buildCardBackDecor())),
              childWhenDragging: Opacity(opacity: 0.0, child: SizedBox(width: sw, height: sh, child: _buildCardBackDecor())),
              onDragEnd: (_) {},
              child: SizedBox(width: sw, height: sh, child: _buildCardBackDecor()),
            ),
          // 提示
          Positioned(
            bottom: 4,
            child: Text(ref.read(appStringsProvider).hintDragToSlot, style: const TextStyle(fontSize: 12, color: DynamicTokens.textBlack87)),
          ),
        ],
      ),
    );
  }

  // 构建单张牌
  Widget _buildSingleCard(int index) {
    // 静态单卡（无动画、无渐变）
    return SizedBox(
      width: 120,
      height: 180,
      child: _buildCardBackWidget(),
    );
  }

  // 新洗牌方案：Riffle + Bridge（左右分叠 → 交错落下 → 桥式回拢）
  (Offset, double, double) _computeRiffleTransform(int index) {
    final double t = _shuffleController.value; // 0..1
    // 分段：0..0.25 分叠；0.25..0.75 交错落下；0.75..1.0 bridge 回拢
    final double splitP = (t / 0.25).clamp(0.0, 1.0);
    final double dropP = ((t - 0.25) / 0.5).clamp(0.0, 1.0);
    final double bridgeP = ((t - 0.75) / 0.25).clamp(0.0, 1.0);

    final int total = _deck.isEmpty ? 1 : _deck.length;
    final int splitIndex = (total / 2).floor();
    final bool isLeft = index < splitIndex;
    final int localOrder = isLeft ? (splitIndex - 1 - index) : (index - splitIndex);

    // 第1段：左右分叠
    final double sign = isLeft ? -1.0 : 1.0;
    double x = sign * ui.lerpDouble(0, 84, splitP)!;
    double y = ui.lerpDouble(0, -10, splitP)!;
    double angle = sign * 0.12 * splitP;
    double scale = ui.lerpDouble(1.0, 1.02, splitP)!;

    // 第2段：交错回落到中心（按索引错峰）
    final double stagger = localOrder * 0.03; // 交错延迟
    final double localDrop = ((dropP - stagger) / 0.25).clamp(0.0, 1.0);
    x = ui.lerpDouble(x, 0, localDrop)!;
    y = ui.lerpDouble(y, 0, localDrop)!;
    angle = ui.lerpDouble(angle, 0, localDrop)!;
    scale = ui.lerpDouble(scale, 1.0, localDrop)!;

    // 第3段：Bridge 弧形回拢（轻微上拱之后归位）
    if (bridgeP > 0) {
      final double bridgeY = -22 * sin(bridgeP * pi);
      y += bridgeY * (1.0 - localDrop);
    }

    return (Offset(x, y), angle, scale);
  }

  // 方案B（倒数第三版）：桌面滑推切叠（无8字轨迹、无底部对齐，固定卡片尺寸）
  Widget _buildSlideCutCard(int index, double t, double cardW, double cardH, double toBottomDeltaY) {
    // 时间线分段：0..0.33 分叠水平滑推；0.33..0.67 回中交错对齐；0.67..1.0 轻微压叠
    final double splitP = (t / 0.33).clamp(0.0, 1.0);
    final double alignP = ((t - 0.33) / 0.34).clamp(0.0, 1.0);
    final double stackP = ((t - 0.67) / 0.33).clamp(0.0, 1.0);

    final int total = _deck.isEmpty ? 1 : _deck.length;
    final int mid = (total / 2).floor();
    final bool isLeft = index < mid;
    final int localOrder = isLeft ? (mid - 1 - index) : (index - mid);

    // 固定卡片尺寸（该版本未与抽牌槽对齐尺寸）
    const double w = 120;
    const double h = 180;

    double dx = 0.0;
    double dy = 0.0;
    double ang = 0.0;
    double scale = 1.0;

    // 1) 左右水平滑推（轻微上抬与旋转）
    if (splitP > 0) {
      final double s = Curves.easeOut.transform(splitP);
      final double sign = isLeft ? -1.0 : 1.0;
      dx = sign * ui.lerpDouble(0, w * 0.7, s)!;
      dy = ui.lerpDouble(0, -h * 0.06, s)!;
      ang = sign * 0.10 * s;
      scale = ui.lerpDouble(1.0, 1.02, s)!;
    }

    // 2) 回中并交错对齐（按索引错峰）
    if (alignP > 0) {
      final double stagger = localOrder * 0.03;
      final double p = Curves.easeInOut.transform(((alignP - stagger) / 0.6).clamp(0.0, 1.0));
      dx = ui.lerpDouble(dx, 0, p)!;
      dy = ui.lerpDouble(dy, 0, p)!;
      ang = ui.lerpDouble(ang, 0, p)!;
      scale = ui.lerpDouble(scale, 1.0, p)!;
    }

    // 3) 轻微压叠（制造层叠质感）
    if (stackP > 0) {
      final double p = Curves.easeOut.transform(stackP);
      final double layer = (index % 6) * 1.5;
      dx = ui.lerpDouble(dx, layer, p)!;
      dy = ui.lerpDouble(dy, layer, p)!;
      scale = ui.lerpDouble(scale, 0.985, p)!;
    }

    // 该版不进行整体下移到底部牌堆中心（无 toBottomDeltaY 应用）
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: ang,
        child: Transform.scale(
          scale: scale,
          child: SizedBox(
            width: w,
            height: h,
            child: _buildCardBackDecor(),
          ),
        ),
      ),
    );
  }

  // 方案C：扇面重排切叠（展开→交错折叠→压回），结束落位到底部牌堆中心
  Widget _buildFanReshuffleCard(
    int index,
    double t,
    double cardW,
    double cardH,
    double toBottomDeltaY,
    int displayCount,
  ) {
    // 时间线：0..0.45 扇面展开；0.45..0.8 交错折叠归中；0.8..1.0 压回堆叠并下移到抽牌位置
    final double fanP = (t / 0.45).clamp(0.0, 1.0);
    final double foldP = ((t - 0.45) / 0.35).clamp(0.0, 1.0);
    final double stackP = ((t - 0.8) / 0.2).clamp(0.0, 1.0);

    // 扇形角度与半径
    final double slot = displayCount <= 1 ? 0.5 : index / (displayCount - 1);
    final double baseAngle = ui.lerpDouble(-0.55, 0.55, slot)! * Curves.easeOutCubic.transform(fanP);
    final double baseRadius = ui.lerpDouble(0, max(cardW, 140), Curves.easeOutBack.transform(fanP))!;

    // 展开位移
    double dx = baseRadius * sin(baseAngle);
    double dy = -baseRadius * (1 - cos(baseAngle)) * 0.6; // 轻微上抬弧度
    double ang = baseAngle * 0.9;
    double scale = 1.0;

    // 折叠归中（交错延迟）
    if (foldP > 0) {
      final double stagger = (index % 6) * 0.05;
      final double p = Curves.easeInOut.transform((foldP - stagger).clamp(0.0, 1.0));
      dx = ui.lerpDouble(dx, 0, p)!;
      dy = ui.lerpDouble(dy, 0, p)!;
      ang = ui.lerpDouble(ang, 0, p)!;
      scale = ui.lerpDouble(1.0, 1.02, p)!;
    }

    // 压回堆叠并整体下移到底部牌堆中心（终点与抽牌位置一致）
    if (stackP > 0) {
      final double p = Curves.easeOut.transform(stackP);
      final double layerBias = ((index % 3) - 1) * 0.01; // -0.01, 0, +0.01
      scale = ui.lerpDouble(scale, 0.98 + layerBias, p)!;
      dy += ui.lerpDouble(0, 4.0, p)!; // 轻压
    }

    final double finalDy = dy + ui.lerpDouble(0, toBottomDeltaY, Curves.easeInOut.transform(t))!;

    return Transform.translate(
      offset: Offset(dx, finalDy),
      child: Transform.rotate(
        angle: ang,
        child: Transform.scale(
          scale: scale,
          child: SizedBox(
            width: cardW,
            height: cardH,
            child: _buildCardBackDecor(),
          ),
        ),
      ),
    );
  }

  // 构建抽出的牌
  List<Widget> _buildDrawnCards() {
    final labels = _getCardLabels();
    return _drawnCards.asMap().entries.map((entry) {
      final index = entry.key;
      final card = entry.value;
      final label = index < labels.length ? labels[index] : '';
      
      return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ref.read(dynamicTokensProvider).surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: DynamicTokens.textBlack87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(width: 120, height: 180, child: _buildCardBackWidget()),
              ],
      );
    }).toList();
  }

  // 构建控制按钮（“シャッフル”→自动カット→抽牌阶段隐藏按钮；抽满后自动跳转）
  Widget _buildControlButton() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final isEnabled = _currentState != ShuffleState.shuffling && _allCards.isNotEmpty;
    if (_currentState == ShuffleState.drawing) {
      // 抽牌阶段不显示按钮，达到上限自动结束
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? () {
          switch (_currentState) {
            case ShuffleState.initial:
              _onShuffle();
              break;
            default:
              break;
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: dynamicTokens.primaryColor,
          foregroundColor: DynamicTokens.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DynamicTokens.radiusLg),
          ),
          elevation: 0,
        ),
        child: Text(
          _getButtonText(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
          // 标题（无页面入场动画）
          Text(
              _getTitle(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: DynamicTokens.spacingSm),
          
          const SizedBox(height: DynamicTokens.spacingMd),
          
          // 牌组区域（无页面入场动画）
          Expanded(
            child: Center(
                child: _buildDeckArea(),
            ),
          ),
          
          // 控制按钮（无页面入场动画）
          _buildControlButton(),
          
          const SizedBox(height: DynamicTokens.spacingLg),
        ],
      ),
    );
  }
}

// 扇形展开区域
extension _FanDeck on _ShufflePageState {
  Widget _buildFanDeck() {
    final count = min(_deck.length, 18);
    if (count == 0) {
      return const SizedBox(width: 320, height: 220);
    }
    return SizedBox(
      width: 360,
      height: 240,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(count, (i) {
          final t = count == 1 ? 0.5 : i / (count - 1);
          final progress = _fanOpened ? Curves.easeOutBack.transform(_fanController.value) : 0.0;
          final angle = (ui.lerpDouble(-0.50, 0.50, t)! ) * progress; // 扇形更大
          final dx = ui.lerpDouble(-160, 160, t)! * progress;        // 水平更宽
          final dy = -16.0 * progress;                                // 轻微上抬
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: GestureDetector(
                onTap: () => _handlePick(i),
                child: _buildCardBackWidget(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCardBackWidget() {
    return FutureBuilder<String>(
      future: _backUrlFuture,
      builder: (context, snapshot) {
        final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
        return _buildCardBackDecor(backUrl: backUrl);
      },
    );
  }

  Widget _buildCardBackDecor({String? backUrl, bool rounded = true, BoxFit fit = BoxFit.cover}) {
    // 简化卡背：仅显示图片；可选倒角与适配方式
    final image = backUrl != null
        ? Image.asset(backUrl, fit: fit)
        : FutureBuilder<String>(
            future: _backUrlFuture,
            builder: (context, snapshot) {
              final url = snapshot.data ?? 'assets/images/tarot/cat/back.png';
              return Image.asset(url, fit: fit);
            },
          );
    if (!rounded) return image;
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: image);
  }

  Widget _buildFlipPreview(TarotCard card) {
    return SizedBox(
      width: 120,
      height: 180,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, _) {
          final v = _flipController.value * pi; // 0..pi
          final showBack = v < (pi / 2);
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(v);
          return Transform(
            transform: m,
            alignment: Alignment.center,
            child: showBack
                ? _buildCardBackWidget()
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(card.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DynamicTokens.textWhite.withOpacity(0.1)
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

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashLength = 6,
    this.dashGap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 画虚线边框：沿矩形四边分段绘制
    void drawDashedLine(Offset start, Offset end) {
      final double totalLength = (end - start).distance;
      final int dashCount = (totalLength / (dashLength + dashGap)).floor();
      final Offset direction = (end - start) / totalLength;
      Offset current = start;
      for (int i = 0; i < dashCount; i++) {
        final Offset next = current + direction * dashLength;
        canvas.drawLine(current, next, paint);
        current = next + direction * dashGap;
      }
      // 尾段
      if ((end - current).distance > 0) {
        final Offset tail = (current + direction * dashLength).dx.isNaN ? end : current + direction * dashLength;
        canvas.drawLine(current, tail.dx.isNaN ? end : tail, paint);
      }
    }

    final Rect r = Rect.fromLTWH(0, 0, size.width, size.height);
    drawDashedLine(r.topLeft, r.topRight);
    drawDashedLine(r.topRight, r.bottomRight);
    drawDashedLine(r.bottomRight, r.bottomLeft);
    drawDashedLine(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        dashGap != oldDelegate.dashGap;
  }
}