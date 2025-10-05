import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:mystic_tarot_jp/providers/subscription_provider.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';

class SubscriptionPurchaseDialog extends StatefulWidget {
  final WidgetRef ref;
  final VoidCallback? onPurchaseSuccess;

  const SubscriptionPurchaseDialog({super.key, required this.ref, this.onPurchaseSuccess});

  @override
  State<SubscriptionPurchaseDialog> createState() => _SubscriptionPurchaseDialogState();
}

class _SubscriptionPurchaseDialogState extends State<SubscriptionPurchaseDialog> {
  String? selectedProductId;

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = widget.ref.watch(dynamicTokensProvider);

    return AlertDialog(
      title: Consumer(
        builder: (context, ref, child) {
          final hasActiveSubscription = ref.watch(hasActiveSubscriptionProvider);
          return hasActiveSubscription.when(
            data: (isActive) => Row(
              children: [
                Icon(AppIcons.workspacePremium, color: dynamicTokens.primaryColor, size: 28),
                const SizedBox(width: 8),
                const Text('プレミアムプラン', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
              ],
            ),
            loading: () => Row(
              children: [
                Icon(AppIcons.workspacePremium, color: dynamicTokens.primaryColor, size: 28),
                const SizedBox(width: 8),
                const Text('プレミアムプラン', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
              ],
            ),
            error: (error, stack) => Row(
              children: [
                Icon(AppIcons.workspacePremium, color: dynamicTokens.primaryColor, size: 28),
                const SizedBox(width: 8),
                const Text('プレミアムプラン', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dynamicTokens.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dynamicTokens.primaryColor.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プレミアム特典',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: DynamicTokens.textBlack87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('広告なしでスムーズな体験', AppIcons.block),
                  _buildBenefitItem('無制限のタロット解読', AppIcons.autoAwesome),
                  _buildBenefitItem('プレミアムカードデザイン', AppIcons.style),
                  _buildBenefitItem('優先サポート', AppIcons.infoOutline),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'プランを選択',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: DynamicTokens.textBlack87,
              ),
            ),
            const SizedBox(height: 12),

            Consumer(
              builder: (context, ref, child) {
                final availableProducts = ref.watch(availableProductsProvider);

                return availableProducts.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const Text('利用可能なプランがありません');
                    }
                    // 初次打开时默认选中第一个产品
                    selectedProductId ??= products.first.id;

                    return Column(
                      children: products.map((product) {
                        final isSelected = selectedProductId == product.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedProductId = product.id;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? dynamicTokens.primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected ? dynamicTokens.primaryColor.withOpacity(0.06) : Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? AppIcons.checkCircle : AppIcons.radio_button_off,
                                  color: isSelected ? dynamicTokens.primaryColor : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: DynamicTokens.textBlack87,
                                        ),
                                      ),
                                      Text(
                                        product.price,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: DynamicTokens.textBlack87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('エラー: $error'),
                );
              },
            ),

            const SizedBox(height: 16),
            const Text(
              '現在はテスト環境のため、実際の課金は発生しません。',
              style: TextStyle(fontSize: 12, color: DynamicTokens.textGrey600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル', style: TextStyle(color: DynamicTokens.textGrey600)),
        ),
        Consumer(
          builder: (context, ref, child) {
            final productsAsync = ref.watch(availableProductsProvider);
            final String? effectiveSelectedId = productsAsync.maybeWhen(
              data: (products) => selectedProductId ?? (products.isNotEmpty ? products.first.id : null),
              orElse: () => selectedProductId,
            );
            return ElevatedButton(
              onPressed: effectiveSelectedId != null ? () async {
                Navigator.of(context).pop();
                await _purchaseProduct(effectiveSelectedId!);
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: dynamicTokens.primaryColor, foregroundColor: DynamicTokens.textWhite),
              child: const Text('今すぐ購読'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: widget.ref.watch(dynamicTokensProvider).primaryColor),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, color: DynamicTokens.textBlack87)),
        ],
      ),
    );
  }

  Future<void> _purchaseProduct(String productId) async {
    try {
      final success = await SubscriptionService.purchaseSubscription(productId);
      if (success) {
        widget.ref.invalidate(subscriptionStatusProvider);
        widget.ref.invalidate(hasActiveSubscriptionProvider);
        widget.ref.invalidate(subscriptionExpiryProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: DynamicTokens.textSuccess,
              content: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.checkCircle, color: DynamicTokens.textWhite),
                  SizedBox(width: 8),
                  Text('購読が完了しました！', style: TextStyle(color: DynamicTokens.textWhite)),
                ],
              ),
            ),
          );
        }

        if (widget.onPurchaseSuccess != null) {
          widget.onPurchaseSuccess!.call();
        }
      }
    } catch (e) {
      debugPrint('🛒 購入エラー: $e');
    }
  }
}


