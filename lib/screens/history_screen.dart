import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mystic_tarot_jp/core/theme/app_theme.dart';
import 'package:mystic_tarot_jp/providers/history_provider.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
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
                      const Icon(
                        Icons.history,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'まだ履歴がありません',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        'No reading history yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      ElevatedButton(
                        onPressed: () => context.go('/draw-cards'),
                        child: const Text('カードを引く'),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                itemCount: uiList.length,
                itemBuilder: (context, index) {
                  final reading = uiList[index];
                  final readingId = reading['id']?.toString() ?? '';
                  
                  return Dismissible(
                    key: ValueKey<String>('reading_$readingId'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
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
                    child: _buildHistoryCard(context, reading, index),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 64,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  ElevatedButton(
                     onPressed: () => ref.refresh(readingHistoryProvider),
                    child: const Text('再試行'),
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
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('削除確認'),
            content: const Text('この履歴を削除しますか？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除')),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildHistoryCard(BuildContext context, reading, int index) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final date = DateTime.tryParse(reading['created_at'] ?? '') ?? DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
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
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部信息
                  Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: _getReadingTypeColor(reading['spread_id'] ?? ''),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        _getReadingTypeText(reading['spread_id'] ?? ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // 質問
                if ((reading['question'] ?? '').toString().isNotEmpty) ...[
                  Text(
                    '質問',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    (reading['question'] ?? '').toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontSizeMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
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