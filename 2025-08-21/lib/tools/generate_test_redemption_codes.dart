import 'package:flutter/foundation.dart';
import 'package:mystic_tarot_jp/services/redemption_service.dart';

/// 测试兑换码生成工具
class TestRedemptionCodeGenerator {
  
  /// 生成测试兑换码
  static Future<void> generateTestCodes() async {
    if (!kDebugMode) {
      print('❌ 只能在开发模式下生成测试兑换码');
      return;
    }
    
    try {
      print('🎫 开始生成测试兑换码...');
      
      // 生成7天试用码
      final sevenDayCodes = await RedemptionService.generateTestCodes(
        count: 3,
        days: 7,
        batchName: 'test_7days',
      );
      
      // 生成30天订阅码
      final thirtyDayCodes = await RedemptionService.generateTestCodes(
        count: 2,
        days: 30,
        batchName: 'test_30days',
      );
      
      print('✅ 测试兑换码生成完成！');
      print('');
      print('📋 可用的测试兑换码：');
      print('');
      print('🟡 7天试用码：');
      for (final code in sevenDayCodes) {
        print('   $code (7天)');
      }
      print('');
      print('🟠 30天订阅码：');
      for (final code in thirtyDayCodes) {
        print('   $code (30天)');
      }
      print('');
      print('🔍 测试步骤：');
      print('1. 进入 マイページ');
      print('2. 点击 兑換コード');
      print('3. 输入上述任一兑换码');
      print('4. 点击 检查兑换码 → 立即兑换');
      print('5. 验证订阅状态是否正确激活');
      print('');
      print('💡 提示：每个兑换码只能使用一次');
      
    } catch (e) {
      print('❌ 生成测试兑换码失败: $e');
    }
  }
  
  /// 手动创建固定测试码（用于稳定测试）
  static List<Map<String, dynamic>> getFixedTestCodes() {
    return [
      {
        'code': 'TEST7DAY',
        'days': 7,
        'description': '测试用7天兑换码',
        'batch_name': 'fixed_test'
      },
      {
        'code': 'DEMO30DY',
        'days': 30,
        'description': '演示用30天兑换码',
        'batch_name': 'fixed_test'
      },
      {
        'code': 'CARD14DY',
        'days': 14,
        'description': '实体卡片附赠14天兑换码',
        'batch_name': 'physical_card'
      },
      {
        'code': 'PROMO7DY',
        'days': 7,
        'description': '推广活动7天兑换码',
        'batch_name': 'promotion'
      },
      {
        'code': 'VIP60DAY',
        'days': 60,
        'description': 'VIP用户专享60天兑换码',
        'batch_name': 'vip'
      },
    ];
  }
  
  /// 显示测试指南
  static void showTestGuide() {
    print('🎯 兑换码功能测试指南');
    print('');
    print('📱 测试流程：');
    print('1. 启动应用并确保已登录');
    print('2. 进入 マイページ (我的页面)');
    print('3. 在账户部分找到 "兑換コード" 选项');
    print('4. 点击进入兑换码页面');
    print('5. 输入测试兑换码并验证功能');
    print('');
    print('🧪 测试用固定兑换码：');
    final fixedCodes = getFixedTestCodes();
    for (final codeInfo in fixedCodes) {
      print('   ${codeInfo['code']} - ${codeInfo['days']}天 (${codeInfo['description']})');
    }
    print('');
    print('✅ 测试要点：');
    print('- 输入格式验证');
    print('- 兑换码有效性检查');
    print('- 重复使用防护');
    print('- 订阅状态正确激活');
    print('- 到期时间正确延长');
    print('- 用户体验流畅');
    print('');
    print('📝 测试注意事项：');
    print('- 每个兑换码只能使用一次');
    print('- 未登录用户无法使用兑换码');
    print('- 兑换天数会累加到现有订阅');
    print('- 数据库操作需要网络连接');
  }
}
