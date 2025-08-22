import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/widgets/themed_background.dart';
import 'package:go_router/go_router.dart';

class ReadingFlowShell extends ConsumerWidget {
  final Widget child;

  const ReadingFlowShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return Scaffold(
      extendBodyBehindAppBar: false, // 改为false避免透明问题
      backgroundColor: dynamicTokens.backgroundColor,
      resizeToAvoidBottomInset: true, // 标准键盘处理
      appBar: AppBar(
        backgroundColor: dynamicTokens.backgroundColor, // 添加明确背景色
        elevation: 1, // 轻微阴影增强固定效果
        surfaceTintColor: Colors.transparent, // 避免Material 3的tint效果
        scrolledUnderElevation: 1, // 滚动时保持固定外观
        shadowColor: Colors.black.withOpacity(0.1), // 轻微阴影色
        toolbarHeight: kToolbarHeight, // 确保标准高度
        automaticallyImplyLeading: true, // 确保标准行为
        titleSpacing: NavigationToolbar.kMiddleSpacing, // 标准标题间距
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dynamicTokens.textPrimary),
          onPressed: () {
            final currentLocation = GoRouterState.of(context).uri.path;
            
            // 根据当前路径决定返回行为
            switch (currentLocation) {
              case '/reading':
                // 如果在占い首页，返回主页
                context.go('/');
                break;
              case '/reading/intro':
                context.go('/reading');
                break;
              case '/reading/question':
                // 如果在问题页面，返回占い首页
                context.go('/reading/intro');
                break;
              case '/reading/shuffle':
                // 如果在洗牌页面，返回问题页面
                context.go('/reading/question');
                break;
              case '/reading/result':
                // 如果在结果页面，返回洗牌页面
                context.go('/reading/shuffle');
                break;
              default:
                // 默认返回主页
                context.go('/');
            }
          },
        ),
        title: Consumer(
          builder: (context, ref, _) {
            final currentLocation = GoRouterState.of(context).uri.path;
            final readingFormat = ref.watch(readingFormatProvider);
            
            String titleText;
            switch (currentLocation) {
              case '/reading':
                titleText = ref.watch(appStringsProvider).labelSelectSpread;
                break;
              case '/reading/intro':
                titleText = readingFormat.isNotEmpty ? readingFormat : ref.watch(appStringsProvider).readingSelectSpread;
                break;
              case '/reading/question':
              case '/reading/shuffle':
              case '/reading/result':
                titleText = readingFormat.isNotEmpty ? readingFormat : ref.watch(appStringsProvider).readingTitle;
                break;
              default:
                titleText = ref.watch(appStringsProvider).readingTitle;
            }
            
            return Text(
              titleText,
              style: TextStyle(
                color: dynamicTokens.textPrimary,
                fontSize: 20,
                fontWeight: DynamicTokens.fontWeightBold,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: ThemedBackground(
        child: child, // 完全移除SafeArea，让Scaffold自动处理
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: dynamicTokens.backgroundColor, // 添加明确背景色
        currentIndex: 1,
        selectedItemColor: dynamicTokens.primaryColor,
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.home),
                          label: ref.watch(appStringsProvider).homeDailyCard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
                          label: ref.watch(appStringsProvider).readingSelectSpread,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
                          label: ref.watch(appStringsProvider).galleryTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
                          label: ref.watch(appStringsProvider).myDeckTitle,
          ),
        ],
      ),
    );
  }
} 