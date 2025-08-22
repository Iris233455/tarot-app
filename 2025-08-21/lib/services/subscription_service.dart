import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

/// 订阅状态枚举
enum SubscriptionStatus {
  none,       // 无订阅
  active,     // 活跃订阅
  expired,    // 已过期
  cancelled   // 已取消
}

/// 订阅产品信息
class SubscriptionProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currency;
  final double amount;
  final int durationDays;
  final String durationType;
  final Map<String, dynamic>? features;

  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.amount,
    required this.durationDays,
    required this.durationType,
    this.features,
  });

  /// 从JSON创建产品对象
  factory SubscriptionProduct.fromJson(Map<String, dynamic> json) {
    final priceJpy = json['price_jpy'] as int? ?? 0;
    return SubscriptionProduct(
      id: json['id'] as String? ?? '',
      title: json['name_ja'] as String? ?? '',
      description: json['description_ja'] as String? ?? '',
      price: '¥${priceJpy.toString()}',
      currency: 'JPY',
      amount: priceJpy.toDouble(),
      durationDays: json['duration_days'] as int? ?? 30,
      durationType: json['duration_type'] as String? ?? 'monthly',
      features: json['features'] as Map<String, dynamic>?,
    );
  }

  /// 获取显示的期间文本
  String get durationText {
    switch (durationType) {
      case 'monthly':
        return ref.watch(appStringsProvider).labelMonthly;
      case '3months':
        return ref.watch(appStringsProvider).label3Months;
      case 'yearly':
        return ref.watch(appStringsProvider).labelYearly;
      default:
        return '${durationDays}${ref.watch(appStringsProvider).labelDays}';
    }
  }

  /// 获取折扣标签
  String? get discountLabel {
    if (features?['discount'] != null) {
              return '${features!['discount']}${ref.watch(appStringsProvider).labelDiscount}';
    }
    return null;
  }

  /// 是否为最佳价值
  bool get isBestValue {
    return features?['best_value'] == true;
  }

  static const premium = SubscriptionProduct(
          id: 'premium_monthly',
      title: ref.watch(appStringsProvider).labelPremiumSubscription,
      description: ref.watch(appStringsProvider).labelPremiumSubscriptionDescription,
    price: '¥1,000',
    currency: 'JPY',
    amount: 1000.0,
    durationDays: 30,
    durationType: 'monthly',
  );

  static const premium3Months = SubscriptionProduct(
          id: 'premium_3months',
      title: ref.watch(appStringsProvider).labelPremium3MonthsPlan,
      description: ref.watch(appStringsProvider).labelPremium3MonthsPlanDescription,
    price: '¥2,700',
    currency: 'JPY',
    amount: 2700.0,
    durationDays: 90,
    durationType: '3months',
    features: {'discount': '10%'},
  );

  static const premiumYearly = SubscriptionProduct(
          id: 'premium_yearly',
      title: ref.watch(appStringsProvider).labelPremiumYearlyPlan,
      description: ref.watch(appStringsProvider).labelPremiumYearlyPlanDescription,
    price: '¥8,000',
    currency: 'JPY',
    amount: 8000.0,
    durationDays: 365,
    durationType: 'yearly',
    features: {'discount': '33%', 'best_value': true},
  );
}

/// 订阅服务 - 支持本地和Supabase双重数据源
class SubscriptionService {
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _isSimulatedKey = 'is_simulated_subscription';
  static const String _isCodeActivatedKey = 'is_code_activated_subscription';
  static const String _hasSyncedToSupabaseKey = 'has_synced_to_supabase';
  
  /// 是否优先使用Supabase数据源
  static bool _useSupabaseAsSource = true;
  
  /// 当前订阅状态流控制器
  static final StreamController<SubscriptionStatus> _statusController = 
      StreamController<SubscriptionStatus>.broadcast();
  
  /// 订阅状态变化流
  static Stream<SubscriptionStatus> get statusStream => _statusController.stream;
  
  /// 初始化订阅服务
  static Future<void> initialize() async {
          debugPrint('🏪 ${ref.watch(appStringsProvider).messageSubscriptionServiceInitStart}');
    
    if (kDebugMode) {
              debugPrint('🧪 ${ref.watch(appStringsProvider).messageDevModeSimulatedSubscription}');
    }
    
    // 1. 检查是否需要同步本地数据到Supabase
    await _syncLocalDataToSupabaseIfNeeded();
    
    // 2. 检查现有订阅状态
    await _checkSubscriptionStatus();
    
    // 3. 额外延迟确保初始化完全完成
    await Future.delayed(const Duration(milliseconds: 500));
    
          debugPrint('✅ ${ref.watch(appStringsProvider).messageSubscriptionServiceInitComplete}');
  }
  
  /// 获取当前订阅状态
  static Future<SubscriptionStatus> getCurrentStatus() async {
    // 如果没有登录用户，直接返回none
    if (SupabaseService.currentUserId == null) {
              debugPrint('🚨 ${ref.watch(appStringsProvider).messageUserNotLoggedInSubscriptionNone}');
      return SubscriptionStatus.none;
    }
    
    // 优先从Supabase获取数据
    if (_useSupabaseAsSource) {
      try {
        final supabaseStatus = await _getSubscriptionStatusFromSupabase();
        if (supabaseStatus != null) {
          return supabaseStatus;
        }
      } catch (e) {
        debugPrint('🚨 ${ref.watch(appStringsProvider).messageGetSubscriptionStatusFailed}: $e');
      }
    }
    
    // 回退到本地SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final statusIndex = prefs.getInt(_subscriptionStatusKey) ?? 0;
    final status = SubscriptionStatus.values[statusIndex];
    
    // 检查是否过期
    if (status == SubscriptionStatus.active) {
      final expiryTimestamp = prefs.getInt(_subscriptionExpiryKey) ?? 0;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      
      if (DateTime.now().isAfter(expiryDate)) {
        await _setSubscriptionStatus(SubscriptionStatus.expired);
        return SubscriptionStatus.expired;
      }
    }
    
    return status;
  }
  
  /// 检查用户是否拥有活跃订阅
  static Future<bool> hasActiveSubscription() async {
    final status = await getCurrentStatus();
    return status == SubscriptionStatus.active;
  }
  
  /// 获取订阅到期时间
  static Future<DateTime?> getExpiryDate() async {
    // 如果没有登录用户，直接返回null
    if (SupabaseService.currentUserId == null) {
              debugPrint('🚨 ${ref.watch(appStringsProvider).messageUserNotLoggedInExpiryNull}');
      return null;
    }
    
    // 优先从Supabase获取数据
    if (_useSupabaseAsSource) {
      try {
        final supabaseExpiry = await _getSubscriptionExpiryFromSupabase();
        if (supabaseExpiry != null) {
          return supabaseExpiry;
        }
      } catch (e) {
        debugPrint('🚨 ${ref.watch(appStringsProvider).messageGetSubscriptionExpiryFailed}: $e');
      }
    }
    
    // 回退到本地SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final expiryTimestamp = prefs.getInt(_subscriptionExpiryKey);
    if (expiryTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    }
    return null;
  }
  
  /// 购买订阅（支持Supabase产品配置）
  static Future<bool> purchaseSubscription([String? productId]) async {
          debugPrint('🛒 ${ref.watch(appStringsProvider).messageStartingSubscriptionPurchase}');
    
    final currentUser = SupabaseService.currentUser;
    final userId = currentUser?.id;
    
    if (userId == null) {
              debugPrint('❌ ${ref.watch(appStringsProvider).messagePurchaseFailedUserNotLoggedIn}');
      return false;
    }
    
    // 检查用户类型：匿名用户不能购买订阅
    if (currentUser?.isAnonymous == true) {
              debugPrint('❌ ${ref.watch(appStringsProvider).messagePurchaseFailedAnonymousUser}');
      return false;
    }
    
    // 使用默认产品ID如果未指定
    productId ??= 'premium_monthly';
    
    try {
      if (kDebugMode) {
        // 开发模式：使用Supabase模拟购买流程
        debugPrint('🧪 ${ref.watch(appStringsProvider).messageSimulatedPurchaseStart}: $productId');
        
        // 模拟支付处理时间
        await Future.delayed(const Duration(seconds: 2));
        
        // 调用Supabase购买函数
        final response = await SupabaseService.client
            .rpc('purchase_subscription', params: {
              'product_id_param': productId,
              'user_id_param': userId,
              'purchase_method_param': 'test'
            });
        
        if (response != null && response['success'] == true) {
          final durationDays = response['duration_days'] as int;
          final productName = response['product_name'] as String;
          final priceJpy = response['price_jpy'] as int;
          final subscriptionEnd = DateTime.parse(response['subscription_end'] as String);
          
          // 更新本地订阅状态
          await _setSubscriptionStatus(SubscriptionStatus.active, expiryDate: subscriptionEnd);
          await _markAsSimulated(true);
          
          debugPrint('✅ ${ref.watch(appStringsProvider).messageSimulatedPurchaseSuccess}');
          debugPrint('   产品: $productName');
          debugPrint('   价格: ¥$priceJpy');
          debugPrint('   期间: $durationDays天');
          debugPrint('   到期: ${subscriptionEnd.toIso8601String()}');
          
          return true;
        } else {
          final error = response?['error'] ?? 'unknown_error';
          final message = response?['message'] ?? '购买失败';
          debugPrint('❌ ${ref.watch(appStringsProvider).messageSimulatedPurchaseFailed}: $error - $message');
          return false;
        }
      }
      
      // TODO: 真实支付实现
      // 当有开发者账号时，这里将集成：
      // 1. iOS: StoreKit In-App Purchase
      // 2. Android: Google Play Billing Library
      // 3. 服务器端收据验证
      // 4. 调用 purchase_subscription 函数保存到Supabase
      
      debugPrint('❌ ${ref.watch(appStringsProvider).messageRealPaymentNotImplemented}');
      return false;
      
    } catch (e) {
      debugPrint('❌ ${ref.watch(appStringsProvider).messagePurchaseException}: $e');
      return false;
    }
  }
  
  /// 购买指定产品订阅
  static Future<bool> purchaseProduct(String productId) async {
    return await purchaseSubscription(productId);
  }
  
  /// 通过兑换码激活订阅
  static Future<void> activateSubscriptionWithCode(DateTime expiryDate) async {
    debugPrint('🎫 ${ref.watch(appStringsProvider).messageActivateSubscriptionWithCode}: ${expiryDate.toIso8601String()}');
    
    // 同时更新Supabase和本地数据
    await _setSubscriptionStatus(SubscriptionStatus.active, expiryDate: expiryDate);
    await _markAsCodeActivated(true);
    
    // 如果有Supabase用户，同步到云端
    if (SupabaseService.currentUserId != null) {
      try {
        await _updateSubscriptionInSupabase(SubscriptionStatus.active, expiryDate, 'redemption_code');
      } catch (e) {
        debugPrint('🚨 ${ref.watch(appStringsProvider).messageSyncSubscriptionInfoToSupabaseFailed}: $e');
      }
    }
    
    debugPrint('✅ ${ref.watch(appStringsProvider).messageRedemptionComplete}');
  }
  
  /// 延长现有订阅
  static Future<void> extendSubscription(int days) async {
    final currentExpiry = await getExpiryDate();
    final newExpiry = (currentExpiry ?? DateTime.now()).add(Duration(days: days));
    
    debugPrint('🎫 ${ref.watch(appStringsProvider).messageSubscriptionExtended} $days 天，新到期时间: ${newExpiry.toIso8601String()}');
    
    // 同时更新本地和Supabase数据
    await _setSubscriptionStatus(SubscriptionStatus.active, expiryDate: newExpiry);
    
    // 如果有Supabase用户，同步到云端
    if (SupabaseService.currentUserId != null) {
      try {
        await _updateSubscriptionInSupabase(SubscriptionStatus.active, newExpiry, 'redemption_code');
      } catch (e) {
        debugPrint('🚨 同步订阅延长到Supabase失败: $e');
      }
    }
    
    debugPrint('✅ 订阅延长成功');
  }
  
  /// 恢复购买
  static Future<bool> restorePurchases() async {
    debugPrint('🔄 开始恢复购买...');
    
    if (kDebugMode) {
      debugPrint('🧪 模拟恢复购买...');
      await Future.delayed(const Duration(seconds: 1));
      
      // 检查是否有模拟订阅
      final prefs = await SharedPreferences.getInstance();
      final isSimulated = prefs.getBool(_isSimulatedKey) ?? false;
      
      if (isSimulated) {
        final status = await getCurrentStatus();
        if (status == SubscriptionStatus.active || status == SubscriptionStatus.expired) {
          debugPrint('✅ 模拟恢复购买成功');
          return true;
        }
      }
      
      debugPrint('❌ 没有找到可恢复的购买记录');
      return false;
    }
    
    // TODO: 真实恢复购买实现
    return false;
  }
  
  /// 取消订阅（通知用户到期后停止）
  static Future<void> cancelSubscription() async {
    debugPrint('❌ 取消订阅...');
    
    if (kDebugMode) {
      // 开发模式：立即取消
      await _setSubscriptionStatus(SubscriptionStatus.cancelled);
      debugPrint('✅ 模拟取消订阅成功');
      return;
    }
    
    // TODO: 真实取消订阅实现
    // 注意：通常不能立即取消，只是标记为不续订
  }
  
  /// 获取可用产品列表
  static Future<List<SubscriptionProduct>> getAvailableProducts() async {
    debugPrint('🛒 开始获取订阅产品列表...');
    
    try {
      // 从Supabase获取产品列表
      debugPrint('🔄 调用Supabase函数: get_subscription_products');
      final response = await SupabaseService.client
          .rpc('get_subscription_products');
      
      debugPrint('📦 Supabase响应: $response');
      debugPrint('📦 响应类型: ${response.runtimeType}');
      
      if (response != null && response is List) {
        debugPrint('✅ 成功获取${response.length}个产品');
        final products = response.map<SubscriptionProduct>((productData) {
          debugPrint('   产品数据: $productData');
          return SubscriptionProduct.fromJson(productData as Map<String, dynamic>);
        }).toList();
        
        for (final product in products) {
          debugPrint('   产品: ${product.id} - ${product.title} - ${product.price}');
        }
        
        return products;
      } else {
        debugPrint('⚠️ Supabase返回数据格式不正确');
      }
    } catch (e) {
      debugPrint('❌ 获取订阅产品列表失败: $e');
      debugPrint('   错误类型: ${e.runtimeType}');
      if (e is PostgrestException) {
        debugPrint('   PostgrestException: ${e.message}');
        debugPrint('   详细信息: ${e.details}');
      }
    }
    
    // 回退到默认产品
    debugPrint('🔄 回退到默认产品列表');
    return [
      SubscriptionProduct.premium,
      SubscriptionProduct.premium3Months,
      SubscriptionProduct.premiumYearly,
    ];
  }
  
  /// 检查订阅状态（内部方法）
  static Future<void> _checkSubscriptionStatus() async {
    final status = await getCurrentStatus();
    _statusController.add(status);
    debugPrint('📊 当前订阅状态: ${status.name}');
    
    if (status == SubscriptionStatus.active) {
      final expiryDate = await getExpiryDate();
      debugPrint('📅 订阅到期时间: ${expiryDate?.toIso8601String() ?? "未知"}');
    }
  }
  
  /// 设置订阅状态（内部方法）
  static Future<void> _setSubscriptionStatus(
    SubscriptionStatus status, {
    DateTime? expiryDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_subscriptionStatusKey, status.index);
    
    if (expiryDate != null) {
      await prefs.setInt(_subscriptionExpiryKey, expiryDate.millisecondsSinceEpoch);
    }
    
    _statusController.add(status);
    debugPrint('💾 订阅状态已保存: ${status.name}');
  }
  
  /// 标记为模拟订阅（内部方法）
  static Future<void> _markAsSimulated(bool isSimulated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSimulatedKey, isSimulated);
  }
  
  /// 标记为兑换码激活订阅（内部方法）
  static Future<void> _markAsCodeActivated(bool isCodeActivated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isCodeActivatedKey, isCodeActivated);
  }
  
  /// 检查订阅是否通过兑换码激活
  static Future<bool> isCodeActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isCodeActivatedKey) ?? false;
  }
  
  /// 获取订阅状态显示文本
  static String getStatusDisplayText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.none:
        return '未购读';
      case SubscriptionStatus.active:
        return '有効';
      case SubscriptionStatus.expired:
        return '期限切れ';
      case SubscriptionStatus.cancelled:
        return 'キャンセル済み';
    }
  }
  
  /// 清理用户相关的订阅数据（用户切换时调用）
  static Future<void> clearUserSubscriptionData() async {
    debugPrint('🧹 清理用户订阅数据...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 清理所有订阅相关的本地数据
      await prefs.remove(_subscriptionStatusKey);
      await prefs.remove(_subscriptionExpiryKey);
      await prefs.remove(_isSimulatedKey);
      await prefs.remove(_isCodeActivatedKey);
      await prefs.remove(_hasSyncedToSupabaseKey);
      
      // 发送状态变更通知
      _statusController.add(SubscriptionStatus.none);
      
      debugPrint('✅ 用户订阅数据清理完成');
    } catch (e) {
      debugPrint('🚨 清理用户订阅数据失败: $e');
    }
  }

  /// 清理资源
  static void dispose() {
    _statusController.close();
  }
  
  // =================================
  // 🔄 Supabase 数据同步功能
  // =================================
  
  /// 检查是否需要同步本地数据到Supabase
  static Future<void> _syncLocalDataToSupabaseIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSynced = prefs.getBool(_hasSyncedToSupabaseKey) ?? false;
    
    // 如果已经同步过，或者没有用户登录，则跳过
    if (hasSynced || SupabaseService.currentUserId == null) {
      return;
    }
    
    debugPrint('🔄 开始同步本地订阅数据到Supabase...');
    
    try {
      // 获取本地订阅数据
      final localStatusIndex = prefs.getInt(_subscriptionStatusKey) ?? 0;
      final localStatus = SubscriptionStatus.values[localStatusIndex];
      final localExpiryTimestamp = prefs.getInt(_subscriptionExpiryKey);
      final isCodeActivated = prefs.getBool(_isCodeActivatedKey) ?? false;
      
      // 如果有有效的本地订阅数据，同步到Supabase
      if (localStatus != SubscriptionStatus.none && localExpiryTimestamp != null) {
        final localExpiry = DateTime.fromMillisecondsSinceEpoch(localExpiryTimestamp);
        final activationType = isCodeActivated ? 'redemption_code' : 'purchase';
        
        debugPrint('🔄 同步本地订阅到Supabase: $localStatus, 到期: ${localExpiry.toIso8601String()}');
        
        await _updateSubscriptionInSupabase(localStatus, localExpiry, activationType);
        
        // 标记为已同步
        await prefs.setBool(_hasSyncedToSupabaseKey, true);
        
        debugPrint('✅ 本地订阅数据同步到Supabase成功');
      } else {
        // 没有有效的本地数据，直接标记为已同步
        await prefs.setBool(_hasSyncedToSupabaseKey, true);
        debugPrint('📝 没有本地订阅数据需要同步');
      }
    } catch (e) {
      debugPrint('🚨 同步本地订阅数据到Supabase失败: $e');
    }
  }
  
  /// 从Supabase获取订阅状态
  static Future<SubscriptionStatus?> _getSubscriptionStatusFromSupabase() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;
      
      final response = await SupabaseService.client
          .rpc('get_user_subscription_status', params: {'target_user_id': userId});
      
      if (response != null) {
        final status = response['status'] as String?;
        switch (status) {
          case 'active':
            return SubscriptionStatus.active;
          case 'expired':
            return SubscriptionStatus.expired;
          case 'cancelled':
            return SubscriptionStatus.cancelled;
          default:
            return SubscriptionStatus.none;
        }
      }
    } catch (e) {
      debugPrint('🚨 从Supabase获取订阅状态失败: $e');
    }
    return null;
  }
  
  /// 从Supabase获取订阅到期时间
  static Future<DateTime?> _getSubscriptionExpiryFromSupabase() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return null;
      
      final response = await SupabaseService.client
          .rpc('get_user_subscription_status', params: {'target_user_id': userId});
      
      if (response != null && response['expires_at'] != null) {
        return DateTime.parse(response['expires_at'] as String);
      }
    } catch (e) {
      debugPrint('🚨 从Supabase获取订阅到期时间失败: $e');
    }
    return null;
  }
  
  /// 更新订阅信息到Supabase
  static Future<void> _updateSubscriptionInSupabase(
    SubscriptionStatus status,
    DateTime? expiryDate,
    String activationType,
  ) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('🚨 无法同步到Supabase：用户未登录');
        return;
      }
      
      // 确保用户profile存在
      await SupabaseService.client.from('user_profiles').upsert({
        'user_id': userId,
      }, onConflict: 'user_id');
      
      // 更新订阅信息
      final updateData = {
        'subscription_status': status.name,
        'subscription_activated_by': activationType,
        'subscription_updated_at': DateTime.now().toIso8601String(),
      };
      
      if (expiryDate != null) {
        updateData['subscription_expires_at'] = expiryDate.toIso8601String();
      }
      
      if (status == SubscriptionStatus.active) {
        updateData['subscription_activated_at'] = DateTime.now().toIso8601String();
      }
      
      await SupabaseService.client
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', userId);
      
      debugPrint('✅ 订阅信息已同步到Supabase: ${status.name}');
    } catch (e) {
      debugPrint('🚨 同步订阅信息到Supabase失败: $e');
      rethrow;
    }
  }
  
  /// 强制从Supabase同步订阅状态到本地
  static Future<void> syncFromSupabase() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('🚨 无法从Supabase同步：用户未登录');
        return;
      }
      
      debugPrint('🔄 开始从Supabase同步订阅状态...');
      
      final response = await SupabaseService.client
          .rpc('get_user_subscription_status', params: {'target_user_id': userId});
      
      if (response != null) {
        final statusStr = response['status'] as String? ?? 'none';
        final expiresAtStr = response['expires_at'] as String?;
        final activatedBy = response['activated_by'] as String? ?? 'purchase';
        
        SubscriptionStatus status;
        switch (statusStr) {
          case 'active':
            status = SubscriptionStatus.active;
            break;
          case 'expired':
            status = SubscriptionStatus.expired;
            break;
          case 'cancelled':
            status = SubscriptionStatus.cancelled;
            break;
          default:
            status = SubscriptionStatus.none;
        }
        
        DateTime? expiryDate;
        if (expiresAtStr != null) {
          expiryDate = DateTime.parse(expiresAtStr);
        }
        
        // 更新本地数据
        await _setSubscriptionStatus(status, expiryDate: expiryDate);
        
        if (activatedBy == 'redemption_code') {
          await _markAsCodeActivated(true);
        }
        
        debugPrint('✅ 从Supabase同步订阅状态成功: ${status.name}');
      }
    } catch (e) {
      debugPrint('🚨 从Supabase同步订阅状态失败: $e');
    }
  }
  
  // =================================
  // 🚀 预留真实支付接口
  // =================================
  
  /// 【预留】初始化真实支付SDK
  static Future<void> _initializeRealPayment() async {
    // TODO: 初始化 in_app_purchase
    // InAppPurchase.instance.isAvailable()
    // 监听购买状态变化
    // InAppPurchase.instance.purchaseStream.listen(_handlePurchaseUpdate)
  }
  
  /// 【预留】处理真实购买更新
  static void _handleRealPurchaseUpdate(dynamic purchaseDetails) {
    // TODO: 处理购买状态更新
    // 验证收据
    // 更新订阅状态
    // 完成交易
  }
  
  /// 【预留】服务器端收据验证
  static Future<bool> _verifyReceiptWithServer(String receipt) async {
    // TODO: 发送收据到服务器验证
    // 防止本地伪造
    return false;
  }
}
