import '../data/enhanced_tarot_data.dart';
import '../classifiers/question_classifier.dart';

// 多卡组合解读器 - 处理2卡选择、3卡时间线等组合解读逻辑
class CardCombinationInterpreter {
  
  // 两卡比较解读（用于选择决策）
  static TarotCombinationReading interpretTwoCardChoice({
    required List<EnhancedTarotCard> cards,
    required TarotQuestionAnalysis questionAnalysis,
    required List<bool> isReversed,
  }) {
    assert(cards.length == 2, '两卡解读需要恰好2张牌');
    assert(isReversed.length == 2, '逆位信息需要与卡片数量匹配');
    
    final cardA = cards[0];
    final cardB = cards[1];
    final isReversedA = isReversed[0];
    final isReversedB = isReversed[1];
    
    // 获取主题相关的解释
    final themeA = _getThemeInterpretation(cardA, questionAnalysis.detectedTheme, isReversedA);
    final themeB = _getThemeInterpretation(cardB, questionAnalysis.detectedTheme, isReversedB);
    
    // 比较分析
    final comparison = _compareCards(cardA, cardB, isReversedA, isReversedB, questionAnalysis.detectedTheme);
    
    // 生成建议
    final recommendation = _generateChoiceRecommendation(
      cardA, cardB, isReversedA, isReversedB, 
      questionAnalysis.detectedTheme, comparison
    );
    
    return TarotCombinationReading(
      readingType: CombinationReadingType.twoCardChoice,
      cards: cards,
      isReversed: isReversed,
      mainInterpretation: _buildTwoCardChoiceInterpretation(
        cardA, cardB, themeA, themeB, comparison, recommendation
      ),
      individualCardMeanings: [
        _buildIndividualMeaning(cardA, isReversedA, questionAnalysis.detectedTheme, ' 選択肢A'),
        _buildIndividualMeaning(cardB, isReversedB, questionAnalysis.detectedTheme, '選択肢B'),
      ],
      combinationInsights: comparison,
      recommendation: recommendation,
      confidence: _calculateCombinationConfidence(cards, questionAnalysis.detectedTheme),
    );
  }
  
  // 三卡时间线解读（过去现在未来）
  static TarotCombinationReading interpretThreeCardTimeline({
    required List<EnhancedTarotCard> cards,
    required TarotQuestionAnalysis questionAnalysis,
    required List<bool> isReversed,
  }) {
    assert(cards.length == 3, '三卡解读需要恰好3张牌');
    assert(isReversed.length == 3, '逆位信息需要与卡片数量匹配');
    
    final pastCard = cards[0];
    final presentCard = cards[1];
    final futureCard = cards[2];
    
    // 获取时间维度的解释
    final pastMeaning = _getTimeContextInterpretation(pastCard, isReversed[0], TimePosition.past);
    final presentMeaning = _getTimeContextInterpretation(presentCard, isReversed[1], TimePosition.present);
    final futureMeaning = _getTimeContextInterpretation(futureCard, isReversed[2], TimePosition.future);
    
    // 分析时间线趋势
    final timelineTrend = _analyzeTimelineTrend(cards, isReversed);
    
    // 生成综合解读
    final overallNarrative = _buildTimelineNarrative(
      pastMeaning, presentMeaning, futureMeaning, timelineTrend, questionAnalysis.detectedTheme
    );
    
    return TarotCombinationReading(
      readingType: CombinationReadingType.threeCardTimeline,
      cards: cards,
      isReversed: isReversed,
      mainInterpretation: overallNarrative,
      individualCardMeanings: [
        _buildIndividualMeaning(pastCard, isReversed[0], questionAnalysis.detectedTheme, '過去'),
        _buildIndividualMeaning(presentCard, isReversed[1], questionAnalysis.detectedTheme, '現在'),
        _buildIndividualMeaning(futureCard, isReversed[2], questionAnalysis.detectedTheme, '未来'),
      ],
      combinationInsights: {
        'timeline_trend': timelineTrend,
        'energy_flow': _analyzeEnergyFlow(cards, isReversed),
        'key_transition_points': _identifyTransitionPoints(cards, isReversed),
      },
      recommendation: _generateTimelineAdvice(cards, isReversed, timelineTrend, questionAnalysis.detectedTheme),
      confidence: _calculateCombinationConfidence(cards, questionAnalysis.detectedTheme),
    );
  }
  
  // 单卡深度解读
  static TarotCombinationReading interpretSingleCard({
    required EnhancedTarotCard card,
    required TarotQuestionAnalysis questionAnalysis,
    required bool isReversed,
  }) {
    final themeInterpretation = _getThemeInterpretation(card, questionAnalysis.detectedTheme, isReversed);
    final contextMessage = _getContextMessage(card, questionAnalysis.questionType, isReversed);
    
    return TarotCombinationReading(
      readingType: CombinationReadingType.singleCard,
      cards: [card],
      isReversed: [isReversed],
      mainInterpretation: _buildSingleCardInterpretation(card, themeInterpretation, contextMessage, questionAnalysis),
      individualCardMeanings: [
        _buildIndividualMeaning(card, isReversed, questionAnalysis.detectedTheme, 'メインカード'),
      ],
      combinationInsights: {
        'card_energy': _analyzeCardEnergy(card, isReversed),
        'theme_alignment': _calculateThemeAlignment(card, questionAnalysis.detectedTheme),
      },
      recommendation: _generateSingleCardAdvice(card, isReversed, questionAnalysis),
      confidence: questionAnalysis.confidence,
    );
  }
  
  // 獲取主題解釋
  static String _getThemeInterpretation(EnhancedTarotCard card, TarotTheme theme, bool isReversed) {
    if (card.themeInterpretations.containsKey(theme)) {
      final interpretation = card.themeInterpretations[theme]!;
      return isReversed ? interpretation.reversed : interpretation.upright;
    }
    return isReversed ? card.meaningReversed : card.meaningUpright;
  }
  
  // 獲取情境消息
  static String _getContextMessage(EnhancedTarotCard card, QuestionType questionType, bool isReversed) {
    TarotContext? context;
    
    switch (questionType) {
      case QuestionType.timing:
      case QuestionType.outcome:
        context = TarotContext.pastPresentFuture;
        break;
      case QuestionType.advice:
        context = TarotContext.causeSolution;
        break;
      default:
        context = TarotContext.emotionConsciousness;
    }
    
    if (card.contextMessages.containsKey(context)) {
      final message = card.contextMessages[context]!;
      return isReversed ? message.reversed : message.upright;
    }
    
    return isReversed ? card.meaningReversed : card.meaningUpright;
  }
  
  // 獲取時間情境解釋
  static String _getTimeContextInterpretation(EnhancedTarotCard card, bool isReversed, TimePosition position) {
    if (card.contextMessages.containsKey(TarotContext.pastPresentFuture)) {
      final message = card.contextMessages[TarotContext.pastPresentFuture]!;
      final baseMessage = isReversed ? message.reversed : message.upright;
      
      // 根據時間位置添加特定含義
      switch (position) {
        case TimePosition.past:
          return '【過去の影響】$baseMessage';
        case TimePosition.present:
          return '【現在の状況】$baseMessage';
        case TimePosition.future:
          return '【未来の可能性】$baseMessage';
      }
    }
    
    return isReversed ? card.meaningReversed : card.meaningUpright;
  }
  
  // 比較兩張牌
  static Map<String, dynamic> _compareCards(
    EnhancedTarotCard cardA, EnhancedTarotCard cardB,
    bool isReversedA, bool isReversedB,
    TarotTheme theme
  ) {
    return {
      'energy_comparison': _compareEnergy(cardA, cardB, isReversedA, isReversedB),
      'theme_strength': _compareThemeStrength(cardA, cardB, theme),
      'stability_vs_change': _analyzeStabilityVsChange(cardA, cardB, isReversedA, isReversedB),
      'recommended_choice': _determineRecommendedChoice(cardA, cardB, isReversedA, isReversedB, theme),
    };
  }
  
  static String _compareEnergy(EnhancedTarotCard cardA, EnhancedTarotCard cardB, bool revA, bool revB) {
    final energyA = revA ? 'blocked' : 'flowing';
    final energyB = revB ? 'blocked' : 'flowing';
    
    if (energyA == 'flowing' && energyB == 'blocked') {
      return '選択肢Aはエネルギーが流れており、選択肢Bは停滞している';
    } else if (energyA == 'blocked' && energyB == 'flowing') {
      return '選択肢Bはエネルギーが流れており、選択肢Aは停滞している';
    } else if (energyA == 'flowing' && energyB == 'flowing') {
      return '両方の選択肢ともエネルギーが良好に流れている';
    } else {
      return '両方の選択肢とも現在は停滞している状況';
    }
  }
  
  static String _compareThemeStrength(EnhancedTarotCard cardA, EnhancedTarotCard cardB, TarotTheme theme) {
    final strengthA = cardA.themeInterpretations.containsKey(theme) ? 'strong' : 'weak';
    final strengthB = cardB.themeInterpretations.containsKey(theme) ? 'strong' : 'weak';
    
    if (strengthA == 'strong' && strengthB == 'weak') {
      return '選択肢Aがこのテーマにより適している';
    } else if (strengthA == 'weak' && strengthB == 'strong') {
      return '選択肢Bがこのテーマにより適している';
    } else {
      return '両方の選択肢とも同程度の関連性がある';
    }
  }
  
  // 其他輔助方法...
  static String _analyzeStabilityVsChange(EnhancedTarotCard cardA, EnhancedTarotCard cardB, bool revA, bool revB) {
    // 這裡可以根據牌的性質分析穩定性與變化的傾向
    return '変化と安定性のバランスを考慮する必要がある';
  }
  
  static String _determineRecommendedChoice(EnhancedTarotCard cardA, EnhancedTarotCard cardB, bool revA, bool revB, TarotTheme theme) {
    // 基於分析結果給出推薦
    if (!revA && revB) return 'A';
    if (revA && !revB) return 'B';
    return '慎重に検討する';
  }
  
  static String _analyzeTimelineTrend(List<EnhancedTarotCard> cards, List<bool> isReversed) {
    final trends = <String>[];
    
    for (int i = 0; i < cards.length; i++) {
      if (!isReversed[i]) {
        trends.add('positive');
      } else {
        trends.add('challenging');
      }
    }
    
    if (trends.every((t) => t == 'positive')) {
      return '全体的に上向きのトレンド';
    } else if (trends.every((t) => t == 'challenging')) {
      return '困難が続く期間だが、学びの機会';
    } else {
      return '変化に富んだ期間、柔軟性が鍵';
    }
  }
  
  // 構建解釋文本的方法
  static String _buildTwoCardChoiceInterpretation(
    EnhancedTarotCard cardA, EnhancedTarotCard cardB,
    String themeA, String themeB,
    Map<String, dynamic> comparison,
    String recommendation
  ) {
    return '''
【二択の比較解読】

${cardA.nameJp}（選択肢A）
$themeA

${cardB.nameJp}（選択肢B）  
$themeB

【比較分析】
${comparison['energy_comparison']}
${comparison['theme_strength']}

【推奨】
$recommendation
''';
  }
  
  static String _buildTimelineNarrative(
    String past, String present, String future,
    String trend, TarotTheme theme
  ) {
    return '''
【時間の流れの解読】

$past

$present

$future

【全体的な流れ】
$trend

これらのカードは、あなたの人生の流れと変化のパターンを示しています。過去から現在、そして未来への道筋を理解することで、より良い選択ができるでしょう。
''';
  }
  
  static String _buildSingleCardInterpretation(
    EnhancedTarotCard card,
    String themeInterpretation,
    String contextMessage,
    TarotQuestionAnalysis questionAnalysis
  ) {
    return '''
${card.nameJp}[[memory:4806989]]

物語り
${card.story}

解釈[[memory:4806988]]
$themeInterpretation

$contextMessage
''';
  }
  
  static CardMeaning _buildIndividualMeaning(
    EnhancedTarotCard card, bool isReversed, TarotTheme theme, String position
  ) {
    return CardMeaning(
      cardName: card.nameJp,
      position: position,
      isReversed: isReversed,
      meaning: _getThemeInterpretation(card, theme, isReversed),
      keywords: isReversed ? card.keywordsReversed : card.keywordsUpright,
    );
  }
  
  static String _generateChoiceRecommendation(
    EnhancedTarotCard cardA, EnhancedTarotCard cardB,
    bool revA, bool revB, TarotTheme theme,
    Map<String, dynamic> comparison
  ) {
    final recommended = comparison['recommended_choice'];
    return '''
【アドバイス】
${recommended == 'A' ? '選択肢Aがより有利な結果をもたらす可能性が高い' : 
  recommended == 'B' ? '選択肢Bがより有利な結果をもたらす可能性が高い' : 
  'どちらの選択肢も一長一短があるため、慎重に検討することが大切'}

ただし、最終的な決断はあなた自身の直感と価値観に従って行うことが重要です。
''';
  }
  
  static String _generateTimelineAdvice(
    List<EnhancedTarotCard> cards, List<bool> isReversed,
    String trend, TarotTheme theme
  ) {
    return '''
【時間軸からのアドバイス】
$trend

過去の経験を活かし、現在の状況を正しく理解し、未来への準備を整えることが重要です。変化を恐れず、流れに身を任せながらも、自分の意志を持って歩んでいきましょう。
''';
  }
  
  static String _generateSingleCardAdvice(
    EnhancedTarotCard card, bool isReversed, TarotQuestionAnalysis questionAnalysis
  ) {
    final advice = isReversed 
        ? 'このカードが逆位置で現れているのは、現在の状況を見直し、新しい視点から問題に取り組む必要があることを示しています。'
        : 'このカードの正位置のエネルギーを活用し、積極的に行動することで良い結果を得られるでしょう。';
    
    return '''
【一枚引きのアドバイス】
$advice

${card.nameJp}のメッセージを心に留め、自分の直感を信じて前進してください。
''';
  }
  
  // 輔助計算方法
  static double _calculateCombinationConfidence(List<EnhancedTarotCard> cards, TarotTheme theme) {
    double confidence = 0.7; // 基礎信心度
    
    for (final card in cards) {
      if (card.themeInterpretations.containsKey(theme)) {
        confidence += 0.1;
      }
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  static String _analyzeCardEnergy(EnhancedTarotCard card, bool isReversed) {
    return isReversed ? '阻塞或内向的能量' : '流动和积极的能量';
  }
  
  static double _calculateThemeAlignment(EnhancedTarotCard card, TarotTheme theme) {
    return card.themeInterpretations.containsKey(theme) ? 0.9 : 0.5;
  }
  
  static Map<String, String> _analyzeEnergyFlow(List<EnhancedTarotCard> cards, List<bool> isReversed) {
    return {
      'flow_direction': '時間とともに変化するエネルギーの流れ',
      'intensity': '中程度から高強度',
    };
  }
  
  static List<String> _identifyTransitionPoints(List<EnhancedTarotCard> cards, List<bool> isReversed) {
    return ['過去から現在への転換点', '現在から未来への移行期'];
  }
}

// 時間位置枚舉
enum TimePosition { past, present, future }

// 組合解讀類型
enum CombinationReadingType { singleCard, twoCardChoice, threeCardTimeline, celtic }

// 組合解讀結果
class TarotCombinationReading {
  final CombinationReadingType readingType;
  final List<EnhancedTarotCard> cards;
  final List<bool> isReversed;
  final String mainInterpretation;
  final List<CardMeaning> individualCardMeanings;
  final Map<String, dynamic> combinationInsights;
  final String recommendation;
  final double confidence;

  const TarotCombinationReading({
    required this.readingType,
    required this.cards,
    required this.isReversed,
    required this.mainInterpretation,
    required this.individualCardMeanings,
    required this.combinationInsights,
    required this.recommendation,
    required this.confidence,
  });
}

// 單卡含義
class CardMeaning {
  final String cardName;
  final String position;
  final bool isReversed;
  final String meaning;
  final List<String> keywords;

  const CardMeaning({
    required this.cardName,
    required this.position,
    required this.isReversed,
    required this.meaning,
    required this.keywords,
  });
}