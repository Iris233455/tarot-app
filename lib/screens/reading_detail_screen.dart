import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Consumer(
      builder: (context, ref, __) {
        final dt = ref.watch(dynamicTokensProvider);
        return Scaffold(
          appBar: AppBar(
            title: const Text('解釈の詳細'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: Border(
              bottom: BorderSide(color: dt.primaryColor.withOpacity(0.12)),
            ),
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: const Icon(AppIcons.arrowBack),
              onPressed: () => context.pop(),
              tooltip: '戻る',
            ),
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(dt.primaryColor),
                  ),
                )
              : _data == null
                  ? const Center(child: Text('記録が見つかりません'))
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
                                    color: dt.primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                                    border: Border.all(color: dt.primaryColor.withOpacity(0.22)),
                                  ),
                                  child: Text(
                                    _typeLabel(_data!['spread_id'] ?? ''),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('yyyy/MM/dd HH:mm').format(
                                    DateTime.tryParse(_data!['created_at'] ?? '') ?? DateTime.now(),
                                  ),
                                  style: const TextStyle(color: DynamicTokens.textGrey600),
                                ),
                              ],
                            ),
                            
                            // カード情報
                            if (_cardDetails.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildCardInfoSection(),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 16),
                            // 質問
                            if ((_data!['question'] ?? '').toString().isNotEmpty) ...[
                              const Text('質問', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
                              const SizedBox(height: 6),
                              Text(
                                (_data!['question'] ?? '').toString(),
                                style: const TextStyle(height: 1.5, color: DynamicTokens.textBlack87),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // 解釈
                            const Text('解釈', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dt.primaryColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                                border: Border.all(color: dt.primaryColor.withOpacity(0.18)),
                              ),
                              child: Text(
                                _sanitizeInterpretationJP(
                                  (_data!['interpretation'] ?? '').toString(),
                                  (_data!['question'] ?? '').toString(),
                                ),
                                style: const TextStyle(fontSize: 14, height: 1.6, color: DynamicTokens.textBlack87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'one':
        return 'ワンオラクル';
      case 'two':
        return 'ツーカード';
      case 'three':
        return 'スリーカード';
      default:
        return '占い';
    }
  }

  Widget _buildCardInfoSection() {
    final spreadId = (_data!['spread_id'] ?? '').toString();
    
    if (spreadId == 'one' && _cardDetails.isNotEmpty) {
      // ワンオラクル
      final card = _cardDetails[0];
      return Text(
        'カード: ${card['name']} ${card['is_upright'] ? '正位置' : '逆位置'}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
    } else if (spreadId == 'two' && _cardDetails.length >= 2) {
      // ツーカード
      final cardA = _cardDetails[0];
      final cardB = _cardDetails[1];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選択A: ${cardA['name']} ${cardA['is_upright'] ? '正位置' : '逆位置'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '選択B: ${cardB['name']} ${cardB['is_upright'] ? '正位置' : '逆位置'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
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
            '過去: ${pastCard['name']} ${pastCard['is_upright'] ? '正位置' : '逆位置'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '現在: ${presentCard['name']} ${presentCard['is_upright'] ? '正位置' : '逆位置'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '未来: ${futureCard['name']} ${futureCard['is_upright'] ? '正位置' : '逆位置'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
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
    t = t.replaceAll('正位', '正位置');
    t = t.replaceAll('逆位', '逆位置');
    // 余分な空行を整える
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return t.isEmpty ? '（解釈は保存されていません）' : t;
  }
}


