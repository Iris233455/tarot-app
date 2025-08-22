import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
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
                Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(isActive ? 'プレミアム期間延長' : 'プレミアムプラン'),
              ],
            ),
            loading: () => Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Text('プレミアムプラン'),
              ],
            ),
            error: (error, stack) => Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Text('プレミアムプラン'),
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
                gradient: LinearGradient(
                  colors: [Colors.amber.shade50, Colors.orange.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プレミアム特典',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('広告なしでスムーズな体験', Icons.block),
                  _buildBenefitItem('無制限のタロット解読', Icons.all_inclusive),
                  _buildBenefitItem('プレミアムカードデザイン', Icons.style),
                  _buildBenefitItem('優先サポート', Icons.support_agent),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'プランを選択',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade700,
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
                                color: isSelected ? Colors.amber : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected ? Colors.amber.shade50 : Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? Colors.amber : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.amber.shade800 : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        product.price,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.amber.shade800 : Colors.black87,
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
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: selectedProductId != null ? () async {
            Navigator.of(context).pop();
            await _purchaseProduct(selectedProductId!);
          } : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: const Text('今すぐ購読'),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.amber.shade700)),
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
            const SnackBar(content: Text('🎉 購読が完了しました！'), backgroundColor: Colors.green),
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


