import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

/// 用户数据恢复服务
class UserRecoveryService {
  static const String _recoveryCodeKey = 'user_recovery_code';
  static const String _userDataBackupKey = 'user_data_backup';
  static const String _lastKnownUserIdKey = 'last_known_user_id';
  
  /// 生成用户恢复代码（6位数字）
  static Future<String> generateRecoveryCode() async {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recoveryCodeKey, code);
    
    // 同时保存当前用户ID
    final currentUserId = SupabaseService.currentUserId;
    if (currentUserId != null) {
      await prefs.setString(_lastKnownUserIdKey, currentUserId);
    }
    
    return code;
  }
  
  /// 获取当前的恢复代码
  static Future<String?> getCurrentRecoveryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recoveryCodeKey);
  }
  
  /// 备份当前用户数据
  static Future<void> backupUserData() async {
    try {
      final currentUserId = SupabaseService.currentUserId;
      if (currentUserId == null) return;
      
      // 获取用户profile
      final profile = await SupabaseService.getUserProfile();
      
      // 获取最近的占卜记录
      final readings = await SupabaseService.getReadingHistory(limit: 10);
      
      // 获取本月的每日抽牌记录
      final now = DateTime.now();
      final dailyCards = await SupabaseService.getMonthlyCards(now.year, now.month);
      
      final backupData = {
        'user_id': currentUserId,
        'profile': profile,
        'recent_readings': readings,
        'daily_cards': dailyCards,
        'backup_time': now.toIso8601String(),
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataBackupKey, json.encode(backupData));
      
      print('✅ 用户数据已备份');
    } catch (e) {
      print('⚠️ 用户数据备份失败: $e');
    }
  }
  
  /// 检查是否有备份数据
  static Future<bool> hasBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    final backupData = prefs.getString(_userDataBackupKey);
    return backupData != null;
  }
  
  /// 获取备份数据信息
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getString(_userDataBackupKey);
      if (backupData == null) return null;
      
      final data = json.decode(backupData) as Map<String, dynamic>;
      return {
        'backup_time': data['backup_time'],
        'user_id': data['user_id'],
        'has_profile': data['profile'] != null,
        'readings_count': (data['recent_readings'] as List?)?.length ?? 0,
        'daily_cards_count': (data['daily_cards'] as List?)?.length ?? 0,
      };
    } catch (e) {
      print('⚠️ 读取备份信息失败: $e');
      return null;
    }
  }
  
  /// 通过恢复代码验证用户身份
  static Future<bool> validateRecoveryCode(String inputCode) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_recoveryCodeKey);
    return savedCode == inputCode;
  }
  
  /// 恢复用户数据到新账户
  static Future<bool> restoreUserData(String recoveryCode) async {
    try {
      // 验证恢复代码
      if (!await validateRecoveryCode(recoveryCode)) {
        print('❌ 恢复代码无效');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getString(_userDataBackupKey);
      if (backupData == null) {
        print('❌ 没有找到备份数据');
        return false;
      }
      
      final data = json.decode(backupData) as Map<String, dynamic>;
      final currentUserId = SupabaseService.currentUserId;
      if (currentUserId == null) {
        print('❌ 用户未登录');
        return false;
      }
      
      // 恢复profile数据
      if (data['profile'] != null) {
        final profile = data['profile'] as Map<String, dynamic>;
        await SupabaseService.upsertDetailedUserProfile(
          name: profile['name'],
          gender: profile['gender'],
          birthDate: profile['birth_date'] != null 
              ? DateTime.parse(profile['birth_date']) 
              : null,
          occupation: profile['occupation'],
          relationshipStatus: profile['relationship_status'],
        );
      }
      
      print('✅ 用户数据恢复成功');
      return true;
    } catch (e) {
      print('❌ 用户数据恢复失败: $e');
      return false;
    }
  }
  
  /// 检查用户ID是否发生变化
  static Future<bool> hasUserIdChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final lastKnownUserId = prefs.getString(_lastKnownUserIdKey);
    final currentUserId = SupabaseService.currentUserId;
    
    if (lastKnownUserId == null || currentUserId == null) return false;
    
    return lastKnownUserId != currentUserId;
  }
  
  /// 更新最后已知的用户ID
  static Future<void> updateLastKnownUserId() async {
    final currentUserId = SupabaseService.currentUserId;
    if (currentUserId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastKnownUserIdKey, currentUserId);
    }
  }
  
  /// 清除所有恢复数据
  static Future<void> clearRecoveryData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recoveryCodeKey);
    await prefs.remove(_userDataBackupKey);
    await prefs.remove(_lastKnownUserIdKey);
  }
}