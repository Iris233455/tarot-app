import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/data_service.dart';
import '../../models/tarot_card.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';

class StepsInfoDialog extends ConsumerStatefulWidget {
  final String spreadType;
  final bool showNextButton;

  const StepsInfoDialog({
    super.key,
    required this.spreadType,
    this.showNextButton = false,
  });

  @override
  ConsumerState<StepsInfoDialog> createState() => _StepsInfoDialogState();
}

class _StepsInfoDialogState extends ConsumerState<StepsInfoDialog> {
  SpreadInfo? _spreadInfo;
  bool _isLoading = true;
  Map<String, dynamic>? _meta;

  @override
  void initState() {
    super.initState();
    _loadSpreadInfo();
  }

  Future<void> _loadSpreadInfo() async {
    try {
      final meta = await DataService.getSpreadMeta();
      // spreadType 可能为日文名，尝试通过名称映射到spreads_id
      _meta = meta.values.firstWhere(
        (m) => (m['title'] ?? '') == widget.spreadType,
        orElse: () => {},
      );
      // 退回：直接使用spreads_id匹配
      if ((_meta == null || _meta!.isEmpty) && meta.containsKey(widget.spreadType)) {
        _meta = meta[widget.spreadType];
      }

      if (widget.spreadType == 'daily_spread') {
        _spreadInfo = await DataService.getDailySpread();
      } else {
        final spreads = await DataService.getSpreads();
        final spreadsList = spreads.where((spread) => 
          spread.name.contains(widget.spreadType) || 
          _getSpreadName(widget.spreadType) == spread.name
        );
        if (spreadsList.isNotEmpty) {
          _spreadInfo = spreadsList.first;
        }
      }
    } catch (e) {
      print('スプレッド情報の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getSpreadName(String spreadType) {
    switch (spreadType) {
      case 'ワンオラクル':
        return 'ワンオラクル';
      case 'スリーカード':
        return 'スリーカード';
      case 'ケルト十字':
        return 'ケルト十字';
      default:
        return spreadType;
    }
  }

  List<String> _getSteps() {
    final metaSteps = (_meta?['steps'] as String?)?.trim() ?? '';
    if (metaSteps.isNotEmpty) {
      // steps 可能包含多段落，以换行分割
      final lines = metaSteps.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (lines.isNotEmpty) return lines;
    }
    return _spreadInfo?.steps ?? const [];
  }

  List<String> _getQuestionPoints() {
    final points = (_meta?['question_points'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];
    return points;
  }

  String _resolveSpreadImage(String title) {
    // 与 FormatSelectPage 的规则保持一致
    if (title.contains('ワンオラクル')) return 'assets/images/spreads/eye_tarot1.png';
    if (title.contains('ツーカード')) return 'assets/images/spreads/eye_tarot2.png';
    if (title.contains('スリーカード')) return 'assets/images/spreads/eye_tarot3.png';
    return 'assets/images/spreads/eye_tarot1.png';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(DynamicTokens.spacingLg),
        constraints: const BoxConstraints(
          maxWidth: 560,
          maxHeight: 720,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _spreadInfo == null
                ? const Center(
                    child: Text(
                      'スプレッド情報が見つかりません',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (_meta?['title'] as String?) ?? _spreadInfo!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(AppIcons.close, size: 16),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const Size(24, 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DynamicTokens.spacingMd),

                      // 顶部图片（spreads_1/2/3）
                      if (_meta != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            _resolveSpreadImage((_meta?['title'] as String?) ?? ''),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Description / message
                      if (((_meta?['message'] ?? '') as String).isNotEmpty || _spreadInfo!.description != null) ...[
                        Container(
                          padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.infoOutline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: DynamicTokens.spacingSm),
                              Expanded(
                                child: Text(
                                  (((_meta?['message'] ?? '') as String).isNotEmpty)
                                      ? (_meta?['message'] as String)
                                      : (_spreadInfo!.description ?? ''),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DynamicTokens.spacingLg),
                      ],
                      
                      // Steps（来自 contents.json 的 steps 优先）
                      Text(
                        '手順',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: DynamicTokens.spacingSm),
                      
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _getSteps().length,
                          itemBuilder: (context, index) {
                            final step = _getSteps()[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: DynamicTokens.spacingSm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: DynamicTokens.spacingSm),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: DynamicTokens.spacingSm),

                      // 質問ポイント
                      if (_getQuestionPoints().isNotEmpty) ...[
                        Text(
                          '質問のポイント',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: DynamicTokens.spacingXs),
                        ..._getQuestionPoints().map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: DynamicTokens.spacingXs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(p, style: Theme.of(context).textTheme.bodyMedium)),
                            ],
                          ),
                        )),
                      ],

                      if (widget.showNextButton) ...[
                        const SizedBox(height: DynamicTokens.spacingMd),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            const SizedBox(width: DynamicTokens.spacingXs),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ref.read(dynamicTokensProvider).primaryColor,
                                foregroundColor: DynamicTokens.textWhite,
                                elevation: 0,
                              ),
                              child: const Text('次へ'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
} 