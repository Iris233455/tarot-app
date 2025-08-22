import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mystic_tarot_jp/app.dart';
import 'package:mystic_tarot_jp/core/config/supabase_config.dart';
import 'package:mystic_tarot_jp/services/data_service.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/services/ad_service.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';
import 'package:mystic_tarot_jp/utils/debug_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据服务
  await DataService.initialize();
  
  // 初始化AdMob
  try {
    await AdService.initialize();
          print('✅ ${ref.watch(appStringsProvider).messageAdMobInitSuccess}');
  } catch (e) {
          print('⚠️ ${ref.watch(appStringsProvider).messageAdMobInitFailed}: $e');
  }
  
  // 初始化订阅服务
  try {
    await SubscriptionService.initialize();
          print('✅ ${ref.watch(appStringsProvider).messageSubscriptionInitSuccess}');
  } catch (e) {
          print('⚠️ ${ref.watch(appStringsProvider).messageSubscriptionInitFailed}: $e');
  }
  
  // 清除所有缓存，确保使用最新的数据源
  DataService.clearCache();
  
  // 初始化 Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
          print('✅ ${ref.watch(appStringsProvider).messageSupabaseInitSuccess}');
    
    // 等待session恢复（特别是在Flutter Web中）
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 额外等待auth状态稳定
    int attempts = 0;
    while (attempts < 3) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        print('🔍 ${ref.watch(appStringsProvider).messageExistingUserSession}: ${currentUser.id}');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
  } catch (e) {
          print('⚠️ ${ref.watch(appStringsProvider).messageSupabaseInitFailed}: $e');
      print('📱 ${ref.watch(appStringsProvider).messageUsingOfflineMode}');
    await DataService.setOfflineMode(true);
  }
  
  // 每次启动都尝试连接测试（不管之前的状态）
  bool connectionSuccessful = false;
  
  try {
    // 检查现有的认证状态，但不自动登录
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
              print('✅ ${ref.watch(appStringsProvider).messageExistingUserSession}: ${currentUser.id}');
        print('📧 ${ref.watch(appStringsProvider).messageUserType}: ${currentUser.isAnonymous ? ref.watch(appStringsProvider).labelAnonymousUser : "${ref.watch(appStringsProvider).labelEmailUser} (${currentUser.email})"}');
      
      // 更新缓存
      await SupabaseService.cacheUserId(currentUser.id);
    } else {
              print('🔐 ${ref.watch(appStringsProvider).messageNoUserSession}');
      
      // 检查是否有缓存的用户ID（用于数据恢复提示）
      final cachedUserId = await SupabaseService.getCachedUserId();
      if (cachedUserId != null) {
        print('🔍 ${ref.watch(appStringsProvider).messageCachedUserId}: $cachedUserId');
        print('💡 ${ref.watch(appStringsProvider).messageLoginToRecoverData}');
      }
    }
    
    // 测试数据库连接
    await Supabase.instance.client
        .from('tarot_cards')
        .select('card_id')
        .limit(1);
    
    connectionSuccessful = true;
            print('✅ ${ref.watch(appStringsProvider).messageDatabaseConnectionSuccess}');
  } catch (e) {
            print('⚠️ ${ref.watch(appStringsProvider).messageConnectionFailed}: $e');
    connectionSuccessful = false;
  }
  
  // 设置运行模式
  await DataService.setOfflineMode(!connectionSuccessful);
  
  // 显示当前模式
  if (DataService.isOfflineMode) {
          print('🔄 ${ref.watch(appStringsProvider).messageCurrentMode}: ${ref.watch(appStringsProvider).labelOfflineMode}');
      print('💡 ${ref.watch(appStringsProvider).messageOfflineModeDescription}');
  } else {
          print('🌐 ${ref.watch(appStringsProvider).messageCurrentMode}: ${ref.watch(appStringsProvider).labelOnlineMode}');
      print('🎉 ${ref.watch(appStringsProvider).messageSupabaseConnectionSuccess}');
  }
  
  runApp(
    const ProviderScope(
      child: MysticTarotApp(),
    ),
  );
} 