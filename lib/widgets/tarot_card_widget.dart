import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:mystic_tarot_jp/core/theme/app_theme.dart';
import 'package:mystic_tarot_jp/models/tarot_card.dart';
import 'package:mystic_tarot_jp/services/card_back_service.dart';

class TarotCardWidget extends StatefulWidget {
  final TarotCard card;
  final bool isRevealed;
  final bool showDetails;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const TarotCardWidget({
    super.key,
    required this.card,
    this.isRevealed = false,
    this.showDetails = false,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<TarotCardWidget> createState() => _TarotCardWidgetState();
}

class _TarotCardWidgetState extends State<TarotCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _scaleController;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isRevealed) {
      _flipController.forward();
    }
  }

  @override
  void didUpdateWidget(TarotCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _flipController.forward();
    } else if (!widget.isRevealed && oldWidget.isRevealed) {
      _flipController.reverse();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 200.0;
    final cardHeight = widget.height ?? 300.0;
    
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flipController, _scaleController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_flipAnimation.value * 3.14159),
                alignment: Alignment.center,
                child: _flipAnimation.value < 0.5
                    ? _buildCardBack(cardWidth, cardHeight)
                    : Transform(
                        transform: Matrix4.identity()..rotateY(3.14159),
                        alignment: Alignment.center,
                        child: _buildCardFront(cardWidth, cardHeight),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBack(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: FutureBuilder<String>(
          future: CardBackService.getCurrentBackImageUrl(),
          builder: (context, snapshot) {
            final backUrl = snapshot.data ?? 'assets/images/tarot/cat/back.png';
            return Image.asset(
              backUrl,
              fit: BoxFit.cover,
              width: width,
              height: height,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 卡片图像区域
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusM),
                  topRight: Radius.circular(AppTheme.radiusM),
                ),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusM),
                  topRight: Radius.circular(AppTheme.radiusM),
                ),
                child: _buildCardImage(),
              ),
            ),
          ),
          
          // 卡片信息区域
          if (widget.showDetails)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.radiusM),
                    bottomRight: Radius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.card.nameJa,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.card.nameEn,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall - 2,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _isMajorArcana()
                                ? AppTheme.primaryColor
                                : AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getSuitName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isMajorArcana()
                              ? AppIcons.star
                              : AppIcons.style,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    return Image.asset(
      widget.card.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // 如果图片加载失败，使用占位符
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppIcons.imageNotSupported,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  widget.card.nameEn,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isMajorArcana() {
    return widget.card.filename.toLowerCase().startsWith('major_');
  }

  String _getSuitName() {
    final filename = widget.card.filename.toLowerCase();
    
    if (filename.startsWith('major_')) {
      return '大アルカナ';
    } else if (filename.contains('wands')) {
      return 'ワンド';
    } else if (filename.contains('cups')) {
      return 'カップ';
    } else if (filename.contains('swords')) {
      return 'ソード';
    } else if (filename.contains('pentacles')) {
      return 'ペンタクル';
    } else {
      return '不明';
    }
  }
} 