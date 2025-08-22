import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/screens/home/home_screen.dart';
import 'package:mystic_tarot_jp/screens/reading/reading_flow_shell.dart';
import 'package:mystic_tarot_jp/screens/reading/format_select_page.dart';
import 'package:mystic_tarot_jp/screens/reading/question_input_page.dart';
import 'package:mystic_tarot_jp/screens/reading/shuffle_page.dart';
import 'package:mystic_tarot_jp/screens/reading/result_page.dart';
import 'package:mystic_tarot_jp/screens/reading/spread_intro_page.dart';
import 'package:mystic_tarot_jp/screens/gallery/gallery_screen.dart';
import 'package:mystic_tarot_jp/screens/mydeck/mydeck_screen.dart';
import 'package:mystic_tarot_jp/screens/history_screen.dart';
import 'package:mystic_tarot_jp/screens/favorites_screen.dart';
import 'package:mystic_tarot_jp/screens/reading_detail_screen.dart';
import 'package:mystic_tarot_jp/screens/deck_selection/deck_selection_screen.dart';
import 'package:mystic_tarot_jp/screens/auth/auth_screen.dart';
import 'package:mystic_tarot_jp/screens/redemption/redemption_screen.dart';
import 'package:mystic_tarot_jp/screens/dev/design_tokens_screen.dart';
import 'package:mystic_tarot_jp/screens/dev/language_demo_screen.dart';
import 'package:mystic_tarot_jp/providers/auth_state_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthPath = state.matchedLocation == '/auth';
      final currentLocation = state.matchedLocation;
      
              print('🔄 ${ref.watch(appStringsProvider).messageRouterRedirectCheck}: ${authState.authState} @ $currentLocation');
      
      // 如果在加载中，不重定向
      if (authState.authState == AuthState.loading) {
                  print('   → ${ref.watch(appStringsProvider).messageLoadingStateNoRedirect}');
        return null;
      }
      
      // 如果URL包含OAuth回调参数，允许处理完成，不强制重定向
      final uri = Uri.parse(currentLocation);
      if (uri.queryParameters.containsKey('code') || 
          uri.fragment.contains('access_token') ||
          currentLocation.contains('callback')) {
                  print('   → ${ref.watch(appStringsProvider).messageOAuthCallbackDetected}');
        return null;
      }
      
      // 如果未认证且不在认证页面，重定向到认证页面（但豁免开发页面）
      final isDevPath = currentLocation.startsWith('/design-tokens') ||
                        currentLocation.startsWith('/language-demo');
      if (authState.authState == AuthState.unauthenticated && !isAuthPath && !isDevPath) {
                  print('   → ${ref.watch(appStringsProvider).messageUnauthenticatedRedirect}');
        return '/auth';
      }
      
      // 如果已认证但在认证页面，重定向到主页
      if (authState.authState == AuthState.authenticated && isAuthPath) {
                  print('   → ${ref.watch(appStringsProvider).messageAuthenticatedRedirect}');
        return '/';
      }
      
              print('   → ${ref.watch(appStringsProvider).messageNoRedirect}');
      return null;
    },
    refreshListenable: _GoRouterRefreshNotifier(ref),
    routes: [
      // 认证屏幕
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      // 主屏幕
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 即时切换，无动画
            return child;
          },
          transitionDuration: Duration.zero,
        ),
      ),
      
      // 阅读流程
      ShellRoute(
        builder: (context, state, child) => ReadingFlowShell(child: child),
        routes: [
          GoRoute(
            path: '/reading',
            name: 'reading',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const FormatSelectPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // 即时切换，无动画
                return child;
              },
              transitionDuration: Duration.zero,
            ),
          ),
          GoRoute(
            path: '/reading/intro',
            name: 'reading-intro',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const SpreadIntroPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // 即时切换，无动画
                return child;
              },
              transitionDuration: Duration.zero,
            ),
          ),
          GoRoute(
            path: '/reading/question',
            name: 'question',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const QuestionInputPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // 即时切换，无动画
                return child;
              },
              transitionDuration: Duration.zero,
            ),
          ),
          GoRoute(
            path: '/reading/shuffle',
            name: 'shuffle',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const ShufflePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // 即时切换，无动画
                return child;
              },
              transitionDuration: Duration.zero,
            ),
          ),
          GoRoute(
            path: '/reading/result',
            name: 'result',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const ResultPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // 即时切换，无动画
                return child;
              },
              transitionDuration: Duration.zero,
            ),
          ),
        ],
      ),
      
      // 画廊
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const GalleryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 即时切换，无动画
            return child;
          },
          transitionDuration: Duration.zero,
        ),
      ),
      
      // 我的牌组
      GoRoute(
        path: '/mydeck',
        name: 'mydeck',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const MyDeckScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 即时切换，无动画
            return child;
          },
          transitionDuration: Duration.zero,
        ),
      ),
      // 履歴
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      // お気に入り
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      // 履歴詳細
      GoRoute(
        path: '/history/:id',
        name: 'history-detail',
        builder: (context, state) => ReadingDetailScreen(
          readingId: state.pathParameters['id']!,
        ),
      ),
      
      // 套牌选择
      GoRoute(
        path: '/deck-selection',
        name: 'deck-selection',
        builder: (context, state) => const DeckSelectionScreen(),
      ),
      
      // 兑换码页面
      GoRoute(
        path: '/redemption',
        name: 'redemption',
        builder: (context, state) => const RedemptionScreen(),
      ),
      
      // 设计令牌可视化页面（开发用）
      GoRoute(
        path: '/design-tokens',
        name: 'design-tokens',
        builder: (context, state) => const DesignTokensScreen(),
      ),
      GoRoute(
        path: '/language-demo',
        name: 'language-demo',
        builder: (context, state) => const LanguageDemoScreen(),
      ),
    ],
  );
});

/// GoRouter刷新通知器，监听认证状态变化
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(this.ref) {
    ref.listen<UserState>(authStateProvider, (previous, next) {
      if (previous?.authState != next.authState) {
        notifyListeners();
      }
    });
  }

  final Ref ref;
} 