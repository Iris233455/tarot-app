import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

/// 订阅状态Provider
final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((ref) {
  return SubscriptionService.statusStream;
});

/// 是否拥有活跃订阅Provider（支持自动刷新）
final hasActiveSubscriptionProvider = FutureProvider.autoDispose<bool>((ref) async {
  print('🔔 [Provider] 检查活跃订阅状态...');
  
  // 监听订阅状态变化以触发重新计算
  ref.watch(subscriptionStatusProvider);
  
  // 添加一个小延迟确保Supabase初始化完成
  if (SupabaseService.currentUserId == null) {
    print('🔔 [Provider] 用户未登录，等待100ms...');
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  try {
    final isActive = await SubscriptionService.hasActiveSubscription();
    print('🔔 [Provider] 活跃订阅状态: $isActive');
    return isActive;
  } catch (e) {
    print('🔔 [Provider] 获取活跃订阅状态失败: $e');
    return false;
  }
});

/// 订阅到期时间Provider（支持自动刷新）
final subscriptionExpiryProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  print('📅 [Provider] 获取订阅到期时间开始...');
  
  // 监听订阅状态变化以触发重新计算
  final statusState = ref.watch(subscriptionStatusProvider);
  print('📅 [Provider] 当前订阅状态流: ${statusState.runtimeType}');
  
  // 添加一个小延迟确保Supabase初始化完成
  if (SupabaseService.currentUserId == null) {
    print('📅 [Provider] 用户未登录，等待100ms...');
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  try {
    print('📅 [Provider] 调用SubscriptionService.getExpiryDate()...');
    final expiryDate = await SubscriptionService.getExpiryDate();
    print('📅 [Provider] 获取到期时间成功: $expiryDate');
    
    // 确保数据获取完成后有足够时间处理
    await Future.delayed(const Duration(milliseconds: 50));
    
    return expiryDate;
  } catch (e, stackTrace) {
    print('📅 [Provider] 获取订阅到期时间失败: $e');
    print('📅 [Provider] 堆栈跟踪: $stackTrace');
    return null;
  }
});

/// 可用订阅产品Provider（支持自动刷新）
final availableProductsProvider = FutureProvider.autoDispose<List<SubscriptionProduct>>((ref) async {
  print('🛒 [Provider] 开始获取产品列表...');
  
  // 添加一个小延迟确保Supabase初始化完成
  if (SupabaseService.currentUserId == null) {
    print('🛒 [Provider] 用户未登录，等待200ms...');
    await Future.delayed(const Duration(milliseconds: 200));
  }
  
  try {
    final products = await SubscriptionService.getAvailableProducts();
    print('🛒 [Provider] 获取产品成功，数量: ${products.length}');
    for (var product in products) {
      print('   - ${product.id}: ${product.title} (${product.price})');
    }
    return products;
  } catch (e) {
    print('🛒 [Provider] 获取产品失败: $e');
    rethrow;
  }
});

/// 订阅购买状态Provider
class SubscriptionPurchaseState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const SubscriptionPurchaseState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  SubscriptionPurchaseState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return SubscriptionPurchaseState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
    );
  }
}

class SubscriptionPurchaseNotifier extends StateNotifier<SubscriptionPurchaseState> {
  SubscriptionPurchaseNotifier() : super(const SubscriptionPurchaseState());

  /// 购买订阅
  Future<void> purchaseSubscription() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final success = await SubscriptionService.purchaseSubscription();
      
      if (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '購入に失敗しました。もう一度お試しください。',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '購入中にエラーが発生しました: $e',
      );
    }
  }

  /// 购买指定产品
  Future<void> purchaseProduct(String productId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final success = await SubscriptionService.purchaseProduct(productId);
      
      if (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '購入に失敗しました。もう一度お試しください。',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '購入中にエラーが発生しました: $e',
      );
    }
  }

  /// 恢复购买
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final success = await SubscriptionService.restorePurchases();
      
      if (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '復元可能な購入が見つかりませんでした。',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '購入復元中にエラーが発生しました: $e',
      );
    }
  }

  /// 取消订阅
  Future<void> cancelSubscription() async {
    try {
      await SubscriptionService.cancelSubscription();
      state = state.copyWith(isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        error: 'キャンセル中にエラーが発生しました: $e',
      );
    }
  }

  /// 重置状态
  void reset() {
    state = const SubscriptionPurchaseState();
  }
}

final subscriptionPurchaseProvider = StateNotifierProvider<SubscriptionPurchaseNotifier, SubscriptionPurchaseState>((ref) {
  return SubscriptionPurchaseNotifier();
});
