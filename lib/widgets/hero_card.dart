import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';

class HeroCard extends ConsumerWidget {
  final TarotCard card;
  final bool isUpright;
  final double? width;
  final double? height;
  final VoidCallback onTap;

  const HeroCard({
    Key? key,
    required this.card,
    required this.isUpright,
    this.width,
    this.height,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
          ),
          child: Stack(
            children: [
              // 卡片图片
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(isUpright ? 0 : 3.14159), // 逆位时旋转180度
                    child: Image.asset(
                      card.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 点击提示（仅在鼠标悬停时显示）
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 