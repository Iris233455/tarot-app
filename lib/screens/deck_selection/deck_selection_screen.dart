import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/deck_service.dart';
import 'package:mystic_tarot_jp/providers/deck_provider.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/providers/daily_card_provider.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

class DeckSelectionScreen extends ConsumerStatefulWidget {
  const DeckSelectionScreen({super.key});

  @override
  ConsumerState<DeckSelectionScreen> createState() => _DeckSelectionScreenState();
}

class _DeckSelectionScreenState extends ConsumerState<DeckSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final allDecksAsync = ref.watch(allDecksProvider);
    final currentDeckId = ref.watch(currentDeckIdProvider);
    final currentDeckAsync = ref.watch(currentDeckProvider);
    
    return Scaffold(
      backgroundColor: dynamicTokens.backgroundColor,
      appBar: AppBar(
        title: const Text('タロットデッキ選択'),
        backgroundColor: dynamicTokens.surfaceColor,
        foregroundColor: dynamicTokens.primaryColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: currentDeckAsync.when(
              loading: () => const Text(
                '読み込み中...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              error: (error, stack) => const Text(
                '使用するタロットカードを選択',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              data: (currentDeck) => Text(
                currentDeck?.nameJp ?? '使用するタロットカードを選択',
                style: TextStyle(
                  fontSize: 14, 
                  color: dynamicTokens.primaryColor.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
      body: allDecksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
        data: (allDecks) => allDecks.isEmpty 
            ? _buildEmptyState() 
            : _buildDeckList(allDecks, currentDeckId),
      ),
    );
  }

  Future<void> _selectDeck(String deckId) async {
    try {
      // 使用 provider 来切换套牌，这会自动通知所有依赖的 widget
      await ref.read(currentDeckIdProvider.notifier).setDeck(deckId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('デッキが変更されました'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // 少し遅延后刷新所有provider并返回前一页面
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 手动刷新相关 provider，确保立即更新
        ref.invalidate(allTarotCardsProvider);
        ref.invalidate(groupedTarotCardsProvider);
        ref.invalidate(majorArcanaProvider);
        ref.invalidate(minorArcanaProvider);
        
        // 刷新首日抽牌，确保显示当前套牌的图片
        await ref.read(dailyCardProvider.notifier).refresh();
        
        // 刷新月度卡片provider，确保日历立即更新
        ref.invalidate(monthlyCardsProvider);
        
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('デッキの変更に失敗しました: $e')),
        );
      }
    }
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました\n$error',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '利用可能なデッキがありません',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList(List<TarotDeck> allDecks, String currentDeckId) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allDecks.length,
      itemBuilder: (context, index) {
        final deck = allDecks[index];
        final isSelected = deck.deckId == currentDeckId;
        
        return FadeInUp(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: isSelected ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isSelected
                    ? BorderSide(color: dynamicTokens.primaryColor, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () => _selectDeck(deck.deckId),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 套牌预览图片
                          Container(
                            width: 60,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              color: Colors.grey[100],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/tarot/${deck.imagePath}/major_00_fool${deck.deckId == 'rider_waite' ? '.jpeg' : '.png'}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.style,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // 套牌信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deck.nameJp,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? dynamicTokens.primaryColor : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  deck.nameEn,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '作者: ${deck.author}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  '年代: ${deck.year}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 选中状态指示器
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: dynamicTokens.primaryColor,
                              size: 30,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 套牌描述
                      Text(
                        deck.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                      
                      // 默认标签
                      if (deck.isDefault)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: dynamicTokens.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'デフォルト',
                            style: TextStyle(
                              color: dynamicTokens.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}