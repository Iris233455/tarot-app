import 'package:mystic_tarot_jp/models/tarot_card.dart';

/// 每日抽牌信息，包含牌和方向以及当天的解说
class DailyCardInfo {
  final TarotCard card;
  final bool isUpright;
  final String? explanation; // 当天的解说，未来会用AI生成，目前使用meaning

  const DailyCardInfo({
    required this.card,
    required this.isUpright,
    this.explanation,
  });
  
  /// 获取当天的解说，如果没有自定义解说则使用牌意
  String get todayExplanation {
    if (explanation != null && explanation!.isNotEmpty) {
      return explanation!;
    }
    // 默认使用对应方向的牌意作为解说
    return isUpright ? card.meaningUpright : card.meaningReversed;
  }
}

// 用于FutureProvider.family的参数类
class MonthlyCardParams {
  final int year;
  final int month;

  MonthlyCardParams(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyCardParams &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
} 