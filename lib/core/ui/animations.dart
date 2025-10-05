import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

/// 动画集中管理（统一配置与切换入口）
///
/// 用法：
/// - 通过 `aiTextAnimationStyleProvider` 选择 AI 文本出现动画风格
/// - 在 UI 中调用 `wrapAiTextAnimation(child: ..., ref: ref)` 自动套用动画
/// - 之后想尝试其他方案，只需切换 Provider 的值或扩展枚举分支

/// AI 文本出现动画的可选样式
enum AiTextAnimationStyle {
  /// 自下而上滑入并渐显
  fadeInUp,

  /// 纯淡入
  fadeIn,

  /// 自下而上平移进入
  slideInUp,

  /// 自上而下滑入
  slideInDown,

  /// 自左到右滑入
  slideInLeft,

  /// 自右到左滑入
  slideInRight,

  /// 轻微缩放进入
  zoomIn,

  /// 从小到大弹性放大
  elasticIn,

  /// 不使用动画
  none,
}

/// AI 文本出现动画的全局配置 Provider
final aiTextAnimationStyleProvider =
    StateProvider<AiTextAnimationStyle>((ref) => AiTextAnimationStyle.fadeIn);

/// 包装 AI 文本出现动画
Widget wrapAiTextAnimation({
  required Widget child,
  required WidgetRef ref,
  Duration? duration,
  Duration? delay,
}) {
  final style = ref.watch(aiTextAnimationStyleProvider);
  final d = duration ?? DynamicTokens.animationDuration;
  final dl = delay ?? Duration.zero;

  switch (style) {
    case AiTextAnimationStyle.fadeInUp:
      return FadeInUp(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.fadeIn:
      return FadeIn(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.slideInUp:
      return SlideInUp(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.slideInDown:
      return SlideInDown(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.slideInLeft:
      return SlideInLeft(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.slideInRight:
      return SlideInRight(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.zoomIn:
      return ZoomIn(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.elasticIn:
      return ElasticIn(duration: d, delay: dl, child: child);
    case AiTextAnimationStyle.none:
      return child;
  }
}


