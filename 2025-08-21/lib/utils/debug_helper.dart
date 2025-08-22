import 'package:mystic_tarot_jp/services/supabase_service.dart';

/// Debug模式下的工具类
class DebugHelper {
  /// 详细的用户ID状态报告
  static Future<void> printUserIdReport() async {
    print('\n🔍 ===== ${ref.watch(appStringsProvider).messageUserIdStatusReport} =====');
    
    final currentUser = SupabaseService.currentUser;
    final currentUserId = SupabaseService.currentUserId;
    final cachedUserId = await SupabaseService.getCachedUserId();
    
    print('📱 ${ref.watch(appStringsProvider).messageCurrentSupabaseUser}: ${currentUser?.id ?? ref.watch(appStringsProvider).labelNotLoggedIn}');
    print('🆔 ${ref.watch(appStringsProvider).messageCurrentUserId}: ${currentUserId ?? "null"}');
    print('💾 ${ref.watch(appStringsProvider).messageCachedUserId}: ${cachedUserId ?? ref.watch(appStringsProvider).labelNoCache}');
    
    if (currentUserId != null && cachedUserId != null) {
      if (currentUserId == cachedUserId) {
        print('✅ ${ref.watch(appStringsProvider).messageUserIdConsistent}');
      } else {
        print('⚠️ ${ref.watch(appStringsProvider).messageUserIdInconsistent}');
        print('   ${ref.watch(appStringsProvider).messageUserIdInconsistentAdvice}');
      }
    }
    
    print('================================\n');
  }
  
  /// 用户ID变化时的警告
  static void warnUserIdChange(String? oldId, String? newId) {
    if (oldId != null && newId != null && oldId != newId) {
          print('🚨 ${ref.watch(appStringsProvider).messageUserIdChangedWarning}');
    print('   ${ref.watch(appStringsProvider).messageOldId}: $oldId');
    print('   ${ref.watch(appStringsProvider).messageNewId}: $newId');
    print('   ${ref.watch(appStringsProvider).messageUserIdChangedReason}');
    print('   ${ref.watch(appStringsProvider).messageUserIdChangedImpact}');
    }
  }
}