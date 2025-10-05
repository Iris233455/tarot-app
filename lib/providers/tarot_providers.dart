import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/providers/deck_provider.dart';
import 'package:mystic_tarot_jp/providers/ai_reading_provider.dart';

/// 所有塔罗牌数据 Provider
final allTarotCardsProvider = FutureProvider<List<TarotCard>>((ref) async {
  // 监听套牌变化，确保在套牌切换时重新加载数据
  ref.watch(currentDeckIdProvider);
  return await DataService.getAllTarotCards();
});

/// 根据ID获取塔罗牌 Provider
final tarotCardByIdProvider = FutureProvider.family<TarotCard?, String>((ref, cardId) async {
  // 监听套牌变化
  ref.watch(currentDeckIdProvider);
  return await DataService.getTarotCard(cardId);
});

/// 卡片详情 Provider（与tarotCardByIdProvider相同，但用于详情页面）
final cardDetailsProvider = FutureProvider.family<TarotCard?, String>((ref, cardId) async {
  // 监听套牌变化
  ref.watch(currentDeckIdProvider);
  return await DataService.getTarotCard(cardId);
});

/// 分组后的塔罗牌数据 Provider
final groupedTarotCardsProvider = FutureProvider<Map<String, List<TarotCard>>>((ref) async {
  // 监听套牌变化
  ref.watch(currentDeckIdProvider);
  return await DataService.getGroupedCards();
});

/// 大阿尔卡纳牌 Provider
final majorArcanaProvider = FutureProvider<List<TarotCard>>((ref) async {
  final grouped = await ref.watch(groupedTarotCardsProvider.future);
  return grouped['大アルカナ'] ?? [];
});

/// 小阿尔卡纳牌 Provider
final minorArcanaProvider = FutureProvider<Map<String, List<TarotCard>>>((ref) async {
  final grouped = await ref.watch(groupedTarotCardsProvider.future);
  return {
    'ワンド': grouped['ワンド'] ?? [],
    'カップ': grouped['カップ'] ?? [],
    'ソード': grouped['ソード'] ?? [],
    'ペンタクル': grouped['ペンタクル'] ?? [],
  };
});

/// 随机塔罗牌 Provider（用于抽牌）
final randomTarotCardProvider = FutureProvider<TarotCard?>((ref) async {
  // 监听套牌变化
  ref.watch(currentDeckIdProvider);
  return await DataService.getRandomCard();
});

/// 搜索塔罗牌 Provider
final searchTarotCardsProvider = FutureProvider.family<List<TarotCard>, String>((ref, query) async {
  // 监听套牌变化
  ref.watch(currentDeckIdProvider);
  return await DataService.searchCards(query);
});

/// 随机抽取多张牌 Provider
final randomCardsProvider = FutureProvider.family<List<TarotCard>, int>((ref, count) async {
  // 监听套牌变化
  ref.watch(currentDeckIdProvider);
  return await DataService.getRandomCards(count);
});

/// 连接状态 Provider
final connectionStatusProvider = Provider<String>((ref) {
  return DataService.getConnectionStatus();
});

/// 离线模式状态 Provider
final isOfflineModeProvider = Provider<bool>((ref) {
  return DataService.isOfflineMode;
});

// 状态提供者
final selectedCardsProvider = StateProvider<List<TarotCard>>((ref) => []);

final isCardReversedProvider = StateProvider<bool>((ref) => false);

final currentQuestionProvider = StateProvider<String>((ref) => '');

final readingTypeProvider = StateProvider<String>((ref) => 'single');

final isLoadingProvider = StateProvider<bool>((ref) => false);

// 占い相关 Provider
/// 占い类型状态
final readingFormatProvider = StateProvider<String>((ref) => '');

/// 占い问题状态
final readingQuestionProvider = StateProvider<String>((ref) => '');

/// Two Cards選択肢状態
final optionAProvider = StateProvider<String>((ref) => '');
final optionBProvider = StateProvider<String>((ref) => '');

/// 占い结果状态
class ReadingResult {
  final List<TarotCard> cards;
  final List<bool> orientations; // 每张牌的方向
  final String readingType;
  final String question;
  final DateTime timestamp;

  const ReadingResult({
    required this.cards,
    required this.orientations,
    required this.readingType,
    required this.question,
    required this.timestamp,
  });
}

/// 占い结果Provider
final readingResultProvider = StateProvider<ReadingResult?>((ref) => null);

/// 执行占い抽牌
final performReadingProvider = FutureProvider.family<ReadingResult, Map<String, dynamic>>((ref, params) async {
  final readingType = params['type'] as String;
  final question = params['question'] as String;
  final uiPickedCards = params['cards'] as List<TarotCard>?;
  final uiOrientations = params['orientations'] as List<bool>?;

  // 优先使用 UI 已选的牌与方向；否则回退到随机抽取
  List<TarotCard> cards;
  List<bool> orientations;
  if (uiPickedCards != null && uiPickedCards.isNotEmpty) {
    cards = uiPickedCards;
    orientations = (uiOrientations != null && uiOrientations.length == uiPickedCards.length)
        ? uiOrientations
        : List<bool>.generate(uiPickedCards.length, (i) => (DateTime.now().millisecondsSinceEpoch + i) % 2 == 0);
  } else {
    // 根据占い类型确定抽牌数量
    int cardCount = 1;
    switch (readingType) {
      case 'one':
      case 'ワンオラクル':
        cardCount = 1;
        break;
      case 'yesno':
      case 'ツーカード':
        cardCount = 2;
        break;
      case 'three':
      case 'スリーカード':
        cardCount = 3;
        break;
      default:
        cardCount = 1;
    }
    cards = await DataService.getRandomCards(cardCount);
    orientations = List<bool>.generate(cardCount, (i) => (DateTime.now().millisecondsSinceEpoch + i) % 2 == 0);
  }

  final result = ReadingResult(
    cards: cards,
    orientations: orientations,
    readingType: readingType,
    question: question,
    timestamp: DateTime.now(),
  );
  return result;
});

/// 清除占い结果
final clearReadingProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(readingResultProvider.notifier).state = null;
    ref.read(readingFormatProvider.notifier).state = '';
    ref.read(readingQuestionProvider.notifier).state = '';
  };
}); 