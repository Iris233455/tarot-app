import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:mystic_tarot_jp/services/supabase_service.dart';

class PasswordResetCompleteScreen extends StatefulWidget {
  const PasswordResetCompleteScreen({super.key});

  @override
  State<PasswordResetCompleteScreen> createState() => _PasswordResetCompleteScreenState();
}

class _PasswordResetCompleteScreenState extends State<PasswordResetCompleteScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isValidResetLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await SupabaseService.client.auth.getSessionFromUrl(Uri.base);
        if (!mounted) return;
        setState(() => _isValidResetLink = true);
      } catch (_) {
        // フォールバック: 既にセッションが回復している（PASSWORD_RECOVERY イベント後）場合も有効とみなす
        try {
          final user = SupabaseService.currentUser;
          if (!mounted) return;
          if (user != null) {
            setState(() => _isValidResetLink = true);
          } else {
            setState(() => _errorMessage =
              'パスワードリセットのリンクが無効、または期限切れです。\n新しいリセットリンクを送信してください。');
          }
        } catch (_) {
          if (!mounted) return;
          setState(() => _errorMessage =
            'パスワードリセットのリンクが無効、または期限切れです。\n新しいリセットリンクを送信してください。');
        }
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 新しいパスワードで更新
  Future<void> _updatePassword() async {
    final pwd = _newPasswordController.text;
    final pwd2 = _confirmPasswordController.text;

    if (pwd.isEmpty || pwd2.isEmpty) {
      setState(() => _errorMessage = 'すべてのフィールドを入力してください');
      return;
    }
    if (pwd != pwd2) {
      setState(() => _errorMessage = 'パスワードが一致しません');
      return;
    }
    if (pwd.length < 8) {
      setState(() => _errorMessage = 'パスワードは8文字以上で設定してください');
      return;
    }

    if (_isLoading) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await SupabaseService.client.auth.updateUser(
        supabase.UserAttributes(password: pwd),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードが正常に更新されました'), backgroundColor: Colors.green),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.go('/auth');
    } catch (e) {
      if (!mounted) return;
      // よくあるケース: 新旧パスワードが同一
      final err = e.toString();
      print('❌ パスワード更新エラー: $err');
      String message;
      if (err.contains('New password should be different') ||
          err.contains('same as the old') ||
          err.contains('password should be different')) {
        message = '新しいパスワードは以前のパスワードと異なる必要があります';
      } else if (err.contains('expired') || err.contains('expired_action_link')) {
        message = 'リンクの有効期限が切れています。もう一度リセットリンクを送信してください';
      } else if (err.contains('invalid') && err.contains('token')) {
        message = 'リセット用トークンが無効です。もう一度リセットリンクを送信してください';
      } else {
        message = 'パスワード更新に失敗しました。しばらくしてからお試しください';
      }
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.go('/auth'),
        ),
        title: Text(
          'パスワードリセット',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // 标题和图标
              FadeInDown(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isValidResetLink ? Icons.lock_reset : Icons.error_outline,
                      size: 64,
                      color: _isValidResetLink 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isValidResetLink 
                          ? '新しいパスワードを設定'
                          : 'パスワードリセットエラー',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isValidResetLink
                          ? 'リセットリンクを確認しました。新しいパスワードを設定してください。\nパスワードは8文字以上で設定してください。'
                          : 'パスワードリセットでエラーが発生しました。',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              if (_isValidResetLink) ...[
                // 新しいパスワード入力フィールド
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: TextField(
                    controller: _newPasswordController,
                    obscureText: !_isPasswordVisible,
                    onChanged: (_) { if (_errorMessage != null) setState(() => _errorMessage = null); },
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // パスワード確認フィールド
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    onChanged: (_) { if (_errorMessage != null) setState(() => _errorMessage = null); },
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _updatePassword(),
                    decoration: InputDecoration(
                      labelText: 'パスワード確認',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 更新ボタン
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'パスワードを更新',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
              
              // エラーメッセージ
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // 操作按钮
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/auth'),
                      icon: const Icon(Icons.login),
                      label: const Text('ログイン'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/password-reset'),
                      icon: const Icon(Icons.refresh),
                      label: const Text('再送信'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
