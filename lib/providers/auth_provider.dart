import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

/// 认证状态 Provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// 当前用户 Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 用户是否已登录 Provider
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// 认证服务 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

/// 认证服务类
class AuthService {
  final Ref ref;
  
  AuthService(this.ref);
  
  /// 匿名登录
  Future<void> signInAnonymously() async {
    try {
      await SupabaseService.signInAnonymously();
    } catch (e) {
      throw Exception('匿名登录失败: $e');
    }
  }
  
  /// 邮箱注册
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await SupabaseService.signUpWithEmail(email, password);
    } catch (e) {
      throw Exception('注册失败: $e');
    }
  }
  
  /// 邮箱登录
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await SupabaseService.signInWithEmail(email, password);
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }
  
  /// 登出
  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {
      throw Exception('登出失败: $e');
    }
  }
  
  /// 确保用户已登录（如果未登录则自动匿名登录）
  Future<void> ensureLoggedIn() async {
    // 如果URL包含OAuth回调参数(code/state等)，说明正在进行第三方登录
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('code') || uri.queryParameters.containsKey('state')) {
      // 等待Supabase恢复session，避免误触发匿名登录
      for (int i = 0; i < 30; i++) {
        final existingUser = SupabaseService.currentUser;
        if (existingUser != null) {
          if (!existingUser.isAnonymous) {
            // 已获取到非匿名用户，直接返回
            return;
          }
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // 再次检查是否已有用户
    var user = SupabaseService.currentUser;
    if (user != null) return; // 已登录

    // 等待一段时间，给Supabase恢复session的机会
    for (int i = 0; i < 30; i++) {
      user = SupabaseService.currentUser;
      if (user != null) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 仍然没有用户 -> 匿名登录
    await signInAnonymously();
  }
} 