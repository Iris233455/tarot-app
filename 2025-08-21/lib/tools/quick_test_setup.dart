import 'package:flutter/foundation.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

/// 快速测试设置工具
class QuickTestSetup {
  
  /// 检查数据库表是否存在
  static Future<bool> checkTablesExist() async {
    try {
      await SupabaseService.client
          .from('redemption_codes')
          .select('code')
          .limit(1);
      
      return true; // 如果没有异常，表存在
    } catch (e) {
      debugPrint('❌ redemption_codes表不存在: $e');
      return false;
    }
  }
  
  /// 快速插入测试兑换码数据
  static Future<void> insertTestRedemptionCodes() async {
    try {
      debugPrint('🎫 开始插入测试兑换码...');
      
      final testCodes = [
        {
          'code': 'TEST0001',
          'days': 7,
          'is_used': false,
          'description': 'テスト引き換えコード - 7日間トライアル',
          'batch_name': 'test_batch',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'code': 'TEST0002',
          'days': 30,
          'is_used': false,
          'description': 'テスト引き換えコード - 30日間購読',
          'batch_name': 'test_batch',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'code': 'DEMO001A',
          'days': 7,
          'is_used': false,
          'description': 'デモ引き換えコード - 7日間',
          'batch_name': 'demo_batch',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'code': 'DEMO002B',
          'days': 14,
          'is_used': false,
          'description': 'デモ引き換えコード - 14日間',
          'batch_name': 'demo_batch',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'code': 'TRIAL7DY',
          'days': 7,
          'is_used': false,
          'description': 'トライアル用7日間コード',
          'batch_name': 'trial',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
      
      // 使用upsert来避免重复插入
      await SupabaseService.client
          .from('redemption_codes')
          .upsert(testCodes, onConflict: 'code');
      
      debugPrint('✅ 测试兑换码插入成功！');
      debugPrint('📋 可用测试兑换码：');
      for (final code in testCodes) {
        debugPrint('   ${code['code']} - ${code['days']}日間 (${code['description']})');
      }
      
    } catch (e) {
      debugPrint('❌ 插入测试兑换码失败: $e');
      rethrow;
    }
  }
  
  /// 检查兑换码函数是否存在
  static Future<bool> checkRedeemFunctionExists() async {
    try {
      // 尝试调用函数（使用无效参数）
      await SupabaseService.client
          .rpc('redeem_code', params: {
            'redemption_code': 'INVALID_TEST',
            'user_id': '00000000-0000-0000-0000-000000000000',
          });
      
      return true;
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('function') && errorMessage.contains('does not exist')) {
        debugPrint('❌ redeem_code函数不存在');
        return false;
      }
      // 其他错误（如参数错误）说明函数存在
      return true;
    }
  }
  
  /// 完整的诊断检查
  static Future<Map<String, bool>> runDiagnostics() async {
    debugPrint('🔍 开始兑换码系统诊断...');
    
    final results = <String, bool>{};
    
    // 检查表是否存在
    results['tables_exist'] = await checkTablesExist();
    debugPrint('📊 数据库表存在: ${results['tables_exist']}');
    
    // 检查函数是否存在
    results['function_exists'] = await checkRedeemFunctionExists();
    debugPrint('⚙️ 兑换函数存在: ${results['function_exists']}');
    
    // 检查用户是否已登录
    final currentUser = SupabaseService.currentUser;
    results['user_logged_in'] = currentUser != null;
    debugPrint('👤 用户已登录: ${results['user_logged_in']}');
    if (currentUser != null) {
      debugPrint('   用户ID: ${currentUser.id}');
      debugPrint('   邮箱: ${currentUser.email}');
    }
    
    // 检查网络连接
    try {
      await SupabaseService.client.auth.getUser();
      results['network_connected'] = true;
      debugPrint('🌐 网络连接: ${results['network_connected']}');
    } catch (e) {
      results['network_connected'] = false;
      debugPrint('🌐 网络连接: ${results['network_connected']} - $e');
    }
    
    debugPrint('');
    debugPrint('📋 诊断结果总结:');
    results.forEach((key, value) {
      final status = value ? '✅' : '❌';
      debugPrint('   $status $key: $value');
    });
    
    return results;
  }
  
  /// 快速修复（尝试插入测试数据）
  static Future<void> quickFix() async {
    debugPrint('🛠️ 开始快速修复...');
    
    final diagnostics = await runDiagnostics();
    
    if (!diagnostics['user_logged_in']!) {
      debugPrint('❌ 用户未登录，无法继续修复');
      return;
    }
    
    if (!diagnostics['network_connected']!) {
      debugPrint('❌ 网络连接失败，无法继续修复');
      return;
    }
    
    if (diagnostics['tables_exist']!) {
      debugPrint('✅ 数据库表存在，尝试插入测试数据...');
      try {
        await insertTestRedemptionCodes();
        debugPrint('✅ 测试数据插入成功');
      } catch (e) {
        debugPrint('❌ 插入测试数据失败: $e');
      }
    } else {
      debugPrint('❌ 数据库表不存在，请在Supabase Dashboard中执行SQL脚本');
      debugPrint('   脚本文件: manual_setup_redemption_codes.sql');
    }
    
    if (!diagnostics['function_exists']!) {
      debugPrint('❌ 兑换函数不存在，请在Supabase Dashboard中执行SQL脚本');
      debugPrint('   脚本文件: manual_setup_redemption_codes.sql');
    }
    
    debugPrint('🎉 快速修复完成！');
  }
  
  /// 获取测试指导
  static void showTestInstructions() {
    debugPrint('');
    debugPrint('🎯 兑换码测试指导：');
    debugPrint('');
    debugPrint('📋 步骤1: 数据库设置');
    debugPrint('1. 在Supabase Dashboard中打开SQL Editor');
    debugPrint('2. 复制并执行 manual_setup_redemption_codes.sql 脚本');
    debugPrint('3. 确认表和函数创建成功');
    debugPrint('');
    debugPrint('🧪 步骤2: 测试兑换码');
    debugPrint('可用的测试兑换码：');
    debugPrint('- TEST0001 (7日間)');
    debugPrint('- TEST0002 (30日間)');
    debugPrint('- DEMO001A (7日間)');
    debugPrint('- DEMO002B (14日間)');
    debugPrint('- TRIAL7DY (7日間)');
    debugPrint('');
    debugPrint('🚀 步骤3: 应用内测试');
    debugPrint('1. 确保已登录应用');
    debugPrint('2. 进入 マイページ → 引き換えコード');
    debugPrint('3. 输入上述任一测试兑换码');
    debugPrint('4. 点击 コードをチェック → 今すぐ引き換え');
    debugPrint('5. 验证订阅状态是否正确激活');
    debugPrint('');
    debugPrint('💡 如果仍有问题：');
    debugPrint('1. 检查Supabase项目是否正确连接');
    debugPrint('2. 检查RLS策略是否正确设置');
    debugPrint('3. 查看应用日志中的具体错误信息');
  }
}
