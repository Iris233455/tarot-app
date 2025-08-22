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
import 'package:mystic_tarot_jp/screens/auth/password_reset_screen.dart';
import 'package:mystic_tarot_jp/screens/auth/password_reset_complete_screen.dart';
import 'package:mystic_tarot_jp/screens/redemption/redemption_screen.dart';
import 'package:mystic_tarot_jp/providers/auth_state_provider.dart';
import 'package:mystic_tarot_jp/providers/auth_state_provider.dart';

/// 检查是否为密码重置/OAuth回调流程（宽松白名单）
bool _isRecoveryFlow(GoRouterState state) {
  final href  = state.uri.toString();            // 原始完整 URL
  final path  = state.matchedLocation;           // GoRouter 匹配到的路径
  final qp    = state.uri.queryParameters;
  final frag  = state.uri.fragment;

  print('🔍 Router debug - 检查恢复流程:');
  print('   完整URL: $href');
  print('   匹配路径: $path');
  print('   Query参数: $qp');
  print('   Fragment: $frag');

  // 1) 目标页本身
  if (path == '/password-reset-complete' || path.startsWith('/password-reset-complete')) {
    print('   ✅ 匹配路径检查: true');
    return true;
  }

  // 2) Supabase 常见回传标记（query / fragment）
  if (qp.containsKey('type') && qp['type'] == 'recovery') {
    print('   ✅ Recovery参数检查: true');
    return true;
  }
  if (qp.containsKey('code') || qp.containsKey('state') || qp.containsKey('access_token')) {
    print('   ✅ OAuth码检查: true');
    return true;
  }
  if (frag.contains('access_token') || frag.contains('type=recovery')) {
    print('   ✅ Fragment检查: true');
    return true;
  }

  // 3) 兜底：整串 URL 中含目标路由也放行（对某些 HMR/首次渲染时序有效）
  if (href.contains('/password-reset-complete')) {
    print('   ✅ URL兜底检查: true');
    return true;
  }

  print('   ❌ 所有检查都失败，不是恢复流程');
  return false;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // 🔐 恢复流程：两种触发条件
      // 1) URL 中包含 recovery / code / access_token
      // 2) AuthStateProvider 标记了 passwordRecovery 事件
      final auth = ref.read(authStateProvider);
      final urlLooksLikeRecovery = _isRecoveryFlow(state);
      final isRecoveryEvent = auth.isPasswordRecovery == true;
      if (urlLooksLikeRecovery || isRecoveryEvent) {
        print('🔄 Router: 检测到恢复流程，强制跳转到 /password-reset-complete');
        if (state.matchedLocation != '/password-reset-complete') {
          return '/password-reset-complete';
        }
        return null;
      }

      // 此处之后再读取 auth 用于常规逻辑
      final auth2 = ref.read(authStateProvider);

      // Loading 状态不重定向
      if (auth.authState == AuthState.loading) {
        print('🔄 Router: Loading状态，不重定向');
        return null;
      }

      final isAuthPath      = state.matchedLocation == '/auth';
      final isResetAsk      = state.matchedLocation == '/password-reset';
      final isResetComplete = state.matchedLocation == '/password-reset-complete';

      final isSignedIn = auth2.authState == AuthState.authenticated;
      final isAnon     = auth2.isAnonymous == true;

      // 未登录用户：只放行 /auth、/password-reset、/password-reset-complete
      if (!isSignedIn && !(isAuthPath || isResetAsk || isResetComplete)) {
        print('🔄 Router: 未登录，重定向到/auth');
        return '/auth';
      }

      // 已登录用户：避免回到 /auth
      if (isSignedIn && isAuthPath) {
        print('🔄 Router: 已登录，重定向到/');
        return '/';
      }

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
      
      // 密码重置页面
      GoRoute(
        path: '/password-reset',
        name: 'password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      
      // 密码重置完成页面
      GoRoute(
        path: '/password-reset-complete',
        name: 'password-reset-complete',
        builder: (context, state) => const PasswordResetCompleteScreen(),
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
    ],
  );
});

/// GoRouter刷新通知器，监听认证状态和用户信息变化
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(this.ref) {
    ref.listen<UserState>(authStateProvider, (previous, next) {
      final changed = previous?.authState != next.authState
                   || previous?.isAnonymous != next.isAnonymous
                   || previous?.userId != next.userId
                   || previous?.email != next.email
                   || previous?.isPasswordRecovery != next.isPasswordRecovery;
      if (changed) {
        print('🔄 Router: 认证状态变化，触发路由重算');
        notifyListeners();
      }
    });
  }

  final Ref ref;
} 