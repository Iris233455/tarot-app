import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';

class ReadingDetailScreen extends StatefulWidget {
  const ReadingDetailScreen({super.key, required this.readingId});
  final String readingId;

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  List<Map<String, dynamic>> _cardDetails = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resp = await SupabaseService.getReadingById(widget.readingId);
    if (!mounted) return;
    
    // 获取所有卡片的详细信息
    final cardDetails = <Map<String, dynamic>>[];
    try {
      final spread = (resp?['spread_id'] ?? '').toString();
      final cards = (resp?['cards'] as List?)?.cast<dynamic>();
      if (cards != null && cards.isNotEmpty) {
        for (final cardData in cards) {
          final cardMap = Map<String, dynamic>.from(cardData as Map);
          final cardId = (cardMap['card_id'] ?? '').toString();
          final isUpright = (cardMap['is_upright'] == true);
          final position = (cardMap['position'] ?? 1);
          
          if (cardId.isNotEmpty) {
            final row = await SupabaseService.getTarotCard(cardId);
            if (row != null) {
              final cardName = (row['name_jp'] ?? row['name'] ?? '').toString();
              cardDetails.add({
                'name': cardName,
                'is_upright': isUpright,
                'position': position,
              });
            }
          }
        }
        // 按position排序
        cardDetails.sort((a, b) => (a['position'] ?? 0).compareTo(b['position'] ?? 0));
      }
    } catch (_) {}

    setState(() {
      _data = resp;
      _cardDetails = cardDetails;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(appStringsProvider).labelReadingDetail),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
                      tooltip: ref.watch(appStringsProvider).buttonBack,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text(ref.watch(appStringsProvider).messageNoRecordFound))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトル行（タイプ + 時刻）
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                              ),
                              child: Text(
                                _typeLabel(_data!['spread_id'] ?? ''),
                                style: TextStyle(fontWeight: DynamicTokens.fontWeightBold),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('yyyy/MM/dd HH:mm').format(
                                DateTime.tryParse(_data!['created_at'] ?? '') ?? DateTime.now(),
                              ),
                              style: TextStyle(color: DynamicTokens.textTertiaryStatic),
                            ),
                          ],
                        ),
                        
                        // 卡片信息显示
                        if (_cardDetails.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildCardInfoSection(),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 16),
                        // 質問（上部に表示）
                        if ((_data!['question'] ?? '').toString().isNotEmpty) ...[
                          Consumer(builder: (context, ref, _) {
                            final strings = ref.watch(appStringsProvider);
                            return Text(strings.readingQuestion, style: TextStyle(fontWeight: DynamicTokens.fontWeightBold));
                          }),
                          const SizedBox(height: 6),
                          Text(
                            (_data!['question'] ?? '').toString(),
                            style: const TextStyle(height: 1.5),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // 解釈
                        Consumer(builder: (context, ref, _) {
                          final strings = ref.watch(appStringsProvider);
                          return Text(strings.readingInterpretation, style: TextStyle(fontWeight: DynamicTokens.fontWeightBold));
                        }),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DynamicTokens.textTertiaryStatic.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: DynamicTokens.textTertiaryStatic.withOpacity(0.3)),
                          ),
                          child: Text(
                            _sanitizeInterpretationJP(
                              (_data!['interpretation'] ?? '').toString(),
                              (_data!['question'] ?? '').toString(),
                            ),
                            style: TextStyle(fontSize: DynamicTokens.fontSizeBodyMedium, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'one':
        return ref.watch(appStringsProvider).labelOneOracle;
      case 'two':
        return ref.watch(appStringsProvider).labelTwoCard;
      case 'three':
        return ref.watch(appStringsProvider).labelThreeCard;
      default:
        return ref.watch(appStringsProvider).readingTitle;
    }
  }

  Widget _buildCardInfoSection() {
    final spreadId = (_data!['spread_id'] ?? '').toString();
    
    if (spreadId == 'one' && _cardDetails.isNotEmpty) {
      // ワンオラクル
      final card = _cardDetails[0];
      return Text(
                  '${ref.watch(appStringsProvider).labelCard}: ${card['name']} ${card['is_upright'] ? ref.watch(appStringsProvider).labelUpright : ref.watch(appStringsProvider).labelReversed}',
        style: TextStyle(fontWeight: DynamicTokens.fontWeightSemiBold),
      );
    } else if (spreadId == 'two' && _cardDetails.length >= 2) {
      // ツーカード
      final cardA = _cardDetails[0];
      final cardB = _cardDetails[1];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ref.watch(appStringsProvider).readingOptionA}: ${cardA['name']} ${cardA['is_upright'] ? ref.watch(appStringsProvider).labelUpright : ref.watch(appStringsProvider).labelReversed}',
            style: TextStyle(fontWeight: DynamicTokens.fontWeightSemiBold),
          ),
          Text(
            '${ref.watch(appStringsProvider).readingOptionB}: ${cardB['name']} ${cardB['is_upright'] ? ref.watch(appStringsProvider).labelUpright : ref.watch(appStringsProvider).labelReversed}',
            style: TextStyle(fontWeight: DynamicTokens.fontWeightSemiBold),
          ),
        ],
      );
    } else if (spreadId == 'three' && _cardDetails.length >= 3) {
      // スリーカード
      final pastCard = _cardDetails[0];
      final presentCard = _cardDetails[1];
      final futureCard = _cardDetails[2];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ref.watch(appStringsProvider).labelPast}: ${pastCard['name']} ${pastCard['is_upright'] ? ref.watch(appStringsProvider).labelUpright : ref.watch(appStringsProvider).labelReversed}',
            style: TextStyle(fontWeight: DynamicTokens.fontWeightSemiBold),
          ),
          Text(
            '${ref.watch(appStringsProvider).labelPresent}: ${presentCard['name']} ${presentCard['is_upright'] ? ref.watch(appStringsProvider).labelUpright : ref.watch(appStringsProvider).labelReversed}',
            style: TextStyle(fontWeight: DynamicTokens.fontWeightSemiBold),
          ),
          Text(
            '${ref.watch(appStringsProvider).labelFuture}: ${futureCard['name']} ${futureCard['is_upright'] ? ref.watch(appStringsProvider).labelUpright : ref.watch(appStringsProvider).labelReversed}',
            style: TextStyle(fontWeight: DynamicTokens.fontWeightSemiBold),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  // 日本語表示向けの整形：
  // - 中国語ヘッダ（占卜问题/牌面解读/占卜时间）を除去
  // - 「正位/逆位」→「正位置/逆位置」に置換
  String _sanitizeInterpretationJP(String text, String question) {
    String t = text;
    // 中国語ヘッダを削除
    t = t.replaceAll(RegExp(r'【占卜问题】[\s\S]*?(?=\n\n|\Z)'), '');
    t = t.replaceAll('【牌面解读】', '');
    t = t.replaceAll('【牌面解読】', '');
    t = t.replaceAll(RegExp(r'【占卜时间】[\s\S]*$'), '');
    // データ由来の見出し「今日の運勢：...」を除去（先頭または段落先頭）
    t = t.replaceAll(RegExp(r'(^|\n)\s*今日の運勢[:：].*'), '');
    // 正位/逆位 → 正位置/逆位置
          t = t.replaceAll('正位', ref.watch(appStringsProvider).labelUpright);
      t = t.replaceAll('逆位', ref.watch(appStringsProvider).labelReversed);
    // 余分な空行を整える
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
          return t.isEmpty ? ref.watch(appStringsProvider).messageNoInterpretationSaved : t;
  }
}


