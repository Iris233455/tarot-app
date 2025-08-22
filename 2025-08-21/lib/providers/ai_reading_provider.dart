import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/services/ai_service.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';

/// AI解読の状態
enum AIReadingState {
  idle,
  loading,
  completed,
  error,
}

/// AI解読データクラス
class AIReadingData {
  final AIReadingState state;
  final String result;
  final String? error;

  const AIReadingData({
    required this.state,
    this.result = '',
    this.error,
  });

  AIReadingData copyWith({
    AIReadingState? state,
    String? result,
    String? error,
  }) {
    return AIReadingData(
      state: state ?? this.state,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// AI解読プロバイダー
class AIReadingNotifier extends StateNotifier<AIReadingData> {
  AIReadingNotifier() : super(const AIReadingData(state: AIReadingState.idle));

  /// 毎日の抽牌解読を取得
  Future<void> getDailyReading({
    required TarotCard card,
    required bool isUpright,
    Map<String, String>? userInfo,
  }) async {
    state = state.copyWith(state: AIReadingState.loading);

    try {
      final cardData = {
        'name': card.nameJa,
        'orientation': isUpright ? 'upright' : 'reversed',
      };

      final result = await AIService.getDailyReading(
        card: cardData,
        user: userInfo,
      );

      state = state.copyWith(
        state: AIReadingState.completed,
        result: result,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        state: AIReadingState.error,
        error: e.toString(),
      );
    }
  }

  /// ワンオラクル解読を取得
  Future<void> getOneCardReading({
    required String question,
    required TarotCard card,
    required bool isUpright,
    Map<String, String>? userInfo,
  }) async {
    state = state.copyWith(state: AIReadingState.loading);

    try {
      final cardData = {
        'name': card.nameJa,
        'orientation': isUpright ? 'upright' : 'reversed',
      };

      final result = await AIService.getOneCardReading(
        question: question,
        card: cardData,
        user: userInfo,
      );

      state = state.copyWith(
        state: AIReadingState.completed,
        result: result,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        state: AIReadingState.error,
        error: e.toString(),
      );
    }
  }

  /// 二択解読を取得
  Future<void> getTwoCardsReading({
    required String question,
    required TarotCard cardA,
    required bool isUprightA,
    required TarotCard cardB,
    required bool isUprightB,
    Map<String, String>? userInfo,
    String? optionA,
    String? optionB,
  }) async {
    state = state.copyWith(state: AIReadingState.loading);

    try {
      final cardDataA = {
        'name': cardA.nameJa,
        'orientation': isUprightA ? 'upright' : 'reversed',
      };
      final cardDataB = {
        'name': cardB.nameJa,
        'orientation': isUprightB ? 'upright' : 'reversed',
      };

      final result = await AIService.getTwoCardsReading(
        question: question,
        cardA: cardDataA,
        cardB: cardDataB,
        user: userInfo,
        optionA: optionA,
        optionB: optionB,
      );

      state = state.copyWith(
        state: AIReadingState.completed,
        result: result,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        state: AIReadingState.error,
        error: e.toString(),
      );
    }
  }

  /// 三枚読み解読を取得
  Future<void> getThreeCardsReading({
    required String question,
    required TarotCard pastCard,
    required bool isPastUpright,
    required TarotCard presentCard,
    required bool isPresentUpright,
    required TarotCard futureCard,
    required bool isFutureUpright,
    Map<String, String>? userInfo,
  }) async {
    state = state.copyWith(state: AIReadingState.loading);

    try {
      final pastData = {
        'name': pastCard.nameJa,
        'orientation': isPastUpright ? 'upright' : 'reversed',
      };
      final presentData = {
        'name': presentCard.nameJa,
        'orientation': isPresentUpright ? 'upright' : 'reversed',
      };
      final futureData = {
        'name': futureCard.nameJa,
        'orientation': isFutureUpright ? 'upright' : 'reversed',
      };

      final result = await AIService.getThreeCardsReading(
        question: question,
        pastCard: pastData,
        presentCard: presentData,
        futureCard: futureData,
        user: userInfo,
      );

      state = state.copyWith(
        state: AIReadingState.completed,
        result: result,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        state: AIReadingState.error,
        error: e.toString(),
      );
    }
  }

  /// 状態をリセット
  void reset() {
    state = const AIReadingData(state: AIReadingState.idle);
  }
}

/// AI解読プロバイダーのインスタンス（family版 - 解読タイプ別に状態分離）
final aiReadingProvider = StateNotifierProvider.family<AIReadingNotifier, AIReadingData, String>(
  (ref, readingType) => AIReadingNotifier(),
);

/// AI接続テストプロバイダー
final aiConnectionProvider = FutureProvider<bool>((ref) async {
  return await AIService.testConnection();
});