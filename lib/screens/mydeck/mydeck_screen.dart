import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mystic_tarot_jp/themes/tokens.dart';
import 'package:mystic_tarot_jp/screens/shop/base_shop_screen.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/widgets/themed_background.dart';
import 'package:mystic_tarot_jp/providers/theme_provider.dart';
import 'package:mystic_tarot_jp/screens/redemption/redemption_screen.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/tools/quick_test_setup.dart';
import 'package:mystic_tarot_jp/providers/deck_provider.dart';
import 'package:mystic_tarot_jp/services/card_back_service.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

import 'package:mystic_tarot_jp/providers/auth_state_provider.dart';
import 'package:mystic_tarot_jp/providers/daily_card_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/providers/subscription_provider.dart';
import 'package:mystic_tarot_jp/services/subscription_service.dart';
import 'package:mystic_tarot_jp/widgets/subscription_purchase_dialog.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:mystic_tarot_jp/core/ui/app_logo.dart';

class MyDeckScreen extends ConsumerStatefulWidget {
  const MyDeckScreen({super.key});

  @override
  ConsumerState<MyDeckScreen> createState() => _MyDeckScreenState();
}

class _MyDeckScreenState extends ConsumerState<MyDeckScreen> {
  // プロフィール設定
  String _name = '';
  String _openId = '';  // 新增：Open ID（显示名称）
  String _gender = '彼';
  DateTime _birthDate = DateTime.now();
  String _occupation = '';
  String _relationship = 'シングル';
  
  // 設定
  String _selectedBgm = 'none';
  String _selectedBackDesign = 'default';
  String _selectedBackDesignName = 'デフォルト';
  bool _dailyTarotEnabled = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  


  final List<String> _genderOptions = ['彼', '彼女', '彼ら'];
  final List<String> _relationshipOptions = [
    'シングル', '片思い', '交際中', '婚約中', '既婚', '離婚', '分からない'
  ];

  final List<Map<String, dynamic>> _bgmTracks = [
    {'name': 'なし', 'file': 'none'},
    {'name': '瞑想', 'file': 'meditation.mp3'},
    {'name': '自然音', 'file': 'nature.mp3'},
    {'name': 'クラシック', 'file': 'classical.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBackDesignSettings();
    _loadProfileData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // 统一的成功/失败提示样式
  void _showSuccessSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DynamicTokens.accentPremium,
        duration: duration,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.checkCircle, color: DynamicTokens.textWhite),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: DynamicTokens.textWhite)),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DynamicTokens.textError,
        duration: duration,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.errorOutline, color: DynamicTokens.textWhite),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: DynamicTokens.textWhite))),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBackDesignSettings() async {
    try {
      final selectedDesign = await CardBackService.getSelectedBackDesign();
      final availableDesigns = CardBackService.getAvailableBackDesigns();
      
      final designInfo = availableDesigns.firstWhere(
        (design) => design['type'] == selectedDesign,
        orElse: () => availableDesigns.first,
      );
      
      setState(() {
        _selectedBackDesign = selectedDesign;
        _selectedBackDesignName = designInfo['name'];
      });
    } catch (e) {
      print('背面設定の読み込みに失敗: $e');
    }
  }
  
  Future<void> _loadProfileData() async {
    try {
      final profileData = await SupabaseService.getUserProfile();
      if (profileData != null && mounted) {
        setState(() {
          _name = profileData['name'] ?? '';
          _openId = profileData['open_id'] ?? '';  // 新增
          _gender = profileData['gender'] ?? '彼';
          _occupation = profileData['occupation'] ?? '';
          _relationship = profileData['relationship_status'] ?? 'シングル';
          
          // 处理生日字段
          if (profileData['birth_date'] != null) {
            try {
              _birthDate = DateTime.parse(profileData['birth_date']);
            } catch (e) {
              // 如果日期格式有问题，使用默认值
              _birthDate = DateTime.now();
            }
          }
        });
      }
    } catch (e) {
      // 如果加载失败，使用默认值，不显示错误（可能是离线模式）
      print('Profile加载失败（可能在离线模式）: $e');
    }
  }
  
  Future<void> _saveProfileData() async {
    try {
      print('🔄 MyDeck: 开始保存Profile数据...');
      print('   名前: $_name');
      print('   性別: $_gender');
      print('   職業: $_occupation');
      print('   関係: $_relationship');
      
      await SupabaseService.upsertDetailedUserProfile(
        name: _name.isEmpty ? null : _name,
        gender: _gender,
        birthDate: _birthDate,
        occupation: _occupation.isEmpty ? null : _occupation,
        relationshipStatus: _relationship,
      );
      
      print('✅ MyDeck: Profile保存成功');
      
      // 显示成功提示
      if (mounted) {
        _showSuccessSnackBar('プロフィールを保存しました');
      }
      
    } catch (e) {
      print('❌ MyDeck: Profile保存失败: $e');
      
      // 显示详细的错误信息
      if (mounted) {
        _showErrorSnackBar('プロフィールの保存に失敗しました\n詳細: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final currentTheme = ref.watch(currentThemeNameProvider);
    final neutralTextColor = DynamicTokens.textBlack87;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 2,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        backgroundColor: dynamicTokens.backgroundColor,
        title: InkWell(
          onTap: () => context.go('/'),
          customBorder: const CircleBorder(),
          child: const AppLogo(size: 36),
        ),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? dynamicTokens.primaryColor.withOpacity(0.6)
              : dynamicTokens.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      body: ThemedBackground(
        child: SafeArea(
          child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          children: [
            // 标题
            FadeInDown(
              duration: DesignTokens.animationDuration,
              child: Text(
                'マイページ',
                style: TextStyle(
                  fontSize: DynamicTokens.fontSizeHeadlineMedium,
                  fontWeight: FontWeight.w600,
                  color: neutralTextColor,
                ),
              ),
            ),
            
            const SizedBox(height: DesignTokens.spacingSm),
            

            
            const SizedBox(height: DynamicTokens.spacingMd),
            
            // 1. テーマ
            _buildThemeSection(),
            
            // 2. マイデッキ
            _buildMyTarotSection(),
            
            // 3. プロフィール
            _buildProfileSection(),
            
            // 4. アカウント
            _buildAccountSection(),
            
            // 5. 設定
            _buildSettingsSection(),
          ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: neutralTextColor,
        unselectedItemColor: neutralTextColor,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/reading');
              break;
            case 2:
              context.go('/gallery');
              break;
            case 3:
              context.go('/mydeck');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(AppIcons.home),
            label: '毎日の占い',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.autoAwesome),
            label: 'スプレット',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.libraryBooks),
            label: 'ギャラリー',
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.style),
            label: 'マイページ',
          ),
        ],
      ),
    );
  }



  Widget _buildProfileSection() {
    return FadeInUp(
      duration: DynamicTokens.animationDuration,
      delay: const Duration(milliseconds: 100),
      child: _buildSection(
        title: 'プロフィール',
        subtitle: 'プロフィール',
        child: Column(
          children: [
            // ID (原Open ID)
            _buildProfileField(
              label: 'ID',
              value: _openId.isEmpty ? '未設定' : _openId,
              onTap: () => _showOpenIdDialog(),
            ),
            const Divider(),
            
            // Avatar URL 隐藏（需求：不显示该项）
            
            // 名前
            _buildProfileField(
              label: '名前',
              value: _name.isEmpty ? '未設定' : _name,
              onTap: () => _showNameDialog(),
            ),
            const Divider(),
            
            // 性別
            _buildProfileField(
              label: '性別',
              value: _gender,
              onTap: () => _showGenderDialog(),
            ),
            const Divider(),
            
            // 誕生日
            _buildProfileField(
              label: '誕生日',
              value: '${_birthDate.year}年${_birthDate.month}月${_birthDate.day}日 (${_getZodiacSign(_birthDate)})',
              onTap: () => _showBirthDatePicker(),
            ),
            const Divider(),
            
            // 職業
            _buildProfileField(
              label: '職業',
              value: _occupation.isEmpty ? '未設定' : _occupation,
              onTap: () => _showOccupationDialog(),
            ),
            const Divider(),
            
            // 恋愛関係
            _buildProfileField(
              label: '恋愛関係',
              value: _relationship,
              onTap: () => _showRelationshipDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final authState = ref.watch(authStateProvider);
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final hasActiveSubscription = ref.watch(hasActiveSubscriptionProvider);
    final currentLanguage = ref.watch(localizationServiceProvider);
    
    return FadeInUp(
      duration: DynamicTokens.animationDuration,
      delay: const Duration(milliseconds: 150),
      child: _buildSection(
        title: 'アカウント',
        subtitle: 'ログイン状態と購読情報',
        child: Column(
          children: [
            // 登录状态
            _buildProfileField(
              label: 'ログイン状態',
              value: _getAuthStatusText(authState),
              onTap: null, // 只读
            ),
            
            if (authState.authState == AuthState.authenticated) ...[
              const Divider(),
              
              // 用户信息
              if (authState.isAnonymous) 
                _buildProfileField(
                  label: 'アカウントタイプ',
                  value: 'ゲストユーザー',
                  onTap: null,
                )
              else
                _buildProfileField(
                  label: 'メールアドレス',
                  value: authState.email ?? '不明',
                  onTap: null,
                ),
              
              const Divider(),
              
              // 言語設定
              ListTile(
                leading: Icon(AppIcons.language, color: dynamicTokens.primaryColor),
                title: const Text(
                  '言語 / Language',
                  style: TextStyle(color: DynamicTokens.textBlack87),
                ),
                subtitle: Text(
                  currentLanguage.displayName,
                  style: const TextStyle(color: DynamicTokens.textBlack87),
                ),
                trailing: const Icon(AppIcons.arrowForwardIos),
                onTap: () => _showLanguageDialog(),
              ),
              
              const Divider(),
              
              // 用户ID + 未订阅时显示升级按钮
              ListTile(
                title: const Text(
                  'ユーザーID',
                  style: TextStyle(color: DynamicTokens.textBlack87),
                ),
                subtitle: Text(
                  authState.userId ?? '不明',
                  style: const TextStyle(color: DynamicTokens.textBlack87),
                ),
                trailing: hasActiveSubscription.when(
                  data: (isActive) {
                    if (isActive) return null;
                    return OutlinedButton.icon(
                      onPressed: () => _showSubscriptionPurchaseDialog(),
                      icon: const Icon(AppIcons.workspacePremium, size: 18),
                      label: const Text('プレミアム'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dynamicTokens.primaryColor,
                        side: BorderSide(color: dynamicTokens.primaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stack) => null,
                ),
              ),
              
              const Divider(),
              
              // 若已订阅，显示管理入口
              hasActiveSubscription.when(
                data: (isActive) {
                  if (!isActive) return const SizedBox.shrink();
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(AppIcons.manageAccounts, color: dynamicTokens.primaryColor),
                        title: const Text(
                          'プレミアム管理',
                          style: TextStyle(color: DynamicTokens.textBlack87),
                        ),
                        subtitle: const Text(
                          '購読の管理とキャンセル',
                          style: TextStyle(color: DynamicTokens.textBlack87),
                        ),
                        trailing: const Icon(AppIcons.arrowForwardIos),
                        onTap: () => _showSubscriptionManagementDialog(),
                      ),
                      const Divider(),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              
              // 引き換えコード（プレミアム管理の下）
              _buildRedemptionCodeButton(),
              const Divider(),
              
              // 本日のカードをリセット
              _buildProfileField(
                label: 'リセット',
                value: '本日のカードをリセット',
                onTap: () => _resetTodayCard(),
              ),
              
              const Divider(),
              
              // 履歴
              _buildProfileField(
                label: '履歴',
                value: '過去の占い結果を確認',
                onTap: () => context.go('/history'),
              ),
              
              const Divider(),
              
              // お気に入り（隐藏）
              // 已按要求隐藏该入口
              
              // 登出按钮
              _buildProfileField(
                label: 'ログアウト',
                value: 'アカウントからログアウト',
                onTap: () => _showLogoutDialog(),
              ),
              
              // 如果是匿名用户，显示升级选项
              if (authState.isAnonymous) ...[
                const Divider(),
                _buildProfileField(
                  label: 'アカウント作成',
                  value: 'データを永続保存するために',
                  onTap: () => _showUpgradeAccountDialog(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  String _getAuthStatusText(UserState authState) {
    switch (authState.authState) {
      case AuthState.loading:
        return '確認中...';
      case AuthState.authenticated:
        if (authState.isAnonymous) {
          return 'ゲスト';
        } else {
          // 检查登录方式 - 需要更精确的检测
          final user = authState.user;
          
          // 调试信息：打印user metadata
          print('🔍 Debug - 用户metadata:');
          print('   appMetadata: ${user?.appMetadata}');
          print('   userMetadata: ${user?.userMetadata}');
          print('   providers: ${user?.appMetadata?['providers']}');
          print('   provider: ${user?.appMetadata?['provider']}');
          
          // 检测Google登录的多种可能方式
          final isGoogleUser = user?.appMetadata?['provider'] == 'google' ||
                              user?.appMetadata?['providers']?.contains('google') == true ||
                              user?.userMetadata?['auth_provider'] == 'google_native' ||
                              user?.userMetadata?['google_id'] != null;
          
          if (isGoogleUser) {
            return 'Googleアカウント';
          } else {
            return 'メールアドレス';
          }
        }
      case AuthState.unauthenticated:
        return 'ログインしていません';
    }
  }
  
  /// 强制刷新认证状态 (调试用)
  void _forceRefreshAuthState() {
    final currentUser = SupabaseService.currentUser;
    final authState = ref.read(authStateProvider);
    
    print('🔧 Debug: 强制刷新认证状态');
    print('   当前用户: ${currentUser?.id}');
    print('   邮箱: ${currentUser?.email}');
    print('   原始isAnonymous: ${currentUser?.isAnonymous}');
    print('   最终isAnonymous: ${authState.isAnonymous}');
    print('   认证状态: ${authState.authState}');
    
    // 强制重新渲染Widget
    if (mounted) {
      setState(() {});
    }
    
    final userType = authState.isAnonymous ? 'ゲスト' : 'メール';
    _showSuccessSnackBar('認証状態を更新しました\nユーザータイプ: $userType\nメール: ${currentUser?.email}', duration: const Duration(seconds: 4));
  }
  
  /// 测试Google OAuth (诊断用)
  Future<void> _testGoogleOAuth() async {
    print('🧪 开始Google OAuth诊断测试...');
    
    try {
      // 检查widget是否还mounted
      if (!mounted) {
        print('❌ Widget已被disposed，无法执行测试');
        return;
      }
      
      // 直接开始Google OAuth（不先登出，避免触发匿名登录混乱）
      print('🚪 跳过登出，直接进行Google OAuth');
      
      // 如果当前为匿名用户，可选择登出，但此处先尝试直接OAuth
      // 如果需要强制登出可取消注释以下代码
      // if (SupabaseService.currentUser?.isAnonymous == true) {
      //   await SupabaseService.signOut();
      //   await Future.delayed(const Duration(milliseconds: 300));
      // }
      
      // 再次检查widget状态
      if (!mounted) {
        print('❌ Widget在等待期间被disposed');
        return;
      }
      
      // 尝试Google登录
      await ref.read(authStateProvider.notifier).signInWithGoogle();
      
      // 等待认证完成
      await Future.delayed(const Duration(seconds: 3));
      
      // 最后检查widget状态
      if (!mounted) {
        print('❌ Widget在登录期间被disposed');
        return;
      }
      
      final currentUser = SupabaseService.currentUser;
      final authState = ref.read(authStateProvider);
      
      print('🔍 Google OAuth测试结果:');
      print('   用户ID: ${currentUser?.id}');
      print('   邮箱: ${currentUser?.email}');
      print('   isAnonymous: ${currentUser?.isAnonymous}');
      print('   认证状态: ${authState.authState}');
      
      if (mounted) {
        _showSuccessSnackBar('Google OAuthテスト完了\nコンソールログで詳細を確認\nユーザーID: ${currentUser?.id}', duration: const Duration(seconds: 5));
      }
      
    } catch (e) {
      print('❌ Google OAuth测试失败: $e');
      if (mounted) {
        _showErrorSnackBar('Google OAuthテスト失敗\nエラー: $e', duration: const Duration(seconds: 5));
      }
    }
  }
  
  /// 重置今日卡片，允许重新抽牌
  Future<void> _resetTodayCard() async {
    // 先显示确认对话框
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('リセット', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
            SizedBox(height: 12),
            Text('本日のカードをリセットして、新しいカードを引き直しますか？', style: TextStyle(color: DynamicTokens.textBlack87)),
          ],
        ),
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // 清除今日的卡片记录
      await SupabaseService.clearTodayCard();
      
      // 清除前端的daily card provider缓存
      ref.invalidate(dailyCardProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DynamicTokens.accentPremium,
            duration: const Duration(seconds: 3),
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.checkCircle, color: DynamicTokens.textWhite),
                SizedBox(width: 8),
                Expanded(child: Text('本日のカードをリセットしました。新しいカードを引くことができます！', style: TextStyle(color: DynamicTokens.textWhite))),
              ],
            ),
          ),
        );
      }
      
    } catch (e) {
      print('❌ 本日のカードリセット失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DynamicTokens.textError,
            duration: const Duration(seconds: 3),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.errorOutline, color: DynamicTokens.textWhite),
                const SizedBox(width: 8),
                Expanded(child: Text('リセットに失敗しました: $e', style: const TextStyle(color: DynamicTokens.textWhite))),
              ],
            ),
          ),
        );
      }
    }
  }



  Widget _buildThemeSection() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final currentTheme = ref.watch(currentThemeNameProvider);
    
    return FadeInUp(
      duration: DynamicTokens.animationDuration,
      delay: const Duration(milliseconds: 200),
      child: _buildSection(
        title: 'テーマ',
        subtitle: 'テーマ',
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: DynamicTokens.spacingMd,
            mainAxisSpacing: DynamicTokens.spacingMd,
            childAspectRatio: 1,
          ),
          itemCount: AppThemes.themes.keys
              .where((k) => k == 'オーシャン' || k == 'ナイトスカイ' || k == 'ムーンライト')
              .length,
          itemBuilder: (context, index) {
            final filteredKeys = AppThemes.themes.keys
                .where((k) => k == 'オーシャン' || k == 'ナイトスカイ' || k == 'ムーンライト')
                .toList();
            final themeName = filteredKeys[index];
            final themeData = AppThemes.themes[themeName]!;
            final isSelected = currentTheme == themeName;
            
            return GestureDetector(
              onTap: () {
                ref.read(themeProvider.notifier).setTheme(themeName);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: themeData.primaryColor,
                  borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
                  border: isSelected 
                      ? Border.all(
                          color: DynamicTokens.textWhite,
                          width: 3,
                        )
                      : null,
                  boxShadow: isSelected ? DynamicTokens.shadowCard : null,
                ),
                child: Center(
                  child: Text(
                    themeData.name,
                    style: const TextStyle(
                      color: DynamicTokens.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMyTarotSection() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final currentDeckAsync = ref.watch(currentDeckProvider);
    
    return FadeInUp(
      duration: DynamicTokens.animationDuration,
      delay: const Duration(milliseconds: 250),
      child: _buildSection(
        title: 'マイデッキ',
        subtitle: 'My Deck',
        child: Column(
          children: [
            ListTile(
              leading: Icon(AppIcons.style, color: dynamicTokens.primaryColor),
              title: const Text('デッキを選択',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              subtitle: currentDeckAsync.when(
                loading: () => const Text('読み込み中...', 
                  style: TextStyle(color: DynamicTokens.textBlack87),
                ),
                error: (error, stack) => const Text('使用するデッキを選択',
                  style: TextStyle(color: DynamicTokens.textBlack87),
                ),
                data: (currentDeck) => Text(currentDeck?.nameJp ?? '使用するデッキを選択',
                  style: const TextStyle(color: DynamicTokens.textBlack87),
                ),
              ),
              trailing: const Icon(AppIcons.arrowForwardIos),
              onTap: () {
                context.push('/deck-selection');
              },
            ),
            // 背面デザイン機能を一時的に非表示
            ListTile(
              leading: Icon(AppIcons.shoppingCart, color: dynamicTokens.primaryColor),
              title: const Text('リアルデッキを購入',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              subtitle: const Text('実物のタロットカードを購入',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              trailing: const Icon(AppIcons.arrowForwardIos),
              onTap: () => _openBaseShop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return FadeInUp(
      duration: DynamicTokens.animationDuration,
      delay: const Duration(milliseconds: 300),
      child: _buildSection(
        title: '設定',
        subtitle: '設定',
        child: Column(
          children: [
            ListTile(
              leading: Icon(AppIcons.musicNote, color: dynamicTokens.primaryColor),
              title: const Text('音楽',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              subtitle: Text('${_selectedBgm}',
                style: const TextStyle(color: DynamicTokens.textBlack87),
              ),
              trailing: const Icon(AppIcons.arrowForwardIos),
              onTap: () => _showBgmDialog(),
            ),
            const Divider(),
            SwitchListTile(
              secondary: Icon(AppIcons.today, color: dynamicTokens.primaryColor),
              title: const Text('リマインダー',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              subtitle: const Text('リマインダー機能を有効にする',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              value: _dailyTarotEnabled,
              onChanged: (value) {
                setState(() {
                  _dailyTarotEnabled = value;
                });
              },
              activeColor: dynamicTokens.primaryColor,
            ),
            const Divider(),
            ListTile(
              leading: Icon(AppIcons.bugReport, color: dynamicTokens.primaryColor),
              title: const Text('バグを報告',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              subtitle: const Text('問題やバグを報告',
                style: TextStyle(color: DynamicTokens.textBlack87),
              ),
              trailing: const Icon(AppIcons.arrowForwardIos),
              onTap: () => _showBugReportDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(DynamicTokens.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? [
            // 有背景图：使用 DesignTokens.surfaceColor 的高透明度背景
            DesignTokens.surfaceColor.withOpacity(0.95),
            DesignTokens.surfaceColor.withOpacity(0.90),
          ] : [
            // 纯色背景主题：保持原来的surface颜色
            dynamicTokens.surfaceColor.withOpacity(0.8),
            dynamicTokens.surfaceColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(DynamicTokens.radiusMd),
        border: Border.all(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
            ? dynamicTokens.primaryColor.withOpacity(0.6)
            : dynamicTokens.primaryColor.withOpacity(0.2),
          width: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 2 : 1,
        ),
        // no box shadows
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: DynamicTokens.fontSizeTitleLarge,
              fontWeight: FontWeight.w600,
              color: DynamicTokens.textBlack87,
            ),
          ),
          const SizedBox(height: DynamicTokens.spacingMd),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          color: DynamicTokens.textBlack87,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: DynamicTokens.textBlack87,
        ),
      ),
      trailing: onTap != null 
          ? const Icon(AppIcons.edit, color: DynamicTokens.textBlack87)
          : const Icon(AppIcons.infoOutline, color: DynamicTokens.textBlack87),
      onTap: onTap,
    );
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('名前を入力', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '名前を入力してください'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _dialogSecondaryButton('キャンセル', () => Navigator.pop(context)),
                const SizedBox(width: 8),
                _dialogPrimaryButton('保存', () async {
                    setState(() { _name = controller.text; });
                    Navigator.pop(context);
                    await _saveProfileData();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// ID设置对话框
  void _showOpenIdDialog() {
    final controller = TextEditingController(text: _openId);
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('IDを入力', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'IDを入力してください',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('※ IDは他のユーザーに表示される公開IDです', style: TextStyle(fontSize: 12, color: DynamicTokens.textBlack87)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _dialogSecondaryButton('キャンセル', () => Navigator.pop(context)),
                const SizedBox(width: 8),
                _dialogPrimaryButton('保存', () async {
                    try {
                      await SupabaseService.updateOpenId(controller.text);
                      setState(() { _openId = controller.text; });
                      Navigator.pop(context);
                        _showSuccessSnackBar('IDを更新しました');
                    } catch (e) {
                      _showErrorSnackBar('エラー: $e');
                    }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('性別を選択', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._genderOptions.map((gender) => RadioListTile<String>(
                  title: Text(gender, style: const TextStyle(color: DynamicTokens.textBlack87)),
                  value: gender,
                  groupValue: _gender,
                  activeColor: ref.watch(dynamicTokensProvider).primaryColor,
                  onChanged: (value) async {
                    setState(() { _gender = value!; });
                    Navigator.pop(context);
                    await _saveProfileData();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showBirthDatePicker() {
    final dt = ref.read(dynamicTokensProvider);
    showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: dt.primaryColor, // 选中高亮、OK按钮
              onPrimary: DynamicTokens.textWhite,
              surface: dt.surfaceColor,
              onSurface: DynamicTokens.textBlack87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: dt.primaryColor),
            ),
          ),
          child: child!,
        );
      },
    ).then((date) async {
      if (date != null) {
        setState(() {
          _birthDate = date;
        });
        await _saveProfileData();
      }
    });
  }

  void _showOccupationDialog() {
    final controller = TextEditingController(text: _occupation);
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('職業を入力', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '職業を入力してください'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _dialogSecondaryButton('キャンセル', () => Navigator.pop(context)),
                const SizedBox(width: 8),
                _dialogPrimaryButton('保存', () async {
                  setState(() { _occupation = controller.text; });
                  Navigator.pop(context);
                  await _saveProfileData();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRelationshipDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('恋愛関係を選択', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._relationshipOptions.map((relationship) => RadioListTile<String>(
                  title: Text(relationship, style: const TextStyle(color: DynamicTokens.textBlack87)),
                  value: relationship,
                  groupValue: _relationship,
                  activeColor: ref.watch(dynamicTokensProvider).primaryColor,
                  onChanged: (value) async {
                    setState(() { _relationship = value!; });
                    Navigator.pop(context);
                    await _saveProfileData();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showBackDesignDialog() {
    final currentDeck = ref.read(currentDeckProvider).asData?.value;
    final availableDesigns = CardBackService.getAvailableBackDesigns();
    
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('背面デザインを選択', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
            const SizedBox(height: 12),
            ...availableDesigns.map((design) => RadioListTile<String>(
                  title: Text(design['name']),
                  subtitle: design['type'] == 'default' && currentDeck != null
                      ? Text('${currentDeck.nameJp}の背面')
                      : Text(design['description']),
                  value: design['type'],
                  groupValue: _selectedBackDesign,
                  onChanged: (value) async {
                    if (value != null) {
                      try {
                        await CardBackService.setBackDesign(value);
                        setState(() {
                          _selectedBackDesign = value;
                          _selectedBackDesignName = design['name'];
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _showSuccessSnackBar('背面デザインを「${design['name']}」に変更しました');
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          _showErrorSnackBar('背面デザインの変更に失敗しました: $e');
                        }
                      }
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showBgmDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('BGMを選択', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
            const SizedBox(height: 12),
            ..._bgmTracks.map((track) => RadioListTile<String>(
                  title: Text(track['name'], style: const TextStyle(color: DynamicTokens.textBlack87)),
                  value: track['name'],
                  groupValue: _selectedBgm,
                  activeColor: ref.watch(dynamicTokensProvider).primaryColor,
                  onChanged: (value) {
                    setState(() { _selectedBgm = value!; });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showBugReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: ref.watch(dynamicTokensProvider).primaryColor,
              selectionHandleColor: ref.watch(dynamicTokensProvider).primaryColor,
              selectionColor: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.28),
            ),
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: const TextStyle(color: DynamicTokens.textBlack87),
              floatingLabelStyle: TextStyle(color: ref.watch(dynamicTokensProvider).primaryColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ref.watch(dynamicTokensProvider).primaryColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('バグを報告', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
            const SizedBox(height: 12),
            const Text('問題やバグについて詳しく教えてください：', style: TextStyle(color: DynamicTokens.textBlack87)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'バグの詳細を入力してください',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _dialogSecondaryButton('キャンセル', () => Navigator.pop(context)),
                const SizedBox(width: 8),
                _dialogPrimaryButton('送信', () {
                  Navigator.pop(context);
                  _showSuccessSnackBar('バグ報告を送信しました。ありがとうございます。');
                }),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Base店铺を開く（アプリ内WebView）
  void _openBaseShop() {
    // Base店铺的URL - 请替换为实际的店铺链接
    const baseShopUrl = 'https://www.bendang.com'; // 示例URL，请替换为实际链接
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BaseShopScreen(
          shopUrl: baseShopUrl,
        ),
      ),
    );
  }

  String _getZodiacSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;
    
    switch (month) {
      case 1:
        return day <= 19 ? 'やぎ座' : 'みずがめ座';
      case 2:
        return day <= 18 ? 'みずがめ座' : 'うお座';
      case 3:
        return day <= 20 ? 'うお座' : 'おひつじ座';
      case 4:
        return day <= 19 ? 'おひつじ座' : 'おうし座';
      case 5:
        return day <= 20 ? 'おうし座' : 'ふたご座';
      case 6:
        return day <= 20 ? 'ふたご座' : 'かに座';
      case 7:
        return day <= 22 ? 'かに座' : 'しし座';
      case 8:
        return day <= 22 ? 'しし座' : 'おとめ座';
      case 9:
        return day <= 22 ? 'おとめ座' : 'てんびん座';
      case 10:
        return day <= 22 ? 'てんびん座' : 'さそり座';
      case 11:
        return day <= 21 ? 'さそり座' : 'いて座';
      case 12:
        return day <= 21 ? 'いて座' : 'やぎ座';
      default:
        return '';
    }
  }
  

  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ログアウト', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
            const SizedBox(height: 12),
            const Text('ログアウトしますか？\n\n保存されていないデータは失われる可能性があります。'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _dialogSecondaryButton('キャンセル', () => Navigator.pop(context)),
                const SizedBox(width: 8),
                _dialogPrimaryButton('ログアウト', () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(authStateProvider.notifier).signOut();
                    if (mounted) {
                      _showSuccessSnackBar('ログアウトしました');
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorSnackBar('ログアウトに失敗しました: $e');
                    }
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 统一样式的弹窗容器（与首页/Gallery/Spread一致）
  Widget _buildStyledDialog({required BuildContext context, required Widget content}) {
    final dt = ref.watch(dynamicTokensProvider);
    return Dialog(
      backgroundColor: dt.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: (dt.isDark || dt.backgroundImage != null)
                ? [DesignTokens.surfaceColor.withOpacity(0.95), DesignTokens.surfaceColor.withOpacity(0.90)]
                : [dt.surfaceColor.withOpacity(0.8), dt.surfaceColor.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (dt.isDark || dt.backgroundImage != null)
                ? dt.primaryColor.withOpacity(0.6)
                : dt.primaryColor.withOpacity(0.2),
            width: (dt.isDark || dt.backgroundImage != null) ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(child: content),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                width: 24, // 原始约 48 的 0.5
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(AppIcons.close, size: 16),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(24, 24),
                    backgroundColor: DynamicTokens.textBlack87.withOpacity(0.1),
                    foregroundColor: DynamicTokens.textGrey600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 统一弹窗按钮样式（与首页一致）
  Widget _dialogPrimaryButton(String label, VoidCallback onPressed) {
    final dt = ref.watch(dynamicTokensProvider);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: dt.primaryColor,
        foregroundColor: DynamicTokens.textWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _dialogSecondaryButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: DynamicTokens.textBlack87,
      ),
      child: Text(label),
    );
  }
  
  void _showUpgradeAccountDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _buildStyledDialog(
          context: context,
          content: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: const TextStyle(color: DynamicTokens.textBlack87),
                floatingLabelStyle: TextStyle(color: ref.watch(dynamicTokensProvider).primaryColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ref.watch(dynamicTokensProvider).primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIconColor: DynamicTokens.textGrey600,
              ),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('アカウント作成', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
              const SizedBox(height: 12),
              const Text('現在のゲストデータをそのまま引き継ぎ、\nメールアカウントにアップグレードします：'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(AppIcons.emailOutlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード (6文字以上)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(AppIcons.lockOutlined),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.checkCircle, size: 16, color: ref.watch(dynamicTokensProvider).primaryColor),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('すべてのデータが引き継がれます', style: TextStyle(fontSize: 12, color: DynamicTokens.textBlack87)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(AppIcons.checkCircle, size: 16, color: ref.watch(dynamicTokensProvider).primaryColor),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('同一ユーザーIDを継続利用できます', style: TextStyle(fontSize: 12, color: DynamicTokens.textBlack87)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(AppIcons.checkCircle, size: 16, color: ref.watch(dynamicTokensProvider).primaryColor),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('データが安全に保存されます', style: TextStyle(fontSize: 12, color: DynamicTokens.textBlack87)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('既にアカウントをお持ちの方は'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showLoginDialog();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: ref.watch(dynamicTokensProvider).primaryColor,
                    ),
                    child: const Text(
                      'ログイン',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
          // 移除 actions；按钮已内置到 content 末尾
        ),
      ),
    );
  }
  

  
  /// 订阅升级按钮
  Widget _buildSubscriptionUpgradeButton() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final hasActiveSubscription = ref.watch(hasActiveSubscriptionProvider);
    final purchaseState = ref.watch(subscriptionPurchaseProvider);
    
    return hasActiveSubscription.when(
      data: (isActive) {
        if (isActive) {
          // 已有订阅，显示管理按钮
          return ListTile(
            leading: Icon(AppIcons.manageAccounts, color: dynamicTokens.primaryColor),
            title: Text(
              'プレミアム管理',
              style: const TextStyle(color: DynamicTokens.textBlack87),
            ),
            subtitle: Text(
              '購読の管理とキャンセル',
              style: const TextStyle(color: DynamicTokens.textBlack87),
            ),
            trailing: const Icon(AppIcons.arrowForwardIos),
            onTap: () => _showSubscriptionManagementDialog(),
          );
        } else {
          // 无订阅，显示升级按钮
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: purchaseState.isLoading ? null : () => _showSubscriptionPurchaseDialog(),
              icon: purchaseState.isLoading 
                  ? SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : Icon(AppIcons.workspacePremium),
              label: Text(purchaseState.isLoading ? '処理中...' : 'プレミアムにアップグレード'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dynamicTokens.primaryColor,
                foregroundColor: DynamicTokens.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          );
        }
      },
      loading: () => ListTile(
        leading: Icon(AppIcons.hourglassEmpty, color: DynamicTokens.textGrey600),
        title: Text('読み込み中...'),
        subtitle: Text('購読状態を確認中'),
      ),
      error: (error, stack) => ListTile(
        leading: Icon(AppIcons.error, color: DynamicTokens.textError),
        title: Text('エラー'),
        subtitle: Text('購読状態の取得に失敗しました'),
      ),
    );
  }
  
  /// 兑换码入口按钮
  Widget _buildRedemptionCodeButton() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return ListTile(
      leading: Icon(AppIcons.confirmationNumber, color: dynamicTokens.primaryColor),
      title: Text(
        '引き換えコード',
        style: TextStyle(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? DynamicTokens.textWhite
              : DynamicTokens.textBlack87,
        ),
      ),
      subtitle: Text(
        '引き換えコードを入力',
        style: TextStyle(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
              ? DynamicTokens.textWhite
              : DynamicTokens.textBlack87,
        ),
      ),
      trailing: const Icon(AppIcons.arrowForwardIos),
      onTap: () => _openRedemptionScreen(),
    );
  }
  
  /// 打开兑换码页面
  void _openRedemptionScreen() {
    final authState = ref.read(authStateProvider);
    
    // 检查用户类型：匿名用户需要先注册
    if (authState.isAnonymous) {
      _showAnonymousUserWarning('引き換えコード');
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RedemptionScreen(),
      ),
    );
  }
  
  /// 开发者工具按钮（仅开发模式）
  Widget _buildDeveloperToolsButton() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return ListTile(
      leading: const Icon(AppIcons.build, color: DynamicTokens.textWarning),
      title: const Text(
        '開発者ツール',
        style: TextStyle(color: DynamicTokens.textBlack87),
      ),
      subtitle: const Text(
        '引き換えコード診断・修復',
        style: TextStyle(color: DynamicTokens.textBlack87),
      ),
      trailing: const Icon(
        AppIcons.arrowForwardIos,
        color: DynamicTokens.textBlack87,
      ),
      onTap: _showDeveloperToolsDialog,
    );
  }
  
  /// 显示开发者工具对话框
  void _showDeveloperToolsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            const Icon(AppIcons.build, color: DynamicTokens.textWarning),
            const SizedBox(width: 8),
            Text('開発者ツール'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('引き換えコードシステムの診断と修復を行います。'),
            SizedBox(height: 8),
            Text('サブスクリプション状態をSupabaseと同期できます。'),
            SizedBox(height: 8),
            Row(
              children: const [
                Icon(AppIcons.warningAmber, size: 18, color: DynamicTokens.textWarning),
                SizedBox(width: 6),
                Expanded(child: Text('この機能は開発モードでのみ利用可能です。')),
              ],
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
              Navigator.of(context).pop();
              await _syncSubscriptionToSupabase();
            },
            child: const Text('サブスク同期'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _runRedemptionDiagnostics();
            },
            child: const Text('診断実行'),
          ),
        ],
      ),
    );
  }
  
  /// 运行兑换码系统诊断
  Future<void> _runRedemptionDiagnostics() async {
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('診断を実行中...'),
          ],
        ),
      ),
    );
    
    try {
      // 运行诊断
      print('🔍 开始运行兑换码系统诊断...');
      final diagnostics = await QuickTestSetup.runDiagnostics();
      
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示诊断结果
      _showDiagnosticsResult(diagnostics);
      
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示错误
      _showErrorSnackBar('診断に失敗しました: $e');
    }
  }
  
  /// 强制同步订阅状态到Supabase
  Future<void> _syncSubscriptionToSupabase() async {
    try {
      _showSuccessSnackBar('正在同步订阅状态到Supabase...', duration: const Duration(seconds: 2));
      
      // 强制从Supabase同步订阅状态
      await SubscriptionService.syncFromSupabase();
      
      _showSuccessSnackBar('✅ 订阅状态同步成功');
    } catch (e) {
      _showErrorSnackBar('❌ 同步失败: $e');
    }
  }
  
  /// 显示诊断结果对话框
  void _showDiagnosticsResult(Map<String, bool> results) {
    final hasIssues = results.values.any((result) => !result);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hasIssues ? Icons.warning : Icons.check_circle,
              color: hasIssues ? DynamicTokens.textWarning : DynamicTokens.textSuccess,
            ),
            const SizedBox(width: 8),
            const Text('診断結果'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...results.entries.map((entry) {
                final icon = entry.value ? '✅' : '❌';
                final label = _getDiagnosticLabel(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('$icon $label'),
                );
              }).toList(),
              
              if (hasIssues) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '問題が検出されました。修復を実行するか、manual_setup_redemption_codes.sqlをSupabase Dashboardで実行してください。',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          if (hasIssues)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _runQuickFix();
              },
              child: const Text('修復実行'),
            ),
        ],
      ),
    );
  }
  
  /// 获取诊断项目的日语标签
  String _getDiagnosticLabel(String key) {
    switch (key) {
      case 'tables_exist':
        return 'データベーステーブル存在';
      case 'function_exists':
        return '引き換え関数存在';
      case 'user_logged_in':
        return 'ユーザーログイン';
      case 'network_connected':
        return 'ネットワーク接続';
      default:
        return key;
    }
  }
  
  /// 运行快速修复
  Future<void> _runQuickFix() async {
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('修復を実行中...'),
          ],
        ),
      ),
    );
    
    try {
      await QuickTestSetup.quickFix();
      
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示成功消息
      _showSuccessSnackBar('修復が完了しました！');
      
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示错误
      _showErrorSnackBar('修復に失敗しました: $e');
    }
  }
  
  /// 订阅管理对话框
  void _showSubscriptionManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.verified, color: Colors.green),
              title: const Text('ステータス'),
              subtitle: const Text('プレミアム有効'),
            ),
            
            Consumer(
              builder: (context, ref, child) {
                final subscriptionExpiry = ref.watch(subscriptionExpiryProvider);
                print('📅 [UI] 订阅到期时间Provider状态: ${subscriptionExpiry.runtimeType}');
                
                return subscriptionExpiry.when(
                  data: (expiry) {
                    print('📅 [UI] 收到到期时间数据: $expiry');
                    return expiry != null
                        ? ListTile(
                            leading: const Icon(AppIcons.schedule),
                            title: const Text('次回更新日'),
                            subtitle: Text('${expiry.year}年${expiry.month}月${expiry.day}日'),
                          )
                        : ListTile(
                            leading: const Icon(AppIcons.schedule),
                            title: const Text('次回更新日'),
                            subtitle: const Text('期限なし'),
                          );
                  },
                  loading: () {
                    print('📅 [UI] 到期时间正在加载...');
                    return ListTile(
                      leading: const Icon(AppIcons.schedule),
                      title: const Text('次回更新日'),
                      subtitle: const Text('読み込み中...'),
                    );
                  },
                  error: (error, stack) {
                    print('📅 [UI] 到期时间加载错误: $error');
                    return ListTile(
                      leading: const Icon(AppIcons.schedule),
                      title: const Text('次回更新日'),
                      subtitle: Text('エラー: $error'),
                    );
                  },
                );
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(AppIcons.shoppingCart, color: DynamicTokens.accentPremium),
              title: const Text('プレミアムサービスを購入', style: TextStyle(color: DynamicTokens.textBlack87)),
              subtitle: const Text('期間を延長または追加購入', style: TextStyle(color: DynamicTokens.textBlack87)),
              onTap: () {
                Navigator.of(context).pop();
                _showSubscriptionPurchaseDialog();
              },
            ),
            
            ListTile(
              leading: const Icon(AppIcons.restore, color: DynamicTokens.textInfo),
              title: const Text('購入を復元', style: TextStyle(color: DynamicTokens.textBlack87)),
              subtitle: const Text('他のデバイスでの購入を復元', style: TextStyle(color: DynamicTokens.textBlack87)),
              onTap: () {
                Navigator.of(context).pop();
                _restorePurchases();
              },
            ),
            
            ListTile(
              leading: const Icon(AppIcons.cancel, color: DynamicTokens.textError),
              title: const Text('購読をキャンセル', style: TextStyle(color: DynamicTokens.textBlack87)),
              subtitle: const Text('次回更新日に自動停止', style: TextStyle(color: DynamicTokens.textBlack87)),
              onTap: () {
                Navigator.of(context).pop();
                _cancelSubscription();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 订阅购买对话框
  void _showSubscriptionPurchaseDialog() {
    final authState = ref.read(authStateProvider);
    
    // 检查用户类型：匿名用户需要先注册
    if (authState.isAnonymous) {
      _showAnonymousUserWarning('購読');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => SubscriptionPurchaseDialog(ref: ref),
    );
  }

  /// 显示匿名用户警告对话框
  void _showAnonymousUserWarning(String action) {
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('アカウント登録が必要', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
            const SizedBox(height: 12),
            Text('${action}機能をご利用いただくには、メールアドレスでの登録が必要です。', style: const TextStyle(color: DynamicTokens.textBlack87)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(children: [
                    Icon(AppIcons.infoOutline, color: DynamicTokens.textBlack87, size: 20),
                    SizedBox(width: 8),
                    Text('ゲストアカウントの制限', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
                  ]),
                  SizedBox(height: 8),
                  Text('• ログアウトすると履歴が失われます', style: TextStyle(fontSize: 14, color: DynamicTokens.textBlack87)),
                  Text('• デバイスを変更時にデータを引き継ぎません', style: TextStyle(fontSize: 14, color: DynamicTokens.textBlack87)),
                  Text('• データの復元ができません', style: TextStyle(fontSize: 14, color: DynamicTokens.textBlack87)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(children: [
                    Icon(AppIcons.checkCircleOutline, color: DynamicTokens.textBlack87, size: 20),
                    SizedBox(width: 8),
                    Text('メール登録のメリット', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
                  ]),
                  SizedBox(height: 8),
                  Text('• 現在のデータをすべて保存できます', style: TextStyle(fontSize: 14, color: DynamicTokens.textBlack87)),
                  Text('• 複数デバイスでの利用が可能になります', style: TextStyle(fontSize: 14, color: DynamicTokens.textBlack87)),
                  Text('• データを安全にデータが保護できます', style: TextStyle(fontSize: 14, color: DynamicTokens.textBlack87)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _dialogSecondaryButton('後で', () => Navigator.of(context).pop()),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () { Navigator.of(context).pop(); _showUpgradeAccountDialog(); },
                  icon: const Icon(AppIcons.personAdd),
                  label: const Text('登録/ログイン'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ref.watch(dynamicTokensProvider).primaryColor,
                    foregroundColor: DynamicTokens.textWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 登录对话框
  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _buildStyledDialog(
          context: context,
          content: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: const TextStyle(color: DynamicTokens.textBlack87),
                floatingLabelStyle: TextStyle(color: ref.watch(dynamicTokensProvider).primaryColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ref.watch(dynamicTokensProvider).primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIconColor: DynamicTokens.textGrey600,
              ),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ログイン', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
              const SizedBox(height: 12),
              const Text('既存のアカウントにログインします：', style: TextStyle(color: DynamicTokens.textBlack87)),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(AppIcons.emailOutlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(AppIcons.lockOutlined),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ref.watch(dynamicTokensProvider).primaryColor.withOpacity(0.22)),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.infoOutline, color: DynamicTokens.textBlack87, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ログイン後、現在のゲストデータは失われます。',
                        style: TextStyle(fontSize: 12, color: DynamicTokens.textBlack87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('アカウントをお持ちでない方は', style: TextStyle(color: DynamicTokens.textBlack87)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showUpgradeAccountDialog();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: ref.watch(dynamicTokensProvider).primaryColor,
                    ),
                    child: const Text(
                      '新規作成',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _dialogSecondaryButton('キャンセル', () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('メールアドレスとパスワードを入力してください')),
                        );
                        return;
                      }
                      
                      setState(() => isLoading = true);
                      
                      try {
                        // 邮箱登录
                        final authNotifier = ref.read(authStateProvider.notifier);
                        await authNotifier.signInWithEmail(
                          emailController.text.trim(),
                          passwordController.text,
                        );
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _showSuccessSnackBar('ログインが完了しました！');
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => isLoading = false);
                          String errorMessage = 'ログインに失敗しました';
                          
                          if (e.toString().contains('Invalid login credentials')) {
                            errorMessage = 'メールアドレスまたはパスワードが正しくありません';
                          } else if (e.toString().contains('Email not confirmed')) {
                            errorMessage = 'メール確認が必要です。受信したメールから確認してください';
                          } else if (e.toString().contains('Too many requests')) {
                            errorMessage = '試行回数が多すぎます。しばらく待ってから再度お試しください';
                          }
                          
                          _showErrorSnackBar(errorMessage, duration: const Duration(seconds: 4));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ref.watch(dynamicTokensProvider).primaryColor,
                      foregroundColor: DynamicTokens.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(DynamicTokens.textWhite),
                            ),
                          )
                        : const Text('ログイン'),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  /// 恢复购买
  Future<void> _restorePurchases() async {
    try {
      final success = await SubscriptionService.restorePurchases();
      if (success) {
        _showSuccessSnackBar('購入を復元しました');
      } else {
        _showErrorSnackBar('復元可能な購入が見つかりませんでした');
      }
    } catch (e) {
      _showErrorSnackBar('購入復元中にエラーが発生しました: $e');
    }
  }

  /// 取消订阅
  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購読キャンセル'),
        content: const Text('本当にプレミアム購読をキャンセルしますか？\n次回更新日まではプレミアム機能をご利用いただけます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('いいえ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: DynamicTokens.textError),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await SubscriptionService.cancelSubscription();
        _showSuccessSnackBar('購読をキャンセルしました');
      } catch (e) {
        _showErrorSnackBar('キャンセル中にエラーが発生しました: $e');
      }
    }
  }

  

  void _showLanguageDialog() {
    final currentLang = ref.read(localizationServiceProvider);
    showDialog(
      context: context,
      builder: (context) => _buildStyledDialog(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('言語を選択', style: TextStyle(fontWeight: FontWeight.w600, color: DynamicTokens.textBlack87)),
            const SizedBox(height: 12),
            ...SupportedLanguage.values.map((lang) => RadioListTile<SupportedLanguage>(
                  title: Text(lang.displayName, style: const TextStyle(color: DynamicTokens.textBlack87)),
                  value: lang,
                  groupValue: currentLang,
                  activeColor: ref.watch(dynamicTokensProvider).primaryColor,
                  onChanged: (value) async {
                    if (value != null) {
                      await ref.read(localizationServiceProvider.notifier).changeLanguage(value);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }
}

 
