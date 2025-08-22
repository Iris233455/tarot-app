import 'dart:convert';
import 'enhanced_tarot_data.dart';

/// JSON数据转换器 - 将现有JSON数据转换为增强的数据结构
class JsonDataConverter {
  
  /// 从JSON字符串转换为增强的塔罗牌数据
  static List<EnhancedTarotCard> convertFromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<EnhancedTarotCard> cards = [];
    
    // 转换大阿卡那牌
    if (data['major_arcana'] != null) {
      final majorArcana = data['major_arcana'] as List;
      for (final cardData in majorArcana) {
        cards.add(_convertCardData(cardData));
      }
    }
    
    // 转换小阿卡那牌
    if (data['minor_arcana'] != null) {
      final minorArcana = data['minor_arcana'] as List;
      for (final cardData in minorArcana) {
        cards.add(_convertCardData(cardData));
      }
    }
    
    return cards;
  }
  
  /// 转换单张牌的数据
  static EnhancedTarotCard _convertCardData(Map<String, dynamic> cardData) {
    return EnhancedTarotCard(
      cardId: cardData['card_id'] ?? '',
      nameJp: cardData['name_jp'] ?? '',
      nameEn: cardData['name_en'] ?? '',
      story: cardData['story'] ?? '',
      meaningUpright: cardData['meaning_upright'] ?? '',
      meaningReversed: cardData['meaning_reversed'] ?? '',
      keywordsUpright: _parseKeywords(cardData['keywords_upright']),
      keywordsReversed: _parseKeywords(cardData['keywords_reversed']),
      themeInterpretations: _extractThemeInterpretations(cardData),
      contextMessages: _extractContextMessages(cardData),
      // 向量嵌入字段暂时为空，可以后续添加
      storyEmbedding: null,
      meaningEmbedding: null,
      themeEmbeddings: null,
    );
  }
  
  /// 解析关键词字符串
  static List<String> _parseKeywords(dynamic keywordsData) {
    if (keywordsData == null) return [];
    
    if (keywordsData is String) {
      // 处理字符串格式的关键词（可能是JSON数组字符串）
      try {
        final parsed = json.decode(keywordsData);
        if (parsed is List) {
          return parsed.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // 如果解析失败，尝试按逗号分割
        return keywordsData.split(',').map((e) => e.trim()).toList();
      }
    } else if (keywordsData is List) {
      return keywordsData.map((e) => e.toString()).toList();
    }
    
    return [];
  }
  
  /// 提取主题解释
  static Map<TarotTheme, TarotThemeInterpretation> _extractThemeInterpretations(Map<String, dynamic> cardData) {
    final Map<TarotTheme, TarotThemeInterpretation> interpretations = {};
    
    // 爱情主题
    if (cardData['theme_love_upright'] != null && cardData['theme_love_reversed'] != null) {
      interpretations[TarotTheme.love] = TarotThemeInterpretation(
        upright: cardData['theme_love_upright'] ?? '',
        reversed: cardData['theme_love_reversed'] ?? '',
        uprightKeywords: _parseKeywords(cardData['theme_love_upright_keywords']),
        reversedKeywords: _parseKeywords(cardData['theme_love_reversed_keywords']),
      );
    }
    
    // 事业主题
    if (cardData['theme_career_upright'] != null && cardData['theme_career_reversed'] != null) {
      interpretations[TarotTheme.career] = TarotThemeInterpretation(
        upright: cardData['theme_career_upright'] ?? '',
        reversed: cardData['theme_career_reversed'] ?? '',
        uprightKeywords: _parseKeywords(cardData['theme_career_upright_keywords']),
        reversedKeywords: _parseKeywords(cardData['theme_career_reversed_keywords']),
      );
    }
    
    // 金钱主题
    if (cardData['theme_money_upright'] != null && cardData['theme_money_reversed'] != null) {
      interpretations[TarotTheme.money] = TarotThemeInterpretation(
        upright: cardData['theme_money_upright'] ?? '',
        reversed: cardData['theme_money_reversed'] ?? '',
        uprightKeywords: _parseKeywords(cardData['theme_money_upright_keywords']),
        reversedKeywords: _parseKeywords(cardData['theme_money_reversed_keywords']),
      );
    }
    
    // 人际关系主题
    if (cardData['theme_interpersonal_upright'] != null && cardData['theme_interpersonal_reversed'] != null) {
      interpretations[TarotTheme.interpersonal] = TarotThemeInterpretation(
        upright: cardData['theme_interpersonal_upright'] ?? '',
        reversed: cardData['theme_interpersonal_reversed'] ?? '',
        uprightKeywords: _parseKeywords(cardData['theme_interpersonal_upright_keywords']),
        reversedKeywords: _parseKeywords(cardData['theme_interpersonal_reversed_keywords']),
      );
    }
    
    return interpretations;
  }
  
  /// 提取情境消息
  static Map<TarotContext, TarotContextMessage> _extractContextMessages(Map<String, dynamic> cardData) {
    final Map<TarotContext, TarotContextMessage> messages = {};
    
    // 过去现在未来情境
    if (cardData['message_past_present_future_upright'] != null && 
        cardData['message_past_present_future_reversed'] != null) {
      messages[TarotContext.pastPresentFuture] = TarotContextMessage(
        upright: cardData['message_past_present_future_upright'] ?? '',
        reversed: cardData['message_past_present_future_reversed'] ?? '',
        uprightKeywords: _parseKeywords(cardData['message_past_present_future_upright_keywords']),
        reversedKeywords: _parseKeywords(cardData['message_past_present_future_reversed_keywords']),
      );
    }
    
    // 情感意识情境
    if (cardData['message_emotion_consciousness_upright'] != null && 
        cardData['message_emotion_consciousness_reversed'] != null) {
      messages[TarotContext.emotionConsciousness] = TarotContextMessage(
        upright: cardData['message_emotion_consciousness_upright'] ?? '',
        reversed: cardData['message_emotion_consciousness_reversed'] ?? '',
        uprightKeywords: _parseKeywords(cardData['message_emotion_consciousness_upright_keywords']),
        reversedKeywords: _parseKeywords(cardData['message_emotion_consciousness_reversed_keywords']),
      );
    }
    
    // 原因解决情境
    if (cardData['message_cause_solution_upright'] != null && 
        cardData['message_cause_solution_reversed'] != null) {
      messages[TarotContext.causeSolution] = TarotContextMessage(
        upright: cardData['message_cause_solution_upright'] ?? '',
        reversed: cardData['message_cause_solution_reversed'] ?? '',
        uprightKeywords: _parseKeywords(cardData['message_cause_solution_upright_keywords']),
        reversedKeywords: _parseKeywords(cardData['message_cause_solution_reversed_keywords']),
      );
    }
    
    return messages;
  }
  
  /// 加载并转换JSON文件数据
  static Future<List<EnhancedTarotCard>> loadFromAsset(String assetPath) async {
    try {
      // 这里需要使用Flutter的rootBundle来加载资产文件
      // 由于这是一个纯Dart文件，我们暂时返回空列表
      // 在实际使用时，需要在Widget中调用此方法并传入JSON字符串
      return [];
    } catch (e) {
      print('加载JSON数据时出错: $e');
      return [];
    }
  }
  
  /// 创建示例数据（用于测试）
  static List<EnhancedTarotCard> createSampleData() {
    return [
      EnhancedTarotCard(
        cardId: 'major_00_fool',
        nameJp: '愚者',
        nameEn: 'The Fool',
        story: '新たな始まり\n未知への探求心と希望を抱く若者の軽い足取り...',
        meaningUpright: '新しいことが始まる\n新たな一歩を踏み出そうという旅立ちの兆し...',
        meaningReversed: '状況が混乱している\n心の奥底に秘めた夢や目標、思いがありながら...',
        keywordsUpright: ['冒険', '自由', '無限の可能性', '純粋', '新しい旅'],
        keywordsReversed: ['無計画', '愚かさ', '軽率', '過信', '迷い'],
        themeInterpretations: {
          TarotTheme.love: TarotThemeInterpretation(
            upright: '自分を変えてくれる情熱的な恋がしたいという期待を抱いています。',
            reversed: '先の見えない関係がストレスになっている可能性あり。',
            uprightKeywords: ['新しい恋', '情熱', '冒険的な愛'],
            reversedKeywords: ['不安定', '迷い', '先が見えない'],
          ),
          TarotTheme.career: TarotThemeInterpretation(
            upright: '大躍進の始まり。挑戦したいことがあるなら、いよいよ実行に移すチャンス。',
            reversed: '何かしたいという気持ちだけで空回りしているようです。',
            uprightKeywords: ['新しい挑戦', '転職', '起業'],
            reversedKeywords: ['計画不足', '空回り', '迷い'],
          ),
        },
        contextMessages: {
          TarotContext.pastPresentFuture: TarotContextMessage(
            upright: '環境や人生に大きな変化が訪れようとしています。',
            reversed: 'どうせ無理だと決めつけて、見ないように避けている問題があるのかも。',
            uprightKeywords: ['希望にあふれている', '自由', '新天地'],
            reversedKeywords: ['タイミングを逃す', '状況が整わない'],
          ),
        },
      ),
    ];
  }
  
  /// 验证转换后的数据完整性
  static ValidationResult validateConvertedData(List<EnhancedTarotCard> cards) {
    final issues = <String>[];
    final warnings = <String>[];
    
    if (cards.isEmpty) {
      issues.add('変換されたカードデータが空です');
      return ValidationResult(isValid: false, issues: issues, warnings: warnings);
    }
    
    for (final card in cards) {
      // 检查基本字段
      if (card.cardId.isEmpty) {
        issues.add('カードIDが空です: ${card.nameJp}');
      }
      
      if (card.nameJp.isEmpty) {
        issues.add('日本語名が空です: ${card.cardId}');
      }
      
      if (card.story.isEmpty) {
        warnings.add('ストーリーが空です: ${card.nameJp}');
      }
      
      // 检查主题解释的完整性
      if (card.themeInterpretations.isEmpty) {
        warnings.add('テーマ解釈がありません: ${card.nameJp}');
      }
      
      // 检查关键词
      if (card.keywordsUpright.isEmpty && card.keywordsReversed.isEmpty) {
        warnings.add('キーワードが設定されていません: ${card.nameJp}');
      }
    }
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      warnings: warnings,
    );
  }
  
  /// 统计转换后的数据
  static DataStats generateStats(List<EnhancedTarotCard> cards) {
    final majorArcanaCount = cards.where((c) => c.cardId.startsWith('major')).length;
    final minorArcanaCount = cards.where((c) => c.cardId.startsWith('minor')).length;
    
    final themesCoverage = <TarotTheme, int>{};
    final contextsCoverage = <TarotContext, int>{};
    
    for (final theme in TarotTheme.values) {
      themesCoverage[theme] = cards.where((c) => c.themeInterpretations.containsKey(theme)).length;
    }
    
    for (final context in TarotContext.values) {
      contextsCoverage[context] = cards.where((c) => c.contextMessages.containsKey(context)).length;
    }
    
    return DataStats(
      totalCards: cards.length,
      majorArcanaCount: majorArcanaCount,
      minorArcanaCount: minorArcanaCount,
      themesCoverage: themesCoverage,
      contextsCoverage: contextsCoverage,
    );
  }
}

/// 验证结果类
class ValidationResult {
  final bool isValid;
  final List<String> issues;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.warnings,
  });
}

/// 数据统计类
class DataStats {
  final int totalCards;
  final int majorArcanaCount;
  final int minorArcanaCount;
  final Map<TarotTheme, int> themesCoverage;
  final Map<TarotContext, int> contextsCoverage;

  const DataStats({
    required this.totalCards,
    required this.majorArcanaCount,
    required this.minorArcanaCount,
    required this.themesCoverage,
    required this.contextsCoverage,
  });
  
  @override
  String toString() {
    return '''
データ統計:
- 総カード数: $totalCards
- 大アルカナ: $majorArcanaCount
- 小アルカナ: $minorArcanaCount
- テーマカバレッジ: $themesCoverage
- コンテキストカバレッジ: $contextsCoverage
''';
  }
}