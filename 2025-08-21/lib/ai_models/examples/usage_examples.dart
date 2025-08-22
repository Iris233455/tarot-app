import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/tarot_ai_service.dart';
import '../data/json_data_converter.dart';
import '../data/enhanced_tarot_data.dart';

/// 塔罗牌AI系统使用示例
class TarotAIUsageExamples {
  
  /// 初始化AI服务的完整示例
  static Future<TarotAIService> initializeAIService() async {
    // 1. 从资产中加载JSON数据
    final jsonString = await rootBundle.loadString('assets/data/tarot_books_contents.json');
    
    // 2. 转换为增强数据结构
    final enhancedCards = JsonDataConverter.convertFromJson(jsonString);
    
    // 3. 验证数据完整性
    final validation = JsonDataConverter.validateConvertedData(enhancedCards);
    if (!validation.isValid) {
      print('数据验证失败: ${validation.issues}');
      // 可以选择使用示例数据或抛出异常
      throw Exception('塔罗牌数据初始化失败');
    }
    
    // 4. 创建并返回AI服务
    return TarotAIService(enhancedCards);
  }
  
  /// 单卡解读示例
  static Future<void> singleCardReadingExample() async {
    final aiService = await initializeAIService();
    
    // 示例问题
    final question = '今日の恋愛運はどうですか？';
    final drawnCardId = 'major_00_fool'; // 愚者牌
    final isReversed = false;
    
    try {
      // 执行解读
      final reading = await aiService.interpretSingleCard(
        question: question,
        cardId: drawnCardId,
        isReversed: isReversed,
      );
      
      // 输出结果
      print('=== 単独カード解読結果 ===');
      print('質問: ${reading.question}');
      print('検出されたテーマ: ${reading.questionAnalysis.detectedTheme}');
      print('信頼度: ${(reading.questionAnalysis.confidence * 100).toInt()}%');
      print('\n解読内容:');
      print(reading.interpretation.mainInterpretation);
      print('\nキーワードタグ: ${reading.getKeywordTags().join(', ')}');
      
    } catch (e) {
      print('解読中にエラーが発生しました: $e');
    }
  }
  
  /// 两卡选择解读示例
  static Future<void> twoCardChoiceExample() async {
    final aiService = await initializeAIService();
    
    final question = '転職すべきか現在の仕事を続けるべきか迷っています';
    final cardIds = ['major_00_fool', 'major_01_magician'];
    final isReversed = [false, true]; // 愚者正位，魔术师逆位
    
    try {
      final reading = await aiService.interpretTwoCardChoice(
        question: question,
        cardIds: cardIds,
        isReversed: isReversed,
      );
      
      print('=== 二択比較解読結果 ===');
      print('質問: ${reading.question}');
      print('\n${reading.interpretation.mainInterpretation}');
      print('\n推薦: ${reading.interpretation.recommendation}');
      
      // 个别卡片含义
      print('\n=== 個別カードの意味 ===');
      for (final cardMeaning in reading.interpretation.individualCardMeanings) {
        print('${cardMeaning.position}: ${cardMeaning.cardName}');
        print('${cardMeaning.isReversed ? '逆位置' : '正位置'}');
        print('意味: ${cardMeaning.meaning}');
        print('キーワード: ${cardMeaning.keywords.join(', ')}\n');
      }
      
    } catch (e) {
      print('解読中にエラーが発生しました: $e');
    }
  }
  
  /// 三卡时间线解读示例
  static Future<void> threeCardTimelineExample() async {
    final aiService = await initializeAIService();
    
    final question = '私の恋愛の未来はどうなりますか？';
    final cardIds = ['major_16_tower', 'major_17_star', 'major_19_sun'];
    final isReversed = [true, false, false]; // 塔逆位，星正位，太阳正位
    
    try {
      final reading = await aiService.interpretThreeCardTimeline(
        question: question,
        cardIds: cardIds,
        isReversed: isReversed,
      );
      
      print('=== 三カード時系列解読結果 ===');
      print('質問: ${reading.question}');
      print('\n${reading.interpretation.mainInterpretation}');
      print('\n推薦: ${reading.interpretation.recommendation}');
      
      // 组合洞察
      print('\n=== 組み合わせの洞察 ===');
      final insights = reading.interpretation.combinationInsights;
      print('全体的なトレンド: ${insights['timeline_trend']}');
      print('エネルギーの流れ: ${insights['energy_flow']}');
      
    } catch (e) {
      print('解読中にエラーが発生しました: $e');
    }
  }
  
  /// 问题质量评估示例
  static Future<void> questionQualityAssessmentExample() async {
    final aiService = await initializeAIService();
    
    final questions = [
      '恋愛',  // 质量低
      '今日はどうですか？', // 质量中等
      '現在の恋人との関係は将来的に結婚に至る可能性がありますか？', // 质量高
    ];
    
    print('=== 質問品質評価例 ===');
    
    for (final question in questions) {
      final assessment = aiService.assessQuestionQuality(question);
      
      print('\n質問: "$question"');
      print('品質スコア: ${(assessment.qualityScore * 100).toInt()}%');
      print('品質レベル: ${assessment.isGoodQuality ? '良好' : assessment.needsImprovement ? '改善が必要' : '普通'}');
      
      if (assessment.issues.isNotEmpty) {
        print('問題点: ${assessment.issues.join(', ')}');
      }
      
      if (assessment.suggestions.isNotEmpty) {
        print('改善提案: ${assessment.suggestions.join(', ')}');
      }
      
      print('検出されたテーマ: ${assessment.detectedTheme}');
    }
  }
  
  /// 主题建议获取示例
  static Future<void> themeSuggestionsExample() async {
    final aiService = await initializeAIService();
    
    print('=== テーマ別質問提案例 ===');
    
    for (final theme in TarotTheme.values) {
      final suggestions = aiService.getThemeBasedSuggestions(theme);
      print('\n${theme}テーマの質問例:');
      for (int i = 0; i < suggestions.length; i++) {
        print('${i + 1}. ${suggestions[i]}');
      }
    }
  }
  
  /// 数据库统计信息示例
  static Future<void> databaseStatsExample() async {
    final aiService = await initializeAIService();
    
    final stats = aiService.getDatabaseStats();
    
    print('=== データベース統計情報 ===');
    print('総カード数: ${stats['total_cards']}');
    print('大アルカナ: ${stats['major_arcana']}');
    print('小アルカナ: ${stats['minor_arcana']}');
    print('データベースバージョン: ${stats['database_version']}');
    
    print('\nテーマカバレッジ:');
    final themeCoverage = stats['theme_coverage'] as Map<String, int>;
    themeCoverage.forEach((theme, count) {
      print('  $theme: $count カード');
    });
  }
  
  /// 错误处理示例
  static Future<void> errorHandlingExample() async {
    try {
      final aiService = await initializeAIService();
      
      // 意图传入无效卡片ID
      final reading = await aiService.interpretSingleCard(
        question: 'テスト質問',
        cardId: 'invalid_card_id',
        isReversed: false,
      );
      
      print('解读結果: ${reading.getSummary()}');
      
    } catch (e) {
      print('期待されたエラーをキャッチしました: $e');
      
      // 使用后备策略
      print('フォールバック戦略を使用して示例データで続行...');
      final sampleCards = JsonDataConverter.createSampleData();
      final aiService = TarotAIService(sampleCards);
      
      final reading = await aiService.interpretSingleCard(
        question: 'テスト質問',
        cardId: 'major_00_fool',
        isReversed: false,
      );
      
      print('フォールバック解読結果: ${reading.getSummary()}');
    }
  }
  
  /// 批量解读示例
  static Future<void> batchInterpretationExample() async {
    final aiService = await initializeAIService();
    
    final question = '私の人生の全体的な方向性について教えてください';
    final cardIdGroups = [
      ['major_00_fool'], // 单卡 - 当前状态
      ['major_01_magician', 'major_02_priestess'], // 两卡 - 选择
      ['major_16_tower', 'major_17_star', 'major_19_sun'], // 三卡 - 时间线
    ];
    final isReversedGroups = [
      [false],
      [false, true],
      [true, false, false],
    ];
    
    try {
      final readings = await aiService.batchInterpret(
        question: question,
        cardIdGroups: cardIdGroups,
        isReversedGroups: isReversedGroups,
      );
      
      print('=== バッチ解読結果 ===');
      print('質問: $question\n');
      
      for (int i = 0; i < readings.length; i++) {
        final reading = readings[i];
        print('--- 解読 ${i + 1} (${reading.interpretation.readingType}) ---');
        print(reading.interpretation.mainInterpretation);
        print('信頼度: ${(reading.questionAnalysis.confidence * 100).toInt()}%\n');
      }
      
    } catch (e) {
      print('バッチ解読中にエラーが発生しました: $e');
    }
  }
  
  /// 运行所有示例
  static Future<void> runAllExamples() async {
    print('🔮 塔罗牌AI系统使用示例开始 🔮\n');
    
    try {
      await singleCardReadingExample();
      print('\n' + '='*50 + '\n');
      
      await twoCardChoiceExample();
      print('\n' + '='*50 + '\n');
      
      await threeCardTimelineExample();
      print('\n' + '='*50 + '\n');
      
      await questionQualityAssessmentExample();
      print('\n' + '='*50 + '\n');
      
      await themeSuggestionsExample();
      print('\n' + '='*50 + '\n');
      
      await databaseStatsExample();
      print('\n' + '='*50 + '\n');
      
      await errorHandlingExample();
      print('\n' + '='*50 + '\n');
      
      await batchInterpretationExample();
      
      print('\n🎉 すべての例が正常に完了しました！ 🎉');
      
    } catch (e) {
      print('❌ 例の実行中にエラーが発生しました: $e');
    }
  }
}

/// 集成指南类
class TarotAIIntegrationGuide {
  
  /// 获取集成步骤
  static List<String> getIntegrationSteps() {
    return [
      '1. AI模型依赖项添加到pubspec.yaml',
      '2. 确保assets/data/tarot_books_contents.json文件存在',
      '3. 在main.dart中初始化TarotAIService',
      '4. 在相关屏幕中注入服务依赖',
      '5. 调用相应的解读方法',
      '6. 处理异常和错误情况',
      '7. 实现UI更新逻辑',
    ];
  }
  
  /// 获取最佳实践建议
  static List<String> getBestPractices() {
    return [
      '问题质量检查：使用assessQuestionQuality验证用户输入',
      '缓存策略：缓存常用的解读结果以提高性能',
      '错误处理：实现健壮的错误处理和后备策略',
      '用户体验：提供加载状态和进度指示器',
      '本地化：确保所有文本都适当本地化',
      '测试：为所有AI组件编写单元测试',
      '性能监控：监控解读响应时间和准确性',
    ];
  }
  
  /// 获取常见问题解决方案
  static Map<String, String> getCommonIssues() {
    return {
      'JSON加载失败': '检查资产路径和文件格式，确保JSON结构正确',
      '解读质量低': '改进问题分类器的关键词映射，增加更多训练数据',
      '性能问题': '实现异步处理和结果缓存，考虑使用Isolates',
      '内存使用过高': '优化数据结构，移除不必要的向量嵌入',
      '本地化问题': '确保所有枚举和消息都有对应的本地化字符串',
    };
  }
}

/// 性能测试和基准测试
class TarotAIPerformanceTests {
  
  /// 执行性能基准测试
  static Future<void> runPerformanceBenchmarks() async {
    print('=== 性能基准测试 ===');
    
    final stopwatch = Stopwatch();
    
    // 初始化测试
    stopwatch.start();
    final aiService = await TarotAIUsageExamples.initializeAIService();
    stopwatch.stop();
    print('初始化时间: ${stopwatch.elapsedMilliseconds}ms');
    
    // 单卡解读测试
    stopwatch.reset();
    stopwatch.start();
    await aiService.interpretSingleCard(
      question: 'テスト質問',
      cardId: 'major_00_fool',
      isReversed: false,
    );
    stopwatch.stop();
    print('单卡解读时间: ${stopwatch.elapsedMilliseconds}ms');
    
    // 三卡解读测试
    stopwatch.reset();
    stopwatch.start();
    await aiService.interpretThreeCardTimeline(
      question: 'テスト質問',
      cardIds: ['major_00_fool', 'major_01_magician', 'major_02_priestess'],
      isReversed: [false, false, false],
    );
    stopwatch.stop();
    print('三卡解读时间: ${stopwatch.elapsedMilliseconds}ms');
    
    // 问题分析测试
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 100; i++) {
      aiService.analyzeQuestionOnly('恋愛について教えてください');
    }
    stopwatch.stop();
    print('100回问题分析时间: ${stopwatch.elapsedMilliseconds}ms');
    print('平均问题分析时间: ${stopwatch.elapsedMilliseconds / 100}ms');
  }
}