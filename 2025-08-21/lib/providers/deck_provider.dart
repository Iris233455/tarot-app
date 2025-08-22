import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/deck_service.dart';

/// 当前选中的套牌ID
final currentDeckIdProvider = StateNotifierProvider<CurrentDeckNotifier, String>((ref) {
  return CurrentDeckNotifier();
});

class CurrentDeckNotifier extends StateNotifier<String> {
  CurrentDeckNotifier() : super('rider_waite') {
    _loadCurrentDeck();
  }

  Future<void> _loadCurrentDeck() async {
    try {
      final deckId = await DeckService.getCurrentDeckId();
      state = deckId;
    } catch (e) {
      print('Error loading current deck: $e');
    }
  }

  Future<void> setDeck(String deckId) async {
    try {
      await DeckService.setCurrentDeck(deckId);
      state = deckId;
    } catch (e) {
      print('Error setting deck: $e');
    }
  }

  Future<void> resetToDefault() async {
    try {
      await DeckService.resetToDefault();
      final deckId = await DeckService.getCurrentDeckId();
      state = deckId;
    } catch (e) {
      print('Error resetting to default deck: $e');
    }
  }
}

/// 当前选中的套牌信息
final currentDeckProvider = FutureProvider<TarotDeck?>((ref) async {
  final deckId = ref.watch(currentDeckIdProvider);
  return await DeckService.getDeckById(deckId);
});

/// 所有可用套牌列表
final allDecksProvider = FutureProvider<List<TarotDeck>>((ref) async {
  return await DeckService.getAllDecks();
});

/// 检查套牌是否可用
final deckAvailabilityProvider = FutureProvider.family<bool, String>((ref, deckId) async {
  return await DeckService.isDeckAvailable(deckId);
});