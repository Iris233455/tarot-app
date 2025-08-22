import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/services/ad_service.dart';

/// 广告奖励状态
enum AdRewardState {
  idle,
  loading,
  watching,
  rewarded,
  failed,
  limitReached,
}

/// 广告奖励数据类
class AdRewardData {
  final AdRewardState state;
  final int remainingCount;
  final String? error;

  const AdRewardData({
    required this.state,
    this.remainingCount = 0,
    this.error,
  });

  AdRewardData copyWith({
    AdRewardState? state,
    int? remainingCount,
    String? error,
  }) {
    return AdRewardData(
      state: state ?? this.state,
      remainingCount: remainingCount ?? this.remainingCount,
      error: error ?? this.error,
    );
  }
}

/// 广告奖励Notifier
class AdRewardNotifier extends StateNotifier<AdRewardData> {
  AdRewardNotifier() : super(const AdRewardData(state: AdRewardState.idle)) {
    _updateRemainingCount();
  }

  /// 更新剩余次数
  Future<void> _updateRemainingCount() async {
    final count = await AdService.getRemainingAdCount();
    state = state.copyWith(remainingCount: count);
  }

  /// 显示激励视频广告
  Future<bool> showRewardedAd() async {
    // 检查是否达到每日限制
    if (!await AdService.canWatchAdToday()) {
      state = state.copyWith(
        state: AdRewardState.limitReached,
        error: '今日广告观看次数已达上限（3次）',
      );
      return false;
    }

    // 检查广告是否就绪
    if (!AdService.isAdReady()) {
      state = state.copyWith(
        state: AdRewardState.loading,
      );
      
      // 尝试预加载广告
      await AdService.preloadAd();
      
      if (!AdService.isAdReady()) {
        state = state.copyWith(
          state: AdRewardState.failed,
          error: '广告暂时无法加载，请稍后重试',
        );
        return false;
      }
    }

    state = state.copyWith(state: AdRewardState.watching);

    try {
      final rewarded = await AdService.showRewardedAd();
      
      if (rewarded) {
        await _updateRemainingCount();
        state = state.copyWith(
          state: AdRewardState.rewarded,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          state: AdRewardState.failed,
          error: '广告未完整观看，请重试',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        state: AdRewardState.failed,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 重置状态到闲置
  void reset() {
    _updateRemainingCount();
    state = state.copyWith(
      state: AdRewardState.idle,
      error: null,
    );
  }

  /// 检查是否可以观看广告
  Future<bool> canWatchAd() async {
    return await AdService.canWatchAdToday() && AdService.isAdReady();
  }
}

/// 广告奖励Provider
final adRewardProvider = StateNotifierProvider<AdRewardNotifier, AdRewardData>(
  (ref) => AdRewardNotifier(),
);

/// 剩余广告次数Provider (只读)
final remainingAdCountProvider = FutureProvider<int>((ref) async {
  return await AdService.getRemainingAdCount();
});

/// 广告就绪状态Provider (只读)
final adReadyProvider = Provider<bool>((ref) {
  return AdService.isAdReady();
});
