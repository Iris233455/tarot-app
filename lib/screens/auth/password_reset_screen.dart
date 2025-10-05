import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/core/config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// 发送密码重置邮件
  Future<void> _sendResetEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'メールアドレスを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 直接发送重置邮件并统一显示"发送成功"（避免用户枚举）
      // 优先使用构建时注入的公开URL，避免开发/生产端口不一致导致回调异常
      // 仅在 Web 下读取 Uri.base.origin；原生环境 Uri.base 为 file:// 会抛异常
      String redirect;
      if (kIsWeb) {
        final origin = SupabaseConfig.appPublicUrl.isNotEmpty
            ? SupabaseConfig.appPublicUrl
            : (() {
                final scheme = Uri.base.scheme;
                if (scheme == 'http' || scheme == 'https') {
                  return Uri.base.origin;
                }
                // 开发期兜底
                return 'http://localhost:5173';
              })();
        redirect = '$origin/password-reset-complete';
      } else {
        redirect = SupabaseConfig.nativeCallbackUrl;
      }
      await SupabaseService.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: redirect,
      );
      
      if (mounted) {
        setState(() {
          _emailSent = true;
        });
      }
    } catch (e) {
      print('❌ 密码重置错误: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'パスワードリセット用メールの送信に失敗しました。\n'
                        'メールアドレスをご確認ください。';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowBack, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'パスワードリセット',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // 标题和说明
              FadeInDown(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _emailSent ? 'メール送信完了' : 'パスワードを忘れた方',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _emailSent
                              ? 'パスワードリセット用のリンクを送信しました。'
                              : 'パスワードリセット用のリンクをお送りします。\nメールアドレスを入力してください。',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (_emailSent) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(AppIcons.emailOutlined, size: 16),
                              SizedBox(width: 6),
                              Expanded(child: Text('メールをご確認ください')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(AppIcons.link, size: 16),
                              SizedBox(width: 6),
                              Expanded(child: Text('リンクをクリックして新しいパスワードを設定')),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(AppIcons.warningAmber, size: 16, color: DynamicTokens.textWarning),
                              SizedBox(width: 6),
                              Expanded(child: Text('重要：このブラウザでリンクを開いてください')),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              if (!_emailSent)
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'メールアドレス',
                          prefixIcon: const Icon(AppIcons.emailOutlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'リセット用メールを送信',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DynamicTokens.spacingMd),
                    decoration: BoxDecoration(
                      color: DynamicTokens.textSuccess.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                      border: Border.all(color: DynamicTokens.textSuccess.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 48,
                          color: DynamicTokens.textSuccess,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _emailController.text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'にパスワードリセット用のメールを送信しました。',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(AppIcons.emailOutlined, size: 16),
                                SizedBox(width: 6),
                                Expanded(child: Text('メールのリンクをクリックすると、安全なページでパスワードを変更できます。')),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(AppIcons.warningAmber, size: 16, color: DynamicTokens.textWarning),
                                SizedBox(width: 6),
                                Expanded(child: Text('重要：このブラウザでリンクを開いてください')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // 返回登录页面
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'ログインページに戻る',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
