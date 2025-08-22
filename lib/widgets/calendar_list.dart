import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/models/daily_card_info.dart'; // 导入新模型文件
import 'package:mystic_tarot_jp/services/card_back_service.dart';
import 'dart:math' as math;

class MonthCalendar extends ConsumerStatefulWidget {
  final Map<DateTime, DailyCardInfo?> cardMap; // 每天的牌数据，未抽为null
  final void Function(DateTime date)? onDayTap;
  final DateTime? initialMonth;
  final ValueChanged<DateTime>? onMonthChanged;
  final Widget Function(BuildContext context, DateTime date, DailyCardInfo? info, bool isSelected, bool isToday)? dayBuilder;

  const MonthCalendar({
    super.key,
    required this.cardMap,
    this.onDayTap,
    this.initialMonth,
    this.onMonthChanged,
    this.dayBuilder,
  });

  @override
  ConsumerState<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<MonthCalendar> with SingleTickerProviderStateMixin {
  late DateTime currentMonth; // 指向当月的任意一天（使用1号计算）
  DateTime? selectedDate;
  late AnimationController _todayShimmerController;

  List<int> get years => List.generate(11, (i) => 2020 + i);
  List<int> get months => List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final init = widget.initialMonth ?? DateTime(now.year, now.month, 1);
    currentMonth = DateTime(init.year, init.month, 1);
    _todayShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000), // 8秒更平滑
    )..repeat();
  }

  @override
  void dispose() {
    _todayShimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildAdaptiveLayout(context);

  Widget _buildAdaptiveLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // 计算日历需要的总高度
    final headerHeight = 120.0; // 年月导航 + 星期头的高度
    final availableHeight = screenHeight - headerHeight - 200; // 减去其他UI元素的高度
    // 计算每个单元格的最小高度（保持3:4比例）
    final cellWidth = screenWidth / 7 - 4; // 减去margin
    final cellHeight = cellWidth * 4 / 3; // 保持3:4比例
    final calendarHeight = cellHeight * 6; // 最多6行
    // 判断是否需要横向滚动
    if (calendarHeight > availableHeight) {
      final scrollWidth = screenWidth * 1.2;
      // 这里不要用Expanded，直接用SizedBox给定最大高度
      return Column(
        children: [
          // 宽屏/高度不足时，仅在这里放"月份导航"，周标题放到滚动区域内部，避免重复
          _buildMonthNavigator(context),
          const SizedBox(height: 8),
          SizedBox(
            height: 500, // 你可以根据实际需要调整这个高度
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: scrollWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(children: [
                    _buildWeekHeader(context),
                    const SizedBox(height: 8),
                    _buildCalendar(),
                  ]),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // 正常模式：优化底部留白
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          _buildCompactCalendar(context),
        ],
      );
    }
  }

  Widget _buildAdaptiveCalendar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellWidth = screenWidth / 7 - 4;
    final cellHeight = cellWidth * 4 / 3;
    final calendarHeight = cellHeight * 6;
    return Container(
      height: calendarHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DynamicTokens.radiusXs),
      ),
      child: _buildCalendar(),
    );
  }

  Widget _buildCompactCalendar(BuildContext context) {
    // 紧凑版日历：根据实际需要的行数来计算高度，减少底部留白
    final screenWidth = MediaQuery.of(context).size.width;
    final cellWidth = screenWidth / 7 - 4;
    final cellHeight = cellWidth * 4 / 3;
    
    // 计算这个月实际需要的行数
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday = firstDay.weekday % 7; // 0:周日, 1:周一...
    final totalCells = (firstWeekday == 0 ? 6 : firstWeekday - 1) + daysInMonth;
    final actualRows = (totalCells / 7).ceil();
    final actualHeight = cellHeight * actualRows;
    
    return Container(
      height: actualHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DynamicTokens.radiusXs),
      ),
      child: _buildCalendar(),
    );
  }

  Widget _buildMonthNavigator(BuildContext context) {
    final label = DateFormat('y年M月').format(currentMonth);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Row(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final dynamicTokens = ref.watch(dynamicTokensProvider);
              return IconButton(
                icon: Icon(Icons.chevron_left,
                  color: dynamicTokens.isDark ? Colors.black87 : dynamicTokens.textPrimary),
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
                  });
                  widget.onMonthChanged?.call(currentMonth);
                },
              );
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openYearPicker(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final dynamicTokens = ref.watch(dynamicTokensProvider);
                    return Text(
                      label,
                      key: ValueKey(label),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
                          ? Colors.black87  // 有背景图的主题：在白色背景上用深色文字
                          : dynamicTokens.textPrimary, // 纯色背景主题：用原来的文字颜色
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final dynamicTokens = ref.watch(dynamicTokensProvider);
              return IconButton(
                icon: Icon(Icons.chevron_right,
                  color: dynamicTokens.isDark ? Colors.black87 : dynamicTokens.textPrimary),
                onPressed: () {
                  setState(() {
                    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                  });
                  widget.onMonthChanged?.call(currentMonth);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openYearPicker(BuildContext context) async {
    final now = DateTime.now();
    final first = DateTime(now.year - 20, 1, 1);
    final last = DateTime(now.year + 20, 12, 31);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('年を選択'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: first,
              lastDate: last,
              selectedDate: currentMonth,
              onChanged: (date) => Navigator.of(ctx).pop(date),
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        currentMonth = DateTime(picked.year, currentMonth.month, 1);
      });
      widget.onMonthChanged?.call(currentMonth);
    }
  }

  Widget _buildWeekHeader(BuildContext context) {
    final weekLabels = ['月', '火', '水', '木', '金', '土', '日'];
    return Consumer(
      builder: (context, ref, child) {
        final dynamicTokens = ref.watch(dynamicTokensProvider);
        return Container(
          decoration: BoxDecoration(
            color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? Colors.grey.shade200  // 有背景图的主题：浅灰色背景
              : Colors.grey.shade100, // 纯色背景主题：原来的背景
            borderRadius: BorderRadius.circular(DynamicTokens.radiusXs),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekLabels
                .map((w) => Expanded(
                      child: Center(
                        child: Text(w,
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: Colors.black87  // 始终使用深色，在浅色背景上显示
                            )),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) => Column(children: [
        _buildMonthNavigator(context),
        const SizedBox(height: 8),
        _buildWeekHeader(context),
      ]);

  Widget _buildCalendar() {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; // 0:周日, 1:周一...
    // 生成日历格子
    List<Widget> dayCells = [];
    for (int i = 0; i < (firstWeekday == 0 ? 6 : firstWeekday - 1); i++) {
      dayCells.add(Container());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(currentMonth.year, currentMonth.month, d);
      final cardInfo = widget.cardMap[date];
      dayCells.add(_buildDayCell(context, date, cardInfo));
    }
    while (dayCells.length % 7 != 0) {
      dayCells.add(Container());
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 3 / 4,
      ),
      itemCount: dayCells.length,
      itemBuilder: (_, i) => dayCells[i],
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // 禁用自身滚动，由外层控制
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, DailyCardInfo? cardInfo) {
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    final isPast = date.isBefore(DateTime.now());
    final hasCard = cardInfo != null;
    final isSelected = selectedDate != null &&
        selectedDate!.year == date.year &&
        selectedDate!.month == date.month &&
        selectedDate!.day == date.day;

    if (widget.dayBuilder != null) {
      return GestureDetector(
        onTap: () {
          setState(() => selectedDate = date);
          widget.onDayTap?.call(date);
        },
        child: widget.dayBuilder!(context, date, cardInfo, isSelected, isToday),
      );
    }

    final isFuture = date.isAfter(DateTime.now());
    
    Widget cellContent;
    if (hasCard) {
      // 有卡片：显示实际塔罗牌
      cellContent = ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(cardInfo.isUpright ? 0 : 3.14159), // 逆位时旋转180度
          child: Image.asset(cardInfo.card.imageUrl, // 使用正确的imageUrl
              fit: BoxFit.contain, // 修改fit属性
              errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 16),
            );
          }),
        ),
      );
    } else if (isToday) {
      // 今日但未抽牌：显示卡背，不显示问号
      cellContent = ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        child: Opacity(
          opacity: 0.6,
          child: FutureBuilder<String>(
            future: CardBackService.getCurrentBackImageUrl(),
            builder: (context, snapshot) {
              final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
              return Image.asset(
                backUrl,
                fit: BoxFit.contain, // 修改fit属性
                errorBuilder: (_, __, ___) {
                  // 如果卡背图片也加载失败，显示灰色背景
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusXs),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    } else {
      // 未来日期或过去无卡片日期：显示卡背+问号
      cellContent = ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 弱化的背景图片
            Opacity(
              opacity: 0.5,
              child: FutureBuilder<String>(
                future: CardBackService.getCurrentBackImageUrl(),
                builder: (context, snapshot) {
                  final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
                  return Image.asset(
                    backUrl,
                    fit: BoxFit.contain, // 修改fit属性
                    errorBuilder: (_, __, ___) {
                      // 如果卡背图片也加载失败，显示灰色背景
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusXs),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // "？"图标（只对未来日期和过去无卡片日期显示）
            Center(
              child: Container(
                width: isFuture ? 28 : 24,
                height: isFuture ? 28 : 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.question_mark_rounded,
                  color: Colors.white,
                  size: isFuture ? 16 : 14, // 调整图标大小以适应圆形背景
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => selectedDate = date);
        widget.onDayTap?.call(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
          color: isSelected
              ? DesignTokens.primaryColor.withOpacity(0.10)
              : Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: isToday
                    ? AnimatedBuilder(
                        animation: _todayShimmerController,
                        builder: (context, child) {
                          // 使用缓存的动画值，避免重复计算
                          final progress = _todayShimmerController.value;
                          
                          // 更自然的漂浮：使用缓动曲线
                          final smoothY = Curves.easeInOut.transform((math.sin(progress * 2 * math.pi) + 1) / 2);
                          final smoothX = Curves.easeInOut.transform((math.sin(progress * 1.3 * math.pi + 1) + 1) / 2);
                          
                          final floatY = (smoothY - 0.5) * 3.0; // -1.5 到 1.5
                          final floatX = (smoothX - 0.5) * 1.6; // -0.8 到 0.8
                          
                          // 柔和呼吸，使用缓动
                          final breathProgress = Curves.easeInOut.transform((math.sin(progress * 2 * math.pi + math.pi / 4) + 1) / 2);
                          final scale = 1.0 + (breathProgress * 0.06); // 1.0 到 1.06
                          
                          // 闪烁透明度（缓慢呼吸）
                          final shimmerProgress = Curves.easeInOut.transform((math.sin(progress * 3 * math.pi) + 1) / 2);
                          final opacity = 0.85 + (shimmerProgress * 0.15); // 0.85-1.0透明度变化
                          
                          // 动态阴影强度
                          final shadowProgress = Curves.easeInOut.transform((math.sin(progress * 2.5 * math.pi + math.pi / 3) + 1) / 2);
                          final shadowOpacity = 0.25 + (shadowProgress * 0.2); // 阴影强度变化
                          
                          return Transform.translate(
                            offset: Offset(floatX, floatY),
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                                    boxShadow: [
                                      // 动态发光阴影
                                      BoxShadow(
                                        color: DesignTokens.primaryColor.withOpacity(shadowOpacity),
                                        blurRadius: 12 + shadowProgress * 6, // 12-18px动态模糊
                                        offset: Offset(0, 3 + floatY * 0.2),
                                      ),
                                      // 额外的外圈光晕
                                      BoxShadow(
                                        color: DesignTokens.primaryColor.withOpacity(shadowOpacity * 0.4),
                                        blurRadius: 20 + shadowProgress * 8, // 20-28px外圈
                                        offset: Offset(0, 4 + floatY * 0.15),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                                        child: cellContent,
                                      ),
                                      // 角落闪光点
                                      if (shimmerProgress > 0.7) // 只在高峰时显示
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: IgnorePointer(
                                            child: Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity((shimmerProgress - 0.7) * 3.33), // 渐现
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white.withOpacity((shimmerProgress - 0.7) * 2),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : cellContent,
              ),
            ),
            const SizedBox(height: 2),
            Consumer(
              builder: (context, ref, child) {
                final dynamicTokens = ref.watch(dynamicTokensProvider);
                return Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
                        ? (!isPast ? Colors.grey.shade600 : Colors.black87)
                        : (!isPast ? Colors.grey : Colors.black87),
                  ),
                );
              },
            ),
            // 神秘标记：節分、二至二分、星座切替日
            Builder(builder: (_) {
              final marker = _getMysticMarker(date);
              if (marker == null) return const SizedBox(height: 0);
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(marker, style: const TextStyle(fontSize: 11)),
              );
            }),
          ],
        ),
      ),
    );
  }

  String? _getMysticMarker(DateTime d) {
    // 移除所有特殊标记
    return null;
  }


}

// 你需要在assets/images/下准备card_back.png（牌背），如无则用纯色占位。
// TarotCard模型需有imageUrl字段。 