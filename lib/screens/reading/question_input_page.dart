import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/providers/ad_watched_provider.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';


class QuestionInputPage extends ConsumerStatefulWidget {
  const QuestionInputPage({super.key});

  @override
  ConsumerState<QuestionInputPage> createState() => _QuestionInputPageState();
}

class _QuestionInputPageState extends ConsumerState<QuestionInputPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  String? _selectedQuestion;
  List<String> _commonQuestions = [];
  bool _questionsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionExamples();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionExamples() async {
    try {
      final readingFormat = ref.read(readingFormatProvider);
      final spreadMeta = await DataService.getSpreadMeta();
      
      // 根据当前选择的 spread 找到对应的質問の例
      List<String> examples = [];
      for (final meta in spreadMeta.values) {
        if ((meta['title'] as String?) == readingFormat) {
          examples = (meta['question_examples'] as List<dynamic>?)
              ?.map((e) => e.toString()).toList() ?? [];
          break;
        }
      }
      
      // 如果没找到，使用默认问题
      if (examples.isEmpty) {
        examples = [
          '今日の運勢は？',
          '恋愛について教えて',
          '仕事のアドバイスを',
          '健康について',
          'お金の運勢は？',
          '人間関係について',
          '将来の方向性',
          '今抱えている悩み',
        ];
      }
      
      setState(() {
        _commonQuestions = examples;
        _questionsLoading = false;
      });
    } catch (e) {
      print('質問例の読み込みに失敗: $e');
      setState(() {
        _commonQuestions = [
          '今日の運勢は？',
          '恋愛について教えて',
          '仕事のアドバイスを',
        ];
        _questionsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final readingFormat = ref.watch(readingFormatProvider);
    final isTwoCards = readingFormat.contains('ツーカード') || readingFormat.contains('two') || readingFormat.contains('spreads_2');
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(
                  left: DynamicTokens.spacingMd,
                  right: DynamicTokens.spacingMd,
                  top: DynamicTokens.spacingMd,
                  bottom: DynamicTokens.spacingMd,
                ),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
          // よくある質問
          FadeInUp(
            duration: DynamicTokens.animationDuration,
            delay: const Duration(milliseconds: 100),
            child: Text(
              'よくある質問',
              style: TextStyle(
                fontSize: DynamicTokens.fontSizeTitleLarge,
                fontWeight: FontWeight.w600,
                color: ref.watch(dynamicTokensProvider).textPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: DynamicTokens.spacingMd),
          
          // よくある質問タグ
          FadeInUp(
            duration: DynamicTokens.animationDuration,
            delay: const Duration(milliseconds: 150),
            child: _questionsLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: _commonQuestions.map((question) {
                      final isSelected = _selectedQuestion == question;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: DynamicTokens.spacingSm),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedQuestion = question;
                              _questionController.text = question;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? dynamicTokens.primaryColor
                                  : dynamicTokens.surfaceColor,
                              borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                              border: Border.all(
                                color: isSelected 
                                    ? dynamicTokens.primaryColor
                                    : ref.watch(dynamicTokensProvider).textSecondary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              question,
                              style: TextStyle(
                                fontSize: DynamicTokens.fontSizeBodyMedium,
                                color: isSelected 
                                    ? DynamicTokens.textWhite
                                    : ref.watch(dynamicTokensProvider).textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          
          const SizedBox(height: DynamicTokens.spacingXl),
          
          // あなたの質問入力
          FadeInUp(
            duration: DynamicTokens.animationDuration,
            delay: const Duration(milliseconds: 200),
            child: Text(
              'あなたの質問',
              style: TextStyle(
                fontSize: DynamicTokens.fontSizeTitleLarge,
                fontWeight: FontWeight.w600,
                color: ref.watch(dynamicTokensProvider).textPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: DynamicTokens.spacingMd),
          
          FadeInUp(
            duration: DynamicTokens.animationDuration,
            delay: const Duration(milliseconds: 250),
            child: TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'あなたの質問を入力してください...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedQuestion = value.isNotEmpty ? value : null;
                });
              },
            ),
          ),
          
          // Two Cards専用：選択肢A/B入力
          if (isTwoCards) ...[
            const SizedBox(height: DynamicTokens.spacingXl),
            
            FadeInUp(
              duration: DynamicTokens.animationDuration,
              delay: const Duration(milliseconds: 300),
              child: Text(
                '選択肢の詳細',
                style: TextStyle(
                  fontSize: DynamicTokens.fontSizeTitleLarge,
                  fontWeight: FontWeight.w600,
                  color: ref.watch(dynamicTokensProvider).textPrimary,
                ),
              ),
            ),
            
            const SizedBox(height: DynamicTokens.spacingMd),
            
            FadeInUp(
              duration: DynamicTokens.animationDuration,
              delay: const Duration(milliseconds: 350),
              child: TextField(
                controller: _optionAController,
                decoration: const InputDecoration(
                  labelText: '選択肢A',
                  hintText: '例：安定した会社に転職',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            
            const SizedBox(height: DynamicTokens.spacingMd),
            
            FadeInUp(
              duration: DynamicTokens.animationDuration,
              delay: const Duration(milliseconds: 400),
              child: TextField(
                controller: _optionBController,
                decoration: const InputDecoration(
                  labelText: '選択肢B',
                  hintText: '例：チャレンジングなスタートアップに転職',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            
            const SizedBox(height: DynamicTokens.spacingSm),
            
            FadeInUp(
              duration: DynamicTokens.animationDuration,
              delay: const Duration(milliseconds: 450),
              child: Text(
                '※ 選択肢を具体的に入力すると、より精密な解読が得られます。空欄の場合は質問文から自動判定します。',
                style: TextStyle(
                  fontSize: DynamicTokens.fontSizeCaption,
                  color: ref.watch(dynamicTokensProvider).textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ],
            
            const SizedBox(height: DynamicTokens.spacingXl),
          ],
        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DynamicTokens.spacingMd,
                0,
                DynamicTokens.spacingMd,
                DynamicTokens.spacingMd,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedQuestion != null && _selectedQuestion!.isNotEmpty
                      ? () => _handleNextButton()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dynamicTokens.primaryColor,
                    foregroundColor: DynamicTokens.textWhite,
                  ),
                  child: const Text('次へ'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理【次へ】按钮点击
  Future<void> _handleNextButton() async {
    // 保存问题数据
    ref.read(readingQuestionProvider.notifier).state = _selectedQuestion!;
    
    // Two Cardsの場合、選択肢A/Bを保存
    final isTwoCards = ref.read(readingFormatProvider) == 'ツーカード';
    if (isTwoCards) {
      ref.read(optionAProvider.notifier).state = _optionAController.text;
      ref.read(optionBProvider.notifier).state = _optionBController.text;
    }
    
    // 检查是否已经观看过广告
    final readingFormat = ref.read(readingFormatProvider);
    final adWatchedNotifier = ref.read(adWatchedProvider.notifier);
    
    if (adWatchedNotifier.hasWatchedForType(readingFormat)) {
      // 已观看广告，直接跳转
      if (mounted) {
        context.go('/reading/shuffle');
      }
      return;
    }
    
    // 否则直接跳转（广告已在说明页面处理）
    if (mounted) {
      context.go('/reading/shuffle');
    }
  }
} 