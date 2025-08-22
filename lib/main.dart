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
import 'package:mystic_tarot_jp/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据服务
  await DataService.initialize();

  // 初始化深链（原生：mystictarot://）
  await DeepLinkService.initialize();
  
  // 初始化AdMob
  try {
    await AdService.initialize();
    print('✅ AdMob初始化成功');
  } catch (e) {
    print('⚠️ AdMob初始化失败: $e');
  }
  
  // 初始化订阅服务
  try {
    await SubscriptionService.initialize();
    print('✅ 订阅服务初始化成功');
  } catch (e) {
    print('⚠️ 订阅服务初始化失败: $e');
  }
  
  // 清除所有缓存，确保使用最新的数据源
  DataService.clearCache();
  
  // 初始化 Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Supabase初始化成功');
    
    // 等待session恢复（特别是在Flutter Web中）
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 额外等待auth状态稳定
    int attempts = 0;
    while (attempts < 3) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        print('🔍 检测到已存在的用户session: ${currentUser.id}');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
  } catch (e) {
    print('⚠️ Supabase初始化失败: $e');
    print('📱 将使用离线模式');
    await DataService.setOfflineMode(true);
  }
  
  // 每次启动都尝试连接测试（不管之前的状态）
  bool connectionSuccessful = false;
  
  try {
    // 检查现有的认证状态，但不自动登录
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      print('✅ 检测到现有用户session: ${currentUser.id}');
      print('📧 用户类型: ${currentUser.isAnonymous ? "匿名用户" : "邮箱用户 (${currentUser.email})"}');
      
      // 更新缓存
      await SupabaseService.cacheUserId(currentUser.id);
    } else {
      print('🔐 没有检测到用户session，需要登录/注册');
      
      // 检查是否有缓存的用户ID（用于数据恢复提示）
      final cachedUserId = await SupabaseService.getCachedUserId();
      if (cachedUserId != null) {
        print('🔍 检测到缓存的用户ID: $cachedUserId');
        print('💡 建议：登录后可以尝试恢复之前的数据');
      }
    }
    
    // 测试数据库连接
    await Supabase.instance.client
        .from('tarot_cards')
        .select('card_id')
        .limit(1);
    
    connectionSuccessful = true;
    print('✅ 数据库连接成功');
  } catch (e) {
    print('⚠️ 连接失败: $e');
    connectionSuccessful = false;
  }
  
  // 设置运行模式
  await DataService.setOfflineMode(!connectionSuccessful);
  
  // 显示当前模式
  if (DataService.isOfflineMode) {
    print('🔄 当前运行模式：离线模式');
    print('💡 应用将使用本地JSON数据，所有功能正常可用');
  } else {
    print('🌐 当前运行模式：在线模式');
    print('🎉 Supabase连接成功，所有功能正常可用');
  }
  
  runApp(
    const ProviderScope(
      child: MysticTarotApp(),
    ),
  );
} 