import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/services/redemption_service.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';
import 'package:mystic_tarot_jp/providers/subscription_provider.dart';
import 'package:mystic_tarot_jp/providers/auth_state_provider.dart';
import 'package:mystic_tarot_jp/widgets/loading_overlay.dart';
import 'package:mystic_tarot_jp/screens/redemption/qr_scanner_screen.dart';

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
            Icon(Icons.check_circle, color: Colors.green, size: 32),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${result.days}日間のプレミアムサービスを取得しました。',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
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
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '新しい期限: ${expiry.year}/${expiry.month}/${expiry.day}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
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
        title: const Text('引き換えコード'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 说明文本
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                          Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '引き換えコードについて',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
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
              
              const SizedBox(height: 32),
              
              // 兑换码输入
              Text(
                '引き換えコードを入力',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _codeController,
                onChanged: _formatCodeInput,
                decoration: InputDecoration(
                  hintText: '引き換えコードを入力してください',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: _pasteFromClipboard,
                        tooltip: 'ペースト',
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _openQRScanner,
                        tooltip: 'スキャン',
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
              ),
              
              const SizedBox(height: 16),
              
              // 错误或成功消息
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _checkCode,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('コードを確認'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _lastCheckResult?.success != true) 
                          ? null 
                          : _redeemCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '今すぐ引き換える',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 使用说明
              Text(
                '使用方法',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoItem(
                    icon: Icons.info,
                    text: '各引き換えコードは1回のみ使用可能です',
                  ),
                  _InfoItem(
                    icon: Icons.schedule,
                    text: '一部の引き換えコードには有効期限があります',
                  ),
                  _InfoItem(
                    icon: Icons.person,
                    text: 'コードを利用する前にアカウントへログインしてください',
                  ),
                  _InfoItem(
                    icon: Icons.add_circle,
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
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
