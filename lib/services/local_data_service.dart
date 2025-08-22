import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/deck_service.dart';
import 'dart:math';

class LocalDataService {
  static TarotData? _cachedData;
  static List<TarotCard>? _cachedAllCards;
  static Map<String, Map<String, dynamic>>? _cachedSpreadMeta;
  static String? _cachedDataFile;
  
  /// 清除缓存
  static void clearCache() {
    _cachedData = null;
    _cachedAllCards = null;
    _cachedSpreadMeta = null;
    _cachedDataFile = null;
    print('🧹 LocalDataService缓存已清除');
  }
  
  /// 获取完整的塔罗牌数据
  static Future<TarotData> getTarotData([String? dataFile]) async {
    // 如果指定了数据文件且不同于缓存的数据，则清除缓存
    final String actualDataFile = dataFile ?? 'tarot_books_contents.json';
    
    if (_cachedData != null) {
      return _cachedData!;
    }
    
    // 根据文件类型选择加载方式
    final data = await _loadFromSpecificFile(actualDataFile);
    _cachedData = data;
    return data;
  }

  static Future<TarotData> _loadFromProcessedJson() async {
    final String jsonString = await rootBundle.loadString('assets/data/tarot_books_contents.json');
    return await _loadFromProcessedJsonString(jsonString);
  }

  static Future<TarotData> _loadFromProcessedJsonString(String jsonString) async {
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // 组装卡片
    List<TarotCard> allCards = [];
    for (final key in ['major_arcana', 'minor_arcana']) {
      final list = jsonData[key] as List<dynamic>?;
      if (list == null) continue;
      for (final cardData in list) {
        if (cardData is Map<String, dynamic>) {
          final cleaned = _validateAndCleanCardData(cardData);
          if (cleaned != null) {
            allCards.add(TarotCard.fromJson(cleaned));
          }
        }
      }
    }



    // 花色
    Map<String, SuitInfo> suits = {};
    final suitsData = jsonData['minor_suits'] as List<dynamic>?;
    if (suitsData != null) {
      for (final suitData in suitsData) {
        if (suitData is Map<String, dynamic>) {
          final suitInfo = SuitInfo.fromJson(suitData);
          suits[suitInfo.nameEn.toLowerCase()] = suitInfo;
        }
      }
    }

    // daily & spreads（按原结构）
    final daily = jsonData['daily_spread'] != null
        ? SpreadInfo.fromJson(jsonData['daily_spread'])
        : const SpreadInfo(name: '今日のカード', steps: ['心を落ち着けて、カードを一枚引いてください。']);

    Map<String, SpreadInfo> spreads = {};
    final spreadsData = jsonData['spreads'] as List<dynamic>?;
    if (spreadsData != null) {
      for (final s in spreadsData) {
        if (s is Map<String, dynamic>) {
          final info = SpreadInfo(
            name: s['spreads_jp'] ?? '',
            description: null,
            steps: [s['steps'] ?? ''],
          );
          final key = s['spreads_id'] ?? s['spreads_en'] ?? 'unknown';
          spreads[key] = info;
        }
      }
    }

    return TarotData(cards: allCards, suits: suits, dailySpread: daily, spreads: spreads);
  }

  /// 从指定的数据文件加载数据
  static Future<TarotData> _loadFromSpecificFile(String dataFile) async {
    try {
      print('🔄 Loading data file: $dataFile');
      final String jsonString = await rootBundle.loadString('assets/data/$dataFile');
      
      // 检查数据文件格式（contents格式 vs processed格式）
      if (dataFile.contains('contents')) {
        print('✅ Loaded contents format: $dataFile');
        return await _loadFromContentsJsonString(jsonString);
      } else {
        print('✅ Loaded processed format: $dataFile');
        return await _loadFromProcessedJsonString(jsonString);
      }
    } catch (e) {
      print('❌ Error loading data file $dataFile: $e');
      // 如果指定文件加载失败，回退到默认文件
      print('🔄 Falling back to contents.json');
      return await _loadFromContentsJson();
    }
  }

  static Future<TarotData> _loadFromContentsJson() async {
    final String jsonString = await rootBundle.loadString('assets/data/tarot_books_contents.json');
    return await _loadFromContentsJsonString(jsonString);
  }

  static Future<TarotData> _loadFromContentsJsonString(String jsonString) async {
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // 解析卡片：major_arcana 和 minor_arcana 数组
    final List<TarotCard> cards = [];
    
    // Process major arcana
    final majorList = jsonData['major_arcana'] as List<dynamic>?;
    if (majorList != null) {
      for (final cardData in majorList) {
        if (cardData is Map<String, dynamic>) {
          final merged = _mergeContentsCardToProcessedShape(cardData);
          final cleaned = _validateAndCleanCardData(merged);
          if (cleaned != null) {
            cards.add(TarotCard.fromJson(cleaned));
          }
        }
      }
    }
    
    // Process minor arcana
    final minorList = jsonData['minor_arcana'] as List<dynamic>?;
    if (minorList != null) {
      for (final cardData in minorList) {
        if (cardData is Map<String, dynamic>) {
          final merged = _mergeContentsCardToProcessedShape(cardData);
          final cleaned = _validateAndCleanCardData(merged);
          if (cleaned != null) {
            cards.add(TarotCard.fromJson(cleaned));
          }
        }
      }
    }

    // 花色
    Map<String, SuitInfo> suits = {};
    final suitsList = jsonData['minor_suits'] as List<dynamic>?;
    if (suitsList != null) {
      for (final s in suitsList) {
        if (s is Map<String, dynamic>) {
          suits[s['suit_name_en'].toString().toLowerCase()] = SuitInfo(
            nameJp: s['suit_name_jp'] ?? '',
            nameEn: s['suit_name_en'] ?? '',
            story: s['suit_story'] ?? '',
            symbolism: s['suit_symbolism'] ?? '',
          );
        }
      }
    }

    // spreads：沿用 processed 的解析方式（名称/steps）
    Map<String, SpreadInfo> spreads = {};
    final spreadsList = jsonData['spreads'] as List<dynamic>?;
    if (spreadsList != null) {
      for (final s in spreadsList) {
        if (s is Map<String, dynamic>) {
          spreads[s['spreads_id'] ?? s['spreads_en'] ?? 'unknown'] = SpreadInfo(
            name: s['spreads_jp'] ?? '',
            description: null,
            steps: [(s['steps'] ?? '').toString()],
          );
        }
      }
    }

    // daily：没有专门 daily_spread，则给一个默认
    const daily = SpreadInfo(
      name: '今日のカード',
      steps: ['心を落ち着けて、カードを一枚引いてください。'],
    );

    return TarotData(cards: cards, suits: suits, dailySpread: daily, spreads: spreads);
  }

  /// 将 contents.json 的卡片条目映射为 processed_clean.json 期望的字段结构
  static Map<String, dynamic> _mergeContentsCardToProcessedShape(Map<String, dynamic> v) {
    final map = <String, dynamic>{};
    // 基本标识
    map['card_id'] = v['card_id'] ?? '';
    map['name_jp'] = v['name_jp'] ?? v['name'] ?? '';
    map['name_en'] = v['name_en'] ?? '';
    map['filename'] = v['filename'] ?? '';
    // 主文案：story 使用 story_app
    map['story'] = v['story_app'] ?? v['story'] ?? '';
    // meanings
    map['meaning_upright'] = v['meaning_upright'] ?? '';
    map['meaning_reversed'] = v['meaning_reversed'] ?? '';
    // keywords（若无则空数组字符串，后续清洗器会处理）
    map['keywords_upright'] = v['keywords_upright'] ?? '[]';
    map['keywords_reversed'] = v['keywords_reversed'] ?? '[]';
    // messages
    map['message_past_present_future_upright'] = v['message_past_present_future_upright'] ?? '';
    map['message_past_present_future_reversed'] = v['message_past_present_future_reversed'] ?? '';
    map['message_emotion_consciousness_upright'] = v['message_emotion_consciousness_upright'] ?? '';
    map['message_emotion_consciousness_reversed'] = v['message_emotion_consciousness_reversed'] ?? '';
    map['message_cause_solution_upright'] = v['message_cause_solution_upright'] ?? '';
    map['message_cause_solution_reversed'] = v['message_cause_solution_reversed'] ?? '';
    // themes
    map['theme_interpersonal_upright'] = v['theme_interpersonal_upright'] ?? '';
    map['theme_interpersonal_reversed'] = v['theme_interpersonal_reversed'] ?? '';
    map['theme_money_upright'] = v['theme_money_upright'] ?? '';
    map['theme_money_reversed'] = v['theme_money_reversed'] ?? '';
    map['theme_career_upright'] = v['theme_career_upright'] ?? '';
    map['theme_career_reversed'] = v['theme_career_reversed'] ?? '';
    map['theme_love_upright'] = v['theme_love_upright'] ?? '';
    map['theme_love_reversed'] = v['theme_love_reversed'] ?? '';
    // keywords arrays for messages/themes（尽量沿用 processed 的字段名；无则给空数组）
    map['message_past_present_future_upright_keywords'] = v['message_past_present_future_upright_keywords'] ?? <String>[];
    map['message_past_present_future_reversed_keywords'] = v['message_past_present_future_reversed_keywords'] ?? <String>[];
    map['message_emotion_consciousness_upright_keywords'] = v['message_emotion_consciousness_upright_keywords'] ?? <String>[];
    map['message_emotion_consciousness_reversed_keywords'] = v['message_emotion_consciousness_reversed_keywords'] ?? <String>[];
    map['message_cause_solution_upright_keywords'] = v['message_cause_solution_upright_keywords'] ?? <String>[];
    map['message_cause_solution_reversed_keywords'] = v['message_cause_solution_reversed_keywords'] ?? <String>[];
    map['theme_interpersonal_upright_keywords'] = v['theme_interpersonal_upright_keywords'] ?? <String>[];
    map['theme_interpersonal_reversed_keywords'] = v['theme_interpersonal_reversed_keywords'] ?? <String>[];
    map['theme_money_upright_keywords'] = v['theme_money_upright_keywords'] ?? <String>[];
    map['theme_money_reversed_keywords'] = v['theme_money_reversed_keywords'] ?? <String>[];
    map['theme_career_upright_keywords'] = v['theme_career_upright_keywords'] ?? <String>[];
    map['theme_career_reversed_keywords'] = v['theme_career_reversed_keywords'] ?? <String>[];
    map['theme_love_upright_keywords'] = v['theme_love_upright_keywords'] ?? <String>[];
    map['theme_love_reversed_keywords'] = v['theme_love_reversed_keywords'] ?? <String>[];
    return map;
  }

  /// 从 tarot_books_contents.json 读取 spreads 的标题与简介（message）
  static Future<Map<String, Map<String, dynamic>>> getSpreadMeta() async {
    if (_cachedSpreadMeta != null) return _cachedSpreadMeta!;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/tarot_books_contents.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> spreads = (jsonData['spreads'] as List<dynamic>? ) ?? [];
      final Map<String, Map<String, dynamic>> meta = {};
      for (final item in spreads) {
        if (item is Map<String, dynamic>) {
          final id = (item['spreads_id'] ?? '').toString();
          if (id.isEmpty) continue;
          final title = (item['spreads_jp'] ?? '').toString();
          final message = (item['message'] ?? '').toString();
          final steps = (item['steps'] ?? '').toString();
          final questionPoints = (item['質問ポイント'] is List)
              ? List<String>.from(item['質問ポイント'].map((e) => e.toString()))
              : <String>[];
          final questionExamples = (item['質問の例'] is List)
              ? List<String>.from(item['質問の例'].map((e) => e.toString()))
              : <String>[];
          meta[id] = {
            'title': title,
            'message': message,
            'steps': steps,
            'question_points': questionPoints,
            'question_examples': questionExamples,
          };
        }
      }
      _cachedSpreadMeta = meta;
      return meta;
    } catch (e) {
      print('读取tarot_books_contents.json失败: $e');
      return {};
    }
  }
  
  /// 后备方案：加载旧的数据格式
  static TarotData _loadFallbackData() {
    try {
      // 创建示例卡片数据，包含所有必需字段
      final sampleCards = <TarotCard>[];
      
      // 添加一张示例大阿尔卡纳卡片（愚者）
      sampleCards.add(TarotCard(
        id: 'major_00_fool',
        nameJa: '愚者',
        nameEn: 'The Fool',
        filename: 'major_00_fool.png',
        story: '新たな始まりの象徴',
        meaningUpright: '新しい始まり、純粋さ、自由',
        meaningReversed: '軽率、愚かさ、危険',
        keywordsUpright: "['新しい始まり', '冒険', '自由']",
        keywordsReversed: "['軽率', '愚かさ', '危険']",
        messagePastPresentFutureUpright: '新しい冒険が始まります',
        messagePastPresentFutureReversed: '注意深く進む必要があります',
        messageEmotionConsciousnessUpright: '直感を信じてください',
        messageEmotionConsciousnessReversed: '感情的になりすぎています',
        messageCauseSolutionUpright: '新しい視点で問題を見てください',
        messageCauseSolutionReversed: '計画を見直す必要があります',
        themeInterpersonalUpright: '新しい人との出会い',
        themeInterpersonalReversed: '関係における軽率さ',
        themeMoneyUpright: '新しい投資機会',
        themeMoneyReversed: '金銭的な軽率さ',
        themeCareerUpright: '新しいキャリアの始まり',
        themeCareerReversed: '仕事での軽率な決定',
        themeLoveUpright: '新しい恋の始まり',
        themeLoveReversed: '恋愛での軽率さ',
        messagePastPresentFutureUprightKeywords: ['希望', '新天地'],
        messagePastPresentFutureReversedKeywords: ['軽率', '危険'],
        messageEmotionConsciousnessUprightKeywords: ['直感', '信頼'],
        messageEmotionConsciousnessReversedKeywords: ['感情的', '混乱'],
        messageCauseSolutionUprightKeywords: ['新視点', '解決'],
        messageCauseSolutionReversedKeywords: ['見直し', '計画'],
        themeInterpersonalUprightKeywords: ['出会い', '新関係'],
        themeInterpersonalReversedKeywords: ['軽率', '関係問題'],
        themeMoneyUprightKeywords: ['投資', '機会'],
        themeMoneyReversedKeywords: ['軽率', '金銭問題'],
        themeCareerUprightKeywords: ['新キャリア', '始まり'],
        themeCareerReversedKeywords: ['軽率', '決定ミス'],
        themeLoveUprightKeywords: ['新恋愛', '純粋'],
        themeLoveReversedKeywords: ['軽率', '恋愛問題'],
      ));

      final suits = <String, SuitInfo>{
        'wands': const SuitInfo(
          nameJp: 'ワンド',
          nameEn: 'Wands',
          story: '火の元素を表す',
          symbolism: '創造力と情熱',
        ),
        'cups': const SuitInfo(
          nameJp: 'カップ',
          nameEn: 'Cups',
          story: '水の元素を表す',
          symbolism: '感情と直感',
        ),
        'swords': const SuitInfo(
          nameJp: 'ソード',
          nameEn: 'Swords',
          story: '風の元素を表す',
          symbolism: '思考と知性',
        ),
        'pentacles': const SuitInfo(
          nameJp: 'ペンタクル',
          nameEn: 'Pentacles',
          story: '地の元素を表す',
          symbolism: '物質と安定',
        ),
      };

      const dailySpread = SpreadInfo(
        name: '今日のカード',
        description: '今日の運勢を占います',
        steps: ['心を落ち着けて、カードを一枚引いてください'],
      );

      final spreads = <String, SpreadInfo>{
        'one_card': const SpreadInfo(
          name: 'ワンオラクル',
          description: '一つの質問に答えを出します',
          steps: ['質問を心に念じて、カードを一枚引いてください'],
        ),
        'three_card': const SpreadInfo(
          name: 'スリーカード',
          description: '過去、現在、未来を見通します',
          steps: ['過去、現在、未来を思い描きながら、三枚のカードを引いてください'],
        ),
      };

      return TarotData(
        cards: sampleCards,
        suits: suits,
        dailySpread: dailySpread,
        spreads: spreads,
      );
    } catch (e) {
      print('Fallback data creation failed: $e');
      // 返回空数据以避免应用崩溃
      return const TarotData(
        cards: [],
        suits: {},
        dailySpread: SpreadInfo(
          name: 'デフォルト',
          steps: ['カードを引いてください'],
        ),
        spreads: {},
      );
    }
  }
  
  /// 获取所有塔罗牌数据
  static Future<List<TarotCard>> getAllTarotCards([String? dataFile]) async {
    // 如果指定了数据文件且不同于缓存的数据，则清除缓存
    final String actualDataFile = dataFile ?? 'tarot_books_contents.json';
    
    if (_cachedAllCards != null && _cachedDataFile == actualDataFile) {
      return _cachedAllCards!;
    }
    
    final data = await getTarotData(actualDataFile);
    _cachedAllCards = [...data.cards];
    _cachedDataFile = actualDataFile;
    return _cachedAllCards!;
  }
  
  /// 获取花色信息
  static Future<List<SuitInfo>> getSuits() async {
    final data = await getTarotData();
    return data.suits.values.toList();
  }


  
  /// 获取展开方式信息
  static Future<List<SpreadInfo>> getSpreads() async {
    final data = await getTarotData();
    return data.spreads.values.toList();
  }
  
  /// 根据ID获取塔罗牌
  static Future<TarotCard?> getTarotCard(String cardId, [String? dataFile]) async {
    final allCards = await getAllTarotCards(dataFile);
    try {
      return allCards.firstWhere((card) => card.id == cardId);
    } catch (e) {
      return null;
    }
  }
  
  /// 随机抽取一张牌
  static Future<TarotCard?> getRandomCard() async {
    final allCards = await getAllTarotCards();
    if (allCards.isEmpty) return null;
    
    final random = Random();
    return allCards[random.nextInt(allCards.length)];
  }
  
  /// 随机抽取一张大阿尔卡纳牌（用于每日抽牌）
  static Future<TarotCard?> getRandomMajorArcanaCard() async {
    final allCards = await getAllTarotCards();
    // 筛选出大阿尔卡纳牌
    final majorArcanaCards = allCards.where((card) => card.id.startsWith('major_')).toList();
    
    if (majorArcanaCards.isEmpty) return null;
    
    final random = Random();
    return majorArcanaCards[random.nextInt(majorArcanaCards.length)];
  }
  
  /// 随机抽取多张牌
  static Future<List<TarotCard>> getRandomCards(int count) async {
    final allCards = await getAllTarotCards();
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
    
    return selectedCards;
  }
  
  /// 搜索塔罗牌
  static Future<List<TarotCard>> searchCards(String query) async {
    final allCards = await getAllTarotCards();
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    final results = allCards.where((card) {
      return card.nameJa.toLowerCase().contains(lowerQuery) ||
             card.nameEn.toLowerCase().contains(lowerQuery) ||
             card.meaningUpright.toLowerCase().contains(lowerQuery) ||
             card.meaningReversed.toLowerCase().contains(lowerQuery) ||
             card.story.toLowerCase().contains(lowerQuery);
    }).toList();
    
    // 对搜索结果进行排序
    results.sort((a, b) {
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
    
    return results;
  }
  
  /// 获取大阿尔卡纳牌
  static Future<List<TarotCard>> getMajorArcana() async {
    final data = await getTarotData();
    final majorCards = data.cards.where((card) => card.id.startsWith('major_')).toList();
    
    // 对大阿尔卡纳进行排序
    majorCards.sort((a, b) => _compareMajorArcana(a.id, b.id));
    
    return majorCards;
  }
  
  /// 获取小阿尔卡纳
  static Future<Map<String, List<TarotCard>>> getMinorArcanaBysuit() async {
    final data = await getTarotData();
    final minorCards = data.cards.where((card) => !card.id.startsWith('major_')).toList();
    
    Map<String, List<TarotCard>> groupedCards = {
      'ワンド': [],
      'カップ': [],
      'ソード': [],
      'ペンタクル': [],
    };
    
    for (final card in minorCards) {
      if (card.id.contains('wands')) {
        groupedCards['ワンド']!.add(card);
      } else if (card.id.contains('cups')) {
        groupedCards['カップ']!.add(card);
      } else if (card.id.contains('swords')) {
        groupedCards['ソード']!.add(card);
      } else if (card.id.contains('pentacles')) {
        groupedCards['ペンタクル']!.add(card);
      }
    }
    
    // 对小阿尔卡纳各花色进行排序
    for (final suitKey in ['ワンド', 'カップ', 'ソード', 'ペンタクル']) {
      groupedCards[suitKey]!.sort((a, b) => _compareMinorArcana(a.id, b.id));
    }
    
    return groupedCards;
  }
  
  /// 根据分组获取塔罗牌
  static Future<Map<String, List<TarotCard>>> getGroupedCards() async {
    final data = await getTarotData();
    final majorCards = data.cards.where((card) => card.id.startsWith('major_')).toList();
    
    // 对大阿尔卡纳进行排序
    majorCards.sort((a, b) => _compareMajorArcana(a.id, b.id));
    
    Map<String, List<TarotCard>> groupedCards = {
      '大アルカナ': majorCards,
    };

    // 处理小阿尔卡纳
    final minorCards = data.cards.where((card) => !card.id.startsWith('major_')).toList();
    for (final card in minorCards) {
      if (card.id.contains('wands')) {
        groupedCards.putIfAbsent('ワンド', () => []).add(card);
      } else if (card.id.contains('cups')) {
        groupedCards.putIfAbsent('カップ', () => []).add(card);
      } else if (card.id.contains('swords')) {
        groupedCards.putIfAbsent('ソード', () => []).add(card);
      } else if (card.id.contains('pentacles')) {
        groupedCards.putIfAbsent('ペンタクル', () => []).add(card);
      }
    }

    // 对小阿尔卡纳各花色进行排序
    for (final suitKey in ['ワンド', 'カップ', 'ソード', 'ペンタクル']) {
      if (groupedCards[suitKey] != null) {
        groupedCards[suitKey]!.sort((a, b) => _compareMinorArcana(a.id, b.id));
      }
    }

    return groupedCards;
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
  
  /// 验证和清理卡片数据
  static Map<String, dynamic>? _validateAndCleanCardData(Map<String, dynamic> cardData) {
    try {
      // 检查所有必需的字符串字段
      final requiredStringFields = [
        'card_id', 'name_jp', 'name_en', 'filename', 'story',
        'meaning_upright', 'meaning_reversed', 'keywords_upright', 'keywords_reversed',
        'message_past_present_future_upright', 'message_past_present_future_reversed',
        'message_emotion_consciousness_upright', 'message_emotion_consciousness_reversed',
        'message_cause_solution_upright', 'message_cause_solution_reversed',
        'theme_interpersonal_upright', 'theme_interpersonal_reversed',
        'theme_money_upright', 'theme_money_reversed',
        'theme_career_upright', 'theme_career_reversed',
        'theme_love_upright', 'theme_love_reversed'
      ];

      // 检查所有必需的列表字段
      final requiredListFields = [
        'message_past_present_future_upright_keywords',
        'message_past_present_future_reversed_keywords',
        'message_emotion_consciousness_upright_keywords',
        'message_emotion_consciousness_reversed_keywords',
        'message_cause_solution_upright_keywords',
        'message_cause_solution_reversed_keywords',
        'theme_interpersonal_upright_keywords',
        'theme_interpersonal_reversed_keywords',
        'theme_money_upright_keywords',
        'theme_money_reversed_keywords',
        'theme_career_upright_keywords',
        'theme_career_reversed_keywords',
        'theme_love_upright_keywords',
        'theme_love_reversed_keywords'
      ];

      final cleanedData = Map<String, dynamic>.from(cardData);

      // 验证和清理字符串字段
      for (final field in requiredStringFields) {
        if (!cleanedData.containsKey(field) || cleanedData[field] == null) {
          cleanedData[field] = '';
        } else if (cleanedData[field] is! String) {
          cleanedData[field] = cleanedData[field].toString();
        }
      }

      // 验证和清理列表字段
      for (final field in requiredListFields) {
        if (!cleanedData.containsKey(field) || cleanedData[field] == null) {
          cleanedData[field] = <String>[];
        } else if (cleanedData[field] is List) {
          final list = cleanedData[field] as List;
          cleanedData[field] = list.map((e) => e?.toString() ?? '').toList();
        } else if (cleanedData[field] is String) {
          // 处理字符串形式的数组表示
          final stringValue = cleanedData[field] as String;
          try {
            // 尝试解析字符串形式的数组（如 "['a', 'b', 'c']"）
            if (stringValue.trim().startsWith('[') && stringValue.trim().endsWith(']')) {
              final parsedList = stringValue
                  .substring(1, stringValue.length - 1) // 移除 [ 和 ]
                  .split(',')
                  .map((item) => item.trim().replaceAll(RegExp(r"^'|'$"), '')) // 移除单引号
                  .where((item) => item.isNotEmpty)
                  .toList();
              cleanedData[field] = parsedList;
            } else {
              cleanedData[field] = <String>[];
            }
          } catch (e) {
            cleanedData[field] = <String>[];
          }
        } else {
          cleanedData[field] = <String>[];
        }
      }

      // 处理特殊的keywords字段（它们存储为字符串形式的数组）
      final keywordFields = ['keywords_upright', 'keywords_reversed'];
      for (final field in keywordFields) {
        if (cleanedData.containsKey(field) && cleanedData[field] is String) {
          final stringValue = cleanedData[field] as String;
          try {
            if (stringValue.trim().startsWith('[') && stringValue.trim().endsWith(']')) {
              final parsedList = stringValue
                  .substring(1, stringValue.length - 1)
                  .split(',')
                  .map((item) => item.trim().replaceAll(RegExp(r"^'|'$"), ''))
                  .where((item) => item.isNotEmpty)
                  .toList();
              cleanedData[field] = parsedList.join(', '); // 保持为字符串，因为模型期望字符串
            }
          } catch (e) {
            cleanedData[field] = '';
          }
        }
      }

      // 处理可选的数字字段
      if (cleanedData.containsKey('page_number') && cleanedData['page_number'] != null) {
        if (cleanedData['page_number'] is! num) {
          try {
            cleanedData['page_number'] = num.parse(cleanedData['page_number'].toString());
          } catch (e) {
            cleanedData['page_number'] = null;
          }
        }
      }

      return cleanedData;
    } catch (e) {
      print('数据验证失败: $e');
      return null;
    }
  }
} 