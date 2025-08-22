import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../themes/tokens.dart';
import '../../themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

class DesignTokensScreen extends ConsumerWidget {
  const DesignTokensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(appStringsProvider).labelDesignTokens),
        backgroundColor: currentTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: ref.watch(appStringsProvider).buttonToggleTheme,
            onSelected: (themeName) {
              ref.read(themeProvider.notifier).setTheme(themeName);
            },
            itemBuilder: (context) {
              return AppThemes.themes.entries.map((entry) {
                final themeName = entry.key;
                final themeData = entry.value;
                return PopupMenuItem(
                  value: themeName,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeData.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(themeData.name),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前主题信息
            _buildCurrentThemeInfo(currentTheme),
            const SizedBox(height: 32),
            
            // 颜色令牌
            _buildColorSection(currentTheme, dynamicTokens),
            const SizedBox(height: 32),
            
            // 间距令牌
            _buildSpacingSection(),
            const SizedBox(height: 32),
            
            // 圆角令牌
            _buildRadiusSection(),
            const SizedBox(height: 32),
            
            // 字体令牌
            _buildTypographySection(),
            const SizedBox(height: 32),
            
            // 阴影令牌
            _buildShadowSection(),
            const SizedBox(height: 32),
            
            // 动画令牌
            _buildAnimationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentThemeInfo(AppThemeData currentTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ref.watch(appStringsProvider).labelCurrentTheme, style: TextStyle(fontSize: 18, fontWeight: DynamicTokens.fontWeightBold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: currentTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTheme.name,
                      style: TextStyle(fontWeight: DynamicTokens.fontWeightSemiBold),
                    ),
                    Text(
                      _colorToHex(currentTheme.primaryColor),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (currentTheme.backgroundImage != null) ...[
              const SizedBox(height: 8),
              Text(
                '${ref.watch(appStringsProvider).labelBackgroundImage}: ${currentTheme.backgroundImage}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection(AppThemeData currentTheme, DynamicTokens dynamicTokens) {
    final colors = [
      ('Primary', currentTheme.primaryColor),
      ('Background', currentTheme.backgroundColor),
      ('Surface', currentTheme.surfaceColor),
      ('Text Primary', dynamicTokens.textPrimary),
      ('Text Secondary', dynamicTokens.textSecondary),
      ('Text Tertiary', dynamicTokens.textTertiary),
      ('Text Inverse', dynamicTokens.textInverse),
      ('Border', DesignTokens.borderColor),
    ];

    return _buildSection(
              title: ref.watch(appStringsProvider).labelColors,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final (name, color) = colors[index];
            return _buildColorTile(name, color);
          },
        ),
      ],
    );
  }

  Widget _buildColorTile(String name, Color color) {
    final hex = _colorToHex(color);
    return GestureDetector(
      onTap: () => _copyToClipboard(hex),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 12,
                        fontWeight: DynamicTokens.fontWeightMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      hex,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpacingSection() {
    final spacings = [
      ('XS', DesignTokens.spacingXs),
      ('SM', DesignTokens.spacingSm),
      ('MD', DesignTokens.spacingMd),
      ('LG', DesignTokens.spacingLg),
      ('XL', DesignTokens.spacingXl),
      ('XXL', DesignTokens.spacingXxl),
    ];

    return _buildSection(
              title: ref.watch(appStringsProvider).labelSpacing,
      children: [
        Column(
          children: spacings.map((spacing) {
            final (name, value) = spacing;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      name,
                      style: TextStyle(fontWeight: DynamicTokens.fontWeightMedium),
                    ),
                  ),
                  Container(
                    height: 24,
                    width: value,
                    decoration: BoxDecoration(
                      color: Colors.blue[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${value.toInt()}px',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRadiusSection() {
    final radii = [
      ('XS', DesignTokens.radiusXs),
      ('SM', DesignTokens.radiusSm),
      ('MD', DesignTokens.radiusMd),
      ('LG', DesignTokens.radiusLg),
    ];

    return _buildSection(
              title: ref.watch(appStringsProvider).labelBorderRadius,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: radii.length,
          itemBuilder: (context, index) {
            final (name, radius) = radii[index];
            return Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.purple[300],
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(fontSize: 12,
                    fontWeight: DynamicTokens.fontWeightMedium,
                  ),
                ),
                Text(
                  '${radius.toInt()}px',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypographySection() {
    return _buildSection(
              title: ref.watch(appStringsProvider).labelTypography,
      children: [
        _buildTypographyExample('Headline Large', DesignTokens.fontFamilyHeadline, DesignTokens.fontSizeHeadlineLarge, DynamicTokens.fontWeightBold),
        _buildTypographyExample('Headline Medium', DesignTokens.fontFamilyHeadline, DesignTokens.fontSizeHeadlineMedium, DynamicTokens.fontWeightSemiBold),
        _buildTypographyExample('Title Large', DesignTokens.fontFamilyHeadline, DesignTokens.fontSizeTitleLarge, DynamicTokens.fontWeightSemiBold),
        _buildTypographyExample('Body Large', DesignTokens.fontFamilyBody, DesignTokens.fontSizeBodyLarge, DynamicTokens.fontWeightRegular),
        _buildTypographyExample('Body Medium', DesignTokens.fontFamilyBody, DesignTokens.fontSizeBodyMedium, DynamicTokens.fontWeightRegular),
        _buildTypographyExample('Body Small', DesignTokens.fontFamilyBody, DesignTokens.fontSizeBodySmall, DynamicTokens.fontWeightRegular),
      ],
    );
  }

  Widget _buildTypographyExample(String name, String fontFamily, double fontSize, FontWeight fontWeight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name - $fontFamily',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
          Text(
            'Font: $fontFamily, Size: ${fontSize.toInt()}px, Weight: ${fontWeight.toString().split('.').last}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowSection() {
    return _buildSection(
              title: ref.watch(appStringsProvider).labelShadows,
      children: [
        Container(
          width: double.infinity,
          height: 120,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            boxShadow: DesignTokens.shadowCard,
          ),
          child: const Center(
            child: Text('Card Shadow'),
          ),
        ),
        Text(
          'Box Shadow: ${DesignTokens.shadowCard.toString()}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationSection() {
    return _buildSection(
              title: ref.watch(appStringsProvider).labelAnimation,
      children: [
        Row(
          children: [
            const Text('Duration: '),
            Text(
              '${DesignTokens.animationDuration.inMilliseconds}ms',
              style: TextStyle(fontFamily: 'monospace',
                fontWeight: DynamicTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Curve: '),
            Text(
              DesignTokens.animationCurve.toString(),
              style: TextStyle(fontFamily: 'monospace',
                fontWeight: DynamicTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20,
            fontWeight: DynamicTokens.fontWeightBold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}
