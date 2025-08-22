// 增强的塔罗牌数据模型，专为RAG系统设计
class EnhancedTarotCard {
  final String cardId;
  final String nameJp;
  final String nameEn;
  final String story;
  final String meaningUpright;
  final String meaningReversed;
  final List<String> keywordsUpright;
  final List<String> keywordsReversed;
  
  // 按主题分类的解释
  final Map<TarotTheme, TarotThemeInterpretation> themeInterpretations;
  
  // 按情境分类的消息
  final Map<TarotContext, TarotContextMessage> contextMessages;
  
  // 向量嵌入字段（用于相似度搜索）
  final List<double>? storyEmbedding;
  final List<double>? meaningEmbedding;
  final Map<TarotTheme, List<double>>? themeEmbeddings;

  const EnhancedTarotCard({
    required this.cardId,
    required this.nameJp,
    required this.nameEn,
    required this.story,
    required this.meaningUpright,
    required this.meaningReversed,
    required this.keywordsUpright,
    required this.keywordsReversed,
    required this.themeInterpretations,
    required this.contextMessages,
    this.storyEmbedding,
    this.meaningEmbedding,
    this.themeEmbeddings,
  });
}

// 塔罗牌主题枚举
enum TarotTheme {
  love,           // 爱情
  career,         // 事业
  money,          // 金钱
  interpersonal,  // 人际关系
  health,         // 健康
  personal,       // 个人成长
  family,         // 家庭
  study,          // 学业
}

// 塔罗牌情境枚举
enum TarotContext {
  pastPresentFuture,    // 过去现在未来
  emotionConsciousness, // 情感意识
  causeSolution,        // 原因解决
}

// 主题解释结构
class TarotThemeInterpretation {
  final String upright;
  final String reversed;
  final List<String> uprightKeywords;
  final List<String> reversedKeywords;

  const TarotThemeInterpretation({
    required this.upright,
    required this.reversed,
    required this.uprightKeywords,
    required this.reversedKeywords,
  });
}

// 情境消息结构
class TarotContextMessage {
  final String upright;
  final String reversed;
  final List<String> uprightKeywords;
  final List<String> reversedKeywords;

  const TarotContextMessage({
    required this.upright,
    required this.reversed,
    required this.uprightKeywords,
    required this.reversedKeywords,
  });
}

// 问题类型枚举
enum QuestionType {
  general,        // 一般询问
  choice,         // 选择决策
  timing,         // 时机判断
  relationship,   // 关系状况
  outcome,        // 结果预测
  advice,         // 建议指导
}

// 牌阵类型枚举
enum SpreadType {
  oneCard,        // 单卡
  twoCard,        // 双卡比较
  threeCard,      // 三卡时间线
  celtic,         // 凯尔特十字
  relationship,   // 关系牌阵
}

// RAG检索结果
class TarotRAGResult {
  final List<EnhancedTarotCard> cards;
  final TarotTheme detectedTheme;
  final QuestionType questionType;
  final SpreadType recommendedSpread;
  final double confidence;
  final List<String> relevantKeywords;
  final Map<String, dynamic> contextInfo;

  const TarotRAGResult({
    required this.cards,
    required this.detectedTheme,
    required this.questionType,
    required this.recommendedSpread,
    required this.confidence,
    required this.relevantKeywords,
    required this.contextInfo,
  });
}