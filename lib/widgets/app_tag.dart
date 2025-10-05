import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

/// 统一标签样式组件
/// 默认：黑系淡填充(3%) + 淡描边(10%)，圆角20，字号14，字重w400，文字color与正文一致（textBlack87）
class AppTag extends ConsumerWidget {
  final String text;
  final EdgeInsets? padding;
  final double? borderRadius;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final Color? fillColor;
  final Color? borderColor;
  final bool useTheme; // 使用主题色
  final bool overlay;  // 叠加轻度overlay

  const AppTag(
    this.text, {
    super.key,
    this.padding,
    this.borderRadius,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.fillColor,
    this.borderColor,
    this.useTheme = false,
    this.overlay = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color defaultFill = DynamicTokens.tagFillGrey;
    final Color defaultBorder = DynamicTokens.tagBorderGrey;
    final Color defaultText = DynamicTokens.textBlack87;
    final tokens = ref.read(dynamicTokensProvider);
    // 计算装饰
    Decoration decoration;
    if (useTheme) {
      if (overlay) {
        // 稍微弱化叠加：20% → 10%
        final Color c1 = tokens.primaryColor.withOpacity(0.20);
        final Color c2 = tokens.primaryColor.withOpacity(0.10);
        decoration = BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          border: Border.all(color: borderColor ?? tokens.primaryColor.withOpacity(0.45), width: 1),
        );
      } else {
        decoration = BoxDecoration(
          color: tokens.primaryColor.withOpacity(0.14),
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          border: Border.all(color: borderColor ?? tokens.primaryColor.withOpacity(0.45), width: 1),
        );
      }
    } else {
      decoration = BoxDecoration(
        color: fillColor ?? defaultFill,
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        border: Border.all(color: borderColor ?? defaultBorder, width: 1),
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: decoration,
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? defaultText,
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w400,
        ),
      ),
    );
  }
}


