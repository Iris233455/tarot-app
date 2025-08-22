import '../data/enhanced_tarot_data.dart';

// 问题分类器 - 分析用户问题并确定主题和类型
class TarotQuestionClassifier {
  // 主题关键词映射
  static const Map<TarotTheme, List<String>> _themeKeywords = {
    TarotTheme.love: [
      '恋愛', '彼氏', '彼女', '結婚', '告白', '復縁', '片思い', 
      '好き', '愛', '恋人', 'デート', 'プロポーズ', '恋', '婚活',
      '恋愛運', '相手の気持ち', 'アプローチ', '三角関係', '不倫'
    ],
    TarotTheme.career: [
      '仕事', '転職', 'キャリア', '昇進', '就職', '職場', '上司',
      '同僚', 'プロジェクト', '業績', '会社', '起業', '副業',
      '資格', 'スキル', '出世', '労働', '働く', '職業'
    ],
    TarotTheme.money: [
      'お金', '金運', '収入', '給料', '投資', '貯金', '借金',
      '財産', '宝くじ', 'ギャンブル', '経済', '金銭', '支出',
      'ローン', '株', '不動産', '資産', '節約', '副収入'
    ],
    TarotTheme.interpersonal: [
      '人間関係', '友人', '友達', '家族', '親', '兄弟', '姉妹',
      '知人', '近所', 'コミュニティ', '社交', '付き合い', '関係',
      '対人', '相性', '喧嘩', '仲直り', '信頼', '裏切り'
    ],
    TarotTheme.health: [
      '健康', '病気', '体調', '医者', '病院', '治療', '薬',
      '怪我', '回復', '疲労', 'ストレス', 'メンタル', '精神',
      'ダイエット', '運動', '食事', '睡眠', '体'
    ],
    TarotTheme.personal: [
      '自分', '成長', '変化', '決断', '選択', '迷い', '悩み',
      '目標', '夢', '将来', '人生', '性格', '才能', '能力',
      '自信', '不安', '心配', '希望', '願い'
    ],
    TarotTheme.family: [
      '家族', '親', '父', '母', '子供', '息子', '娘', '夫',
      '妻', '義理', '親戚', '祖父', '祖母', '兄弟', '姉妹',
      '家庭', '育児', '子育て', '介護', '相続'
    ],
    TarotTheme.study: [
      '勉強', '学習', '試験', '受験', '学校', '大学', '資格',
      '成績', '教育', '習い事', 'スキルアップ', '知識',
      '記憶', '集中', '努力', '学問', '研究'
    ],
  };

  // 問題類型關鍵詞映射
  static const Map<QuestionType, List<String>> _questionTypeKeywords = {
    QuestionType.choice: [
      'どちら', '選択', '決める', '迷う', 'Aか B', 'どうする',
      '選ぶ', '決断', 'どっち', '判断', '比較'
    ],
    QuestionType.timing: [
      'いつ', 'タイミング', '時期', '頃', '何時', '時間',
      '今', '将来', '近い', '遠い', '早い', '遅い'
    ],
    QuestionType.relationship: [
      '相手', '気持ち', '考え', '思っている', '感じ', '関係',
      '状況', '状態', '現在', '今の', 'どう思う'
    ],
    QuestionType.outcome: [
      'どうなる', '結果', '未来', '将来', '先', '行く末',
      '成功', '失敗', '結末', '終わり', '最終'
    ],
    QuestionType.advice: [
      'アドバイス', '助言', 'どうすれば', '方法', 'やり方',
      '対策', '解決', '改善', 'コツ', '秘訣', '良い'
    ],
  };

  // 分析用戶問題並分類
  static TarotQuestionAnalysis analyzeQuestion(String question) {
    final lowerQuestion = question.toLowerCase();
    
    // 檢測主題
    final detectedTheme = _detectTheme(lowerQuestion);
    
    // 檢測問題類型
    final questionType = _detectQuestionType(lowerQuestion);
    
    // 推薦牌陣類型
    final recommendedSpread = _recommendSpread(questionType, lowerQuestion);
    
    // 提取關鍵詞
    final keywords = _extractKeywords(lowerQuestion);
    
    // 計算信心度
    final confidence = _calculateConfidence(detectedTheme, questionType, keywords);

    return TarotQuestionAnalysis(
      originalQuestion: question,
      detectedTheme: detectedTheme,
      questionType: questionType,
      recommendedSpread: recommendedSpread,
      confidence: confidence,
      extractedKeywords: keywords,
      analysisMetadata: {
        'question_length': question.length,
        'contains_numbers': _containsNumbers(question),
        'contains_names': _containsNames(question),
        'sentiment': _analyzeSentiment(question),
      },
    );
  }

  // 檢測主題
  static TarotTheme _detectTheme(String question) {
    final scores = <TarotTheme, int>{};
    
    for (final theme in TarotTheme.values) {
      scores[theme] = 0;
      final keywords = _themeKeywords[theme] ?? [];
      
      for (final keyword in keywords) {
        if (question.contains(keyword)) {
          scores[theme] = scores[theme]! + 1;
        }
      }
    }
    
    // 返回得分最高的主題，默認為個人成長
    final maxScore = scores.values.isEmpty ? 0 : scores.values.reduce((a, b) => a > b ? a : b);
    return maxScore > 0 
        ? scores.entries.firstWhere((e) => e.value == maxScore).key
        : TarotTheme.personal;
  }

  // 檢測問題類型
  static QuestionType _detectQuestionType(String question) {
    final scores = <QuestionType, int>{};
    
    for (final type in QuestionType.values) {
      scores[type] = 0;
      final keywords = _questionTypeKeywords[type] ?? [];
      
      for (final keyword in keywords) {
        if (question.contains(keyword)) {
          scores[type] = scores[type]! + 1;
        }
      }
    }
    
    final maxScore = scores.values.isEmpty ? 0 : scores.values.reduce((a, b) => a > b ? a : b);
    return maxScore > 0 
        ? scores.entries.firstWhere((e) => e.value == maxScore).key
        : QuestionType.general;
  }

  // 推薦牌陣
  static SpreadType _recommendSpread(QuestionType questionType, String question) {
    switch (questionType) {
      case QuestionType.choice:
        return SpreadType.twoCard;
      case QuestionType.timing:
      case QuestionType.outcome:
        return SpreadType.threeCard;
      case QuestionType.relationship:
        return SpreadType.relationship;
      default:
        return SpreadType.oneCard;
    }
  }

  // 提取關鍵詞
  static List<String> _extractKeywords(String question) {
    final allKeywords = <String>[];
    
    // 從所有主題關鍵詞中提取
    for (final keywords in _themeKeywords.values) {
      for (final keyword in keywords) {
        if (question.contains(keyword)) {
          allKeywords.add(keyword);
        }
      }
    }
    
    return allKeywords.toSet().toList();
  }

  // 計算信心度
  static double _calculateConfidence(TarotTheme theme, QuestionType type, List<String> keywords) {
    double confidence = 0.5; // 基礎信心度
    
    // 根據關鍵詞數量調整
    confidence += (keywords.length * 0.1).clamp(0.0, 0.3);
    
    // 根據主題匹配度調整
    if (theme != TarotTheme.personal) confidence += 0.1;
    
    // 根據問題類型匹配度調整
    if (type != QuestionType.general) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  static bool _containsNumbers(String question) {
    return RegExp(r'\d').hasMatch(question);
  }

  static bool _containsNames(String question) {
    // 簡單的日文人名檢測
    return RegExp(r'[さん|くん|ちゃん|様]').hasMatch(question);
  }

  static String _analyzeSentiment(String question) {
    final positiveWords = ['嬉しい', '楽しい', '良い', '幸せ', '成功'];
    final negativeWords = ['悩み', '心配', '不安', '困る', '失敗'];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (question.contains(word)) positiveCount++;
    }
    
    for (final word in negativeWords) {
      if (question.contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }
}

// 問題分析結果
class TarotQuestionAnalysis {
  final String originalQuestion;
  final TarotTheme detectedTheme;
  final QuestionType questionType;
  final SpreadType recommendedSpread;
  final double confidence;
  final List<String> extractedKeywords;
  final Map<String, dynamic> analysisMetadata;

  const TarotQuestionAnalysis({
    required this.originalQuestion,
    required this.detectedTheme,
    required this.questionType,
    required this.recommendedSpread,
    required this.confidence,
    required this.extractedKeywords,
    required this.analysisMetadata,
  });
}