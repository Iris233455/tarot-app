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
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';

class MyDeckScreen extends ConsumerStatefulWidget {
  const MyDeckScreen({super.key});

  @override
  ConsumerState<MyDeckScreen> createState() => _MyDeckScreenState();
}

class _MyDeckScreenState extends ConsumerState<MyDeckScreen> {
  AppStringsBase get strings => ref.read(appStringsProvider);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ プロフィールを保存しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('❌ MyDeck: Profile保存失败: $e');
      
      // 显示详细的错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ プロフィールの保存に失敗しました\n詳細: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _saveProfileData(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    final currentTheme = ref.watch(currentThemeNameProvider);
    final strings = ref.watch(appStringsProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemedBackground(
        child: SafeArea(
          child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          children: [
            // 标题
            FadeInDown(
              duration: DesignTokens.animationDuration,
              child: Text(
                strings.myDeckTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: DynamicTokens.fontWeightBold,
                  color: dynamicTokens.textPrimary,
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
        selectedItemColor: dynamicTokens.primaryColor,
        unselectedItemColor: dynamicTokens.textSecondary,
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: strings.homeDailyCard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome),
            label: strings.readingSelectSpread,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: 'ギャラリー',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.style),
            label: strings.myDeckTitle,
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
            
            // Avatar URL (暂时只读，未来可扩展为上传功能)
            _buildProfileField(
              label: 'Avatar URL',
              value: '未対応',
              onTap: null, // 暂时只读
            ),
            const Divider(),
            
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
              
              // 订阅升级按钮 - 移动到User ID位置
              _buildSubscriptionUpgradeButton(),
              const Divider(),
              
              // 兑换码入口
              _buildRedemptionCodeButton(),
              const Divider(),
              
              // 开发者工具（仅开发模式）
              if (kDebugMode) ...[
                _buildDeveloperToolsButton(),
                const Divider(),
              ],
              
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
              
              // 用户ID显示
              _buildProfileField(
                label: 'ユーザーID',
                value: authState.userId ?? '不明',
                onTap: null,
              ),
              
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
              
              // お気に入り
              _buildProfileField(
                label: 'お気に入り',
                value: 'お気に入りの占い結果',
                onTap: () => context.go('/favorites'),
              ),
              
              const Divider(),
              
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
          return 'メールアドレス';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('認証状態を更新しました\nユーザータイプ: $userType\nメール: ${currentUser?.email}'),
        duration: const Duration(seconds: 4),
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google OAuthテスト完了\nコンソールログで詳細を確認\nユーザーID: ${currentUser?.id}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Google OAuth测试失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google OAuthテスト失敗\nエラー: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  /// 重置今日卡片，允许重新抽牌
  Future<void> _resetTodayCard() async {
    final strings = ref.read(appStringsProvider);
    // 先显示确认对话框
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.settingsReset),
        content: Text('本日のカードをリセットして、新しいカードを引き直しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.settingsReset),
          ),
        ],
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
          const SnackBar(
            content: Text('✅ 本日のカードをリセットしました。新しいカードを引くことができます！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ 本日のカードリセット失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ リセットに失敗しました: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
          itemCount: AppThemes.themes.length,
          itemBuilder: (context, index) {
            final themeName = AppThemes.themes.keys.elementAt(index);
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
                          color: Colors.white,
                          width: 3,
                        )
                      : null,
                  boxShadow: isSelected ? DynamicTokens.shadowCard : null,
                ),
                child: Center(
                  child: Text(
                    themeData.name,
                    style: TextStyle(color: Colors.white,
                      fontWeight: DynamicTokens.fontWeightBold,
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
              leading: Icon(Icons.style, color: dynamicTokens.primaryColor),
              title: Text(strings.settingsDeckSelection,
                style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
              ),
              subtitle: currentDeckAsync.when(
                loading: () => Text(strings.messageLoading, 
                  style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.grey.shade600 : null),
                ),
                error: (error, stack) => Text(strings.settingsSelectDeck,
                  style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.grey.shade600 : null),
                ),
                data: (currentDeck) => Text(currentDeck?.nameJp ?? '使用するデッキを選択',
                  style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.grey.shade600 : null),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.push('/deck-selection');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.crop_portrait, color: dynamicTokens.primaryColor),
              title: Text(strings.settingsBackDesign,
                style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
              ),
              subtitle: Text('$_selectedBackDesignName',
                style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showBackDesignDialog(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: dynamicTokens.primaryColor),
              title: Text(strings.settingsBuyRealDeck,
                style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
              ),
              subtitle: Text(strings.settingsBuyDescription,
                style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
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
              leading: Icon(Icons.music_note, color: dynamicTokens.primaryColor),
              title: Text(strings.settingsMusic,
                style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
              ),
              subtitle: Text('${_selectedBgm}',
                style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showBgmDialog(),
            ),
            const Divider(),
            SwitchListTile(
              secondary: Icon(Icons.today, color: dynamicTokens.primaryColor),
              title: Text('リマインダー',
                style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
              ),
              subtitle: Text('リマインダー機能を有効にする',
                style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
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
              leading: Icon(Icons.bug_report, color: dynamicTokens.primaryColor),
              title: Text('バグを報告',
                style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
              ),
              subtitle: Text('問題やバグを報告',
                style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
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
            // 有背景图的主题：使用高透明度白色背景
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.90),
          ] : [
            // 纯色背景主题：保持原来的surface颜色
            dynamicTokens.surfaceColor.withOpacity(0.8),
            dynamicTokens.surfaceColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null)
            ? dynamicTokens.primaryColor.withOpacity(0.6)
            : dynamicTokens.primaryColor.withOpacity(0.2),
          width: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: DynamicTokens.fontWeightBold,
              color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : dynamicTokens.textPrimary,
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
        style: TextStyle(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : dynamicTokens.textPrimary,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.grey.shade600 : dynamicTokens.textSecondary,
        ),
      ),
      trailing: onTap != null 
          ? Icon(Icons.edit, color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.grey.shade600 : dynamicTokens.textSecondary) 
          : Icon(Icons.info_outline, color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.grey.shade600 : dynamicTokens.textSecondary),
      onTap: onTap,
    );
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前を入力'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '名前を入力してください',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _name = controller.text;
              });
              Navigator.pop(context);
              await _saveProfileData();
            },
            child: Text(strings.commonSave),
          ),
        ],
      ),
    );
  }
  
  /// ID设置对话框
  void _showOpenIdDialog() {
    final controller = TextEditingController(text: _openId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IDを入力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'IDを入力してください',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '※ IDは他のユーザーに表示される公開IDです',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // 直接更新Open ID到数据库
                await SupabaseService.updateOpenId(controller.text);
                setState(() {
                  _openId = controller.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('IDを更新しました')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エラー: $e')),
                );
              }
            },
            child: Text(strings.commonSave),
          ),
        ],
      ),
    );
  }

  void _showGenderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('性別を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _genderOptions.map((gender) {
            return RadioListTile<String>(
              title: Text(gender),
              value: gender,
              groupValue: _gender,
              onChanged: (value) async {
                setState(() {
                  _gender = value!;
                });
                Navigator.pop(context);
                await _saveProfileData();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBirthDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
      builder: (context) => AlertDialog(
        title: const Text('職業を入力'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '職業を入力してください',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _occupation = controller.text;
              });
              Navigator.pop(context);
              await _saveProfileData();
            },
            child: Text(strings.commonSave),
          ),
        ],
      ),
    );
  }

  void _showRelationshipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恋愛関係を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _relationshipOptions.map((relationship) {
            return RadioListTile<String>(
              title: Text(relationship),
              value: relationship,
              groupValue: _relationship,
              onChanged: (value) async {
                setState(() {
                  _relationship = value!;
                });
                Navigator.pop(context);
                await _saveProfileData();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBackDesignDialog() {
    final currentDeck = ref.read(currentDeckProvider).asData?.value;
    final availableDesigns = CardBackService.getAvailableBackDesigns();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('背面デザインを選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableDesigns.map((design) {
            return RadioListTile<String>(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('背面デザインを「${design['name']}」に変更しました')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('背面デザインの変更に失敗しました: $e')),
                      );
                    }
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBgmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('BGMを選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _bgmTracks.map((track) {
            return RadioListTile<String>(
              title: Text(track['name']),
              value: track['name'],
              groupValue: _selectedBgm,
              onChanged: (value) {
                setState(() {
                  _selectedBgm = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBugReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バグを報告'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('問題やバグについて詳しく教えてください：'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'バグの詳細を入力してください',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: バグ報告の送信処理
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('バグ報告を送信しました。ありがとうございます。')),
              );
            },
            child: const Text('送信'),
          ),
        ],
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
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？\n\n保存されていないデータは失われる可能性があります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authStateProvider.notifier).signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ログアウトしました')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ログアウトに失敗しました: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ログアウト', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showUpgradeAccountDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('アカウント作成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('現在のゲストデータをそのまま引き継ぎ、\nメールアカウントにアップグレードします：'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード (6文字以上)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '✅ すべてのデータが引き継がれます\n✅ 同一ユーザーIDを継続利用できます\n✅ データが安全に保存されます',
                style: TextStyle(fontSize: 12, color: Colors.green),
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
                    child: Text(
                      'ログイン',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: DynamicTokens.fontWeightBold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(strings.buttonCancel),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (emailController.text.isEmpty || passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('メールアドレスと6文字以上のパスワードを入力してください')),
                  );
                  return;
                }
                
                setState(() => isLoading = true);
                
                try {
                  // 升级账户
                  await SupabaseService.upgradeAnonymousToEmail(
                    emailController.text.trim(),
                    passwordController.text,
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 アカウントの作成が完了しました！\nすべてのデータが引き継がれます。'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                  
                  // 强制刷新状态以显示新的账户类型
                  if (mounted) {
                    this.setState(() {});
                  }
                  
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('アップグレード失敗: $e')),
                  );
                }
              },
              child: isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('アカウント作成'),
            ),
          ],
        );
        },
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
            leading: Icon(Icons.manage_accounts, color: dynamicTokens.primaryColor),
            title: Text(
              'プレミアム管理',
              style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
            ),
            subtitle: Text(
              '購読の管理とキャンセル',
              style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
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
                  : Icon(Icons.workspace_premium),
              label: Text(purchaseState.isLoading ? '処理中...' : 'プレミアムにアップグレード'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
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
        leading: Icon(Icons.hourglass_empty, color: Colors.grey),
        title: Text(strings.messageLoading),
        subtitle: Text('購読状態を確認中'),
      ),
      error: (error, stack) => ListTile(
        leading: Icon(Icons.error, color: Colors.red),
        title: Text('エラー'),
        subtitle: Text('購読状態の取得に失敗しました'),
      ),
    );
  }
  
  /// 兑换码入口按钮
  Widget _buildRedemptionCodeButton() {
    final dynamicTokens = ref.watch(dynamicTokensProvider);
    
    return ListTile(
      leading: Icon(Icons.confirmation_number, color: dynamicTokens.primaryColor),
      title: Text(strings.redemptionTitle,
        style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
      ),
      subtitle: Text(strings.redemptionInputLabel,
        style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
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
      leading: Icon(Icons.build, color: Colors.orange.shade600),
      title: Text(
        '開発者ツール',
        style: TextStyle(color: (dynamicTokens.isDark || dynamicTokens.backgroundImage != null) ? Colors.black87 : null),
      ),
      subtitle: Text(
        '引き換えコード診断・修復',
        style: TextStyle(color: dynamicTokens.isDark ? Colors.grey.shade600 : null),
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showDeveloperToolsDialog(),
    );
  }
  
  /// 显示开发者工具对话框
  void _showDeveloperToolsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.build, color: Colors.orange),
            SizedBox(width: 8),
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
            Text('⚠️ この機能は開発モードでのみ利用可能です。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.buttonCancel),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('診断に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 强制同步订阅状态到Supabase
  Future<void> _syncSubscriptionToSupabase() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在同步订阅状态到Supabase...')),
      );
      
      // 强制从Supabase同步订阅状态
      await SubscriptionService.syncFromSupabase();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 订阅状态同步成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 同步失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              color: hasIssues ? Colors.orange : Colors.green,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('修復が完了しました！'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示错误
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('修復に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 订阅管理对话框
  void _showSubscriptionManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアム管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
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
                            leading: const Icon(Icons.schedule),
                            title: const Text('次回更新日'),
                            subtitle: Text('${expiry.year}年${expiry.month}月${expiry.day}日'),
                          )
                        : ListTile(
                            leading: const Icon(Icons.schedule),
                            title: const Text('次回更新日'),
                            subtitle: const Text('期限なし'),
                          );
                  },
                  loading: () {
                    print('📅 [UI] 到期时间正在加载...');
                    return ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('次回更新日'),
                      subtitle: Text(strings.messageLoading),
                    );
                  },
                  error: (error, stack) {
                    print('📅 [UI] 到期时间加载错误: $error');
                    return ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('次回更新日'),
                      subtitle: Text('エラー: $error'),
                    );
                  },
                );
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.amber),
              title: const Text('プレミアムサービスを購入'),
              subtitle: const Text('期間を延長または追加購入'),
              onTap: () {
                Navigator.of(context).pop();
                _showSubscriptionPurchaseDialog();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.blue),
              title: const Text('購入を復元'),
              subtitle: const Text('他のデバイスでの購入を復元'),
              onTap: () {
                Navigator.of(context).pop();
                _restorePurchases();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('購読をキャンセル'),
              subtitle: const Text('次回更新日に自動停止'),
              onTap: () {
                Navigator.of(context).pop();
                _cancelSubscription();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 强制刷新Provider状态
              ref.invalidate(subscriptionStatusProvider);
              ref.invalidate(subscriptionExpiryProvider);
              ref.invalidate(hasActiveSubscriptionProvider);
              print('🔄 [UI] 手动刷新订阅状态');
            },
            child: const Text('更新'),
          ),
          if (kDebugMode)
            TextButton(
              onPressed: () async {
                // 清理订阅数据
                await SubscriptionService.clearUserSubscriptionData();
                // 刷新UI
                ref.invalidate(subscriptionStatusProvider);
                ref.invalidate(subscriptionExpiryProvider);
                ref.invalidate(hasActiveSubscriptionProvider);
                print('🔄 [UI] 已清理订阅数据并刷新状态');
                Navigator.of(context).pop();
              },
              child: const Text('清理数据', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
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
      builder: (context) => _SubscriptionPurchaseDialog(ref: ref),
    );
  }

  /// 显示匿名用户警告对话框
  void _showAnonymousUserWarning(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('アカウント登録が必要'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${action}機能をご利用いただくには、メールアドレスでの登録が必要です。',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ゲストアカウントの制限',
                        style: TextStyle(
                          fontWeight: DynamicTokens.fontWeightBold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• ログアウトすると履歴が失われます', style: TextStyle(fontSize: 14)),
                  const Text('• デバイスを変更時にデータを引き継ぎません', style: TextStyle(fontSize: 14)),
                  const Text('• データの復元ができません', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'メール登録のメリット',
                        style: TextStyle(
                          fontWeight: DynamicTokens.fontWeightBold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• 現在のデータをすべて保存できます', style: TextStyle(fontSize: 14)),
                  const Text('• 複数デバイスでの利用が可能になります', style: TextStyle(fontSize: 14)),
                  const Text('• データを安全にデータが保護できます', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('後で'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showUpgradeAccountDialog();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('登録/ログイン'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('ログイン'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('既存のアカウントにログインします：'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ログイン後、現在のゲストデータは失われます。',
                        style: TextStyle(fontSize: 12),
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
                  const Text('アカウントをお持ちでない方は'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showUpgradeAccountDialog();
                    },
                    child: Text(
                      '新規作成',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: DynamicTokens.fontWeightBold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(strings.buttonCancel),
            ),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログインが完了しました！'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('ログイン'),
            ),
          ],
        );
        },
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(strings.buttonCancel),
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

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _SubscriptionPurchaseDialog extends StatefulWidget {
  final WidgetRef ref;
  
  const _SubscriptionPurchaseDialog({required this.ref});
  
  @override
  State<_SubscriptionPurchaseDialog> createState() => _SubscriptionPurchaseDialogState();
}

class _SubscriptionPurchaseDialogState extends State<_SubscriptionPurchaseDialog> {
  String? selectedProductId;
  
  @override
  Widget build(BuildContext context) {
    final dynamicTokens = widget.ref.watch(dynamicTokensProvider);
    final strings = widget.ref.watch(appStringsProvider);
    
    return AlertDialog(
      title: Consumer(
        builder: (context, ref, child) {
          final strings = ref.watch(appStringsProvider);
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
                Text(strings.subscriptionPremiumPlan),
              ],
            ),
            error: (error, stack) => Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(strings.subscriptionPremiumPlan),
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
            // 特典列表
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
                  Text(strings.subscriptionBenefits,
                    style: TextStyle(
                      fontWeight: DynamicTokens.fontWeightBold,
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
            
            // 产品选择列表
            Text(
              'プランを選択',
              style: TextStyle(
                fontWeight: DynamicTokens.fontWeightBold,
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
                    print('🛒 [UI] 渲染产品列表，数量: ${products.length}');
                    
                    if (products.isEmpty) {
                      return const Text('利用可能なプランがありません');
                    }
                    
                    // 设置默认选择
                    selectedProductId ??= products.first.id;
                    print('🛒 [UI] 当前选择的产品: $selectedProductId');
                    
                    return Column(
                      children: products.map((product) {
                        final isSelected = selectedProductId == product.id;
                        print('🛒 [UI] 渲染产品: ${product.id}, 选中: $isSelected');
                        
                        return GestureDetector(
                          onTap: () {
                            print('🛒 [UI] 选择产品: ${product.id}');
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
                                          fontWeight: DynamicTokens.fontWeightBold,
                                          color: isSelected ? Colors.amber.shade800 : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        product.price,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: DynamicTokens.fontWeightBold,
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
          child: Text(strings.buttonCancel),
        ),
        ElevatedButton(
          onPressed: selectedProductId != null ? () {
            Navigator.of(context).pop();
            _purchaseProduct(selectedProductId!, widget.ref, context);
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
  
  static Future<void> _purchaseProduct(String productId, WidgetRef ref, BuildContext context) async {
    print('🛒 [UI] 开始购买产品: $productId');
    
    try {
      final success = await SubscriptionService.purchaseSubscription(productId);
      
      if (success) {
        print('🛒 [UI] 购买成功，刷新UI状态');
        ref.invalidate(subscriptionStatusProvider);
        ref.invalidate(hasActiveSubscriptionProvider);
        ref.invalidate(subscriptionExpiryProvider);
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 購読が完了しました！'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      print('🛒 [UI] 购买异常: $e');
    }
  }
}
