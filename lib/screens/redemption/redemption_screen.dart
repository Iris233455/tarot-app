import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/services/redemption_service.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';
import 'package:mystic_tarot_jp/providers/subscription_provider.dart';
import 'package:mystic_tarot_jp/providers/auth_state_provider.dart';
import 'package:mystic_tarot_jp/widgets/loading_overlay.dart';
import 'package:mystic_tarot_jp/screens/redemption/qr_scanner_screen.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';

class RedemptionScreen extends ConsumerStatefulWidget {
  const RedemptionScreen({super.key});

  @override
  ConsumerState<RedemptionScreen> createState() => _RedemptionScreenState();
}

class _RedemptionScreenState extends ConsumerState<RedemptionScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  RedemptionResult? _lastCheckResult;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 格式化输入的兑换码
  void _formatCodeInput(String value) {
    final formatted = RedemptionService.formatCode(value);
    final displayFormatted = RedemptionService.formatCodeForDisplay(formatted);
    
    if (_codeController.text != displayFormatted) {
      _codeController.value = TextEditingValue(
        text: displayFormatted,
        selection: TextSelection.collapsed(offset: displayFormatted.length),
      );
    }
  }

  /// 检查兑换码
  Future<void> _checkCode() async {
    final code = _codeController.text.replaceAll(' ', '');
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = '引き換えコードを入力してください';
        _successMessage = null;
        _lastCheckResult = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await RedemptionService.checkRedemptionCode(code);
      
      setState(() {
        _lastCheckResult = result;
        if (result.success) {
          _successMessage = result.message;
          _errorMessage = null;
        } else {
          _errorMessage = result.message;
          _successMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '確認に失敗しました。もう一度お試しください';
        _successMessage = null;
        _lastCheckResult = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 使用兑换码
  Future<void> _redeemCode() async {
    // 检查用户类型：匿名用户无法使用兑换码
    final authState = ref.read(authStateProvider);
    if (authState.isAnonymous) {
      setState(() {
        _errorMessage = 'ゲストユーザーは引き換えコードを使用できません。メール登録が必要です。';
        _successMessage = null;
      });
      return;
    }
    
    final code = _codeController.text.replaceAll(' ', '');
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = '引き換えコードを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await RedemptionService.redeemCode(code);
      
      if (result.success) {
        // 兑换成功，强制刷新订阅状态
        ref.invalidate(subscriptionStatusProvider);
        ref.invalidate(hasActiveSubscriptionProvider);
        ref.invalidate(subscriptionExpiryProvider);
        
        // 显示成功对话框
        _showSuccessDialog(result);
      } else {
        setState(() {
          _errorMessage = result.message;
          _successMessage = null;
          _lastCheckResult = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '引き換えに失敗しました。もう一度お試しください';
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示成功对话框
  void _showSuccessDialog(RedemptionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(AppIcons.checkCircle, color: DynamicTokens.textSuccess, size: 32),
            SizedBox(width: 12),
            Text('引き換え完了！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(DynamicTokens.spacingSm),
              decoration: BoxDecoration(
                color: DynamicTokens.textSuccess.withOpacity(0.06),
                borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
                border: Border.all(color: DynamicTokens.textSuccess.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.star, color: DynamicTokens.textSuccess),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${result.days}日間のプレミアムサービスを取得しました。',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: DynamicTokens.textSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 返回上级页面
            },
            child: const Text('完了'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final subscriptionExpiry = ref.watch(subscriptionExpiryProvider);
              return subscriptionExpiry.when(
                data: (expiry) => expiry != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: DynamicTokens.spacingSm),
                        child: Text(
                          '新しい期限: ${expiry.year}/${expiry.month}/${expiry.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: DynamicTokens.textSuccess,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 打开扫码页面
  Future<void> _openQRScanner() async {
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );
      
      if (result != null && result.isNotEmpty) {
        _codeController.text = RedemptionService.formatCodeForDisplay(result);
        _checkCode();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'スキャンに失敗しました。引き換えコードを入力してください';
      });
    }
  }

  /// 粘贴剪贴板内容
  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      if (data?.text != null && data!.text!.isNotEmpty) {
        final code = RedemptionService.formatCode(data.text!);
        _codeController.text = RedemptionService.formatCodeForDisplay(code);
        _checkCode();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ペーストできません。引き換えコードを入力してください';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(AppIcons.infoOutline, color: DynamicTokens.textInfo),
            const SizedBox(width: 8),
            Text(
              '引き換えコード',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: DynamicTokens.textInfo,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: DynamicTokens.textBlack87,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DynamicTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 说明文本
              Container(
                padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                decoration: BoxDecoration(
                  color: DynamicTokens.textInfo.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                  border: Border.all(color: DynamicTokens.textInfo.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.infoOutline, color: DynamicTokens.textInfo),
                        const SizedBox(width: 8),
                        Text(
                          '引き換えコードについて',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: DynamicTokens.textInfo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '実物カードやイベントで入手した引き換えコードを入力すると、指定日数のプレミアムサービスを無料でご利用いただけます。',
                      style: TextStyle(height: 1.4),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: DynamicTokens.spacingXl),
              
              // 兑换码输入
              Text(
                '引き換えコードを入力',
                style: TextStyle(fontSize: DynamicTokens.fontSizeTitleLarge, fontWeight: FontWeight.w600),
              ),
              
              const SizedBox(height: DynamicTokens.spacingMd),
              
              TextFormField(
                controller: _codeController,
                onChanged: _formatCodeInput,
                decoration: InputDecoration(
                  hintText: '引き換えコードを入力してください',
                  prefixIcon: const Icon(AppIcons.confirmationNumber),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(AppIcons.paste),
                        onPressed: _pasteFromClipboard,
                        tooltip: 'ペースト',
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.qrCodeScanner),
                        onPressed: _openQRScanner,
                        tooltip: 'スキャン',
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                  ),
                  filled: true,
                  fillColor: DynamicTokens.textGrey500.withOpacity(0.06),
                ),
                style: TextStyle(
                  fontSize: DynamicTokens.fontSizeTitleMedium,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
              ),
              
              const SizedBox(height: DynamicTokens.spacingMd),
              
              // 错误或成功消息
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(DynamicTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: DynamicTokens.textError.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
                    border: Border.all(color: DynamicTokens.textError.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.errorOutline, color: DynamicTokens.textError),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: DynamicTokens.textError),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DynamicTokens.spacingMd),
              ],
              
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(DynamicTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: DynamicTokens.textSuccess.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(DynamicTokens.radiusSm),
                    border: Border.all(color: DynamicTokens.textSuccess.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.checkCircleOutline, color: DynamicTokens.textSuccess),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: DynamicTokens.textSuccess),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DynamicTokens.spacingMd),
              ],
              
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _checkCode,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: DynamicTokens.spacingMd),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                        ),
                      ),
                      child: const Text('コードを確認'),
                    ),
                  ),
                  const SizedBox(width: DynamicTokens.spacingSm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _lastCheckResult?.success != true) 
                          ? null 
                          : _redeemCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: DynamicTokens.spacingMd),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                        ),
                      ),
                      child: const Text(
                        '今すぐ引き換える',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DynamicTokens.spacingXl),
              
              // 使用说明
              Text(
                '使用方法',
                style: TextStyle(fontSize: DynamicTokens.fontSizeTitleMedium, fontWeight: FontWeight.w600),
              ),
              
              const SizedBox(height: DynamicTokens.spacingSm),
              
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoItem(
                    icon: AppIcons.infoOutline,
                    text: '各引き換えコードは1回のみ使用可能です',
                  ),
                  _InfoItem(
                    icon: AppIcons.schedule,
                    text: '一部の引き換えコードには有効期限があります',
                  ),
                  _InfoItem(
                    icon: AppIcons.personAdd,
                    text: 'コードを利用する前にアカウントへログインしてください',
                  ),
                  _InfoItem(
                    icon: AppIcons.checkCircle,
                    text: '引き換えた日数は現在のプレミアム期間に加算されます',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _InfoItem({
    required this.icon,
    required this.text,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: DynamicTokens.textGrey600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: DynamicTokens.textGrey600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
