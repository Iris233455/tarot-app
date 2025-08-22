import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/services/deck_service.dart';
import 'package:mystic_tarot_jp/providers/auth_provider.dart';
import 'package:mystic_tarot_jp/providers/deck_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'package:mystic_tarot_jp/models/daily_card_info.dart'; // 导入新模型文件

/// 每日抽牌状态
class DailyCardState {
  final TarotCard? card;
  final bool isUpright;
  final bool isLoading;
  final String? error;
  final bool hasDrawnToday;

  const DailyCardState({
    this.card,
    this.isUpright = true,
    this.isLoading = false,
    this.error,
    this.hasDrawnToday = false,
  });

  DailyCardState copyWith({
    TarotCard? card,
    bool? isUpright,
    bool? isLoading,
    String? error,
    bool? hasDrawnToday,
  }) {
    return DailyCardState(
      card: card ?? this.card,
      isUpright: isUpright ?? this.isUpright,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasDrawnToday: hasDrawnToday ?? this.hasDrawnToday,
    );
  }
}

/// 每日抽牌 Provider
final dailyCardProvider = StateNotifierProvider<DailyCardNotifier, DailyCardState>((ref) {
  return DailyCardNotifier(ref);
});

final monthlyCardsProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DailyCardInfo>, MonthlyCardParams>(
        (ref, params) async {
  // 监听今日卡片状态变化，确保日历实时更新
  ref.watch(dailyCardProvider);
  // 监听套牌变化，确保在套牌切换时重新加载历史数据
  ref.watch(currentDeckIdProvider);
  
  final notifier = ref.read(dailyCardProvider.notifier);
  return await notifier.getMonthlyCardsWithDetails(params.year, params.month);
});

class DailyCardNotifier extends StateNotifier<DailyCardState> {
  final Ref ref;
  
  DailyCardNotifier(this.ref) : super(const DailyCardState()) {
    _loadTodayCard();
  }

  /// 加载今日抽牌记录
  Future<void> _loadTodayCard() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      Map<String, dynamic>? cardData;
      
      if (DataService.isOfflineMode) {
        // 离线模式 - 从本地存储获取
        cardData = await _getLocalTodayCard();
      } else {
        // 在线模式 - 从Supabase获取
        try {
          await ref.read(authServiceProvider).ensureLoggedIn();
          cardData = await SupabaseService.getTodayCard();
        } catch (e) {
          print('Supabase获取今日卡片失败，切换到离线模式: $e');
          await DataService.setOfflineMode(true);
          cardData = await _getLocalTodayCard();
        }
      }
      
      if (cardData != null) {
        // 已抽过牌 - 从最新数据源重新获取卡片以确保使用最新内容（如story_app）
        final tarotCardData = cardData['tarot_card'] ?? cardData['tarot_cards'];
        final cardId = tarotCardData['card_id'] ?? tarotCardData['id'];
        
        // 重新从DataService获取最新的卡片数据
        final latestCard = await DataService.getTarotCard(cardId);
        if (latestCard != null) {
          state = state.copyWith(
            card: latestCard,
            isUpright: cardData['is_upright'] ?? true,
            hasDrawnToday: true,
            isLoading: false,
          );
        } else {
          // 如果无法获取最新数据，回退到保存的数据
          final card = TarotCard.fromJson(tarotCardData);
          final currentDeckId = await DeckService.getCurrentDeckId();
          final updatedCard = card.copyWith(deckId: currentDeckId);
          
          state = state.copyWith(
            card: updatedCard,
            isUpright: cardData['is_upright'] ?? true,
            hasDrawnToday: true,
            isLoading: false,
          );
        }
      } else {
        // 今日还未抽牌
        state = state.copyWith(
          card: null,
          hasDrawnToday: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// 抽取今日卡牌
  Future<void> drawTodayCard() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 获取随机大阿尔卡纳牌
      final selectedCard = await DataService.getRandomMajorArcanaCard();
      if (selectedCard == null) {
        throw Exception('没有可用的大阿尔卡纳牌数据');
      }
      
      // 随机决定正逆位
      final random = Random();
      final isUpright = random.nextBool();
      
      // 保存抽牌记录
      if (DataService.isOfflineMode) {
        await _saveLocalTodayCard(selectedCard, isUpright);
      } else {
        try {
          await ref.read(authServiceProvider).ensureLoggedIn();
          // 生成每日消息
          final message = _generateDailyMessage(selectedCard, isUpright);
          
          await SupabaseService.saveTodayCard(
            cardId: selectedCard.id,
            isUpright: isUpright,
            message: message,
          );
        } catch (e) {
          print('❌ Daily Card保存失败: $e');
          // 不切换到离线模式，而是抛出错误让UI处理
          if (e.toString().contains('今天已经抽过牌了')) {
            rethrow; // 重新抛出，让UI显示友好的错误信息
          } else {
            print('🔄 保存失败，使用本地存储作为备份');
            await _saveLocalTodayCard(selectedCard, isUpright);
          }
        }
      }
      
      // 更新状态
      state = state.copyWith(
        card: selectedCard,
        isUpright: isUpright,
        hasDrawnToday: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// 生成每日消息（界面上的今日のメッセージ）
  String _generateDailyMessage(TarotCard card, bool isUpright) {
    // 获取卡牌的含义作为今日消息
    final meaning = isUpright ? card.meaningUpright : card.meaningReversed;
    return meaning;
  }

  /// 重新抽牌（清除今日记录后重新抽取）
  Future<void> redrawTodayCard() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 清除今日记录
      if (DataService.isOfflineMode) {
        await _clearLocalTodayCard();
      } else {
        try {
          await ref.read(authServiceProvider).ensureLoggedIn();
          await SupabaseService.clearTodayCard();
        } catch (e) {
          print('Supabase清除失败，切换到离线模式: $e');
          await DataService.setOfflineMode(true);
          await _clearLocalTodayCard();
        }
      }
      
      // 重新抽牌
      await drawTodayCard();
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// 获取指定日期的抽牌记录
  Future<Map<String, dynamic>?> getCardByDate(DateTime date) async {
    try {
      if (DataService.isOfflineMode) {
        return await _getLocalCardByDate(date);
      } else {
        try {
          await ref.read(authServiceProvider).ensureLoggedIn();
          return await SupabaseService.getCardByDate(date);
        } catch (e) {
          print('Supabase获取指定日期卡片失败: $e');
          return await _getLocalCardByDate(date);
        }
      }
    } catch (e) {
      return null;
    }
  }

  /// 获取月度抽牌记录
  Future<List<Map<String, dynamic>>> getMonthlyCards(int year, int month) async {
    try {
      if (DataService.isOfflineMode) {
        return await _getLocalMonthlyCards(year, month);
      } else {
        try {
          await ref.read(authServiceProvider).ensureLoggedIn();
          return await SupabaseService.getMonthlyCards(year, month);
        } catch (e) {
          print('Supabase获取月度卡片失败: $e');
          return await _getLocalMonthlyCards(year, month);
        }
      }
    } catch (e) {
      return [];
    }
  }

  /// 获取包含完整塔罗牌详情的月度抽牌记录
  Future<Map<DateTime, DailyCardInfo>> getMonthlyCardsWithDetails(
      int year, int month) async {
    final monthlyData = await getMonthlyCards(year, month);
    final Map<DateTime, DailyCardInfo> cardMap = {};

    for (final cardData in monthlyData) {
      try {
        final dateStr = cardData['date'] as String;
        final date = DateTime.parse(dateStr);
        final isUpright = cardData['is_upright'] as bool;
        // 修复：统一使用tarot_cards字段名
        final tarotCardData =
            cardData['tarot_cards'] as Map<String, dynamic>?;

        if (tarotCardData != null) {
          final historyCard = TarotCard.fromJson(tarotCardData);
          final cardId = historyCard.id;
          
          // 重新从当前套牌的数据文件获取最新的卡片数据，确保使用正确的图片格式
          final latestCard = await DataService.getTarotCard(cardId);
          if (latestCard != null) {
            cardMap[date] = DailyCardInfo(card: latestCard, isUpright: isUpright);
          } else {
            // 如果无法获取最新数据，回退到历史数据但更新deckId
            final currentDeckId = await DeckService.getCurrentDeckId();
            final updatedCard = historyCard.copyWith(deckId: currentDeckId);
            cardMap[date] = DailyCardInfo(card: updatedCard, isUpright: isUpright);
          }
        }
      } catch (e) {
        print('月度卡片数据解析失败: $e');
        continue;
      }
    }
    return cardMap;
  }

  /// 刷新今日抽牌状态
  Future<void> refresh() async {
    await _loadTodayCard();
  }

  // ============ 本地存储相关方法 ============

  /// 获取本地今日抽牌记录
  Future<Map<String, dynamic>?> _getLocalTodayCard() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'daily_card_$dateStr';
    
    final cardDataStr = prefs.getString(key);
    if (cardDataStr != null) {
      try {
        final cardData = json.decode(cardDataStr);
        if (cardData is Map<String, dynamic>) {
          return cardData;
        }
      } catch (e) {
        print('今日のカードデータ解析に失敗: $e');
      }
    }
    return null;
  }

  /// 保存本地今日抽牌记录
  Future<void> _saveLocalTodayCard(TarotCard card, bool isUpright) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'daily_card_$dateStr';
    
    final cardData = {
      'tarot_card': card.toJson(),
      'is_upright': isUpright,
      'date': dateStr,
    };
    
    await prefs.setString(key, json.encode(cardData));
  }

  /// 清除本地今日抽牌记录
  Future<void> _clearLocalTodayCard() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'daily_card_$dateStr';
    
    await prefs.remove(key);
  }

  /// 获取本地指定日期的抽牌记录
  Future<Map<String, dynamic>?> _getLocalCardByDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final key = 'daily_card_$dateStr';
    
    final cardDataStr = prefs.getString(key);
    if (cardDataStr != null) {
      try {
        final cardData = json.decode(cardDataStr);
        if (cardData is Map<String, dynamic>) {
          return cardData;
        }
      } catch (e) {
        print('指定日期のカードデータ解析に失敗: $e');
      }
    }
    return null;
  }

  /// 获取本地月度抽牌记录
  Future<List<Map<String, dynamic>>> _getLocalMonthlyCards(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final monthlyCards = <Map<String, dynamic>>[];
    
    // 获取该月的所有日期
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final key = 'daily_card_$dateStr';
      
      final cardDataStr = prefs.getString(key);
      if (cardDataStr != null) {
        try {
          final cardData = json.decode(cardDataStr);
          
          // 确保必要的字段存在且有效
          if (cardData is Map<String, dynamic> && 
              cardData['tarot_card'] != null && 
              cardData['tarot_card'] is Map<String, dynamic>) {
            monthlyCards.add({
              'date': dateStr,
              'tarot_cards': cardData['tarot_card'],
              'is_upright': cardData['is_upright'] ?? true,
            });
          }
        } catch (e) {
          // JSONデコードに失敗した場合はスキップ
          print('本地数据解析失败 ($key): $e');
          continue;
        }
      }
    }
    
    return monthlyCards;
  }
} 