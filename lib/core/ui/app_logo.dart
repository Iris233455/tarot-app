import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

class AppLogo extends ConsumerWidget {
  final double size;

  const AppLogo({super.key, this.size = 36});

  String _colorToHex(Color c) {
    return '#'
        '${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  Color _darken(Color color, [double amount = .18]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = ref.watch(dynamicTokensProvider);
    final primaryHex = _colorToHex(dt.primaryColor);
    final deepHex = _colorToHex(_darken(dt.primaryColor, 0.18));

    // 两个路径：外轮廓（描边用主题色），小方块（主题色双层叠加 -> 渐变）
    const String path1 =
        'M63.86,3.82C30.72,3.82,3.86,30.68,3.86,63.82c0,23.1,13.07,43.15,32.21,53.17v-27.81s0-26.58,0-26.58v-8.86h-17.72v-17.71h44.29s26.58,0,26.58,0h13.28v53.15h-26.57l-8.64,34.54c31.54-1.78,56.57-27.91,56.57-59.9S96.99,3.82,63.86,3.82Z';
    const String path2 = 'M73.89,53.67h-20.19v20.19h20.19v-20.19Z';

    final String svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="$size" height="$size">
  <path d="$path1" fill="$primaryHex"/>
  <path d="$path2" fill="$deepHex"/>
</svg>
''';

    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}


