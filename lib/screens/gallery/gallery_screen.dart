import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/widgets/themed_background.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/core/ui/app_logo.dart';
import 'package:mystic_tarot_jp/widgets/app_tag.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  List<TarotCard> _filteredCards = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SuitInfo> _suits = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSuits();
  }

  void _loadSuits() async {
    try {
      final suits = await DataService.getSuits();
      setState(() {
        _suits = suits;
      });
    } catch (e) {
      print('花色信息加载失败: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 2,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        backgroundColor: dynamicTokens.backgroundColor,
        title: InkWell(
          onTap: () => context.go('/'),
          customBorder: const CircleBorder(),
          child: const AppLogo(size: 36),
        ),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? dynamicTokens.primaryColor.withOpacity(0.6)
              : dynamicTokens.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      body: ThemedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 搜索栏
              Padding(
                padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                child: FadeInDown(
                  duration: DynamicTokens.animationDuration,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'カードを検索...',
                      prefixIcon: const Icon(AppIcons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(AppIcons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // 内容区域
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: dynamicTokens.textPrimary,
        unselectedItemColor: dynamicTokens.textSecondary,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/reading');
              break;
            case 2:
              context.go('/gallery');
              break;
            case 3:
              context.go('/mydeck');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(AppIcons.home),
            label: '毎日の占い',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.autoAwesome),
            label: 'スプレット',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.libraryBooks),
            label: 'ギャラリー',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.style),
            label: 'マイページ',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchQuery.isNotEmpty) {
      // 搜索模式
      return _buildSearchResults();
    } else {
      // 分组显示模式
      return _buildGroupedView();
    }
  }

  Widget _buildSearchResults() {
    final searchProvider = ref.watch(searchTarotCardsProvider(_searchQuery));
    
    return searchProvider.when(
      data: (cards) {
        if (cards.isEmpty) {
          return const Center(
            child: Text('検索結果がありません'),
          );
        }
        return _buildCardGrid(cards);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 48, color: DynamicTokens.textError),
            const SizedBox(height: 16),
            Text('エラー: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(searchTarotCardsProvider(_searchQuery)),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedView() {
    final groupedProvider = ref.watch(groupedTarotCardsProvider);
    
    return groupedProvider.when(
      data: (grouped) => _buildGroupedList(grouped),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 48, color: DynamicTokens.textError),
            const SizedBox(height: 16),
            Text('エラー: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(groupedTarotCardsProvider),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid(List<TarotCard> cards) {
    return GridView.builder(
      padding: const EdgeInsets.all(DynamicTokens.spacingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: DynamicTokens.spacingMd,
        mainAxisSpacing: DynamicTokens.spacingMd,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return GestureDetector(
          onTap: () => _showCardDetail(context, card),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? [
                  // 有背景图：使用 DesignTokens.surfaceColor 的高透明度背景
                  DesignTokens.surfaceColor.withOpacity(0.95),
                  DesignTokens.surfaceColor.withOpacity(0.90),
                ] : [
                  // 纯色背景主题：保持原来的surface颜色
                  ref.watch(dynamicTokensProvider).surfaceColor.withOpacity(0.8),
                  ref.watch(dynamicTokensProvider).surfaceColor.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null)
                  ? ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.6)
                  : ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.2),
                width: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? 2 : 1,
              ),
              // no box shadows
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                         child: Image.asset(
                       card.imageUrl,
                       fit: BoxFit.cover,
                       errorBuilder: (c, e, s) => Container(
                         color: ref.watch(dynamicTokensProvider).surfaceColor.withOpacity(0.9),
                         child: const Icon(AppIcons.brokenImage, size: 48, color: DynamicTokens.textGrey600),
                       ),
                     ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.nameJa ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? DynamicTokens.textBlack87 : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        card.nameEn ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? DynamicTokens.textGrey600 : DynamicTokens.textGrey600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedList(Map<String, List<TarotCard>> grouped) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return ListView(
      padding: const EdgeInsets.all(DynamicTokens.spacingMd),
      children: [
        FadeInUp(
          duration: DynamicTokens.animationDuration,
          child: _buildExpansionPanel(
            title: '大アルカナ',
            subtitle: 'Major Arcana',
            icon: AppIcons.star,
            cards: grouped['大アルカナ'] ?? [],
          ),
        ),
        FadeInUp(
          duration: DynamicTokens.animationDuration,
          delay: const Duration(milliseconds: 50),
          child: _buildExpansionPanel(
            title: '小アルカナ',
            subtitle: 'Minor Arcana',
            icon: AppIcons.style,
            cards: [], // 空列表，因为我们使用extraChildren
            extraChildren: [
              _buildSuitExpansion('ワンド', 'Wands', AppIcons.localFireDepartment, grouped['ワンド'] ?? [], 'wands'),
              _buildSuitExpansion('カップ', 'Cups', AppIcons.waterDrop, grouped['カップ'] ?? [], 'cups'),
              _buildSuitExpansion('ソード', 'Swords', AppIcons.flashOn, grouped['ソード'] ?? [], 'swords'),
              _buildSuitExpansion('ペンタクル', 'Pentacles', AppIcons.circle, grouped['ペンタクル'] ?? [], 'pentacles'),
            ],
          ),
        ),
        // 隐藏：タロットカード士 / タロット作品 模块
      ],
    );
  }

  Widget _buildExpansionPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<TarotCard> cards,
    List<Widget>? extraChildren,
  }) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
            // 有背景图的主题：使用高透明度 surface 背景
            DesignTokens.surfaceColor.withOpacity(0.95),
            DesignTokens.surfaceColor.withOpacity(0.90),
          ] : [
            // 纯色背景主题：保持原来的surface颜色
            dynamicTokens.surfaceColor.withOpacity(0.8),
            dynamicTokens.surfaceColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
            ? dynamicTokens.primaryColor.withOpacity(0.6)
            : dynamicTokens.primaryColor.withOpacity(0.2),
          width: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 2 : 1,
        ),
        // no box shadows
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(
            icon,
            color: dynamicTokens.primaryColor,
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? DynamicTokens.textBlack87 : DynamicTokens.textBlack87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? DynamicTokens.textGrey600 : ref.watch(dynamicTokensProvider).textSecondary,
            ),
          ),
          children: [
            ...cards.map((card) => _buildCardTile(card)).toList(),
            if (extraChildren != null) ...extraChildren,
          ],
        ),
      ),
    );
  }



  Widget _buildCardTile(TarotCard card) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          card.imageUrl,
          height: 64,
          width: 44,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Container(
            color: ref.watch(dynamicTokensProvider).surfaceColor.withOpacity(0.9),
            width: 44,
            height: 64,
            child: const Icon(AppIcons.brokenImage, size: 32, color: DynamicTokens.textGrey600),
          ),
        ),
      ),
      title: Text(
        card.nameJa ?? '', 
        style: TextStyle(
          color: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? DynamicTokens.textBlack87 : null,
        ),
      ),
      subtitle: Text(
        card.nameEn ?? '',
        style: TextStyle(
          color: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? DynamicTokens.textGrey600 : null,
        ),
      ),
      onTap: () => _showCardDetail(context, card),
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return ListTile(
      leading: const Icon(AppIcons.infoOutline, color: Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? DynamicTokens.textBlack87 : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: (ref.watch(dynamicTokensProvider).isDark || ref.watch(dynamicTokensProvider).backgroundImage != null) ? DynamicTokens.textGrey600 : null,
        ),
      ),
    );
  }

  Widget _buildSuitExpansion(String title, String subtitle, IconData icon, List<TarotCard> cards, String suitType) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final suitInfo = _suits.firstWhere(
      (suit) => suit.nameEn.toLowerCase() == suitType, 
      orElse: () => SuitInfo(nameJp: title, nameEn: subtitle, story: '', symbolism: ''),
    );
    
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: dynamicTokens.primaryColor),
        title: Text(
          title, 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? DynamicTokens.textBlack87 : DynamicTokens.textBlack87,
          ),
        ),
        subtitle: Text(
          subtitle, 
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: dynamicTokens.isDark ? DynamicTokens.textGrey600 : null,
          ),
        ),
        children: [
          // 花色解说
          if (suitInfo.story.isNotEmpty) _buildSuitDescription(suitInfo),
          // 卡片列表
          ...cards.map((card) => _buildCardTile(card)).toList(),
        ],
      ),
    );
  }

  Widget _buildSuitDescription(SuitInfo suitInfo) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? [DesignTokens.surfaceColor.withOpacity(0.95), DesignTokens.surfaceColor.withOpacity(0.9)]
              : [DesignTokens.surfaceColor, DesignTokens.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(8),
        // 统一去除默认灰色线框，使用主题色边框
        border: Border.all(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? dynamicTokens.primaryColor.withOpacity(0.3)
              : Colors.transparent,
          width: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 1 : 0,
        ),
        // no box shadows
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.infoOutline,
                color: dynamicTokens.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${suitInfo.nameJp}の意味',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DynamicTokens.textBlack87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 主题色标签（单行，不换行，超出可横向滑动）
          SizedBox(
            height: 30,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: (
                  suitInfo.symbolism
                      .split(RegExp(r'[、,\s]+'))
                      .where((e) => e.isNotEmpty)
                      .take(6)
                      .toList()
                ).map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppTag(
                        t,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        borderRadius: 16,
                        fontSize: 12,
                        useTheme: true,
                        overlay: true,
                      ),
                    ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            suitInfo.story,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 解析文本的第一行和剩余内容
  Map<String, String> _parseTextContent(String text) {
    if (text.isEmpty) return {'title': '', 'content': ''};
    
    final lines = text.split('\n');
    if (lines.isEmpty) return {'title': '', 'content': ''};
    
    final firstLine = lines.first.trim();
    final remainingLines = lines.length > 1 ? lines.skip(1).join('\n').trim() : '';
    
    return {
      'title': firstLine,
      'content': remainingLines,
    };
  }

  void _showCardDetail(BuildContext context, TarotCard card) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: dynamicTokens.backgroundColor,
          child: Stack(
            children: [
              // 主要内容
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // 卡片图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    card.imageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(AppIcons.brokenImage, size: 48),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 卡片名称
                Text(
                  card.nameJa ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DynamicTokens.textBlack87,
                  ),
                  textAlign: TextAlign.left,
                ),
                Text(
                  card.nameEn ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ref.watch(dynamicTokensProvider).textSecondary,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),

                // 故事部分
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '物語り',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: DynamicTokens.textBlack87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.story,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 正位含义
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppTag('正位置', padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), borderRadius: 16, fontSize: 12, useTheme: true, overlay: true),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final parsed = _parseTextContent(card.meaningUpright);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (parsed['title']!.isNotEmpty) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    parsed['title']!,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                      color: DynamicTokens.textBlack87,
                                    ),
                                  ),
                                ),
                                if (parsed['content']!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    parsed['content']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: DynamicTokens.textBlack87,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                const SizedBox.shrink(),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // 正位关键词标签
                      Builder(
                        builder: (context) {
                          final keywords = card.uprightKeywordsList;
                          if (keywords.isEmpty) {
                            return const Text(
                              'キーワードデータなし',
                              style: TextStyle(
                                fontSize: 12,
                                color: DynamicTokens.textGrey500,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: keywords
                                .take(8)
                                .map((k) => const SizedBox.shrink())
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 逆位含义
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppTag('逆位置', padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), borderRadius: 16, fontSize: 12, useTheme: true, overlay: true),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final parsed = _parseTextContent(card.meaningReversed);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (parsed['title']!.isNotEmpty) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    parsed['title']!,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                      color: DynamicTokens.textBlack87,
                                    ),
                                  ),
                                ),
                                if (parsed['content']!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    parsed['content']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: DynamicTokens.textBlack87,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                const SizedBox.shrink(),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // 逆位关键词标签
                      Builder(
                        builder: (context) {
                          final keywords = card.reversedKeywordsList;
                          if (keywords.isEmpty) {
                            return const Text(
                              'キーワードデータなし',
                              style: TextStyle(
                                fontSize: 12,
                                color: DynamicTokens.textGrey500,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: keywords
                                .take(8)
                                .map((k) => AppTag(
                                      k,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      borderRadius: 20,
                                      fontSize: 12,
                                      useTheme: true,
                                      overlay: true,
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 关闭按钮 - 右上角X按钮（统一 24x24, icon 16, 间距 8）
          Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.close, size: 16),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(24, 24),
                  backgroundColor: DynamicTokens.textBlack87.withOpacity(0.1),
                  foregroundColor: DynamicTokens.textGrey600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
} 