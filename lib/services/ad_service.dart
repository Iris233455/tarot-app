import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 广告服务 - 处理激励视频广告
class AdService {
  static const String _dailyCountKey = 'daily_ad_count';
  static const String _lastDateKey = 'last_ad_date';
  static const int _maxDailyAds = 3;
  
  // 获取激励视频广告单元ID（根据平台和环境）
  static String get _rewardedAdUnitId {
    if (kDebugMode) {
      // 测试环境
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/1712485313'  // iOS测试ID
          : 'ca-app-pub-3940256099942544/5224354917'; // Android测试ID
    } else {
      // 生产环境 - 请替换为真实的广告单元ID
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'YOUR_IOS_PRODUCTION_AD_UNIT_ID'
          : 'YOUR_ANDROID_PRODUCTION_AD_UNIT_ID';
    }
  }
  
  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;
  
  /// 检查平台是否支持AdMob
  static bool get _isPlatformSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  /// 初始化AdMob
  static Future<void> initialize() async {
    debugPrint('🎯 AdMob初始化开始...');
    debugPrint('📱 当前平台: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : Platform.isAndroid ? "Android" : Platform.isMacOS ? "macOS" : "未知")}');
    
    if (!_isPlatformSupported) {
      debugPrint('⚠️  当前平台不支持AdMob，将使用模拟广告模式');
      _isAdLoaded = true; // 设置为已加载，使用模拟广告
      return;
    }
    
    try {
      final initResult = await MobileAds.instance.initialize();
      debugPrint('🎯 AdMob初始化完成: ${initResult.adapterStatuses}');
      
      await _loadRewardedAd();
      debugPrint('🎯 激励视频广告预加载完成');
    } catch (e) {
      debugPrint('❌ AdMob初始化失败: $e');
      debugPrint('🧪 降级到模拟广告模式');
      _isAdLoaded = true; // 设置为已加载，使用模拟广告
    }
  }
  
  /// 加载激励视频广告
  static Future<void> _loadRewardedAd() async {
    try {
      debugPrint('🎯 开始加载激励视频广告，AdUnitId: $_rewardedAdUnitId');
      
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isAdLoaded = true;
            debugPrint('✅ 激励视频广告加载成功');
          },
          onAdFailedToLoad: (LoadAdError error) {
            _rewardedAd = null;
            _isAdLoaded = false;
            debugPrint('❌ 激励视频广告加载失败: ${error.code} - ${error.message}');
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ 广告加载异常: $e');
      _rewardedAd = null;
      _isAdLoaded = false;
    }
  }
  
  /// 检查今日是否还有广告观看次数
  static Future<bool> canWatchAdToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    final lastDate = prefs.getString(_lastDateKey);
    final dailyCount = prefs.getInt(_dailyCountKey) ?? 0;
    
    // 如果日期不同，重置计数
    if (lastDate != todayString) {
      await prefs.setString(_lastDateKey, todayString);
      await prefs.setInt(_dailyCountKey, 0);
      return true;
    }
    
    return dailyCount < _maxDailyAds;
  }
  
  /// 获取今日剩余广告次数
  static Future<int> getRemainingAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    final lastDate = prefs.getString(_lastDateKey);
    final dailyCount = prefs.getInt(_dailyCountKey) ?? 0;
    
    // 如果日期不同，重置计数
    if (lastDate != todayString) {
      return _maxDailyAds;
    }
    
    return _maxDailyAds - dailyCount;
  }
  
  /// 显示激励视频广告
  static Future<bool> showRewardedAd() async {
    debugPrint('🎯 尝试显示激励视频广告');
    
    // 检查今日次数限制
    if (!await canWatchAdToday()) {
      debugPrint('❌ 今日广告观看次数已达上限');
      return false;
    }
    
    // 不支持的平台时，使用模拟广告
    if (!_isPlatformSupported) {
      debugPrint('🧪 使用模拟广告 - 平台: ${kIsWeb ? "Web" : Platform.isMacOS ? "macOS" : "其他"}');
      
      try {
        // 模拟广告观看过程
        debugPrint('🎬 开始模拟广告播放...');
        await Future.delayed(const Duration(seconds: 2)); // 模拟广告时长
        
        await _incrementDailyCount();
        debugPrint('✅ 模拟广告观看完成，奖励已发放');
        return true;
      } catch (e) {
        debugPrint('❌ 模拟广告异常: $e');
        return false;
      }
    }
    
    // 真实AdMob广告不可用时
    if (_rewardedAd == null) {
      debugPrint('❌ 真实广告对象为空，降级到模拟广告');
      
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _incrementDailyCount();
        debugPrint('✅ 降级模拟广告完成');
        return true;
      } catch (e) {
        debugPrint('❌ 降级模拟广告异常: $e');
        return false;
      }
    }
    
    debugPrint('✅ 开始显示真实激励视频广告');
    bool rewardReceived = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('✅ 激励视频广告开始显示');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('📱 激励视频广告被关闭');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        // 预加载下一个广告
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('❌ 激励视频广告显示失败: ${error.code} - ${error.message}');
        debugPrint('   错误详细信息: ${error.domain}');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        // 预加载下一个广告
        _loadRewardedAd();
      },
    );
    
    try {
      debugPrint('🎬 正在显示激励视频广告...');
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          debugPrint('🎉 用户获得奖励: ${reward.amount} ${reward.type}');
          rewardReceived = true;
          // 增加今日计数
          await _incrementDailyCount();
        },
      );
      debugPrint('📺 广告显示调用完成，等待用户操作...');
    } catch (e) {
      debugPrint('❌ 广告显示异常: $e');
      return false;
    }
    
    return rewardReceived;
  }
  
  /// 增加今日广告观看计数
  static Future<void> _incrementDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    final lastDate = prefs.getString(_lastDateKey);
    int dailyCount = prefs.getInt(_dailyCountKey) ?? 0;
    
    // 如果日期不同，重置计数
    if (lastDate != todayString) {
      dailyCount = 0;
      await prefs.setString(_lastDateKey, todayString);
    }
    
    await prefs.setInt(_dailyCountKey, dailyCount + 1);
    debugPrint('今日广告观看次数: ${dailyCount + 1}/$_maxDailyAds');
  }
  
  /// 检查广告是否已加载
  static bool isAdReady() {
    return _isAdLoaded && _rewardedAd != null;
  }
  
  /// 预加载广告（可在应用启动或空闲时调用）
  static Future<void> preloadAd() async {
    if (!_isAdLoaded) {
      await _loadRewardedAd();
    }
  }
  
  /// 销毁广告资源
  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }
}
