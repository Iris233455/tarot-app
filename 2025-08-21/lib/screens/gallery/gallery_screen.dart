import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/widgets/themed_background.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';

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
    final strings = ref.watch(appStringsProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      hintText: ref.watch(appStringsProvider).labelSearchCard,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
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
        selectedItemColor: dynamicTokens.primaryColor,
        unselectedItemColor: dynamicTokens.textTertiary,
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: strings.homeDailyCard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome),
            label: strings.readingSelectSpread,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
                          label: ref.watch(appStringsProvider).galleryTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.style),
            label: strings.myDeckTitle,
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
          final strings = ref.watch(appStringsProvider);
          return Center(
            child: Text(strings.messageNoHistory),
          );
        }
        return _buildCardGrid(cards);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: DynamicTokens.textError),
            const SizedBox(height: 16),
            Text(ref.watch(appStringsProvider).messageError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(searchTarotCardsProvider(_searchQuery)),
              child: Text(ref.watch(appStringsProvider).buttonRetry),
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
            Icon(Icons.error, size: 48, color: DynamicTokens.textError),
            const SizedBox(height: 16),
            Text(ref.watch(appStringsProvider).messageError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(groupedTarotCardsProvider),
              child: Text(ref.watch(appStringsProvider).buttonRetry),
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
                  // 有背景图的主题：使用高透明度白色背景
                  DynamicTokens.textWhite.withOpacity(0.95),
                  DynamicTokens.textWhite.withOpacity(0.90),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
                         color: DynamicTokens.textTertiaryStatic.withOpacity(0.2),
                         child: Icon(Icons.broken_image, size: 48, color: DynamicTokens.textTertiaryStatic),
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
                          fontWeight: DynamicTokens.fontWeightBold,
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
                    title: ref.watch(appStringsProvider).labelMajorArcana,
        subtitle: 'Major Arcana',
            icon: Icons.star,
            cards: grouped['大アルカナ'] ?? [],
          ),
        ),
        FadeInUp(
          duration: DynamicTokens.animationDuration,
          delay: const Duration(milliseconds: 50),
          child: _buildExpansionPanel(
                    title: ref.watch(appStringsProvider).labelMinorArcana,
        subtitle: 'Minor Arcana',
            icon: Icons.style,
            cards: [], // 空列表，因为我们使用extraChildren
            extraChildren: [
                      _buildSuitExpansion(ref.watch(appStringsProvider).labelWands, 'Wands', Icons.local_fire_department, grouped['ワンド'] ?? [], 'wands'),
        _buildSuitExpansion(ref.watch(appStringsProvider).labelCups, 'Cups', Icons.water_drop, grouped['カップ'] ?? [], 'cups'),
        _buildSuitExpansion(ref.watch(appStringsProvider).labelSwords, 'Swords', Icons.flash_on, grouped['ソード'] ?? [], 'swords'),
        _buildSuitExpansion(ref.watch(appStringsProvider).labelPentacles, 'Pentacles', Icons.circle, grouped['ペンタクル'] ?? [], 'pentacles'),
            ],
          ),
        ),
        FadeInUp(
          duration: DynamicTokens.animationDuration,
          delay: const Duration(milliseconds: 100),
          child: _buildExpansionPanel(
                    title: ref.watch(appStringsProvider).labelTarotExperts,
        subtitle: 'Experts',
            icon: Icons.person,
            cards: grouped['タロットカード士'] ?? [],
            extraChildren: [
                      _buildInfoTile(ref.watch(appStringsProvider).labelWaite, 'A.E. Waite'),
        _buildInfoTile(ref.watch(appStringsProvider).labelSmith, 'Pamela Colman Smith'),
        _buildInfoTile(ref.watch(appStringsProvider).labelCrowley, 'Aleister Crowley'),
            ],
          ),
        ),
        FadeInUp(
          duration: DynamicTokens.animationDuration,
          delay: const Duration(milliseconds: 150),
          child: _buildExpansionPanel(
                    title: ref.watch(appStringsProvider).labelTarotBooks,
        subtitle: 'Books',
            icon: Icons.book,
            cards: grouped['タロット作品'] ?? [],
            extraChildren: [
                      _buildInfoTile(ref.watch(appStringsProvider).labelPictorialKey, 'Pictorial Key to the Tarot'),
        _buildInfoTile(ref.watch(appStringsProvider).labelBookOfThoth, 'Book of Thoth'),
            ],
          ),
        ),
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
            // 有背景图的主题：使用高透明度白色背景
            DynamicTokens.textWhite.withOpacity(0.95),
            DynamicTokens.textWhite.withOpacity(0.90),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
              fontWeight: DynamicTokens.fontWeightBold,
              color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? DynamicTokens.textBlack87 : null,
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
            color: DynamicTokens.textTertiaryStatic.withOpacity(0.2),
            width: 44,
            height: 64,
            child: Icon(Icons.broken_image, size: 32, color: DynamicTokens.textTertiaryStatic),
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
      leading: Icon(Icons.info_outline, color: DynamicTokens.textTertiaryStatic),
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
            color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? DynamicTokens.textBlack87 : null,
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
              ? [DynamicTokens.textWhite.withOpacity(0.95), DynamicTokens.textWhite.withOpacity(0.9)]
              : [DynamicTokens.textWhite, DynamicTokens.textWhite],
        ),
        borderRadius: BorderRadius.circular(8),
        // 统一去除默认灰色线框，使用主题色边框
        border: Border.all(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? dynamicTokens.primaryColor.withOpacity(0.3)
              : Colors.transparent,
          width: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 1 : 0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${suitInfo.nameJp}${ref.watch(appStringsProvider).labelMeaning}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: DynamicTokens.fontWeightBold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              suitInfo.symbolism,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: DynamicTokens.fontWeightBold,
                color: Theme.of(context).primaryColor,
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
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 48),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 卡片名称
                Text(
                  card.nameJa ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: DynamicTokens.fontWeightBold,
                    color: dynamicTokens.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  card.nameEn ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ref.watch(dynamicTokensProvider).textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 故事部分
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(appStringsProvider).labelStory,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: DynamicTokens.fontWeightRegular,
                          fontSize: DynamicTokens.fontSizeBodyMedium,
                          color: Colors.blue.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.story,
                        style: TextStyle(
                          fontSize: DynamicTokens.fontSizeBodyMedium,
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
                    color: DynamicTokens.textSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DynamicTokens.textSuccess.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(appStringsProvider).labelUpright,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: DynamicTokens.fontWeightRegular,
                          fontSize: DynamicTokens.fontSizeBodyMedium,
                          color: DynamicTokens.textSuccess.withOpacity(0.7),
                        ),
                      ),
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
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: DynamicTokens.fontSizeBodyLarge,
                                      fontWeight: DynamicTokens.fontWeightBold,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (parsed['content']!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    parsed['content']!,
                                    style: TextStyle(
                                      fontSize: DynamicTokens.fontSizeBodyMedium,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                Text(
                                  card.meaningUpright,
                                  style: TextStyle(
                                    fontSize: DynamicTokens.fontSizeBodyMedium,
                                    height: 1.4,
                                  ),
                                ),
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
                            return Text(
                              ref.watch(appStringsProvider).messageNoKeywords,
                              style: TextStyle(
                                fontSize: DynamicTokens.fontSizeBodySmall,
                                color: DynamicTokens.textTertiaryStatic,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: keywords
                                .take(8)
                                .map((keyword) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: DynamicTokens.textSuccess.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: DynamicTokens.textSuccess.withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        keyword,
                                        style: TextStyle(
                                          fontSize: DynamicTokens.fontSizeBodySmall,
                                          color: DynamicTokens.textSuccess,
                                          fontWeight: DynamicTokens.fontWeightMedium,
                                        ),
                                      ),
                                    ))
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
                    color: DynamicTokens.textError.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DynamicTokens.textError.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(appStringsProvider).labelReversed,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: DynamicTokens.fontWeightRegular,
                          fontSize: DynamicTokens.fontSizeBodyMedium,
                          color: DynamicTokens.textError.withOpacity(0.7),
                        ),
                      ),
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
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: DynamicTokens.fontSizeBodyLarge,
                                      fontWeight: DynamicTokens.fontWeightBold,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (parsed['content']!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    parsed['content']!,
                                    style: TextStyle(
                                      fontSize: DynamicTokens.fontSizeBodyMedium,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                Text(
                                  card.meaningReversed,
                                  style: TextStyle(
                                    fontSize: DynamicTokens.fontSizeBodyMedium,
                                    height: 1.4,
                                  ),
                                ),
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
                            return Text(
                              ref.watch(appStringsProvider).messageNoKeywords,
                              style: TextStyle(
                                fontSize: DynamicTokens.fontSizeBodySmall,
                                color: DynamicTokens.textTertiaryStatic,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: keywords
                                .take(8)
                                .map((keyword) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: DynamicTokens.textError.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: DynamicTokens.textError.withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        keyword,
                                        style: TextStyle(
                                          fontSize: DynamicTokens.fontSizeBodySmall,
                                          color: DynamicTokens.textError,
                                          fontWeight: DynamicTokens.fontWeightMedium,
                                        ),
                                      ),
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
          // 关闭按钮 - 右上角X按钮
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.1),
                foregroundColor: DynamicTokens.textGrey600,
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