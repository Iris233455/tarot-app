import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase hide AuthState;
import 'package:mystic_tarot_jp/providers/auth_state_provider.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';
import 'package:mystic_tarot_jp/core/config/supabase_config.dart';
import 'package:flutter/foundation.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> 
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _loadingGoogle = false;
  String? _errorMessage;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      // 清掉错误 & 注册 tab 切换时清二次密码
      setState(() {
        _errorMessage = null;
        if (_tabController.index == 0) {
          _confirmPasswordController.clear();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await ref.read(authStateProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインしました'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // 延迟导航确保认证状态完全更新
        await Future.delayed(const Duration(milliseconds: 200));
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        // 简化错误提示
        if (e.toString().contains('Invalid login credentials')) {
          _showErrorToast('メールアドレスまたはパスワードが正しくありません');
        } else {
          _showErrorToast('ログインに失敗しました');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await ref.read(authStateProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントを作成しました'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // 延迟导航确保认证状态完全更新
        await Future.delayed(const Duration(milliseconds: 200));
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('User already registered')) {
          _showErrorToast('このメールアドレスは既に登録されています');
        } else {
          _showErrorToast('アカウント作成に失敗しました');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await ref.read(authStateProvider.notifier).signInAnonymously();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ゲストとしてログインしました'),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('ゲストログインに失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      print('🔄 AuthScreen: 开始Google登录流程...');
      
      await ref.read(authStateProvider.notifier).signInWithGoogle();
      
      // 验证登录是否真正成功（避免widget销毁后使用ref）
      if (mounted) {
        final authState = ref.read(authStateProvider);
        print('🔄 AuthScreen: 验证登录状态: ${authState.authState}');
        
        if (authState.authState == AuthState.authenticated && !authState.isAnonymous) {
          print('✅ AuthScreen: Google登录验证成功，跳转到主页');
          
          _showSuccessToast('Googleアカウントでログインしました');
          context.go('/');
          return; // 立即返回，避免后续代码执行
        } else {
          print('❌ AuthScreen: 登录后状态验证失败');
          _showErrorToast('Googleログインに失敗しました');
        }
      }
    } catch (e) {
      print('❌ AuthScreen: Google登录异常: $e');
      
      // 简化错误提示
      if (e.toString().contains('sign_in_canceled')) {
        // 用户取消，不显示错误
        return;
      } else {
        _showErrorToast('Googleログインに失敗しました');
      }
    }
  }

  /// 显示成功提示
  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误提示
  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleSubmit() async {
    if (_isLoading) return; // 防重复
    final email = _emailController.text.trim();
    final pwd   = _passwordController.text;

    // 基础校验
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailOk) {
      setState(() => _errorMessage = 'メールアドレスの形式が正しくありません');
      return;
    }
    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _errorMessage = 'メールアドレスとパスワードを入力してください');
      return;
    }

    // 注册附加校验
    if (_tabController.index == 1) {
      if (_confirmPasswordController.text.isEmpty) {
        setState(() => _errorMessage = 'パスワード確認を入力してください');
        return;
      }
      if (pwd != _confirmPasswordController.text) {
        setState(() => _errorMessage = 'パスワードが一致しません');
        return;
      }
      if (pwd.length < 8) {
        setState(() => _errorMessage = 'パスワードは8文字以上で設定してください');
        return;
      }
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      if (_tabController.index == 0) {
        await ref.read(authStateProvider.notifier).signInWithEmail(email, pwd);
        if (!mounted) return;
        _showSuccessToast('ログインしました');
      } else {
        await ref.read(authStateProvider.notifier).signUpWithEmail(email, pwd);
        if (!mounted) return;
        _showSuccessToast('アカウントを作成しました');
      }
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.toString().contains('Invalid login credentials')) {
          _errorMessage = 'メールアドレスまたはパスワードが正しくありません';
        } else if (e.toString().contains('User already registered')) {
          _errorMessage = 'このメールアドレスは既に登録されています';
        } else {
          _errorMessage = '処理に失敗しました。しばらくしてからお試しください';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 跳转到密码重置页面
  void _resetPassword() {
    print('🔄 点击忘记密码，跳转到密码重置页面');
    try {
      context.push('/password-reset');
      print('✅ 成功跳转到 /password-reset');
    } catch (e) {
      print('❌ 跳转失败: $e');
      // 备用方案：直接在当前页面显示重置功能
      _showPasswordResetDialog();
    }
  }

  /// 备用方案：在对话框中处理密码重置（极简安全写法）
  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('パスワードリセット'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('パスワードリセット用のメールアドレスを入力してください：'),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  String redirect;
                  if (kIsWeb) {
                    final origin = SupabaseConfig.appPublicUrl.isNotEmpty
                        ? SupabaseConfig.appPublicUrl
                        : (() {
                            final scheme = Uri.base.scheme;
                            if (scheme == 'http' || scheme == 'https') {
                              return Uri.base.origin;
                            }
                            return 'http://localhost:5173';
                          })();
                    redirect = '$origin/password-reset-complete';
                  } else {
                    redirect = SupabaseConfig.nativeCallbackUrl;
                  }
                  await SupabaseService.client.auth.resetPasswordForEmail(
                    ctrl.text.trim(),
                    redirectTo: redirect,
                  );
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _showSuccessToast('パスワードリセット用のメールを送信しました');
                } catch (e) {
                  if (!mounted) return;
                  _showErrorToast('送信に失敗しました');
                } finally {
                  ctrl.dispose(); // 立刻释放
                }
              },
              child: const Text('送信'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logo & Title
              FadeInDown(
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mystic Tarot',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'あなたの運命を占います',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Auth Form
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Card(
                  elevation: 8,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // Tab Bar
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: theme.colorScheme.primary,
                            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                            indicator: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tabs: const [
                              Tab(text: 'ログイン'),
                              Tab(text: '新規登録'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Error Message
                        if (_errorMessage != null) ...[
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
                          const SizedBox(height: 16),
                        ],
                        
                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          onChanged: (_) { 
                            if (_errorMessage != null) setState(() => _errorMessage = null); 
                          },
                          decoration: const InputDecoration(
                            labelText: 'メールアドレス',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          textInputAction: _tabController.index == 0 ? TextInputAction.done : TextInputAction.next,
                          onSubmitted: _tabController.index == 0 ? (_) => _handleSubmit() : null,
                          autofillHints: const [AutofillHints.password],
                          onChanged: (_) { 
                            if (_errorMessage != null) setState(() => _errorMessage = null); 
                          },
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                        ),
                        
                        // 注册时显示确认密码字段
                        if (_tabController.index == 1) ...[
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_confirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSubmit(),
                            autofillHints: const [AutofillHints.newPassword],
                            onChanged: (_) { 
                              if (_errorMessage != null) setState(() => _errorMessage = null); 
                            },
                            decoration: InputDecoration(
                              labelText: 'パスワード確認',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // 密码规则提示
                          Text(
                            'パスワードは8文字以上で設定してください。',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
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
                                : Text(
                                    _tabController.index == 0 ? 'ログイン' : '新規登録',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        
                        // 忘记密码链接（仅在登录tab显示）
                        if (_tabController.index == 0) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'パスワードを忘れた方はこちら',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'または',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Google Sign In
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loadingGoogle ? null : () async {
                      setState(() => _loadingGoogle = true);
                      try {
                        await _signInWithGoogle();
                      } finally {
                        if (mounted) setState(() => _loadingGoogle = false);
                      }
                    },
                    icon: _loadingGoogle 
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                    label: Text(_loadingGoogle ? 'Googleでログイン中...' : 'Googleでログイン'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Guest Access
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _signInAnonymously,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.colorScheme.outline),
                        ),
                        child: const Text('ゲストとして利用'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '※ ゲストモードではデータが保存されません',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}