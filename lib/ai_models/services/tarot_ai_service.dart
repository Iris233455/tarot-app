import '../data/enhanced_tarot_data.dart';
import '../classifiers/question_classifier.dart';
import '../rag/tarot_rag_retriever.dart';
import '../interpreters/card_combination_interpreter.dart';

/// 塔罗牌AI解读服务 - 整合所有AI组件的主要服务类
class TarotAIService {
  final TarotRAGRetriever _ragRetriever;
  final List<EnhancedTarotCard> _cardDatabase;
  
  TarotAIService(this._cardDatabase) 
      : _ragRetriever = TarotRAGRetriever(_cardDatabase);

  /// 主要解读方法 - 单卡解读
  Future<TarotAIReading> interpretSingleCard({
    required String question,
    required String cardId,
    required bool isReversed,
  }) async {
    // 1. 分析问题
    final questionAnalysis = TarotQuestionClassifier.analyzeQuestion(question);
    
    // 2. RAG检索相关信息
    final ragResult = await _ragRetriever.retrieveRelevantCards(
      questionAnalysis: questionAnalysis,
      drawnCardIds: [cardId],
      maxResults: 1,
    );
    
    // 3. 生成解读
    final card = ragResult.cards.first;
    final interpretation = CardCombinationInterpreter.interpretSingleCard(
      card: card,
      questionAnalysis: questionAnalysis,
      isReversed: isReversed,
    );
    
    return TarotAIReading(
      question: question,
      questionAnalysis: questionAnalysis,
      ragResult: ragResult,
      interpretation: interpretation,
      timestamp: DateTime.now(),
      readingId: _generateReadingId(),
    );
  }

  /// 两卡选择解读
  Future<TarotAIReading> interpretTwoCardChoice({
    required String question,
    required List<String> cardIds,
    required List<bool> isReversed,
  }) async {
    assert(cardIds.length == 2, '两卡解读需要恰好2张牌');
    
    // 1. 分析问题
    final questionAnalysis = TarotQuestionClassifier.analyzeQuestion(question);
    
    // 2. RAG检索
    final ragResult = await _ragRetriever.retrieveRelevantCards(
      questionAnalysis: questionAnalysis,
      drawnCardIds: cardIds,
      maxResults: 2,
    );
    
    // 3. 生成解读
    final interpretation = CardCombinationInterpreter.interpretTwoCardChoice(
      cards: ragResult.cards,
      questionAnalysis: questionAnalysis,
      isReversed: isReversed,
    );
    
    return TarotAIReading(
      question: question,
      questionAnalysis: questionAnalysis,
      ragResult: ragResult,
      interpretation: interpretation,
      timestamp: DateTime.now(),
      readingId: _generateReadingId(),
    );
  }

  /// 三卡时间线解读
  Future<TarotAIReading> interpretThreeCardTimeline({
    required String question,
    required List<String> cardIds,
    required List<bool> isReversed,
  }) async {
    assert(cardIds.length == 3, '三卡解读需要恰好3张牌');
    
    // 1. 分析问题
    final questionAnalysis = TarotQuestionClassifier.analyzeQuestion(question);
    
    // 2. RAG检索
    final ragResult = await _ragRetriever.retrieveRelevantCards(
      questionAnalysis: questionAnalysis,
      drawnCardIds: cardIds,
      maxResults: 3,
    );
    
    // 3. 生成解读
    final interpretation = CardCombinationInterpreter.interpretThreeCardTimeline(
      cards: ragResult.cards,
      questionAnalysis: questionAnalysis,
      isReversed: isReversed,
    );
    
    return TarotAIReading(
      question: question,
      questionAnalysis: questionAnalysis,
      ragResult: ragResult,
      interpretation: interpretation,
      timestamp: DateTime.now(),
      readingId: _generateReadingId(),
    );
  }

  /// 批量解读（用于复杂牌阵）
  Future<List<TarotAIReading>> batchInterpret({
    required String question,
    required List<List<String>> cardIdGroups,
    required List<List<bool>> isReversedGroups,
  }) async {
    final questionAnalysis = TarotQuestionClassifier.analyzeQuestion(question);
    final results = <TarotAIReading>[];
    
    for (int i = 0; i < cardIdGroups.length; i++) {
      final cardIds = cardIdGroups[i];
      final isReversed = isReversedGroups[i];
      
      TarotAIReading reading;
      
      switch (cardIds.length) {
        case 1:
          reading = await interpretSingleCard(
            question: question,
            cardId: cardIds.first,
            isReversed: isReversed.first,
          );
          break;
        case 2:
          reading = await interpretTwoCardChoice(
            question: question,
            cardIds: cardIds,
            isReversed: isReversed,
          );
          break;
        case 3:
          reading = await interpretThreeCardTimeline(
            question: question,
            cardIds: cardIds,
            isReversed: isReversed,
          );
          break;
        default:
          // 对于其他数量的牌，使用单卡解读
          reading = await interpretSingleCard(
            question: question,
            cardId: cardIds.first,
            isReversed: isReversed.first,
          );
      }
      
      results.add(reading);
    }
    
    return results;
  }

  /// 问题预分析（不抽牌）
  TarotQuestionAnalysis analyzeQuestionOnly(String question) {
    return TarotQuestionClassifier.analyzeQuestion(question);
  }

  /// 获取主题相关的解释建议
  List<String> getThemeBasedSuggestions(TarotTheme theme) {
    switch (theme) {
      case TarotTheme.love:
        return [
          '相手の気持ちはどうですか？',
          'この恋愛は発展しますか？',
          '復縁の可能性はありますか？',
          '理想の相手に出会えますか？',
        ];
      case TarotTheme.career:
        return [
          '転職すべきタイミングはいつですか？',
          '今の仕事で成功できますか？',
          '新しいプロジェクトはうまくいきますか？',
          'キャリアアップの方法を教えてください',
        ];
      case TarotTheme.money:
        return [
          '金運はいつ上がりますか？',
          '投資すべきですか？',
          '収入を増やす方法はありますか？',
          '経済的な困難を乗り越えられますか？',
        ];
      case TarotTheme.interpersonal:
        return [
          '人間関係を改善する方法は？',
          'あの人との関係はどうなりますか？',
          '職場の人間関係で悩んでいます',
          '友人との喧嘩は解決しますか？',
        ];
      case TarotTheme.health:
        return [
          '体調は回復しますか？',
          '健康維持のためのアドバイスは？',
          'ストレスを軽減する方法は？',
          '病気の治療はうまくいきますか？',
        ];
      case TarotTheme.personal:
        return [
          '自分の人生の方向性は正しいですか？',
          '成長するために何をすべきですか？',
          '人生の目標を見つけるには？',
          '自分の才能を活かす方法は？',
        ];
      case TarotTheme.family:
        return [
          '家族関係を改善するには？',
          '子育ての悩みを解決したい',
          '親との関係で困っています',
          '家庭内の問題は解決しますか？',
        ];
      case TarotTheme.study:
        return [
          '試験に合格できますか？',
          '勉強方法のアドバイスをください',
          '新しいスキルを身につけるべき？',
          '学習の集中力を高めるには？',
        ];
    }
  }

  /// 获取推荐牌阵类型的描述
  String getSpreadDescription(SpreadType spreadType) {
    switch (spreadType) {
      case SpreadType.oneCard:
        return '一枚引き - シンプルで直接的な答えを得るのに最適';
      case SpreadType.twoCard:
        return '二択 - 選択肢を比較検討したい時に使用';
      case SpreadType.threeCard:
        return '三枚引き - 過去・現在・未来の流れを知りたい時に使用';
      case SpreadType.celtic:
        return 'ケルト十字 - 複雑な状況を詳細に分析したい時に使用';
      case SpreadType.relationship:
        return '関係性 - 二人の関係や相互作用を探りたい時に使用';
    }
  }

  /// 检查问题质量并提供改善建议
  QuestionQualityAssessment assessQuestionQuality(String question) {
    final analysis = TarotQuestionClassifier.analyzeQuestion(question);
    
    final issues = <String>[];
    final suggestions = <String>[];
    
    // 检查问题长度
    if (question.length < 5) {
      issues.add('質問が短すぎます');
      suggestions.add('もう少し詳細に質問内容を教えてください');
    } else if (question.length > 200) {
      issues.add('質問が長すぎます');
      suggestions.add('要点を絞って、より簡潔に質問してください');
    }
    
    // 检查具体性
    if (analysis.extractedKeywords.isEmpty) {
      issues.add('質問が漠然としています');
      suggestions.add('具体的な状況や悩みを含めて質問してください');
    }
    
    // 检查问题类型
    if (analysis.questionType == QuestionType.general && analysis.confidence < 0.6) {
      issues.add('質問の意図が不明確です');
      suggestions.add('「どうすれば」「いつ」「どちらが」など、具体的な疑問詞を使ってください');
    }
    
    double qualityScore = 1.0;
    qualityScore -= issues.length * 0.2;
    qualityScore = qualityScore.clamp(0.0, 1.0);
    
    return QuestionQualityAssessment(
      originalQuestion: question,
      qualityScore: qualityScore,
      issues: issues,
      suggestions: suggestions,
      detectedTheme: analysis.detectedTheme,
      confidence: analysis.confidence,
    );
  }

  /// 生成阅读ID
  String _generateReadingId() {
    return 'reading_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 获取卡片数据库统计信息
  Map<String, dynamic> getDatabaseStats() {
    final majorArcana = _cardDatabase.where((c) => c.cardId.startsWith('major')).length;
    final minorArcana = _cardDatabase.where((c) => c.cardId.startsWith('minor')).length;
    
    return {
      'total_cards': _cardDatabase.length,
      'major_arcana': majorArcana,
      'minor_arcana': minorArcana,
      'theme_coverage': _calculateThemeCoverage(),
      'database_version': '1.0.0',
    };
  }

  Map<String, int> _calculateThemeCoverage() {
    final coverage = <String, int>{};
    
    for (final theme in TarotTheme.values) {
      final count = _cardDatabase
          .where((card) => card.themeInterpretations.containsKey(theme))
          .length;
      coverage[theme.toString()] = count;
    }
    
    return coverage;
  }
}

/// AI解读结果封装
class TarotAIReading {
  final String question;
  final TarotQuestionAnalysis questionAnalysis;
  final TarotRAGResult ragResult;
  final TarotCombinationReading interpretation;
  final DateTime timestamp;
  final String readingId;

  const TarotAIReading({
    required this.question,
    required this.questionAnalysis,
    required this.ragResult,
    required this.interpretation,
    required this.timestamp,
    required this.readingId,
  });

  /// 获取解读摘要
  String getSummary() {
    return '''
【解読結果】
質問：$question
主要テーマ：${questionAnalysis.detectedTheme}
推奨スプレッド：${questionAnalysis.recommendedSpread}
信頼度：${(questionAnalysis.confidence * 100).toInt()}%

${interpretation.mainInterpretation}
''';
  }

  /// 获取关键词标签
  List<String> getKeywordTags() {
    final tags = <String>[];
    tags.addAll(questionAnalysis.extractedKeywords);
    tags.addAll(ragResult.relevantKeywords);
    
    // 去重并限制数量
    return tags.toSet().take(10).toList();
  }
}

/// 问题质量评估结果
class QuestionQualityAssessment {
  final String originalQuestion;
  final double qualityScore;
  final List<String> issues;
  final List<String> suggestions;
  final TarotTheme detectedTheme;
  final double confidence;

  const QuestionQualityAssessment({
    required this.originalQuestion,
    required this.qualityScore,
    required this.issues,
    required this.suggestions,
    required this.detectedTheme,
    required this.confidence,
  });

  bool get isGoodQuality => qualityScore >= 0.7;
  bool get needsImprovement => qualityScore < 0.5;
}