import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';

/// 认证状态枚举
enum AuthState {
  loading,      // 正在检查认证状态
  authenticated, // 已认证（包括匿名和邮箱登录）
  unauthenticated, // 未认证
}

/// 用户信息状态
class UserState {
  final AuthState authState;
  final User? user;
  final bool isAnonymous;
  final String? email;
  final String? userId;
  final bool isPasswordRecovery;

  const UserState({
    required this.authState,
    this.user,
    this.isAnonymous = false,
    this.email,
    this.userId,
    this.isPasswordRecovery = false,
  });

  UserState copyWith({
    AuthState? authState,
    User? user,
    bool? isAnonymous,
    String? email,
    String? userId,
    bool? isPasswordRecovery,
  }) {
    return UserState(
      authState: authState ?? this.authState,
      user: user ?? this.user,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
    );
  }
}

/// 认证状态管理
class AuthStateNotifier extends StateNotifier<UserState> {
  AuthStateNotifier() : super(const UserState(authState: AuthState.loading)) {
    _initialize();
  }

  void _initialize() {
    // 监听认证状态变化
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;
      
      print('🔄 Auth状态变化监听器触发: ${data.event}');

      if (user != null) {
        // 改进的匿名用户判断：如果有邮箱地址，就不是匿名用户
        final hasEmail = user.email != null && user.email!.isNotEmpty;
        final isAnonymous = user.isAnonymous && !hasEmail;
        final isRecovery = data.event == AuthChangeEvent.passwordRecovery;
        
        print('   用户ID: ${user.id}');
        print('   邮箱: ${user.email}');
        print('   原始isAnonymous: ${user.isAnonymous}');
        print('   计算后isAnonymous: $isAnonymous');
        print('   是否处于密码恢复流程: $isRecovery');
        
        // 防止重复更新到相同状态
        if (state.userId != user.id || state.isAnonymous != isAnonymous) {
          print('   → 状态有变化，更新AuthState');
          
          // 如果用户ID发生变化，清理之前用户的订阅数据
          if (state.userId != null && state.userId != user.id) {
            print('   🧹 用户ID变化，清理之前用户的订阅数据');
            print('   旧用户ID: ${state.userId}');
            print('   新用户ID: ${user.id}');
            
            // 异步清理订阅数据，不阻塞状态更新
            SubscriptionService.clearUserSubscriptionData().then((_) {
              print('   ✅ 用户订阅数据清理完成');
            }).catchError((error) {
              print('   🚨 用户订阅数据清理失败: $error');
            });
          }
          
          state = UserState(
            authState: AuthState.authenticated,
            user: user,
            isAnonymous: isAnonymous,
            email: user.email,
            userId: user.id,
            isPasswordRecovery: isRecovery,
          );
        } else {
          print('   → 状态无变化，跳过更新');
          // 但仍然需要更新恢复标志（例如仅事件变化）
          if (state.isPasswordRecovery != isRecovery) {
            state = state.copyWith(isPasswordRecovery: isRecovery);
          }
        }
      } else {
        print('   用户已登出或未登录');
        if (state.authState != AuthState.unauthenticated) {
          // 用户登出时清理订阅数据
          if (state.userId != null) {
            print('   🧹 用户登出，清理订阅数据');
            print('   登出用户ID: ${state.userId}');
            
            // 异步清理订阅数据
            SubscriptionService.clearUserSubscriptionData().then((_) {
              print('   ✅ 登出用户订阅数据清理完成');
            }).catchError((error) {
              print('   🚨 登出用户订阅数据清理失败: $error');
            });
          }
          
          state = const UserState(authState: AuthState.unauthenticated);
        }
      }
    });

    // 初始状态检查
    final currentUser = SupabaseService.currentUser;
    print('🔄 Auth初始状态检查:');
    if (currentUser != null) {
      // 改进的匿名用户判断：如果有邮箱地址，就不是匿名用户
      final hasEmail = currentUser.email != null && currentUser.email!.isNotEmpty;
      final isAnonymous = currentUser.isAnonymous && !hasEmail;
      
      print('   已有用户 - ID: ${currentUser.id}');
      print('   邮箱: ${currentUser.email}');
      print('   原始isAnonymous: ${currentUser.isAnonymous}');
      print('   计算后isAnonymous: $isAnonymous');
      
      state = UserState(
        authState: AuthState.authenticated,
        user: currentUser,
        isAnonymous: isAnonymous,
        email: currentUser.email,
        userId: currentUser.id,
        isPasswordRecovery: false,
      );
    } else {
      print('   无用户，未认证状态');
      state = const UserState(authState: AuthState.unauthenticated);
    }
  }

  /// 邮箱登录
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await SupabaseService.signInWithEmail(email, password);
      
      // 手动等待并强制刷新状态 (修复显示延迟问题)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final hasEmail = currentUser.email != null && currentUser.email!.isNotEmpty;
        final isAnonymous = currentUser.isAnonymous && !hasEmail;
        
        state = UserState(
          authState: AuthState.authenticated,
          user: currentUser,
          isAnonymous: isAnonymous,
          email: currentUser.email,
          userId: currentUser.id,
        );
        
        print('🔄 Email登录后强制更新状态:');
        print('   用户ID: ${currentUser.id}');
        print('   邮箱: ${currentUser.email}');
        print('   isAnonymous: $isAnonymous');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 邮箱注册
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await SupabaseService.signUpWithEmail(email, password);
      
      // 手动等待并强制刷新状态 (修复显示延迟问题)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final hasEmail = currentUser.email != null && currentUser.email!.isNotEmpty;
        final isAnonymous = currentUser.isAnonymous && !hasEmail;
        
        state = UserState(
          authState: AuthState.authenticated,
          user: currentUser,
          isAnonymous: isAnonymous,
          email: currentUser.email,
          userId: currentUser.id,
        );
        
        print('🔄 Email注册后强制更新状态:');
        print('   用户ID: ${currentUser.id}');
        print('   邮箱: ${currentUser.email}');
        print('   isAnonymous: $isAnonymous');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 匿名登录
  Future<void> signInAnonymously() async {
    try {
      await SupabaseService.signInAnonymously();
      // 状态会通过监听器自动更新
    } catch (e) {
      rethrow;
    }
  }
  
  /// Google登录
  Future<void> signInWithGoogle() async {
    try {
      print('🔄 AuthStateProvider: 开始Google登录...');
      
      final success = await SupabaseService.signInWithGoogle();
      
      if (!success) {
        print('🔄 AuthStateProvider: Google登录失败');
        throw Exception('Google登录失败');
      }
      
      print('🔄 AuthStateProvider: Google登录返回成功，开始状态更新...');
      
      // 增加等待时间确保Supabase状态完全同步
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final currentUser = SupabaseService.currentUser;
      print('🔄 AuthStateProvider: 获取当前用户: ${currentUser?.id}');
      
      if (currentUser != null) {
        final hasEmail = currentUser.email != null && currentUser.email!.isNotEmpty;
        final isAnonymous = currentUser.isAnonymous && !hasEmail;
        
        print('🔄 AuthStateProvider: 强制更新认证状态');
        print('   用户ID: ${currentUser.id}');
        print('   邮箱: ${currentUser.email}');
        print('   isAnonymous: $isAnonymous');
        
        state = UserState(
          authState: AuthState.authenticated,
          user: currentUser,
          isAnonymous: isAnonymous,
          email: currentUser.email,
          userId: currentUser.id,
        );
        
        print('✅ AuthStateProvider: Google登录状态更新完成');
      } else {
        print('❌ AuthStateProvider: 无法获取当前用户信息');
        throw Exception('无法获取用户信息');
      }
    } catch (e) {
      print('❌ AuthStateProvider: Google登录异常: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      // 状态会通过监听器自动更新
    } catch (e) {
      rethrow;
    }
  }

  /// 检查是否需要认证
  bool get needsAuth => state.authState == AuthState.unauthenticated;

  /// 是否已认证
  bool get isAuthenticated => state.authState == AuthState.authenticated;

  /// 是否为匿名用户
  bool get isAnonymous => state.isAnonymous;

  /// 是否为邮箱用户
  bool get isEmailUser => isAuthenticated && !isAnonymous;
}

/// 认证状态Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, UserState>((ref) {
  return AuthStateNotifier();
});

/// 便捷的认证检查Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.authState == AuthState.authenticated;
});

/// 用户类型Provider
final userTypeProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.authState != AuthState.authenticated) {
    return 'guest';
  }
  return authState.isAnonymous ? 'anonymous' : 'email';
});