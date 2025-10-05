import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/providers/tarot_providers.dart';
import 'package:mystic_tarot_jp/widgets/themed_background.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:mystic_tarot_jp/core/ui/app_logo.dart';
import 'package:mystic_tarot_jp/core/ui/app_return_icon.dart';

class ReadingFlowShell extends ConsumerWidget {
  final Widget child;

  const ReadingFlowShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final currentLocation = GoRouterState.of(context).uri.path;
    
    return Scaffold(
      extendBodyBehindAppBar: false, // 改为false避免透明问题
      backgroundColor: dynamicTokens.backgroundColor,
      resizeToAvoidBottomInset: true, // 标准键盘处理
      appBar: AppBar(
        backgroundColor: dynamicTokens.backgroundColor,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        toolbarHeight: kToolbarHeight,
        automaticallyImplyLeading: false,
        titleSpacing: NavigationToolbar.kMiddleSpacing,
        leading: null,
        title: currentLocation == '/reading'
            ? InkWell(
                onTap: () => context.go('/'),
                customBorder: const CircleBorder(),
                child: const AppLogo(size: 36),
              )
            : GestureDetector(
                onTap: () {
                  switch (currentLocation) {
                    case '/reading/intro':
                      context.go('/reading');
                      break;
                    case '/reading/question':
                      context.go('/reading/intro');
                      break;
                    case '/reading/shuffle':
                      context.go('/reading/question');
                      break;
                    case '/reading/result':
                      context.go('/reading/shuffle');
                      break;
                    default:
                      context.go('/');
                  }
                },
                child: const AppReturnIcon(size: 36),
              ),
        centerTitle: true,
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
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: child, // 与首页首模块保持一致的顶部间距
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: dynamicTokens.backgroundColor, // 添加明确背景色
        currentIndex: 1,
        selectedItemColor: DynamicTokens.textBlack87,
        unselectedItemColor: DynamicTokens.textBlack87,
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
} 