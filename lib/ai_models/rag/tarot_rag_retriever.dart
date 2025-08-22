import 'dart:math';
import '../data/enhanced_tarot_data.dart';
import '../classifiers/question_classifier.dart';

// RAG检索器 - 基于问题分析结果检索相关塔罗牌信息
class TarotRAGRetriever {
  final List<EnhancedTarotCard> _cardDatabase;
  
  TarotRAGRetriever(this._cardDatabase);

  // 主要检索方法
  Future<TarotRAGResult> retrieveRelevantCards({
    required TarotQuestionAnalysis questionAnalysis,
    required List<String> drawnCardIds,
    int maxResults = 5,
  }) async {
    try {
      // 1. 获取抽到的牌
      final drawnCards = _getDrawnCards(drawnCardIds);
      
      // 2. 基于主题检索相关解释
      final themeRelevantCards = _retrieveByTheme(
        questionAnalysis.detectedTheme,
        drawnCards,
      );
      
      // 3. 基于关键词增强检索
      final keywordEnhancedCards = _enhanceWithKeywords(
        themeRelevantCards,
        questionAnalysis.extractedKeywords,
      );
      
      // 4. 基于问题类型调整检索策略
      final contextAdjustedCards = _adjustForQuestionType(
        keywordEnhancedCards,
        questionAnalysis.questionType,
      );
      
      // 5. 计算相关性分数并排序
      final scoredCards = _calculateRelevanceScores(
        contextAdjustedCards,
        questionAnalysis,
      );
      
      // 6. 选择最相关的结果
      final finalResults = scoredCards.take(maxResults).toList();
      
      return TarotRAGResult(
        cards: finalResults,
        detectedTheme: questionAnalysis.detectedTheme,
        questionType: questionAnalysis.questionType,
        recommendedSpread: questionAnalysis.recommendedSpread,
        confidence: questionAnalysis.confidence,
        relevantKeywords: questionAnalysis.extractedKeywords,
        contextInfo: {
          'drawn_cards_count': drawnCards.length,
          'theme_match_score': _calculateThemeMatchScore(finalResults, questionAnalysis.detectedTheme),
          'keyword_coverage': _calculateKeywordCoverage(finalResults, questionAnalysis.extractedKeywords),
          'retrieval_timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // 错误处理：返回默认结果
      return _createFallbackResult(questionAnalysis, drawnCardIds);
    }
  }

  // 获取抽到的牌
  List<EnhancedTarotCard> _getDrawnCards(List<String> cardIds) {
    return cardIds
        .map((id) => _cardDatabase.firstWhere(
              (card) => card.cardId == id,
              orElse: () => _cardDatabase.first, // 找不到时返回第一张牌
            ))
        .toList();
  }

  // 基于主题检索
  List<CardWithRelevance> _retrieveByTheme(
    TarotTheme theme,
    List<EnhancedTarotCard> drawnCards,
  ) {
    return drawnCards.map((card) {
      double relevanceScore = 0.5; // 基础分数
      
      // 检查该牌是否有对应主题的特定解释
      if (card.themeInterpretations.containsKey(theme)) {
        relevanceScore += 0.3;
        
        // 检查主题解释的丰富程度
        final themeInterpretation = card.themeInterpretations[theme]!;
        if (themeInterpretation.upright.length > 20) relevanceScore += 0.1;
        if (themeInterpretation.uprightKeywords.isNotEmpty) relevanceScore += 0.1;
      }
      
      return CardWithRelevance(card: card, relevanceScore: relevanceScore);
    }).toList();
  }

  // 基于关键词增强检索
  List<CardWithRelevance> _enhanceWithKeywords(
    List<CardWithRelevance> cards,
    List<String> keywords,
  ) {
    if (keywords.isEmpty) return cards;
    
    for (final cardWithRelevance in cards) {
      final card = cardWithRelevance.card;
      double keywordBonus = 0.0;
      
      // 在故事中搜索关键词
      for (final keyword in keywords) {
        if (card.story.contains(keyword)) keywordBonus += 0.05;
        if (card.meaningUpright.contains(keyword)) keywordBonus += 0.05;
        if (card.meaningReversed.contains(keyword)) keywordBonus += 0.05;
        
        // 在关键词列表中搜索
        if (card.keywordsUpright.any((k) => k.contains(keyword))) keywordBonus += 0.03;
        if (card.keywordsReversed.any((k) => k.contains(keyword))) keywordBonus += 0.03;
      }
      
      cardWithRelevance.relevanceScore += keywordBonus.clamp(0.0, 0.2);
    }
    
    return cards;
  }

  // 基于问题类型调整
  List<CardWithRelevance> _adjustForQuestionType(
    List<CardWithRelevance> cards,
    QuestionType questionType,
  ) {
    for (final cardWithRelevance in cards) {
      final card = cardWithRelevance.card;
      double adjustment = 0.0;
      
      switch (questionType) {
        case QuestionType.choice:
          // 选择类问题，优先显示决策相关的牌意
          if (card.keywordsUpright.any((k) => k.contains('決断') || k.contains('選択'))) {
            adjustment += 0.1;
          }
          break;
        case QuestionType.timing:
          // 时机类问题，优先显示时间相关的解释
          if (card.contextMessages.containsKey(TarotContext.pastPresentFuture)) {
            adjustment += 0.15;
          }
          break;
        case QuestionType.relationship:
          // 关系类问题，优先显示人际关系主题
          if (card.themeInterpretations.containsKey(TarotTheme.interpersonal) ||
              card.themeInterpretations.containsKey(TarotTheme.love)) {
            adjustment += 0.1;
          }
          break;
        case QuestionType.outcome:
          // 结果类问题，优先显示未来相关的信息
          if (card.contextMessages.containsKey(TarotContext.pastPresentFuture)) {
            adjustment += 0.1;
          }
          break;
        case QuestionType.advice:
          // 建议类问题，优先显示解决方案相关的内容
          if (card.contextMessages.containsKey(TarotContext.causeSolution)) {
            adjustment += 0.15;
          }
          break;
        case QuestionType.general:
          // 一般问题，不做特殊调整
          break;
      }
      
      cardWithRelevance.relevanceScore += adjustment;
    }
    
    return cards;
  }

  // 计算相关性分数
  List<EnhancedTarotCard> _calculateRelevanceScores(
    List<CardWithRelevance> cards,
    TarotQuestionAnalysis questionAnalysis,
  ) {
    // 根据分数排序
    cards.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    return cards.map((c) => c.card).toList();
  }

  // 计算主题匹配分数
  double _calculateThemeMatchScore(List<EnhancedTarotCard> cards, TarotTheme theme) {
    if (cards.isEmpty) return 0.0;
    
    int matchCount = 0;
    for (final card in cards) {
      if (card.themeInterpretations.containsKey(theme)) {
        matchCount++;
      }
    }
    
    return matchCount / cards.length;
  }

  // 计算关键词覆盖率
  double _calculateKeywordCoverage(List<EnhancedTarotCard> cards, List<String> keywords) {
    if (keywords.isEmpty) return 1.0;
    
    final foundKeywords = <String>{};
    
    for (final card in cards) {
      for (final keyword in keywords) {
        if (card.story.contains(keyword) ||
            card.meaningUpright.contains(keyword) ||
            card.meaningReversed.contains(keyword)) {
          foundKeywords.add(keyword);
        }
      }
    }
    
    return foundKeywords.length / keywords.length;
  }

  // 创建后备结果
  TarotRAGResult _createFallbackResult(
    TarotQuestionAnalysis questionAnalysis,
    List<String> drawnCardIds,
  ) {
    final fallbackCards = _getDrawnCards(drawnCardIds);
    
    return TarotRAGResult(
      cards: fallbackCards,
      detectedTheme: questionAnalysis.detectedTheme,
      questionType: questionAnalysis.questionType,
      recommendedSpread: questionAnalysis.recommendedSpread,
      confidence: 0.3, // 低信心度
      relevantKeywords: questionAnalysis.extractedKeywords,
      contextInfo: {
        'is_fallback': true,
        'error_occurred': true,
        'retrieval_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // 批量检索（用于多卡解读）
  Future<List<TarotRAGResult>> batchRetrieve({
    required TarotQuestionAnalysis questionAnalysis,
    required List<List<String>> cardIdGroups,
    int maxResults = 3,
  }) async {
    final results = <TarotRAGResult>[];
    
    for (final cardIds in cardIdGroups) {
      final result = await retrieveRelevantCards(
        questionAnalysis: questionAnalysis,
        drawnCardIds: cardIds,
        maxResults: maxResults,
      );
      results.add(result);
    }
    
    return results;
  }
}

// 带相关性分数的卡片
class CardWithRelevance {
  final EnhancedTarotCard card;
  double relevanceScore;
  
  CardWithRelevance({
    required this.card,
    required this.relevanceScore,
  });
}