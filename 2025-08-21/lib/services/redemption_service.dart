import 'package:flutter/foundation.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';

/// 兑换码兑换结果
class RedemptionResult {
  final bool success;
  final String message;
  final int? days;
  final String? error;
  
  const RedemptionResult({
    required this.success,
    required this.message,
    this.days,
    this.error,
  });
  
  factory RedemptionResult.success(int days, String message) {
    return RedemptionResult(
      success: true,
      message: message,
      days: days,
    );
  }
  
  factory RedemptionResult.failure(String error, String message) {
    return RedemptionResult(
      success: false,
      message: message,
      error: error,
    );
  }
}

/// 兑换码信息
class RedemptionCode {
  final String code;
  final int days;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? description;
  final String batchName;
  
  const RedemptionCode({
    required this.code,
    required this.days,
    required this.isUsed,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
    this.expiresAt,
    this.description,
    required this.batchName,
  });
  
  factory RedemptionCode.fromJson(Map<String, dynamic> json) {
    return RedemptionCode(
      code: json['code'] as String? ?? '',
      days: json['days'] as int? ?? 0,
      isUsed: json['is_used'] as bool? ?? false,
      usedBy: json['used_by'] as String?,
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at'] as String) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      description: json['description'] as String?,
      batchName: json['batch_name'] as String? ?? 'unknown',
    );
  }
}

/// 用户兑换历史
class UserRedemptionHistory {
  final String id;
  final String userId;
  final String redemptionCode;
  final DateTime redeemedAt;
  final int daysGranted;
  
  const UserRedemptionHistory({
    required this.id,
    required this.userId,
    required this.redemptionCode,
    required this.redeemedAt,
    required this.daysGranted,
  });
  
  factory UserRedemptionHistory.fromJson(Map<String, dynamic> json) {
    return UserRedemptionHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      redemptionCode: json['redemption_code'] as String,
      redeemedAt: DateTime.parse(json['redeemed_at']),
      daysGranted: json['days_granted'] as int,
    );
  }
}

/// 兑换码服务
class RedemptionService {
  static const String _logTag = '🎫 ${ref.watch(appStringsProvider).messageRedemptionCodeService}';
  
  /// 验证兑换码格式
  static bool isValidCodeFormat(String code) {
    // 兑换码格式：8位字母数字组合（大写）
    final RegExp codeRegex = RegExp(r'^[A-Z0-9]{6,12}$');
    return codeRegex.hasMatch(code.toUpperCase());
  }
  
  /// 格式化兑换码（转为大写并移除空格）
  static String formatCode(String code) {
    return code.toUpperCase().replaceAll(' ', '');
  }
  
  /// 检查兑换码是否存在且可用（不消耗兑换码）
  static Future<RedemptionResult> checkRedemptionCode(String code) async {
    try {
      debugPrint('$_logTag 检查兑换码: $code');
      
      // 格式化兑换码
      final formattedCode = formatCode(code);
      
      // 检查格式
      if (!isValidCodeFormat(formattedCode)) {
        return RedemptionResult.failure(
                  'invalid_format',
        ref.watch(appStringsProvider).messageInvalidRedemptionCodeFormat,
        );
      }
      
      // 从数据库查询兑换码
      final response = await SupabaseService.client
          .from('redemption_codes')
          .select('code, days, is_used, expires_at, description, created_at, batch_name')
          .eq('code', formattedCode)
          .maybeSingle();
      
      if (response == null) {
        return RedemptionResult.failure(
                  'not_found',
        ref.watch(appStringsProvider).messageRedemptionCodeNotFound,
        );
      }
      
      final redemptionCode = RedemptionCode.fromJson(response);
      
      // 检查是否已使用
      if (redemptionCode.isUsed) {
        return RedemptionResult.failure(
                  'already_used',
        ref.watch(appStringsProvider).messageRedemptionCodeAlreadyUsed,
        );
      }
      
      // 检查是否过期
      if (redemptionCode.expiresAt != null && redemptionCode.expiresAt!.isBefore(DateTime.now())) {
        return RedemptionResult.failure(
                  'expired',
        ref.watch(appStringsProvider).messageRedemptionCodeExpired,
        );
      }
      
      return RedemptionResult.success(
        redemptionCode.days,
        '${ref.watch(appStringsProvider).messageValidRedemptionCode}: ${redemptionCode.days}${ref.watch(appStringsProvider).labelDays}${ref.watch(appStringsProvider).messagePremiumService}',
      );
      
    } catch (e) {
      debugPrint('$_logTag ${ref.watch(appStringsProvider).messageCheckRedemptionCodeFailed}: $e');
      return RedemptionResult.failure(
        'network_error',
        ref.watch(appStringsProvider).messageNetworkErrorCheckConnection,
      );
    }
  }
  
  /// 使用兑换码（消耗兑换码并激活订阅）
  static Future<RedemptionResult> redeemCode(String code) async {
    try {
      debugPrint('$_logTag 使用兑换码: $code');
      
      final currentUser = SupabaseService.currentUser;
      final userId = currentUser?.id;
      
      if (userId == null) {
        return RedemptionResult.failure(
                  'not_authenticated',
        ref.watch(appStringsProvider).messageLoginRequiredForRedemption,
        );
      }
      
      // 检查用户类型：匿名用户不能使用兑换码
      if (currentUser?.isAnonymous == true) {
        return RedemptionResult.failure(
                  'anonymous_user',
        ref.watch(appStringsProvider).messageGuestCannotUseRedemptionCode,
        );
      }
      
      // 格式化兑换码
      final formattedCode = formatCode(code);
      
      // 先检查兑换码状态
      final checkResult = await checkRedemptionCode(formattedCode);
      if (!checkResult.success) {
        return checkResult;
      }
      
      // 调用数据库函数执行兑换
      final response = await SupabaseService.client
          .rpc('redeem_code', params: {
            'redemption_code': formattedCode,
            'user_id': userId,
          });
      
      final result = response as Map<String, dynamic>;
      
      if (result['success'] == true) {
        final days = result['days'] as int;
        
        // 激活订阅服务
        await _activateSubscription(days);
        
        debugPrint('$_logTag 兑换成功: $days天');
        return RedemptionResult.success(
          days,
          result['message'] ?? ref.watch(appStringsProvider).messageRedemptionComplete,
        );
      } else {
        final error = result['error'] ?? 'unknown_error';
        final message = result['message'] ?? ref.watch(appStringsProvider).messageRedemptionFailed;
        
        debugPrint('$_logTag 兑换失败: $error - $message');
        return RedemptionResult.failure(error, message);
      }
      
    } catch (e) {
      debugPrint('$_logTag ${ref.watch(appStringsProvider).messageRedemptionCodeUsageFailed}: $e');
      return RedemptionResult.failure(
        'network_error',
        ref.watch(appStringsProvider).messageNetworkErrorCheckConnection,
      );
    }
  }
  
  /// 激活订阅（内部方法）
  static Future<void> _activateSubscription(int days) async {
    try {
      // 获取当前订阅状态
      final currentStatus = await SubscriptionService.getCurrentStatus();
      final currentExpiry = await SubscriptionService.getExpiryDate();
      
      DateTime newExpiryDate;
      
      if (currentStatus == SubscriptionStatus.active && currentExpiry != null) {
        // 如果当前有活跃订阅，在现有到期时间基础上延长
        newExpiryDate = currentExpiry.add(Duration(days: days));
        debugPrint('$_logTag 延长现有订阅: $days天，新到期时间: ${newExpiryDate.toIso8601String()}');
      } else {
        // 如果没有活跃订阅，从现在开始计算
        newExpiryDate = DateTime.now().add(Duration(days: days));
        debugPrint('$_logTag 激活新订阅: $days天，到期时间: ${newExpiryDate.toIso8601String()}');
      }
      
      // 通过SubscriptionService激活订阅
      await SubscriptionService.activateSubscriptionWithCode(newExpiryDate);
      
    } catch (e) {
      debugPrint('$_logTag 激活订阅失败: $e');
      rethrow;
    }
  }
  
  /// 获取用户兑换历史
  static Future<List<UserRedemptionHistory>> getUserRedemptionHistory() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        return [];
      }
      
      final response = await SupabaseService.client
          .from('user_redemption_history')
          .select('*')
          .eq('user_id', userId)
          .order('redeemed_at', ascending: false);
      
      return (response as List)
          .map((json) => UserRedemptionHistory.fromJson(json))
          .toList();
          
    } catch (e) {
      debugPrint('$_logTag 获取兑换历史失败: $e');
      return [];
    }
  }
  
  /// 生成测试兑换码（仅开发模式）
  static Future<List<String>> generateTestCodes({
    int count = 5,
    int days = 7,
    String batchName = 'test_manual',
  }) async {
    if (!kDebugMode) {
              throw Exception(ref.watch(appStringsProvider).messageTestCodeGenerationDevModeOnly);
    }
    
    try {
      debugPrint('$_logTag 生成测试兑换码: $count个，$days天');
      
      final response = await SupabaseService.client
          .rpc('generate_redemption_codes', params: {
            'count': count,
            'days': days,
            'batch_name': batchName,
          });
      
      final result = response as Map<String, dynamic>;
      
      if (result['success'] == true) {
        final codes = List<String>.from(result['codes']);
        debugPrint('$_logTag 测试兑换码生成成功: $codes');
        return codes;
      } else {
        throw Exception(result['message'] ?? ref.watch(appStringsProvider).messageGenerationFailed);
      }
      
    } catch (e) {
      debugPrint('$_logTag 生成测试兑换码失败: $e');
      rethrow;
    }
  }
  
  /// 格式化兑换码显示（添加空格分隔）
  static String formatCodeForDisplay(String code) {
    if (code.length <= 4) return code;
    
    // 每4位添加一个空格
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < code.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(code[i]);
    }
    return buffer.toString();
  }
}
