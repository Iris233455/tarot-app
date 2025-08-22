import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mystic_tarot_jp/core/theme/app_theme.dart';
import 'package:mystic_tarot_jp/providers/history_provider.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final Set<String> _deletedIds = <String>{};

  List<Map<String, dynamic>> _filterDeletedItems(List<Map<String, dynamic>> items) {
    return items.where((item) => !_deletedIds.contains(item['id']?.toString() ?? '')).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(readingHistoryProvider);
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.historyTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/mydeck');
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: historyAsync.when(
            data: (readings) {
              // 过滤掉已删除的项目
              final uiList = _filterDeletedItems(readings);
              if (uiList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        color: DynamicTokens.textWhite54,
                        size: 64,
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      Text(
                        strings.messageNoHistory,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: DynamicTokens.textWhite70,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      Text(
                        strings.messageNoHistory,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DynamicTokens.textWhite54,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingL),
                      ElevatedButton(
                        onPressed: () => context.go('/draw-cards'),
                        child: Text(strings.readingTarotReading),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: EdgeInsets.all(AppTheme.spacingL),
                itemCount: uiList.length,
                itemBuilder: (context, index) {
                  final reading = uiList[index];
                  final readingId = reading['id']?.toString() ?? '';
                  
                  return Dismissible(
                    key: ValueKey<String>('reading_$readingId'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: DynamicTokens.textError,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(Icons.delete_outline, color: DynamicTokens.textWhite),
                    ),
                    confirmDismiss: (_) async {
                      return await _confirmDelete(context);
                    },
                    onDismissed: (_) async {
                      // 立即从UI中隐藏该项目
                      if (readingId.isNotEmpty) {
                        setState(() {
                          _deletedIds.add(readingId);
                        });
                        
                        // 后台删除
                        try {
                          await SupabaseService.deleteReading(readingId);
                        } catch (e) {
                          print('删除失败: $e');
                        }
                        
                        // 刷新数据
                        ref.invalidate(readingHistoryProvider);
                      }
                    },
                    child: _buildHistoryCard(context, reading, index, dynamicTokens),
                  );
                },
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                color: AppTheme.textPrimary,
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 64,
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  Text(strings.messageError,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingL),
                  ElevatedButton(
                     onPressed: () => ref.refresh(readingHistoryProvider),
                    child: Text(strings.buttonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final strings = ref.read(appStringsProvider);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(strings.dialogDeleteConfirmTitle),
            content: Text(strings.dialogDeleteConfirmContent),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.buttonCancel)),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.buttonDelete)),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildHistoryCard(BuildContext context, reading, int index, DynamicTokens dynamicTokens) {
    final strings = ref.read(appStringsProvider);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final date = DateTime.tryParse(reading['created_at'] ?? '') ?? DateTime.now();
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
          child: InkWell(
          onTap: () {
            final id = (reading['id'] ?? '').toString();
            if (id.isNotEmpty) {
              context.push('/history/$id');
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部信息
                  Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: _getReadingTypeColor(reading['spread_id'] ?? ''),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        _getReadingTypeText(reading['spread_id'] ?? ''),
                        style: TextStyle(
                          color: DynamicTokens.textWhite,
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: DynamicTokens.fontWeightBold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        color: DynamicTokens.textWhite.withOpacity(0.7),
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: AppTheme.spacingM),
                
                // 質問
                if ((reading['question'] ?? '').toString().isNotEmpty) ...[
                  Text(strings.readingQuestion,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: DynamicTokens.fontWeightBold,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingS),
                  Text(
                    (reading['question'] ?? '').toString(),
                    style: TextStyle(
                      color: DynamicTokens.textWhite,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppTheme.spacingM),
                ],
                
                // 时间已在头部显示；卡片内容至此结束（不展示解釈/詳細按钮）
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getReadingTypeColor(String type) {
    switch (type) {
      case 'one':
        return AppTheme.primaryColor;
      case 'two':
        return AppTheme.secondaryColor;
      case 'three':
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getReadingTypeText(String type) {
    switch (type) {
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
} 