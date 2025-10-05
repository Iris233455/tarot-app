import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'app_strings_base.dart';

/// 日文文本定义
class AppStringsJa extends AppStringsBase {
  @override
  String get myDeckTitle => 'マイデッキ';
  
  // ==================== 系统主标题 ====================
  @override
  String get appName => 'Mystic Tarot';
  @override
  String get appSubtitle => 'あなたの運命を占います';
  
  // ==================== 首页相关 ====================
  @override
  String get homeDailyCard => '本日のカード';
  @override
  String get homeTarotCalendar => 'タロットカレンダー';
  @override
  String get homeTodayMessage => '今日のメッセージ';
  @override
  String get homeLongPressToDraw => '長押ししてカードを引く';
  
  // ==================== 占卜流程 ====================
  @override
  String get readingSelectSpread => 'スプレットを選択';
  @override
  String get readingTarotReading => 'タロット占い';
  @override
  String get readingExplanation => '説明';
  @override
  String get readingQuestion => '質問';
  @override
  String get readingInterpretation => '解釈';
  @override
  String get labelQuestionPoints => '質問のポイント';

  // ==================== ページタイトル/タブ ====================
  @override
  String get historyTitle => '履歴';
  @override
  String get tabAI => 'AI診断';
  @override
  String get tabCardInterpretation => 'カードの解釈';
  
  // ==================== 兑换码页面 ====================
  @override
  String get redemptionTitle => '引き換えコード';
  @override
  String get redemptionAbout => '引き換えコードについて';
  @override
  String get redemptionDescription => '実物カードやイベントで入手した引き換えコードを入力すると、指定日数のプレミアムサービスを無料でご利用いただけます。';
  @override
  String get redemptionInputLabel => '引き換えコードを入力';
  @override
  String get redemptionComplete => '引き換え完了！';
  
  // ==================== 订阅相关 ====================
  @override
  String get subscriptionPremiumPlan => 'プレミアムプラン';
  @override
  String get subscriptionBenefits => 'プレミアム特典';
  @override
  String get subscriptionNoAds => '広告なしでスムーズな体験';
  @override
  String get subscriptionUnlimitedReading => '無制限のタロット解読';
  @override
  String get subscriptionPremiumDesign => 'プレミアムカードデザイン';
  @override
  String get subscriptionPrioritySupport => '優先サポート';
  
  // ==================== 设置页面 ====================
  @override
  String get settingsDeckSelection => 'デッキを選択';
  @override
  String get settingsSelectDeck => '使用するデッキを選択';
  @override
  String get settingsBackDesign => '背面デザイン';
  @override
  String get settingsBuyRealDeck => 'リアルデッキを購入';
  @override
  String get settingsBuyDescription => '実物のタロットカードを購入';
  @override
  String get settingsMusic => '音楽';
  @override
  String get settingsReset => 'リセット';
  
  // ==================== 按钮文字 ====================
  @override
  String get buttonComplete => '完了';
  @override
  String get buttonCancel => 'キャンセル';
  @override
  String get buttonConfirm => '確認';
  @override
  String get buttonNext => '次へ';
  @override
  String get buttonRedeemNow => '今すぐ引き換える';
  @override
  String get buttonCheckCode => 'コードを確認';
  @override
  String get buttonReset => 'リセット';
  @override
  String get buttonRetry => '再試行';
  @override
  String get buttonDelete => '削除';
  @override
  String get buttonDrawAgain => 'もう一度占う';
  @override
  String get buttonDrawTodayCard => '本日のカードを引く';
  
  // ==================== 状态消息 ====================
  @override
  String get messageAlreadyDrawnToday => '今日はすでにカードを引いています。明日また来てください！';
  @override
  String get messageRedemptionSuccess => '引き換え完了！';
  @override
  String get messageLoading => '読み込み中...';
  @override
  String get messageError => 'エラーが発生しました';
  @override
  String get messageNoHistory => 'まだ履歴がありません';
  @override
  String get messageCardDrawnToday => '本日のカードを引きました！';
  @override
  String get waitingAIPreparing => 'AI解読を準備中...';
  
  // ==================== 通用文字 ====================
  @override
  String get commonYes => 'はい';
  @override
  String get commonNo => 'いいえ';
  @override
  String get commonOk => 'OK';
  @override
  String get commonSave => '保存';
  @override
  String get commonEdit => '編集';
  @override
  String get commonDelete => '削除';
  @override
  String get commonClose => '閉じる';
  @override
  String get labelUpright => '正位置';
  @override
  String get labelReversed => '逆位置';
  @override
  String get labelStory => '物語り';
  @override
  String get labelKeywords => 'キーワード';
  @override
  String get shareTitle => 'シェア';

  // ==================== 通用对话框/标题 ====================
  @override
  String get dialogDeleteConfirmTitle => '削除確認';
  @override
  String get dialogDeleteConfirmContent => 'この履歴を削除しますか？';
  @override
  String get dialogPleaseWaitTillDay => 'その日までお待ちください';
  @override
  String get shareFeatureComingSoon => 'シェア機能は近日実装予定です';
  @override
  String get adRequiredTitle => '広告視聴が必要です';
  
  // ==================== ルーター/リダイレクトログ ====================
  @override
  String get messageRouterRedirectCheck => 'Router リダイレクトチェック';
  @override
  String get messageLoadingStateNoRedirect => '読み込み状態：リダイレクトしません';
  @override
  String get messageOAuthCallbackDetected => 'OAuth コールバックを検出';
  @override
  String get messageUnauthenticatedRedirect => '未認証：リダイレクト';
  @override
  String get messageAuthenticatedRedirect => '認証済み：リダイレクト';
  @override
  String get messageNoRedirect => 'リダイレクトなし';
  
  // ==================== テーマ名 ====================
  @override
  String get themeOcean => 'オーシャン';
  @override
  String get themeForest => 'フォレスト';
  @override
  String get themeNightSky => 'ナイトスカイ';
  @override
  String get themeMoonlight => 'ムーンライト';
  @override
  String get themeCloud => 'クラウド';
  @override
  String get themeClearSky => 'クリアスカイ';
  
  // ==================== スプレッド選択 ====================
  @override
  String get labelOneOracle => 'ワンオラクル';
  @override
  String get labelOneOracleDescription => '1枚で直感的な指針を得ます';
  @override
  String get labelTwoCard => 'ツーカード';
  @override
  String get labelTwoCardDescription => '比較や対立のテーマに適します';
  @override
  String get labelThreeCard => 'スリーカード';
  @override
  String get labelThreeCardDescription => '過去・現在・未来を読み解きます';
  
  // ==================== ギャラリー ====================
  @override
  String get galleryTitle => 'ギャラリー';
  @override
  String get labelSearchCard => 'カードを検索...';
  @override
  String get labelMinorArcana => '小アルカナ';
  @override
  String get labelTarotExperts => 'タロットの巨匠';
  @override
  String get labelWaite => 'A.E. Waite';
  @override
  String get labelSmith => 'Pamela Colman Smith';
  @override
  String get labelCrowley => 'Aleister Crowley';
  @override
  String get labelTarotBooks => 'タロットの書籍';
  @override
  String get labelPictorialKey => 'Pictorial Key to the Tarot';
  @override
  String get labelBookOfThoth => 'Book of Thoth';
  @override
  String get labelMeaning => 'の意味';
  @override
  String get messageNoKeywords => 'キーワードデータなし';
  
  // ==================== 订阅服务相关 ====================
  @override
  String get messageSimulatedPurchaseSuccess => '✅ 模拟购买成功';
  @override
  String get messageSimulatedPurchaseFailed => '❌ 模拟购买失败';
  @override
  String get messageRealPaymentNotImplemented => '❌ 真实支付尚未实现';
  @override
  String get messagePurchaseException => '❌ 购买订阅异常';
  @override
  String get messageActivateSubscriptionWithCode => '🎫 通过兑换码激活订阅，到期时间';
  @override
  String get messageSubscriptionExtended => '🎫 延长订阅';
  @override
  String get messageRestorePurchasesStart => '🔄 开始恢复购买...';
  @override
  String get messageSimulatedRestorePurchases => '🧪 模拟恢复购买...';
  @override
  String get messageNoRestorablePurchases => '❌ 没有找到可恢复的购买记录';
  @override
  String get messageCancelSubscription => '❌ 取消订阅...';
  @override
  String get messageSimulatedCancelSubscriptionSuccess => '✅ 模拟取消订阅成功';
  @override
  String get messageGetProductsStart => '🛒 开始获取订阅产品列表...';
  @override
  String get messageCallSupabaseFunction => '🔄 调用Supabase函数';
  @override
  String get messageSupabaseResponse => '📦 Supabase响应';
  @override
  String get messageResponseType => '📦 响应类型';
  @override
  String get messageSuccessfullyGotProducts => '✅ 成功获取';
  @override
  String get messageProductData => '   产品数据';
  @override
  String get messageProduct => '   产品';
  @override
  String get messageSupabaseDataFormatIncorrect => '⚠️ Supabase返回数据格式不正确';
  @override
  String get messageGetProductsFailed => '❌ 获取订阅产品列表失败';
  @override
  String get messageErrorType => '   错误类型';
  @override
  String get messagePostgrestException => '   PostgrestException';
  @override
  String get messageFallbackToDefaultProducts => '🔄 回退到默认产品列表';
  @override
  String get messageCurrentSubscriptionStatus => '📊 当前订阅状态';
  @override
  String get messageSubscriptionExpiry => '📅 订阅到期时间';
  @override
  String get messageSubscriptionStatusSaved => '💾 订阅状态已保存';
  @override
  String get messageCleanupUserSubscriptionData => '🧹 清理用户订阅数据...';
  @override
  String get messageUserSubscriptionDataCleanupComplete => '✅ 用户订阅数据清理完成';
  @override
  String get messageCleanupUserSubscriptionDataFailed => '🚨 清理用户订阅数据失败';
  @override
  String get messageSyncLocalDataToSupabase => '🔄 开始同步本地订阅数据到Supabase...';
  @override
  String get messageSyncLocalSubscriptionToSupabase => '🔄 同步本地订阅到Supabase';
  @override
  String get messageLocalSubscriptionDataSyncedToSupabase => '✅ 本地订阅数据同步到Supabase成功';
  @override
  String get messageNoLocalSubscriptionDataToSync => '📝 没有本地订阅数据需要同步';
  @override
  String get messageSyncLocalSubscriptionDataToSupabaseFailed => '🚨 同步本地订阅数据到Supabase失败';
  @override
  String get messageGetSubscriptionStatusFromSupabaseFailed => '🚨 从Supabase获取订阅状态失败';
  @override
  String get messageGetSubscriptionExpiryFromSupabaseFailed => '🚨 从Supabase获取订阅到期时间失败';
  @override
  String get messageCannotSyncToSupabaseUserNotLoggedIn => '🚨 无法同步到Supabase：用户未登录';
  @override
  String get messageSubscriptionInfoSyncedToSupabase => '✅ 订阅信息已同步到Supabase';
  @override
  String get messageSyncSubscriptionInfoToSupabaseFailed => '🚨 同步订阅信息到Supabase失败';
  @override
  String get messageCannotSyncFromSupabaseUserNotLoggedIn => '🚨 无法从Supabase同步：用户未登录';
  @override
  String get messageStartSyncSubscriptionStatusFromSupabase => '🔄 开始从Supabase同步订阅状态...';
  @override
  String get messageSyncSubscriptionStatusFromSupabaseSuccess => '✅ 从Supabase同步订阅状态成功';
  @override
  String get messageSyncSubscriptionStatusFromSupabaseFailed => '🚨 从Supabase同步订阅状态失败';
  @override
  String get messageUserNotLoggedInExpiryNull => '🚨 用户未登录，订阅到期时间为null';
  @override
  String get messageGetSubscriptionExpiryFailed => '🚨 获取订阅到期时间失败';
  @override
  String get messageStartingSubscriptionPurchase => '🛒 开始购买订阅...';
  @override
  String get messagePurchaseFailedUserNotLoggedIn => '❌ 购买失败：用户未登录';
  @override
  String get messagePurchaseFailedAnonymousUser => '❌ 购买失败：匿名用户不能购买订阅';
  @override
  String get messageSimulatedPurchaseStart => '🧪 模拟购买流程开始，产品ID';
  
  // ==================== 其他缺失的键 ====================
  @override
  String get messageAdMobInitSuccess => '✅ AdMob初始化成功';
  @override
  String get messageAdMobInitFailed => '⚠️ AdMob初始化失败';
  @override
  String get messageSubscriptionInitSuccess => '✅ 订阅服务初始化成功';
  @override
  String get messageSubscriptionInitFailed => '⚠️ 订阅服务初始化失败';
  @override
  String get messageSupabaseInitSuccess => '✅ Supabase初始化成功';
  @override
  String get messageExistingUserSession => '🔍 检测到现有用户会话';
  @override
  String get messageSupabaseInitFailed => '⚠️ Supabase初始化失败';
  @override
  String get messageUsingOfflineMode => '📱 オフラインモードを使用';
  @override
  String get messageUserType => '📧 ユーザー種別';
  @override
  String get messageNoUserSession => '🔐 ユーザーセッションなし';
  @override
  String get messageCachedUserId => '🔍 キャッシュされたユーザーID';
  @override
  String get messageLoginToRecoverData => '💡 ログインしてデータを復元';
  @override
  String get messageDatabaseConnectionSuccess => '✅ データベース接続成功';
  @override
  String get messageConnectionFailed => '⚠️ 接続に失敗しました';
  @override
  String get messageCurrentMode => '🔄 現在のモード';
  @override
  String get labelOfflineMode => 'オフラインモード';
  @override
  String get messageOfflineModeDescription => '💡 オフラインモード：データは端末内にのみ保存されます';
  @override
  String get labelOnlineMode => 'オンラインモード';
  @override
  String get messageSupabaseConnectionSuccess => '🎉 Supabaseへの接続に成功しました';
  @override
  String get messageEnterRedemptionCode => '请输入兑换码';
  @override
  String get messageCheckFailed => '检查失败';
  @override
  String get messageGuestCannotUseRedemptionCode => '游客不能使用兑换码';
  @override
  String get messageRedemptionFailed => '兑换失败';
  @override
  String get messagePremiumServiceObtained => '获得高级服务';
  @override
  String get labelDays => '天';
  @override
  String get labelNewExpiry => '新到期时间';
  @override
  String get messageScanFailed => '扫描失败';
  @override
  String get messagePasteFailed => '粘贴失败';
  @override
  String get messageRedemptionCodeDescription => '兑换码说明';
  @override
  String get buttonPaste => '粘贴';
  @override
  String get buttonScan => '扫描';
  @override
  String get labelUsageInstructions => '使用说明';
  @override
  String get messageRedemptionCodeUsageLimit => '兑换码使用限制';
  @override
  String get messageRedemptionCodeExpiry => '兑换码过期时间';
  @override
  String get messageLoginRequiredForRedemption => '兑换需要登录';
  @override
  String get messageRedemptionDaysAdded => '兑换码添加的天数';
  @override
  String get labelSelectYear => '选择年份';
  @override
  String get labelMonday => '月';
  @override
  String get labelTuesday => '火';
  @override
  String get labelWednesday => '水';
  @override
  String get labelThursday => '木';
  @override
  String get labelFriday => '金';
  @override
  String get labelSaturday => '土';
  @override
  String get labelSunday => '日';
  @override
  String get labelFavorites => 'お気に入り';
  @override
  String get messageFavoritesComingSoon => '占い結果のお気に入りは次版で拡充します。現状は履歴から閲覧可能です。';
  @override
  String get labelMajorArcana => '大アルカナ';
  @override
  String get labelWands => 'ワンド';
  @override
  String get labelCups => 'カップ';
  @override
  String get labelSwords => 'ソード';
  @override
  String get labelPentacles => 'ペンタクル';
  @override
  String get labelUnknown => '不明';
  @override
  String get messageAIFailed => 'AI解読の取得に失敗しました';
  @override
  String get buttonGetAIReading => 'AI解読を取得';
  @override
  String get labelLanguage => '语言 / Language / 言語';
  @override
  String get messageLanguageSwitched => '已切换到';
  @override
  String get labelCardDetail => 'カード詳細';
  @override
  String get labelLove => '恋愛';
  @override
  String get labelCareer => '仕事・キャリア';
  @override
  String get labelMoney => '金運';
  @override
  String get labelInterpersonal => '人間関係';
  @override
  String get labelPastPresentFuture => '過去・現在・未来';
  @override
  String get labelEmotionConsciousness => '感情・意識';
  @override
  String get labelCauseSolution => '原因・解決策';
  
  // ==================== 抽牌/洗切牌 页面（Shuffle/Draw） ====================
  @override
  String get readingPreparing => 'カードを準備します';
  @override
  String get readingShuffling => 'カードをシャッフル中';
  @override
  String get readingCutting => 'カードをカット中';
  @override
  String get readingDrawing => 'カードを引いてください';
  @override
  String get readingResultTitle => '占い結果';
  @override
  String get readingComplete => '占い完了';
  @override
  String get hintSwipeUpToPick => '上にスワイプしてトップのカードを取る';
  @override
  String get hintDragToSlot => '上方向にドラッグしてスロットに入れる';
  @override
  String get errorDrawFailed => '抽出に失敗しました';
  @override
  String get buttonSeeResult => '結果を見る';
  @override
  String get readingTitle => '占い';
  @override
  String get labelSelectCardCount => 'カードの枚数を選択';
  @override
  String get buttonShuffle => 'シャッフル';
  @override
  String get buttonCut => 'カット';
  @override
  String get messageStartingGoogleLogin => '🔍 开始Google登录流程';
  @override
  String get messageCurrentPlatform => '   当前平台';
  @override
  String get messageAlreadyLoggedIn => '   ⚠️ 用户已登录';
  @override
  String get messageSkipLoginReturnSuccess => '   → 跳过登录，返回成功';
  @override
  String get messageAnonymousUserLogout => '   🚪 匿名用户登出';
  @override
  String get messageGoogleLoginFailed => '❌ Google登录失败';
  @override
  String get messageWebPlatformOAuth => '🌐 Web平台OAuth流程';
  @override
  String get messageCurrentURL => '   当前URL';
  @override
  String get messageExpectedRedirectURI => '   期望的重定向URI';
  @override
  String get messageGoogleOAuthResult => '🎉 Google OAuth结果';
  @override
  String get messageWebGoogleLoginUserInfo => '🔍 Web Google登录用户信息';
  @override
  String get messageUserId => '   用户ID';
  @override
  String get messageEmail => '   邮箱';
  @override
  String get messageWebGoogleOAuthError => '❌ Web Google OAuth错误';
  @override
  String get messageCheckGoogleCloudConsole => '   💡 检查Google Cloud Console配置';
  @override
  String get messageCheckRedirectURI => '   💡 检查重定向URI配置';
  @override
  String get messageNativePlatformGoogleSignIn => '📱 原生平台Google登录';
  @override
  String get messageStartingNativeGoogleLogin => '   → 开始原生Google登录';
  @override
  String get messageUserCancelledGoogleLogin => '   ❌ 用户取消Google登录';
  @override
  String get messageGoogleLoginSuccess => '   ✅ Google登录成功';
  @override
  String get messageCannotGetGoogleAuthToken => '   ❌ 无法获取Google认证令牌';
  @override
  String get messageGoogleAuthTokenSuccess => '   ✅ Google认证令牌成功';
  @override
  String get messageSupabaseLoginSuccess => '   ✅ Supabase登录成功';
  @override
  String get messageSupabaseLoginFailed => '   ❌ Supabase登录失败';
  @override
  String get messageNativeGoogleLoginErrorDetails => '❌ 原生Google登录错误详情';
  @override
  String get messageErrorInfo => '   错误信息';
  @override
  String get messageUserCancelledLogin => '   💡 用户取消登录';
  @override
  String get messageCheckGoogleConfigBundleId => '   💡 检查Google配置和Bundle ID';
  @override
  String get messageCheckNetworkConnection => '   💡 检查网络连接';
  @override
  String get messageStartingAccountUpgrade => '🔄 开始账户升级';
  @override
  String get messageCurrentAnonymousUserId => '   当前匿名用户ID';
  @override
  String get messageAccountUpgradeSuccess => '✅ 账户升级成功';
  @override
  String get messageUpgradedUserId => '   升级后的用户ID';
  @override
  String get messageAccountUpgradeFailed => '❌ 账户升级失败';
  @override
  String get messageSavingDailyCard => '🔄 保存每日卡牌';
  @override
  String get messageDate => '   日期';
  @override
  String get messageCard => '   卡牌';
  @override
  String get messageAlreadyDrewCardToday => '⚠️ 今天已经抽过卡牌了';
  @override
  String get messageAlreadyDrewCardTodayException => '今天已经抽过卡牌了';
  @override
  String get messageMessage => '   消息';
  @override
  String get messageDailyCardSavedSuccess => '✅ 每日卡牌保存成功';
  @override
  String get messageRedemptionCodeService => '兑换码服务';
  @override
  String get messageInvalidRedemptionCodeFormat => '兑换码格式无效';
  @override
  String get messageRedemptionCodeNotFound => '兑换码未找到';
  @override
  String get messageRedemptionCodeAlreadyUsed => '兑换码已被使用';
  @override
  String get messageRedemptionCodeExpired => '兑换码已过期';
  @override
  String get messageValidRedemptionCode => '有效兑换码';
  @override
  String get messagePremiumService => '高级服务';
  @override
  String get messageCheckRedemptionCodeFailed => '检查兑换码失败';
  @override
  String get messageNetworkErrorCheckConnection => '网络错误，请检查连接';
  // 重复定义已移除：messageLoginRequiredForRedemption / messageGuestCannotUseRedemptionCode
  @override
  String get messageRedemptionComplete => '兑换完成';
  @override
  String get messageRedemptionCodeUsageFailed => '兑换码使用失败';
  @override
  String get messageTestCodeGenerationDevModeOnly => '测试码生成仅在开发模式下可用';
  @override
  String get messageGenerationFailed => '生成失败';
  @override
  String get labelMonthly => '月額';
  @override
  String get label3Months => '3ヶ月';
  @override
  String get labelYearly => '年額';
  @override
  String get labelDiscount => '割引';
  @override
  String get labelPremiumSubscription => 'プレミアムサブスクリプション';
  @override
  String get labelPremiumSubscriptionDescription => '広告なしで無制限のタロット解読を楽しめます';
  @override
  String get labelPremium3MonthsPlan => 'プレミアム3ヶ月プラン';
  @override
  String get labelPremium3MonthsPlanDescription => '3ヶ月間のプレミアムサービス';
  @override
  String get labelPremiumYearlyPlan => 'プレミアム年額プラン';
  @override
  String get labelPremiumYearlyPlanDescription => '年間のプレミアムサービス';
  @override
  String get messageSubscriptionServiceInitStart => '🏪 订阅服务初始化开始...';
  @override
  String get messageDevModeSimulatedSubscription => '🧪 开发模式：使用模拟订阅功能';
  @override
  String get messageSubscriptionServiceInitComplete => '✅ 订阅服务初始化完成';
  @override
  String get messageUserNotLoggedInSubscriptionNone => '🚨 用户未登录，订阅状态为none';
  @override
  String get messageGetSubscriptionStatusFailed => '🚨 从Supabase获取订阅状态失败，回退到本地数据';
}


