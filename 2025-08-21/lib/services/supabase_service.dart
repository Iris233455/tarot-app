import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _userIdCacheKey = 'cached_user_id';
  
  // 获取客户端实例
  static SupabaseClient get client => _client;
  
  // 获取当前用户
  static User? get currentUser => _client.auth.currentUser;
  
  // 获取当前用户ID（带缓存机制）
  static String? get currentUserId => currentUser?.id;
  
  /// 缓存用户ID（Debug模式下的保护机制）
  static Future<void> cacheUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdCacheKey, userId);
  }
  
  /// 获取缓存的用户ID
  static Future<String?> getCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdCacheKey);
  }
  
  /// 清除缓存的用户ID
  static Future<void> clearCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdCacheKey);
  }
  
  // ============ 认证相关 ============
  
  /// 匿名登录
  static Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }
  
  /// 邮箱注册
  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  /// 邮箱登录
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Google登录（支持Web和原生平台）
  static Future<bool> signInWithGoogle() async {
    try {
      print('🔍 ${ref.watch(appStringsProvider).messageStartingGoogleLogin}');
      print('   ${ref.watch(appStringsProvider).messageCurrentPlatform}: ${kIsWeb ? 'Web' : 'Native ${defaultTargetPlatform.name}'}');
      
      // 检查当前认证状态
      final currentUser = _client.auth.currentUser;
      if (currentUser != null && !currentUser.isAnonymous) {
                  print('   ⚠️ ${ref.watch(appStringsProvider).messageAlreadyLoggedIn}: ${currentUser.email}');
          print('   → ${ref.watch(appStringsProvider).messageSkipLoginReturnSuccess}');
        return true;
      }
      
      // 如果是匿名用户，先登出
      if (currentUser?.isAnonymous == true) {
                  print('   🚪 ${ref.watch(appStringsProvider).messageAnonymousUserLogout}');
        await _client.auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      if (kIsWeb) {
        // Web平台：使用Supabase OAuth
        return await _signInWithGoogleWeb();
      } else {
        // iOS/macOS平台：使用原生Google Sign In
        return await _signInWithGoogleNative();
      }
    } catch (e) {
              print('❌ ${ref.watch(appStringsProvider).messageGoogleLoginFailed}: $e');
      return false;
    }
  }
  
  /// Web平台Google登录
  static Future<bool> _signInWithGoogleWeb() async {
    try {
              print('🌐 ${ref.watch(appStringsProvider).messageWebPlatformOAuth}');
        print('   ${ref.watch(appStringsProvider).messageCurrentURL}: ${Uri.base}');
        print('   ${ref.watch(appStringsProvider).messageExpectedRedirectURI}: https://wpblulcekjnhwccrjqlg.supabase.co/auth/v1/callback');
      
      final result = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: null,
      );
      
              print('🎉 ${ref.watch(appStringsProvider).messageGoogleOAuthResult}: $result');
      
      await Future.delayed(const Duration(seconds: 2));
      
      final newUser = _client.auth.currentUser;
              print('🔍 ${ref.watch(appStringsProvider).messageWebGoogleLoginUserInfo}:');
        print('   ${ref.watch(appStringsProvider).messageUserId}: ${newUser?.id}');
        print('   ${ref.watch(appStringsProvider).messageEmail}: ${newUser?.email}');
      
      return result;
    } catch (e) {
              print('❌ ${ref.watch(appStringsProvider).messageWebGoogleOAuthError}: $e');
        if (e.toString().contains('unauthorized_client')) {
          print('   💡 ${ref.watch(appStringsProvider).messageCheckGoogleCloudConsole}');
        } else if (e.toString().contains('redirect_uri_mismatch')) {
          print('   💡 ${ref.watch(appStringsProvider).messageCheckRedirectURI}');
        }
      rethrow;
    }
  }
  
  /// 原生平台Google登录（iOS/macOS）
  static Future<bool> _signInWithGoogleNative() async {
    try {
              print('📱 ${ref.watch(appStringsProvider).messageNativePlatformGoogleSignIn}');
      
      // 配置Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // iOS/macOS配置会从配置文件自动读取
      );
      
      // 执行Google登录
                print('   → ${ref.watch(appStringsProvider).messageStartingNativeGoogleLogin}');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
                  print('   ❌ ${ref.watch(appStringsProvider).messageUserCancelledGoogleLogin}');
        return false;
      }
      
                print('   ✅ ${ref.watch(appStringsProvider).messageGoogleLoginSuccess}: ${googleUser.email}');
      
      // 获取认证凭据
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
                  print('   ❌ ${ref.watch(appStringsProvider).messageCannotGetGoogleAuthToken}');
        return false;
      }
      
                print('   ✅ ${ref.watch(appStringsProvider).messageGoogleAuthTokenSuccess}');
      
      // 使用Google令牌登录Supabase
      final AuthResponse response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
      
      if (response.user != null) {
                  print('   ✅ ${ref.watch(appStringsProvider).messageSupabaseLoginSuccess}');
          print('   ${ref.watch(appStringsProvider).messageUserId}: ${response.user!.id}');
          print('   ${ref.watch(appStringsProvider).messageEmail}: ${response.user!.email}');
        return true;
      } else {
                  print('   ❌ ${ref.watch(appStringsProvider).messageSupabaseLoginFailed}');
        return false;
      }
      
    } catch (e) {
              print('❌ ${ref.watch(appStringsProvider).messageNativeGoogleLoginErrorDetails}:');
        print('   ${ref.watch(appStringsProvider).messageErrorType}: ${e.runtimeType}');
        print('   ${ref.watch(appStringsProvider).messageErrorInfo}: $e');
      
              if (e.toString().contains('sign_in_canceled')) {
          print('   💡 ${ref.watch(appStringsProvider).messageUserCancelledLogin}');
        } else if (e.toString().contains('sign_in_failed')) {
          print('   💡 ${ref.watch(appStringsProvider).messageCheckGoogleConfigBundleId}');
        } else if (e.toString().contains('network_error')) {
          print('   💡 ${ref.watch(appStringsProvider).messageCheckNetworkConnection}');
        }
      
      rethrow;
    }
  }
  
  /// 登出
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  /// 更新用户Open ID（显示名称）
  static Future<void> updateOpenId(String openId) async {
    if (currentUserId == null) throw Exception('用户未登录');
    
    await _client.from('user_profiles').upsert({
      'user_id': currentUserId,
      'open_id': openId,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');  // 指定冲突处理字段
  }
  
  /// 账户升级：将匿名用户升级为邮箱用户
  static Future<void> upgradeAnonymousToEmail(String email, String password) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('用户未登录');
    if (!currentUser.isAnonymous) throw Exception('只有匿名用户可以升级账户');
    
    try {
              print('🔄 ${ref.watch(appStringsProvider).messageStartingAccountUpgrade}');
        print('   ${ref.watch(appStringsProvider).messageCurrentAnonymousUserId}: ${currentUser.id}');
      
      // 使用Supabase的linkIdentity功能将邮箱身份链接到现有匿名用户
      await _client.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
        ),
      );
      
              print('✅ ${ref.watch(appStringsProvider).messageAccountUpgradeSuccess}');
        print('   ${ref.watch(appStringsProvider).messageUpgradedUserId}: ${_client.auth.currentUser?.id}');
        print('   ${ref.watch(appStringsProvider).messageEmail}: ${_client.auth.currentUser?.email}');
      
      // 所有数据自动保留，因为用户ID没有改变
      
    } catch (e) {
              print('❌ ${ref.watch(appStringsProvider).messageAccountUpgradeFailed}: $e');
      rethrow;
    }
  }
  
  // ============ 塔罗牌数据相关 ============
  
  /// 获取所有塔罗牌
  static Future<List<Map<String, dynamic>>> getAllTarotCards() async {
    final response = await _client
        .from('tarot_cards')
        .select('*')
        .order('card_id');
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// 根据ID获取塔罗牌
  static Future<Map<String, dynamic>?> getTarotCard(String cardId) async {
    final response = await _client
        .from('tarot_cards')
        .select('*')
        .eq('card_id', cardId)
        .maybeSingle();
    return response;
  }
  
  /// 批量插入塔罗牌数据（从JSON导入）
  static Future<void> insertTarotCards(List<Map<String, dynamic>> cards) async {
    await _client.from('tarot_cards').upsert(cards);
  }
  
  // ============ 每日抽牌相关 ============
  
  /// 获取今日抽牌记录
  static Future<Map<String, dynamic>?> getTodayCard() async {
    if (currentUserId == null) return null;
    
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final response = await _client
        .from('daily_cards')
        .select('''
          *,
          tarot_cards (*)
        ''')
        .eq('user_id', currentUserId!)
        .eq('date', dateStr)
        .maybeSingle();
    
    return response;
  }
  
  /// 保存今日抽牌记录（一天只能抽一次）
  static Future<void> saveTodayCard({
    required String cardId,
    required bool isUpright,
    String? message,
  }) async {
    if (currentUserId == null) throw Exception('用户未登录');
    
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
            print('🔄 ${ref.watch(appStringsProvider).messageSavingDailyCard}');
        print('   ${ref.watch(appStringsProvider).messageUserId}: $currentUserId');
        print('   ${ref.watch(appStringsProvider).messageDate}: $dateStr');
        print('   ${ref.watch(appStringsProvider).messageCard}: $cardId (${isUpright ? ref.watch(appStringsProvider).labelUpright : ref.watch(appStringsProvider).labelReversed})');
    
    // 检查今天是否已经抽过牌
    final existing = await _client
        .from('daily_cards')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('date', dateStr)
        .maybeSingle();
    
    if (existing != null) {
                print('⚠️ ${ref.watch(appStringsProvider).messageAlreadyDrewCardToday}');
          throw Exception(ref.watch(appStringsProvider).messageAlreadyDrewCardTodayException);
    }
    
    final data = <String, dynamic>{
      'user_id': currentUserId,
      'card_id': cardId,
      'is_upright': isUpright,
      'date': dateStr,
    };
    
    // 添加今日消息（如果提供）
    if (message != null) {
      data['message'] = message;
              print('   ${ref.watch(appStringsProvider).messageMessage}: $message');
    }
    
    await _client.from('daily_cards').insert(data);
          print('✅ ${ref.watch(appStringsProvider).messageDailyCardSavedSuccess}');
  }
  
  /// 删除今日抽牌记录（测试用）
  static Future<void> clearTodayCard() async {
    if (currentUserId == null) return;
    
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      print('🗑️ 删除今日抽牌记录...');
      print('   用户ID: $currentUserId');
      print('   日期: $dateStr');
      
      final result = await _client
          .from('daily_cards')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('date', dateStr);
      
      print('✅ 今日抽牌记录删除成功');
      
    } catch (e) {
      print('❌ 删除今日抽牌记录失败: $e');
    }
  }
  
  /// 删除所有今天的抽牌记录（管理员测试用）
  static Future<void> clearAllTodayCards() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      print('🗑️ 删除所有今日抽牌记录...');
      print('   日期: $dateStr');
      
      await _client
          .from('daily_cards')
          .delete()
          .eq('date', dateStr);
      
      print('✅ 所有今日抽牌记录删除成功');
      
    } catch (e) {
      print('❌ 删除所有今日抽牌记录失败: $e');
    }
  }
  
  /// 获取月度抽牌记录
  static Future<List<Map<String, dynamic>>> getMonthlyCards(int year, int month) async {
    if (currentUserId == null) return [];
    
    // 直接查询数据表，不使用RPC函数
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    
    // 正确处理跨年的情况
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';
    
    final response = await _client
        .from('daily_cards')
        .select('''
          date,
          is_upright,
          tarot_cards (*)
        ''')
        .eq('user_id', currentUserId!)
        .gte('date', startDate)
        .lt('date', endDate)
        .order('date');
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// 获取指定日期的抽牌记录
  static Future<Map<String, dynamic>?> getCardByDate(DateTime date) async {
    if (currentUserId == null) return null;
    
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final response = await _client
        .from('daily_cards')
        .select('''
          *,
          tarot_cards (*)
        ''')
        .eq('user_id', currentUserId!)
        .eq('date', dateStr)
        .maybeSingle();
    
    return response;
  }
  
  // ============ 占卜记录相关 ============
  
    /// 保存占卜记录
  static Future<String> saveReading({
    required String spreadId,
    required List<Map<String, dynamic>> cards,
    String? question,
    String? interpretation,
  }) async {
    if (currentUserId == null) throw Exception('用户未登录');

    final data = <String, dynamic>{
      'user_id': currentUserId,
      'spread_id': spreadId,
      'cards': cards,
    };
    
    // 添加可选字段
    if (question != null) data['question'] = question;
    if (interpretation != null) data['interpretation'] = interpretation;

    try {
      final inserted = await _client.from('readings').insert(data).select('id').single();
      return (inserted['id'] ?? '').toString();
    } catch (e) {
      // 回退：尝试不返回值插入，再取最新一条ID
      try {
        await _client.from('readings').insert(data);
        final last = await _client
            .from('readings')
            .select('id')
            .eq('user_id', currentUserId!)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return (last?['id'] ?? '').toString();
      } catch (e2) {
        rethrow;
      }
    }
  }
  
  /// 删除指定占卜记录
  static Future<void> deleteReading(String readingId) async {
    if (currentUserId == null) throw Exception('用户未登录');
    await _client.from('readings').delete().eq('id', readingId).eq('user_id', currentUserId!);
  }

  /// 更新占卜记录的解读文本
  static Future<void> updateReadingInterpretation(String readingId, String interpretation) async {
    if (currentUserId == null) throw Exception('用户未登录');
    await _client
        .from('readings')
        .update({'interpretation': interpretation})
        .eq('id', readingId)
        .eq('user_id', currentUserId!);
  }

  /// 获取占卜历史（含简化映射，便于前端显示）
  static Future<List<Map<String, dynamic>>> getReadingHistoryLite({int limit = 50, int offset = 0}) async {
    if (currentUserId == null) return [];
    final resp = await _client
        .from('readings')
        .select('*')
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(resp);
  }

  /// 获取单条占卜记录
  static Future<Map<String, dynamic>?> getReadingById(String id) async {
    if (currentUserId == null) return null;
    final resp = await _client
        .from('readings')
        .select('*')
        .eq('user_id', currentUserId!)
        .eq('id', id)
        .maybeSingle();
    if (resp == null) return null;
    return Map<String, dynamic>.from(resp);
  }
  
  /// 获取用户的占卜历史
  static Future<List<Map<String, dynamic>>> getReadingHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    if (currentUserId == null) return [];
    
    final response = await _client
        .from('readings')
        .select('*')
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ============ 用户配置相关 ============
  
  /// 创建或更新用户基础配置
  static Future<void> upsertUserProfile({
    String? username,
    String? avatarUrl,
  }) async {
    if (currentUserId == null) throw Exception('用户未登录');
    
    await _client.from('user_profiles').upsert({
      'user_id': currentUserId,
      'username': username,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
  
  /// 创建或更新用户详细配置（包含个人信息）
  static Future<void> upsertDetailedUserProfile({
    String? username,
    String? avatarUrl,
    String? name,
    String? gender,
    DateTime? birthDate,
    String? occupation,
    String? relationshipStatus,
  }) async {
    if (currentUserId == null) throw Exception('用户未登录');
    
    try {
      print('🔄 开始保存Profile数据...');
      print('   用户ID: $currentUserId');
      
      final data = <String, dynamic>{
        'user_id': currentUserId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // 只添加非null的字段
      if (username != null) data['username'] = username;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (name != null) data['name'] = name;
      if (gender != null) data['gender'] = gender;
      if (birthDate != null) data['birth_date'] = birthDate.toIso8601String().split('T')[0];
      if (occupation != null) data['occupation'] = occupation;
      if (relationshipStatus != null) data['relationship_status'] = relationshipStatus;
      
      print('   保存数据: $data');
      
      // 使用 upsert，基于 user_id 字段进行冲突处理
      final result = await _client
          .from('user_profiles')
          .upsert(data, onConflict: 'user_id');
      
      print('✅ Profile保存成功: $result');
      
    } catch (e) {
      print('❌ Profile保存失败: $e');
      
      // 如果是约束错误，尝试先删除再插入
      if (e.toString().contains('duplicate key') || e.toString().contains('constraint')) {
        try {
          print('🔄 尝试更新现有记录...');
          
          // 先查询是否存在记录
          final existing = await _client
              .from('user_profiles')
              .select('id')
              .eq('user_id', currentUserId!)
              .maybeSingle();
          
          // 重新构建数据，确保不包含id字段
          final retryData = <String, dynamic>{
            'user_id': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          if (name != null) retryData['name'] = name;
          if (gender != null) retryData['gender'] = gender;
          if (birthDate != null) retryData['birth_date'] = birthDate.toIso8601String().split('T')[0];
          if (occupation != null) retryData['occupation'] = occupation;
          if (relationshipStatus != null) retryData['relationship_status'] = relationshipStatus;
          
          print('   重试数据: $retryData');
          
          if (existing != null) {
            // 更新现有记录（不包含user_id和id）
            final updateData = Map<String, dynamic>.from(retryData);
            updateData.remove('user_id'); // 更新时不需要user_id
            
            await _client
                .from('user_profiles')
                .update(updateData)
                .eq('user_id', currentUserId!);
          } else {
            // 插入新记录
            await _client.from('user_profiles').insert(retryData);
          }
          
          print('✅ Profile更新成功');
          
        } catch (retryError) {
          print('❌ Profile重试保存失败: $retryError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }
  
  /// 获取用户配置
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) return null;
    
    final response = await _client
        .from('user_profiles')
        .select('*')
        .eq('user_id', currentUserId!)  // 修复：应该按user_id查询而不是id
        .maybeSingle();
    
    return response;
  }

  // ============ 兼容性方法 ============
  
  /// 获取每日卡片（兼容旧代码）
  static Future<DailyCard> getDailyCard({required DateTime date}) async {
    final cardData = await getCardByDate(date);
    if (cardData == null) {
      throw Exception('该日期没有抽牌记录');
    }
    
    final tarotCardData = cardData['tarot_cards'];
    final card = TarotCard.fromJson(tarotCardData);
    
    return DailyCard(
      id: cardData['id'].toString(),
      card: card,
      isUpright: cardData['is_upright'] ?? true,
      date: DateTime.parse(cardData['date']),
    );
  }
  
  /// 抽取卡片（兼容旧代码）
  static Future<List<TarotCard>> drawCards({
    required String type,
    required String question,
    int count = 1,
  }) async {
    final allCards = await getAllTarotCards();
    if (allCards.isEmpty) return [];
    
    final cards = <TarotCard>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < count; i++) {
      final index = (random + i) % allCards.length;
      final cardData = allCards[index];
      final card = TarotCard.fromJson(cardData);
      cards.add(card);
    }
    
    return cards;
  }
  
  /// 根据ID获取卡片（兼容旧代码）
  static Future<TarotCard> getCardById({required String cardId}) async {
    final cardData = await getTarotCard(cardId);
    if (cardData == null) {
      throw Exception('找不到指定的塔罗牌');
    }
    return TarotCard.fromJson(cardData);
  }
  
  /// 获取所有卡片（兼容旧代码）
  static Future<List<TarotCard>> getAllCards() async {
    final cardsData = await getAllTarotCards();
    return cardsData.map((data) => TarotCard.fromJson(data)).toList();
  }
} 