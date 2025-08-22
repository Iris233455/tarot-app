import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';

/// 塔罗牌套牌管理服务
class DeckService {
  static const String _selectedDeckKey = 'selected_deck_id';
  static const String _defaultDeckId = 'rider_waite';
  
  static TarotDecksData? _cachedDecksData;
  static String? _currentDeckId;
  
  /// 获取所有可用的塔罗牌套牌
  static Future<List<TarotDeck>> getAllDecks() async {
    final decksData = await _getDecksData();
    return decksData.decks;
  }
  
  /// 获取当前选中的套牌ID
  static Future<String> getCurrentDeckId() async {
    if (_currentDeckId != null) {
      return _currentDeckId!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _currentDeckId = prefs.getString(_selectedDeckKey) ?? _defaultDeckId;
    return _currentDeckId!;
  }
  
  /// 设置当前选中的套牌
  static Future<void> setCurrentDeck(String deckId) async {
    _currentDeckId = deckId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedDeckKey, deckId);
    
    // 清除数据缓存，强制重新加载数据以应用新的套牌ID
    DataService.clearCache();
  }
  
  /// 获取当前选中的套牌信息
  static Future<TarotDeck?> getCurrentDeck() async {
    final currentDeckId = await getCurrentDeckId();
    final allDecks = await getAllDecks();
    
    try {
      return allDecks.firstWhere((deck) => deck.deckId == currentDeckId);
    } catch (e) {
      // 如果找不到，返回默认套牌
      try {
        return allDecks.firstWhere((deck) => deck.isDefault);
      } catch (e) {
        // 如果没有默认套牌，返回第一个
        return allDecks.isNotEmpty ? allDecks.first : null;
      }
    }
  }
  
  /// 根据套牌ID获取套牌信息
  static Future<TarotDeck?> getDeckById(String deckId) async {
    final allDecks = await getAllDecks();
    try {
      return allDecks.firstWhere((deck) => deck.deckId == deckId);
    } catch (e) {
      return null;
    }
  }
  
  /// 检查套牌是否可用（图片和数据文件都存在）
  static Future<bool> isDeckAvailable(String deckId) async {
    try {
      final deck = await getDeckById(deckId);
      if (deck == null) return false;
      
      // 检查是否有对应的数据文件
      // 这里可以尝试加载数据文件来验证
      // 暂时返回true，实际使用时可以添加更严格的检查
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取套牌数据
  static Future<TarotDecksData> _getDecksData() async {
    if (_cachedDecksData != null) {
      return _cachedDecksData!;
    }
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/tarot_decks_example.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _cachedDecksData = TarotDecksData.fromJson(jsonData);
      return _cachedDecksData!;
    } catch (e) {
      print('Error loading decks data: $e');
      // 返回默认套牌数据
      return _getDefaultDecksData();
    }
  }
  
  /// 获取默认套牌数据
  static TarotDecksData _getDefaultDecksData() {
    return const TarotDecksData(
      decks: [
        TarotDeck(
          deckId: 'rider_waite',
          nameJp: 'ライダー・ウェイト版',
          nameEn: 'Rider-Waite Tarot',
          description: '最も有名で伝統的なタロットデック',
          author: 'A.E.ウェイト & パメラ・コールマン・スミス',
          year: '1909',
          imagePath: 'rider_waite',
          isDefault: true,
          cardDataFile: 'rider_waite_cards.json',
          backImage: 'back.jpeg',
        ),
      ],
    );
  }
  
  /// 重置为默认套牌
  static Future<void> resetToDefault() async {
    final allDecks = await getAllDecks();
    final defaultDeck = allDecks.where((deck) => deck.isDefault).firstOrNull;
    if (defaultDeck != null) {
      await setCurrentDeck(defaultDeck.deckId);
    } else if (allDecks.isNotEmpty) {
      await setCurrentDeck(allDecks.first.deckId);
    }
  }
  
  /// 清除缓存
  static void clearCache() {
    _cachedDecksData = null;
    _currentDeckId = null;
  }
}