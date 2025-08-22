import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// 广告观看状态
class AdWatchedState {
  final bool hasWatched;
  final String readingType;
  final DateTime? watchedAt;

  const AdWatchedState({
    this.hasWatched = false,
    this.readingType = '',
    this.watchedAt,
  });

  AdWatchedState copyWith({
    bool? hasWatched,
    String? readingType,
    DateTime? watchedAt,
  }) {
    return AdWatchedState(
      hasWatched: hasWatched ?? this.hasWatched,
      readingType: readingType ?? this.readingType,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }
}

/// 广告观看状态Notifier
class AdWatchedNotifier extends StateNotifier<AdWatchedState> {
  AdWatchedNotifier() : super(const AdWatchedState());

  /// 设置广告已观看
  void setWatched(String readingType) {
    state = state.copyWith(
      hasWatched: true,
      readingType: readingType,
      watchedAt: DateTime.now(),
    );
  }

  /// 重置状态
  void reset() {
    state = const AdWatchedState();
  }

  /// 检查是否为当前解读类型观看过广告
  bool hasWatchedForType(String readingType) {
    debugPrint('🔍 检查广告状态: 当前类型=$readingType, 保存类型=${state.readingType}, 已观看=${state.hasWatched}');
    
    if (!state.hasWatched || state.watchedAt == null) {
      debugPrint('❌ 未观看或无时间戳');
      return false;
    }
    
    // 标准化类型名称进行比较
    final currentTypeNormalized = _normalizeReadingType(readingType);
    final savedTypeNormalized = _normalizeReadingType(state.readingType);
    
    debugPrint('🔍 标准化比较: $currentTypeNormalized vs $savedTypeNormalized');
    
    final typeMatches = currentTypeNormalized == savedTypeNormalized;
    final timeDiff = DateTime.now().difference(state.watchedAt!).inMinutes;
    final withinTimeLimit = timeDiff < 120; // 延长到2小时
    
    debugPrint('🔍 类型匹配: $typeMatches, 时间差: ${timeDiff}分钟, 在时限内: $withinTimeLimit');
    
    return typeMatches && withinTimeLimit;
  }
  
  /// 标准化解读类型名称
  String _normalizeReadingType(String readingType) {
    switch (readingType) {
      case 'ワンオラクル':
      case 'one':
      case 'single':
        return 'one';
      case 'ツーカード':
      case 'two':
      case 'yesno':
        return 'two';
      case 'スリーカード':
      case 'three':
        return 'three';
      case '首日抽牌':
      case 'daily':
        return 'daily';
      default:
        return readingType.toLowerCase();
    }
  }
}

/// 广告观看状态Provider
final adWatchedProvider = StateNotifierProvider<AdWatchedNotifier, AdWatchedState>(
  (ref) => AdWatchedNotifier(),
);
