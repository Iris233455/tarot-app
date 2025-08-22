import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

/// 主题背景组件，支持背景纹理和渐变遮罩
class ThemedBackground extends ConsumerWidget {
  final Widget child;
  
  const ThemedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: dynamicTokens.backgroundColor,
      ),
      child: Stack(
        children: [
          // 背景纹理图片（如果有）
          if (dynamicTokens.backgroundImage != null)
            Positioned.fill(
              child: Image.asset(
                dynamicTokens.backgroundImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 如果图片加载失败，显示纯色背景
                  return Container(color: dynamicTokens.backgroundColor);
                },
              ),
            ),
          
          // 渐变遮罩（根据主题类型添加不同效果）
          if (dynamicTokens.backgroundImage != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _getGradientColors(dynamicTokens),
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          
          // 主要内容
          child,
        ],
      ),
    );
  }

  /// 根据主题获取渐变颜色
  List<Color> _getGradientColors(DynamicTokens dynamicTokens) {
    // 根据主题名称判断
    if (dynamicTokens.primaryColor == const Color(0xFF22C55E)) { // Forest主题
      return [
        Colors.transparent, // 顶部完全透明，显示原始森林纹理
        const Color(0xFF064E3B).withOpacity(0.3), // 中部深绿色，30%透明度
        const Color(0xFF064E3B).withOpacity(0.7), // 底部深绿色，70%透明度
      ];
    } else if (dynamicTokens.primaryColor == const Color(0xFF5DB0FF)) { // Clear Sky主题
      return [
        Colors.transparent, // 顶部完全透明，显示原始candy纹理
        const Color(0xFF3B82F6).withOpacity(0.15), // 中部天蓝色，15%透明度
        const Color(0xFF1E40AF).withOpacity(0.35), // 底部深蓝色，35%透明度
      ];
    } else if (dynamicTokens.primaryColor == const Color(0xFF9BB9D4)) { // Cloud主题
      return [
        Colors.transparent, // 顶部完全透明，显示原始云朵纹理
        const Color(0xFF7DD3FC).withOpacity(0.2), // 中部浅蓝色，20%透明度
        const Color(0xFF0EA5E9).withOpacity(0.4), // 底部云蓝色，40%透明度
      ];
    } else {
      // 其他暗色主题使用原来的黑色渐变
      return [
        Colors.black.withOpacity(0.0), // 顶部 0% 不透明度
        Colors.black.withOpacity(0.2), // 中部 20% 不透明度
        Colors.black.withOpacity(0.35), // 底部 35% 不透明度
      ];
    }
  }


}
