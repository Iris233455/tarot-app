import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

class AppReturnIcon extends ConsumerWidget {
  final double size;
  const AppReturnIcon({super.key, this.size = 36});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = ref.watch(dynamicTokensProvider);
    return SvgPicture.asset(
      'assets/icons/return.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(dt.primaryColor, BlendMode.srcIn),
    );
  }
}




