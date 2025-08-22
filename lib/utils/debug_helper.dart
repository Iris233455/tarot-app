import 'package:mystic_tarot_jp/services/supabase_service.dart';

/// Debug模式下的工具类
class DebugHelper {
  /// 详细的用户ID状态报告
  static Future<void> printUserIdReport() async {
    print('\n🔍 ===== 用户ID状态报告 =====');
    
    final currentUser = SupabaseService.currentUser;
    final currentUserId = SupabaseService.currentUserId;
    final cachedUserId = await SupabaseService.getCachedUserId();
    
    print('📱 当前Supabase用户: ${currentUser?.id ?? "未登录"}');
    print('🆔 当前用户ID: ${currentUserId ?? "null"}');
    print('💾 缓存的用户ID: ${cachedUserId ?? "无缓存"}');
    
    if (currentUserId != null && cachedUserId != null) {
      if (currentUserId == cachedUserId) {
        print('✅ 用户ID一致，数据持久化正常');
      } else {
        print('⚠️ 用户ID不一致！可能发生了session重置');
        print('   建议：在正式发布时不会有此问题');
      }
    }
    
    print('================================\n');
  }
  
  /// 用户ID变化时的警告
  static void warnUserIdChange(String? oldId, String? newId) {
    if (oldId != null && newId != null && oldId != newId) {
      print('🚨 警告：用户ID发生变化！');
      print('   旧ID: $oldId');
      print('   新ID: $newId');
      print('   原因：Debug模式下可能发生session重置');
      print('   影响：数据可能分散在不同用户ID下');
    }
  }
}