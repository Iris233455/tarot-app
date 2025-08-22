import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/providers/daily_card_provider.dart';
import 'package:mystic_tarot_jp/widgets/calendar_list.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/services/card_back_service.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/widgets/themed_background.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/models/daily_card_info.dart'; // 导入新模型文件
import 'package:mystic_tarot_jp/providers/ai_reading_provider.dart';
import 'package:mystic_tarot_jp/widgets/ai_reading_widget.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final cardSize = screenSize.width * 0.8; // 将宽度比例从0.4增加到0.8
    const maxCardHeight = 450.0; // 将最大高度从280增加到450
    final heroCardHeight = cardSize > maxCardHeight ? maxCardHeight : cardSize;
    final dailyCardState = ref.watch(dailyCardProvider);
    final isOfflineMode = DataService.isOfflineMode;
    final now = DateTime.now();

    final dynamicTokens = ref.watch(dynamicTokensProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemedBackground(
        child: SingleChildScrollView(
          child: Column(
          children: [
            // 状态栏空间
            const SizedBox(height: 60),
            
            // 离线模式提示
            if (isOfflineMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dynamicTokens.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dynamicTokens.primaryColor.withOpacity(0.22)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: dynamicTokens.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '離線模式 - 正在使用本地データ',
                        style: TextStyle(
                          color: dynamicTokens.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // 尝试重新连接
                        ref.refresh(dailyCardProvider);
                      },
                      child: Text(
                        '再接続',
                        style: TextStyle(color: dynamicTokens.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _ConstellationDivider(),
                const SizedBox(width: 16),
                Text(
                  '本日のカード',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Noto Serif JP',
                    color: dynamicTokens.primaryColor,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.8),
                        offset: const Offset(0, 0),
                        blurRadius: 2,
                      ),
                      Shadow(
                        color: dynamicTokens.primaryColor.withOpacity(0.5),
                        offset: const Offset(1, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const _ConstellationDivider(isReversed: true),
              ],
            ),

            const SizedBox(height: 20),
            
            // 今日的卡片部分
            _HomeDailyCard(
              dailyCardState: dailyCardState,
              heroCardHeight: heroCardHeight,
              ref: ref,
            ),
            
            const SizedBox(height: 20),
            
            // 今日のメッセージ（抽牌后自动生成并显示）
            if (dailyCardState.hasDrawnToday && dailyCardState.card != null)
              _TodayAISection(
                card: dailyCardState.card!,
                isUpright: dailyCardState.isUpright,
              ),
            
            const SizedBox(height: 40),
            
            // 日历标题
            Text(
              'タロットカレンダー',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: dynamicTokens.textPrimary,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 日历（添加背景框包装，自适应高度）
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
                    // 有背景图的主题：使用高透明度白色背景
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.90),
                  ] : [
                    // 纯色背景主题：保持原来的surface颜色
                    dynamicTokens.surfaceColor.withOpacity(0.8),
                    dynamicTokens.surfaceColor.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
                    ? dynamicTokens.primaryColor.withOpacity(0.6)
                    : dynamicTokens.primaryColor.withOpacity(0.2),
                  width: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Consumer(
                  builder: (context, ref, child) {
                    final now = DateTime.now();
                    final monthlyCardsAsync = ref.watch(monthlyCardsProvider(
                      MonthlyCardParams(now.year, now.month),
                    ));

                    return monthlyCardsAsync.when(
                      data: (cardMap) => MonthCalendar(
                        cardMap: cardMap,
                        onDayTap: (date) => _onCalendarDayTap(context, ref, date, cardMap),
                        onMonthChanged: (_) {},
                      ),
                      loading: () => SizedBox(
                        height: 280,
                        child: Center(
                          child: Icon(Icons.auto_awesome, size: 40, color: dynamicTokens.primaryColor.withOpacity(0.35)),
                        ),
                      ),
                      error: (error, stack) => SizedBox(
                        height: 280,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.error, color: Colors.red, size: 48),
                              SizedBox(height: 12),
                              Text('データの読み込みに失敗しました', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final dynamicTokens = ref.watch(dynamicTokensProvider);
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            selectedItemColor: dynamicTokens.primaryColor,
            unselectedItemColor: dynamicTokens.textSecondary,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/reading');
                  break;
                case 2:
                  context.go('/gallery');
                  break;
                case 3:
                  context.go('/mydeck');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '毎日の占い',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome),
                label: 'スプレット',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: 'ギャラリー',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.style),
                label: 'マイページ',
              ),
            ],
          );
        },
      ),
    );
  }

  void _onCalendarDayTap(BuildContext context, WidgetRef ref, DateTime date,
      Map<DateTime, DailyCardInfo?> cardMap) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tapped = DateTime(date.year, date.month, date.day);

    if (tapped.isAfter(today)) {
      // 未来
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text('その日までお待ちください'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('了解')),
          ],
        ),
      );
      return;
    }

    final cardInfo = cardMap[tapped];
    if (cardInfo == null) {
      // 没抽牌
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text('履歴はありません'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('了解')),
          ],
        ),
      );
      return;
    }

    // 有抽牌，显示牌意，现在数据是完整的
    _showCardDetail(context, cardInfo.card, cardInfo.isUpright);
  }
}

// 新增：大牌区的抽牌逻辑和动画
class _HomeDailyCard extends StatefulWidget {
  final double heroCardHeight;
  final DailyCardState dailyCardState;
  final WidgetRef ref;

  const _HomeDailyCard({
    required this.heroCardHeight,
    required this.dailyCardState,
    required this.ref,
  });

  @override
  State<_HomeDailyCard> createState() => _HomeDailyCardState();
}

class _HomeDailyCardState extends State<_HomeDailyCard> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _shakeController;
  late Animation<double> _flipAnimation;
  late Animation<double> _shakeAnimation;
  bool _isLongPressing = false;
  bool _cardDrawn = false;

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
    
    // 如果已经抽过牌，直接显示正面
    if (widget.dailyCardState.hasDrawnToday) {
      _flipController.value = 1.0;
      _cardDrawn = true;
    }
  }
  
  @override
  void didUpdateWidget(_HomeDailyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当今日卡片状态改变时，更新动画状态
    if (oldWidget.dailyCardState.hasDrawnToday != widget.dailyCardState.hasDrawnToday) {
      if (widget.dailyCardState.hasDrawnToday) {
        _flipController.forward();
        _cardDrawn = true;
      } else {
        _flipController.reset();
        _cardDrawn = false;
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onLongPressStart() {
    if (_cardDrawn || widget.dailyCardState.hasDrawnToday) return;
    
    setState(() {
      _isLongPressing = true;
    });
    _shakeController.forward();
  }

  Future<void> _onLongPressEnd() async {
    if (_cardDrawn || widget.dailyCardState.hasDrawnToday) return;
    
    setState(() {
      _isLongPressing = false;
    });
    
    // 如果长按时间够长，执行抽牌
    if (_shakeController.value > 0.7) {
      await _drawCard();
    } else {
      _shakeController.reverse();
    }
  }
  
  Future<void> _drawCard() async {
    setState(() {
      _cardDrawn = true;
    });
    
    try {
      // 执行抽牌
      await widget.ref.read(dailyCardProvider.notifier).drawTodayCard();
      
      // 翻牌动画
      await _flipController.forward();
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('本日のカードを引きました！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 等待一下然后显示详情
        await Future.delayed(const Duration(milliseconds: 1000));
        final currentState = widget.ref.read(dailyCardProvider);
        if (currentState.card != null && mounted) {
          _showCardDetail(context, currentState.card!, currentState.isUpright);
        }
      }
    } catch (e) {
      setState(() {
        _cardDrawn = false;
      });
      _shakeController.reverse();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('抽牌失敗: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.heroCardHeight,
      child: widget.dailyCardState.isLoading
          ? Center(
              child: Container(
                width: widget.heroCardHeight * 0.7,
                height: widget.heroCardHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            )
          : widget.dailyCardState.error != null
              ? Center(
                  child: Container(
                    width: widget.heroCardHeight * 0.7,
                    height: widget.heroCardHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'エラーが発生しました',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => widget.ref.refresh(dailyCardProvider),
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Center(
                  child: GestureDetector(
                    onLongPressStart: (_) => _onLongPressStart(),
                    onLongPressEnd: (_) => _onLongPressEnd(),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_flipController, _shakeController]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_shakeAnimation.value * 0.05 * (_isLongPressing ? 1 : 0)),
                          child: Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_flipAnimation.value * 3.14159),
                            alignment: Alignment.center,
                            child: _flipAnimation.value < 0.5
                                ? _buildCardBack()
                                : Transform(
                                    transform: Matrix4.identity()..rotateY(3.14159),
                                    alignment: Alignment.center,
                                    child: _buildCardFront(),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: widget.heroCardHeight * 0.65,
      height: widget.heroCardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder<String>(
              future: CardBackService.getCurrentBackImageUrl(),
              builder: (context, snapshot) {
                final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
                return Image.asset(
                  backUrl,
                  fit: BoxFit.contain,
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.25),
            ),
          ),
          Center(
            child: Text(
              '長押ししてカードを引く',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront() {
    if (widget.dailyCardState.card == null) {
      return Container(
        width: widget.heroCardHeight * 0.65,
        height: widget.heroCardHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showCardDetail(
        context,
        widget.dailyCardState.card!,
        widget.dailyCardState.isUpright,
      ),
      child: Container(
        width: widget.heroCardHeight * 0.65,
        height: widget.heroCardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateZ(widget.dailyCardState.isUpright ? 0 : 3.14159),
            child: Image.asset(
              widget.dailyCardState.card!.imageUrl, // 直接使用imageUrl
              fit: BoxFit.contain, // 修改fit属性
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// 自定义画笔绘制卡片背面图案
class _CardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制同心圆
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (size.width * 0.1) * i, paint);
    }
    
    // 绘制交叉线
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 星座风格的装饰分割线
class _ConstellationDivider extends ConsumerWidget {
  final bool isReversed;
  const _ConstellationDivider({this.isReversed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    return SizedBox(
      width: 40,
      height: 20,
      child: CustomPaint(
        painter: _ConstellationPainter(
          isReversed: isReversed,
          color: dynamicTokens.primaryColor.withOpacity(0.9),
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final bool isReversed;
  final Color color;
  _ConstellationPainter({required this.isReversed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5;

    final starPaint = Paint()..color = color;

    // 定义星星的位置 (0-1范围)
    var points = [
      const Offset(0.1, 0.8),
      const Offset(0.3, 0.2),
      const Offset(0.6, 0.5),
      const Offset(0.8, 0.1),
      const Offset(0.9, 0.9),
    ];

    if (isReversed) {
      points = points.map((p) => Offset(1.0 - p.dx, p.dy)).toList();
    }

    // 绘制星星和连线
    for (int i = 0; i < points.length; i++) {
      final p1 = Offset(points[i].dx * size.width, points[i].dy * size.height);
      canvas.drawCircle(p1, 3.0, starPaint);

      if (i < points.length - 1) {
        final p2 = Offset(
            points[i + 1].dx * size.width, points[i + 1].dy * size.height);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 将_showCardDetail设为顶级函数，并处理异步加载
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



  void _showCardDetail(BuildContext context, TarotCard card, bool isUpright) {
  showDialog(
    context: context,
    builder: (_) {
      // 不再需要FutureBuilder，因为数据已经加载完毕
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
          child: Stack(
            children: [
              // 主要内容
              Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                // 卡片图像 - 根据正逆位旋转
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateZ(isUpright ? 0 : 3.14159), // 逆位时旋转180度
                  child: Image.asset(card.imageUrl, // 直接使用imageUrl
                      fit: BoxFit.contain, // 修改fit属性
                      width: 120,
                      height: 180),
                ),
                const SizedBox(height: 16),

                // 卡片名称
                Text(
                  card.nameJa,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.nameEn,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 16),

                // 当前方向指示
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isUpright ? Colors.green : Colors.red).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUpright ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isUpright ? '正位置' : '逆位置',
                    style: TextStyle(
                      color: isUpright ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 故事
                Consumer(builder: (context, ref, _) {
                  final dt = ref.watch(dynamicTokensProvider);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dt.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: dt.primaryColor.withOpacity(0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '物語り',
                          textAlign: TextAlign.left, // 左对齐
                          style: TextStyle(
                            fontWeight: FontWeight.normal, // 不加粗
                            fontSize: 14,
                            color: dt.primaryColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.story,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // 正逆位含义
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isUpright ? Colors.green : Colors.red).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isUpright ? Colors.green : Colors.red).withOpacity(0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUpright ? '正位置' : '逆位置',
                        textAlign: TextAlign.left, // 左对齐
                        style: TextStyle(
                          fontWeight: FontWeight.normal, // 不加粗
                          fontSize: 14,
                          color: (isUpright ? Colors.green : Colors.red).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final meaningText = isUpright
                              ? card.meaningUpright
                              : card.meaningReversed;
                          final parsed = _parseTextContent(meaningText);
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (parsed['content']!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    parsed['content']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                Text(
                                  meaningText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // 移除キーワード标题，直接显示标签
                      Builder(
                        builder: (context) {
                          final keywords = isUpright
                              ? card.uprightKeywordsList
                              : card.reversedKeywordsList;

                          if (keywords.isEmpty) {
                            return const Text(
                              'キーワードデータなし',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: keywords
                                .take(8)
                                .map((keyword) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isUpright ? Colors.green : Colors.red).withOpacity(0.16),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (isUpright ? Colors.green : Colors.red).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        keyword,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isUpright
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
            // 关闭按钮 - 右上角X按钮
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.08),
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    },
  );
}

// 今日のメッセージ表示组件
class _TodayAISection extends ConsumerWidget {
  final TarotCard card;
  final bool isUpright;

  const _TodayAISection({
    required this.card,
    required this.isUpright,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    // auto trigger AI daily reading when idle
    final aiData = ref.watch(aiReadingProvider('daily'));
    if (aiData.state == AIReadingState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _requestDailyAIReading(ref);
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
            // 有背景图的主题：使用高透明度白色背景
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.90),
          ] : [
            // 纯色背景主题：使用主色调的淡色背景
            dynamicTokens.primaryColor.withOpacity(0.15),
            dynamicTokens.primaryColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
            ? dynamicTokens.primaryColor.withOpacity(0.6)
            : dynamicTokens.primaryColor.withOpacity(0.35),
          width: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.auto_stories, color: dynamicTokens.primaryColor.withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                '今日のメッセージ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
                    ? dynamicTokens.primaryColor
                    : dynamicTokens.primaryColor.withOpacity(0.8),
                ),
              ),
              const Spacer(),
              // 右侧显示牌名 + 正逆位，提升语境
              Consumer(
                builder: (context, ref, child) {
                  final dynamicTokens = ref.watch(dynamicTokensProvider);
                  return Row(
                    children: [
                      Text(card.nameJa, style: TextStyle(
                        fontSize: 12, 
                        color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.grey.shade600 : Colors.grey,
                      )),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isUpright ? Colors.green : Colors.red).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isUpright ? Colors.green : Colors.red, width: 0.8),
                    ),
                    child: Text(
                      isUpright ? '正位置' : '逆位置',
                      style: TextStyle(
                        color: isUpright ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // AI診断の結果表示（紧凑样式 + 无边框）
          const AIReadingWidget(readingType: 'daily', compact: true),
        ],
      ),
    );
  }
  
  /// 毎日のAI解読をリクエスト
  Future<void> _requestDailyAIReading(WidgetRef ref) async {
    final aiNotifier = ref.read(aiReadingProvider('daily').notifier);
    
    // 実際のユーザー情報を取得（優先順位: name > openid > userid > email前缀 > デフォルト）
    String userName = 'あなた';
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
    };

    try {
      await aiNotifier.getDailyReading(
        card: card,
        isUpright: isUpright,
        userInfo: userInfo,
      );
    } catch (e) {
      // エラーハンドリングは AIReadingWidget で行われる
    }
  }
}