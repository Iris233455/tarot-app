import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/services/local_data_service.dart';
import 'package:mystic_tarot_jp/services/deck_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// 统一的数据服务 - 自动在Supabase和本地数据之间切换
class DataService {
  static bool _isOfflineMode = false;
  static const String _offlineModeKey = 'offline_mode';
  
  /// 清除缓存（套牌切换时调用）
  static void clearCache() {
    LocalDataService.clearCache();
    print('🧹 DataService缓存已清除');
  }
  
  /// 初始化数据服务
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(_offlineModeKey) ?? false;
  }
  
  /// 设置离线模式
  static Future<void> setOfflineMode(bool offline) async {
    _isOfflineMode = offline;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, offline);
  }
  
  /// 检查是否为离线模式
  static bool get isOfflineMode => _isOfflineMode;
  
  /// 获取所有塔罗牌数据
  static Future<List<TarotCard>> getAllTarotCards() async {
    // 获取当前套牌信息
    final currentDeck = await DeckService.getCurrentDeck();
    final dataFile = currentDeck?.cardDataFile ?? 'tarot_books_contents.json';
    
    // 使用套牌特定的数据文件
    final tarotData = await LocalDataService.getTarotData(dataFile);
    final cards = tarotData.cards;
    
    // 获取当前选择的套牌ID，并更新所有卡片的deckId
    final currentDeckId = await DeckService.getCurrentDeckId();
    return cards.map((card) => card.copyWith(deckId: currentDeckId)).toList();
  }
  
  /// 获取花色信息
  static Future<List<SuitInfo>> getSuits() async {
    return await LocalDataService.getSuits();
  }
  
  /// 获取展开方式信息
  static Future<List<SpreadInfo>> getSpreads() async {
    return await LocalDataService.getSpreads();
  }

  /// 获取 spreads 的标题与message元信息（来自tarot_books_contents.json）
  static Future<Map<String, Map<String, dynamic>>> getSpreadMeta() async {
    return await LocalDataService.getSpreadMeta();
  }

  /// 获取每日抽牌信息
  static Future<SpreadInfo> getDailySpread() async {
    final data = await LocalDataService.getTarotData();
    return data.dailySpread;
  }
  
  /// 获取完整的塔罗牌数据
  static Future<TarotData> getTarotData() async {
    // 完整数据目前只从本地获取
    return await LocalDataService.getTarotData();
  }
  
  /// 根据ID获取塔罗牌
  static Future<TarotCard?> getTarotCard(String cardId) async {
    // 获取当前套牌信息以使用正确的数据文件
    final currentDeck = await DeckService.getCurrentDeck();
    final dataFile = currentDeck?.cardDataFile ?? 'tarot_books_contents.json';
    
    final TarotCard? card = await LocalDataService.getTarotCard(cardId, dataFile);
    
    if (card != null) {
      // 获取当前选择的套牌ID，并更新卡片的deckId
      final currentDeckId = await DeckService.getCurrentDeckId();
      return card.copyWith(deckId: currentDeckId);
    }
    
    return null;
  }
  
  /// 搜索塔罗牌
  static Future<List<TarotCard>> searchCards(String query) async {
    // 使用本地 contents.json 为唯一数据源
    List<TarotCard> searchResults;
    final allCards = await getAllTarotCards();
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    searchResults = allCards.where((card) {
      return card.nameJa.toLowerCase().contains(lowerQuery) ||
             card.nameEn.toLowerCase().contains(lowerQuery) ||
             card.meaningUpright.toLowerCase().contains(lowerQuery) ||
             card.meaningReversed.toLowerCase().contains(lowerQuery) ||
             card.story.toLowerCase().contains(lowerQuery);
    }).toList();
    // 对搜索结果进行排序
    searchResults.sort((a, b) {
      if (a.id.startsWith('major_') && b.id.startsWith('major_')) {
        return _compareMajorArcana(a.id, b.id);
      } else if (!a.id.startsWith('major_') && !b.id.startsWith('major_')) {
        return _compareMinorArcana(a.id, b.id);
      } else if (a.id.startsWith('major_')) {
        return -1; // 大阿尔卡纳排在前面
      } else {
        return 1;
      }
    });
    
    // 获取当前选择的套牌ID，并更新所有搜索结果的deckId
    final currentDeckId = await DeckService.getCurrentDeckId();
    return searchResults.map((card) => card.copyWith(deckId: currentDeckId)).toList();
  }
  
  /// 获取分组后的塔罗牌
  static Future<Map<String, List<TarotCard>>> getGroupedCards() async {
    // 使用本地 contents.json 为唯一数据源
    final allCards = await getAllTarotCards();
    final Map<String, List<TarotCard>> grouped = {
      '大アルカナ': [],
      'ワンド': [],
      'カップ': [],
      'ソード': [],
      'ペンタクル': [],
    };
    for (final card in allCards) {
      final filename = card.filename.toLowerCase();
      if (filename.startsWith('major_')) {
        grouped['大アルカナ']!.add(card);
      } else if (filename.contains('wands')) {
        grouped['ワンド']!.add(card);
      } else if (filename.contains('cups')) {
        grouped['カップ']!.add(card);
      } else if (filename.contains('swords')) {
        grouped['ソード']!.add(card);
      } else if (filename.contains('pentacles')) {
        grouped['ペンタクル']!.add(card);
      }
    }
    grouped['大アルカナ']!.sort((a, b) => _compareMajorArcana(a.id, b.id));
    for (final suitKey in ['ワンド', 'カップ', 'ソード', 'ペンタクル']) {
      grouped[suitKey]!.sort((a, b) => _compareMinorArcana(a.id, b.id));
    }
    return grouped;
  }

  /// 比较大阿尔卡纳的排序
  static int _compareMajorArcana(String a, String b) {
    // 提取数字部分 (major_XX_name -> XX)
    final aMatch = RegExp(r'major_(\d+)_').firstMatch(a);
    final bMatch = RegExp(r'major_(\d+)_').firstMatch(b);
    
    if (aMatch != null && bMatch != null) {
      final aNum = int.parse(aMatch.group(1)!);
      final bNum = int.parse(bMatch.group(1)!);
      return aNum.compareTo(bNum);
    }
    
    return a.compareTo(b);
  }

  /// 比较小阿尔卡纳的排序
  static int _compareMinorArcana(String a, String b) {
    // 定义小阿尔卡纳的排序顺序
    const order = [
      'ace', '2', '3', '4', '5', '6', '7', '8', '9', '10',
      'page', 'knight', 'queen', 'king'
    ];
    
    // 提取卡牌类型，基于实际文件名格式 minor_suit_rank
    String getCardType(String id) {
      // 按照优先级顺序检查，匹配 minor_suit_rank 格式
      if (id.endsWith('_ace')) return 'ace';
      if (id.endsWith('_2')) return '2';
      if (id.endsWith('_3')) return '3';
      if (id.endsWith('_4')) return '4';
      if (id.endsWith('_5')) return '5';
      if (id.endsWith('_6')) return '6';
      if (id.endsWith('_7')) return '7';
      if (id.endsWith('_8')) return '8';
      if (id.endsWith('_9')) return '9';
      if (id.endsWith('_10')) return '10';
      if (id.endsWith('_page')) return 'page';
      if (id.endsWith('_knight')) return 'knight';
      if (id.endsWith('_queen')) return 'queen';
      if (id.endsWith('_king')) return 'king';
      
      return id;
    }
    
    final aType = getCardType(a);
    final bType = getCardType(b);
    
    final aIndex = order.indexOf(aType);
    final bIndex = order.indexOf(bType);
    
    if (aIndex != -1 && bIndex != -1) {
      return aIndex.compareTo(bIndex);
    }
    
    return a.compareTo(b);
  }
  
  /// 随机抽取一张牌
  static Future<TarotCard?> getRandomCard() async {
    if (_isOfflineMode) {
      return await LocalDataService.getRandomCard();
    }
    
    try {
      final allCards = await getAllTarotCards();
      if (allCards.isEmpty) return null;
      
      final random = Random();
      return allCards[random.nextInt(allCards.length)];
    } catch (e) {
      print('Supabase随机抽牌失败，切换到离线模式: $e');
      await setOfflineMode(true);
      return await LocalDataService.getRandomCard();
    }
  }
  
  /// 随机抽取一张大阿尔卡纳牌（用于每日抽牌）
  static Future<TarotCard?> getRandomMajorArcanaCard() async {
    List<TarotCard> allCards;
    
    if (_isOfflineMode) {
      allCards = await LocalDataService.getAllTarotCards();
    } else {
      try {
        allCards = await getAllTarotCards();
      } catch (e) {
        print('Supabase随机抽大阿尔卡纳牌失败，切换到离线模式: $e');
        await setOfflineMode(true);
        allCards = await LocalDataService.getAllTarotCards();
      }
    }
    
    // 筛选出大阿尔卡纳牌
    final majorArcanaCards = allCards.where((card) => card.id.startsWith('major_')).toList();
    
    if (majorArcanaCards.isEmpty) return null;
    
    final random = Random();
    final selectedCard = majorArcanaCards[random.nextInt(majorArcanaCards.length)];
    
    // 确保使用当前套牌的 deckId
    final currentDeckId = await DeckService.getCurrentDeckId();
    return selectedCard.copyWith(deckId: currentDeckId);
  }
  
  /// 随机抽取多张牌
  static Future<List<TarotCard>> getRandomCards(int count) async {
    List<TarotCard> allCards;
    
    if (_isOfflineMode) {
      allCards = await LocalDataService.getAllTarotCards();
    } else {
      try {
        allCards = await getAllTarotCards();
      } catch (e) {
        print('Supabase随机抽多张牌失败，切换到离线模式: $e');
        await setOfflineMode(true);
        allCards = await LocalDataService.getAllTarotCards();
      }
    }
    
    if (allCards.isEmpty) return [];
    
    final random = Random();
    final selectedCards = <TarotCard>[];
    final usedIndices = <int>{};
    
    for (int i = 0; i < count && i < allCards.length; i++) {
      int index;
      do {
        index = random.nextInt(allCards.length);
      } while (usedIndices.contains(index));
      
      usedIndices.add(index);
      selectedCards.add(allCards[index]);
    }
    
    // 确保所有卡片使用当前套牌的 deckId
    final currentDeckId = await DeckService.getCurrentDeckId();
    return selectedCards.map((card) => card.copyWith(deckId: currentDeckId)).toList();
  }
  
  /// 尝试重新连接Supabase
  static Future<bool> tryReconnectSupabase() async {
    try {
      await SupabaseService.getAllTarotCards();
      await setOfflineMode(false);
      return true;
    } catch (e) {
      print('重新连接Supabase失败: $e');
      return false;
    }
  }
  
  /// 获取连接状态描述
  static String getConnectionStatus() {
    return _isOfflineMode ? '离线模式' : '在线模式';
  }
} 