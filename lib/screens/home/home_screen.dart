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
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:mystic_tarot_jp/widgets/app_tag.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mystic_tarot_jp/core/ui/app_logo.dart';

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
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 2,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        backgroundColor: dynamicTokens.backgroundColor,
        title: const AppLogo(size: 36),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? dynamicTokens.primaryColor.withOpacity(0.6)
              : dynamicTokens.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      body: ThemedBackground(
        child: SingleChildScrollView(
          child: Column(
          children: [
            // 统一与其他页面一致的顶部间距
            const SizedBox(height: 20),
            
            // 离线模式提示
            if (isOfflineMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dynamicTokens.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dynamicTokens.primaryColor.withOpacity(0.22)),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.wifiOff, color: dynamicTokens.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${strings.labelOfflineMode} - ${strings.messageOfflineModeDescription}',
                        style: TextStyle(
                          color: DynamicTokens.textBlack87,
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
                        strings.buttonRetry,
                        style: TextStyle(color: DynamicTokens.textBlack87),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // 本日のカード模块（带底框，去掉两侧装饰icon）
            Container(
              margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
                    DesignTokens.surfaceColor.withOpacity(0.95),
                    DesignTokens.surfaceColor.withOpacity(0.90),
                  ] : [
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    strings.homeDailyCard,
                    style: TextStyle(
                      fontSize: DynamicTokens.fontSizeHeadlineMedium,
                      fontWeight: DynamicTokens.fontWeightBlack,
                      fontFamily: DynamicTokens.fontFamilyHeadline,
                      color: DynamicTokens.textBlack87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HomeDailyCard(
                    dailyCardState: dailyCardState,
                    heroCardHeight: heroCardHeight,
                    ref: ref,
                  ),
                  if (dailyCardState.hasDrawnToday && dailyCardState.card != null) ...[
                    const SizedBox(height: 12),
                    // 卡名（居中，主色强调）
                    Text(
                      dailyCardState.card!.nameJa,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: DynamicTokens.fontSizeTitleLarge,
                        fontWeight: FontWeight.w600,
                        color: dynamicTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 正/逆位标签（主题色 + overlay）
                    AppTag(
                      dailyCardState.isUpright ? strings.labelUpright : strings.labelReversed,
                      useTheme: true,
                      overlay: true,
                    ),
                  ],
                  SizedBox(height: 8 * 1.6),
                  // 长按提示移动到卡片下方，抽到后隐藏
                  if (!dailyCardState.hasDrawnToday)
                    Text(
                      strings.homeLongPressToDraw,
                      style: TextStyle(
                        color: DynamicTokens.textBlack87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // 抽牌后整合AI解释模块紧随其后
                  if (dailyCardState.hasDrawnToday && dailyCardState.card != null) ...[
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, _) {
                        final ai = ref.watch(aiReadingProvider('daily'));
                        if (ai.state == AIReadingState.idle) {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            await _ensureDailyAIReading(ref, dailyCardState.card!, dailyCardState.isUpright);
                          });
                        }
                        return const AIReadingWidget(readingType: 'daily', compact: true);
                      },
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 今日のメッセージ整合进上方模块展示（此处不再单独渲染）
            
            const SizedBox(height: 40),
            
            // 日历（添加背景框包装，自适应高度；标题内置模块内部）
            Container(
              margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
                    // 有背景图的主题：使用高透明度白色背景
                    DesignTokens.surfaceColor.withOpacity(0.95),
                    DesignTokens.surfaceColor.withOpacity(0.90),
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
                // no box shadows
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    strings.homeTarotCalendar,
                    style: TextStyle(
                      fontSize: DynamicTokens.fontSizeTitleLarge,
                      fontWeight: FontWeight.w600,
                      color: DynamicTokens.textBlack87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
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
                            child: Icon(AppIcons.autoAwesome, size: 40, color: dynamicTokens.primaryColor.withOpacity(0.35)),
                          ),
                        ),
                        error: (error, stack) => SizedBox(
                          height: 280,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(AppIcons.error, color: DynamicTokens.textError, size: 48),
                                SizedBox(height: 12),
                                Text('データの読み込みに失敗しました', style: TextStyle(color: DynamicTokens.textError)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
            selectedItemColor: dynamicTokens.textPrimary,
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
                icon: Icon(AppIcons.home),
                label: '毎日の占い',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.autoAwesome),
                label: 'スプレット',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.libraryBooks),
                label: 'ギャラリー',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.style),
                label: 'マイページ',
              ),
            ],
          );
        },
      ),
    );
  }

  // 触发每日AI解读（若处于idle），避免刷新后卡在loading
  Future<void> _ensureDailyAIReading(WidgetRef ref, TarotCard card, bool isUpright) async {
    try {
      final notifier = ref.read(aiReadingProvider('daily').notifier);
      await notifier.getDailyReading(card: card, isUpright: isUpright);
    } catch (_) {
      // ignore; 由 AIReadingWidget 展示错误
    }
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
        builder: (_) => Consumer(
          builder: (context, ref, __) {
            final strings = ref.watch(appStringsProvider);
            return AlertDialog(
              content: Text(
                strings.dialogPleaseWaitTillDay,
                style: const TextStyle(
                  color: DynamicTokens.textBlack87,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: DynamicTokens.textBlack87,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.commonOk),
                ),
              ],
            );
          },
        ),
      );
      return;
    }

    final cardInfo = cardMap[tapped];
    if (cardInfo == null) {
      // 今日未抽：提供“本日のカードを引く”按钮
      showDialog(
        context: context,
        builder: (_) => Consumer(
          builder: (context, ref, __) {
            final strings = ref.watch(appStringsProvider);
            return AlertDialog(
              content: Text(
                strings.messageNoHistory,
                style: const TextStyle(
                  color: DynamicTokens.textBlack87,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: DynamicTokens.textBlack87,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.commonOk),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: DynamicTokens.textBlack87,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(dailyCardProvider.notifier).drawTodayCard();
                  },
                  child: Text(strings.buttonDrawTodayCard),
                ),
              ],
            );
          },
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
          SnackBar(
            content: const Text('本日のカードを引きました！'),
            backgroundColor: DynamicTokens.textSuccess,
            duration: const Duration(seconds: 2),
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
            backgroundColor: DynamicTokens.textError,
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
                  color: DesignTokens.surfaceColor.withOpacity(0.4),
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
                      color: DesignTokens.surfaceColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.error, color: DynamicTokens.textError, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'エラーが発生しました',
                            style: TextStyle(color: DynamicTokens.textError),
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FutureBuilder<String>(
          future: CardBackService.getCurrentBackImageUrl(),
          builder: (context, snapshot) {
            final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
            return Image.asset(backUrl, fit: BoxFit.contain);
          },
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    if (widget.dailyCardState.card == null) {
      return Container(
        width: widget.heroCardHeight * 0.65,
        height: widget.heroCardHeight,
        decoration: BoxDecoration(
          color: DesignTokens.surfaceColor.withOpacity(0.4),
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
                  color: DesignTokens.surfaceColor.withOpacity(0.4),
                  child: const Center(
                    child: Icon(AppIcons.imageNotSupported, size: 48),
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
      ..color = DynamicTokens.textWhite.withOpacity(0.1)
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
        child: Consumer(
          builder: (context, ref, __) {
            final dt = ref.watch(dynamicTokensProvider);
            final bool useBgImage = (dt.isDark || dt.backgroundImage != null);
            final ScrollController _dialogScrollController = ScrollController();
            return Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: useBgImage
                      ? [
                          DesignTokens.surfaceColor.withOpacity(0.95),
                          DesignTokens.surfaceColor.withOpacity(0.90),
                        ]
                      : [
                          dt.surfaceColor.withOpacity(0.8),
                          dt.surfaceColor.withOpacity(0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: useBgImage
                      ? dt.primaryColor.withOpacity(0.6)
                      : dt.primaryColor.withOpacity(0.2),
                  width: useBgImage ? 2 : 1,
                ),
              ),
              child: Stack(
            children: [
              // 主要内容（去掉自定义滚动条，恢复基础滚动）
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _dialogScrollController,
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

                // 卡片名称（根据语言仅显示一个）
                Consumer(builder: (context, ref, _) {
                  final lang = ref.watch(localizationServiceProvider);
                  final displayName = (lang == SupportedLanguage.english) ? card.nameEn : card.nameJa;
                  return Text(
                    displayName,
                    style: TextStyle(
                      fontSize: DynamicTokens.fontSizeHeadlineLarge,
                      fontWeight: FontWeight.w600,
                      color: DynamicTokens.textBlack87,
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // 当前方向指示（与首页抽卡标签完全一致：黑系淡填充+淡描边）
                Consumer(builder: (context, ref, _) {
                  final strings = ref.watch(appStringsProvider);
                  return AppTag(
                    isUpright ? strings.labelUpright : strings.labelReversed,
                    useTheme: true,
                    overlay: true,
                  );
                }),

                const SizedBox(height: 16),

                // 故事
                Consumer(builder: (context, ref, _) {
                  final dt = ref.watch(dynamicTokensProvider);
                  final strings = ref.watch(appStringsProvider);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dt.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: dt.primaryColor.withOpacity(0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.labelStory,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: DynamicTokens.fontSizeBodyMedium,
                            color: DynamicTokens.textBlack87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.story,
                          style: TextStyle(
                            fontSize: DynamicTokens.fontSizeBodyMedium,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // 含义模块（去掉位置标签，标题样式与“物語り”一致；容器主题色）
                Consumer(builder: (context, ref, _) {
                  final dt = ref.watch(dynamicTokensProvider);
                  final strings = ref.watch(appStringsProvider);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dt.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: dt.primaryColor.withOpacity(0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  Text(
                                    parsed['title']!,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: DynamicTokens.fontSizeBodyMedium,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                      color: DynamicTokens.textBlack87,
                                    ),
                                  ),
                                  if (parsed['content']!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      parsed['content']!,
                                      style: TextStyle(
                                        fontSize: DynamicTokens.fontSizeBodyMedium,
                                        height: 1.4,
                                        color: DynamicTokens.textBlack87,
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  Text(
                                    meaningText,
                                    style: TextStyle(
                                      fontSize: DynamicTokens.fontSizeBodyMedium,
                                      height: 1.4,
                                      color: DynamicTokens.textBlack87,
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
                              return Text(
                                strings.messageNoKeywords,
                                style: TextStyle(
                                  fontSize: DynamicTokens.fontSizeBodySmall,
                                  color: DynamicTokens.textGrey500,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            }
                            return Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: keywords
                                  .take(8)
                                  .map((keyword) => AppTag(
                                        keyword,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        borderRadius: 20,
                                        fontSize: DynamicTokens.fontSizeBodySmall,
                                        useTheme: true,
                                        overlay: true,
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
                  ],
                        ),
                      ),
                    ),
                  ),
                ),
            // 关闭按钮 - 右上角X按钮（统一 24x24, icon 16, 间距 8）
            Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(AppIcons.close, size: 16),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(24, 24),
                    backgroundColor: DynamicTokens.textBlack87.withOpacity(0.08),
                    foregroundColor: DynamicTokens.textGrey600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
          },
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
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
            // 有背景图的主题：使用高透明度白色背景
            DesignTokens.surfaceColor.withOpacity(0.95),
            DesignTokens.surfaceColor.withOpacity(0.90),
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
        // no box shadows
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              // 去掉标题与图标，仅保留右侧牌名与正逆位标签
              const Spacer(),
              Consumer(
                builder: (context, ref, child) {
                  final dynamicTokens = ref.watch(dynamicTokensProvider);
                  final strings = ref.watch(appStringsProvider);
                  return Row(
                    children: [
                      Text(
                        card.nameJa,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: dynamicTokens.textSecondary,
                            ) ?? TextStyle(
                              fontSize: DynamicTokens.fontSizeBodySmall,
                              color: dynamicTokens.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isUpright ? strings.labelUpright : strings.labelReversed,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: dynamicTokens.textSecondary,
                              fontWeight: FontWeight.w600,
                            ) ?? TextStyle(
                              color: dynamicTokens.textSecondary,
                              fontSize: DynamicTokens.fontSizeBodySmall,
                              fontWeight: FontWeight.w600,
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