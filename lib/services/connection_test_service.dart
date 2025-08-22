import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mystic_tarot_jp/core/config/supabase_config.dart';
import 'dart:convert';

class ConnectionTestService {
  /// 测试网络连接
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};
    
    // 1. 测试基本网络连接
    try {
      final response = await http.get(
        Uri.parse('https://httpbin.org/get'),
        headers: {'User-Agent': 'TarotApp/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      results['basic_network'] = {
        'status': 'success',
        'code': response.statusCode,
        'message': '基本网络连接正常'
      };
    } catch (e) {
      results['basic_network'] = {
        'status': 'error',
        'message': '基本网络连接失败: $e'
      };
    }
    
    // 2. 测试Supabase URL可达性
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/'),
        headers: {
          'apikey': SupabaseConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 10));
      
      results['supabase_url'] = {
        'status': response.statusCode < 400 ? 'success' : 'error',
        'code': response.statusCode,
        'message': response.statusCode < 400 
            ? 'Supabase URL可访问' 
            : 'Supabase URL返回错误状态码: ${response.statusCode}'
      };
    } catch (e) {
      results['supabase_url'] = {
        'status': 'error',
        'message': 'Supabase URL不可访问: $e'
      };
    }
    
    // 3. 测试匿名登录功能
    try {
      final client = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
      );
      
      final response = await client.auth.signInAnonymously();
      
      if (response.user != null) {
        results['anonymous_login'] = {
          'status': 'success',
          'message': '匿名登录成功',
          'user_id': response.user!.id
        };
        
        // 登录成功后立即登出
        await client.auth.signOut();
      } else {
        results['anonymous_login'] = {
          'status': 'error',
          'message': '匿名登录失败：未返回用户信息'
        };
      }
    } catch (e) {
      results['anonymous_login'] = {
        'status': 'error',
        'message': '匿名登录失败: $e'
      };
    }
    
    // 4. 测试数据库连接
    try {
      final client = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
      );
      
      // 尝试匿名登录
      await client.auth.signInAnonymously();
      
      // 测试数据库查询
      final response = await client
          .from('tarot_cards')
          .select('card_id')
          .limit(1);
      
      results['database_access'] = {
        'status': 'success',
        'message': '数据库连接成功',
        'data_count': response.length
      };
      
      await client.auth.signOut();
    } catch (e) {
      results['database_access'] = {
        'status': 'error',
        'message': '数据库连接失败: $e'
      };
    }
    
    return results;
  }
  
  /// 生成诊断报告
  static String generateDiagnosticReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== Supabase 连接诊断报告 ===\n');
    
    // 基本网络连接
    final basicNetwork = results['basic_network'];
    buffer.writeln('1. 基本网络连接:');
    buffer.writeln('   状态: ${basicNetwork['status']}');
    buffer.writeln('   信息: ${basicNetwork['message']}\n');
    
    // Supabase URL可达性
    final supabaseUrl = results['supabase_url'];
    buffer.writeln('2. Supabase URL可达性:');
    buffer.writeln('   状态: ${supabaseUrl['status']}');
    buffer.writeln('   信息: ${supabaseUrl['message']}\n');
    
    // 匿名登录
    final anonymousLogin = results['anonymous_login'];
    buffer.writeln('3. 匿名登录:');
    buffer.writeln('   状态: ${anonymousLogin['status']}');
    buffer.writeln('   信息: ${anonymousLogin['message']}\n');
    
    // 数据库访问
    final databaseAccess = results['database_access'];
    buffer.writeln('4. 数据库访问:');
    buffer.writeln('   状态: ${databaseAccess['status']}');
    buffer.writeln('   信息: ${databaseAccess['message']}\n');
    
    // 总结和建议
    buffer.writeln('=== 总结和建议 ===');
    
    if (basicNetwork['status'] == 'error') {
      buffer.writeln('• 网络连接有问题，请检查网络设置');
    } else if (supabaseUrl['status'] == 'error') {
      buffer.writeln('• Supabase服务不可访问，可能是项目被暂停或删除');
      buffer.writeln('• 请检查Supabase项目状态');
    } else if (anonymousLogin['status'] == 'error') {
      buffer.writeln('• 匿名登录功能可能被禁用');
      buffer.writeln('• 请在Supabase项目设置中启用匿名登录');
    } else if (databaseAccess['status'] == 'error') {
      buffer.writeln('• 数据库访问权限有问题');
      buffer.writeln('• 请检查RLS（行级安全）设置');
    } else {
      buffer.writeln('• 所有连接测试都通过了');
      buffer.writeln('• 问题可能是临时性的，请稍后重试');
    }
    
    return buffer.toString();
  }
  
  /// 检查Supabase项目配置
  static Map<String, String> checkConfiguration() {
    final config = <String, String>{};
    
    // 检查URL格式
    if (SupabaseConfig.supabaseUrl.isEmpty) {
      config['url'] = 'URL为空';
    } else if (!SupabaseConfig.supabaseUrl.startsWith('https://')) {
      config['url'] = 'URL格式错误，应该以https://开头';
    } else if (!SupabaseConfig.supabaseUrl.contains('.supabase.co')) {
      config['url'] = 'URL格式错误，应该包含.supabase.co';
    } else {
      config['url'] = 'URL格式正确';
    }
    
    // 检查anon key格式
    if (SupabaseConfig.supabaseAnonKey.isEmpty) {
      config['anon_key'] = 'Anon Key为空';
    } else if (!SupabaseConfig.supabaseAnonKey.startsWith('eyJ')) {
      config['anon_key'] = 'Anon Key格式错误，应该以eyJ开头';
    } else {
      config['anon_key'] = 'Anon Key格式正确';
    }
    
    return config;
  }
} 