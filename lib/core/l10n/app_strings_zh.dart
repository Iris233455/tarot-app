import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'app_strings_base.dart';

/// 简体中文文本定义
class AppStringsZhCN extends AppStringsBase {
  @override
  String get myDeckTitle => '我的牌组';
  
  // ==================== 系统主标题 ====================
  @override
  String get appName => '神秘塔罗';
  @override
  String get appSubtitle => '探索你的命运';
  
  // ==================== 首页相关 ====================
  @override
  String get homeDailyCard => '每日卡牌';
  @override
  String get homeTarotCalendar => '塔罗日历';
  @override
  String get homeTodayMessage => '今日讯息';
  @override
  String get homeLongPressToDraw => '长按抽牌';
  
  // ==================== 占卜流程 ====================
  @override
  String get readingSelectSpread => '选择牌阵';
  @override
  String get readingTarotReading => '塔罗占卜';
  @override
  String get readingExplanation => '说明';
  @override
  String get readingQuestion => '问题';
  @override
  String get readingInterpretation => '解读';
  @override
  String get labelQuestionPoints => '提问要点';

  // ==================== 页面标题/标签 ====================
  @override
  String get historyTitle => '历史记录';
  @override
  String get tabAI => 'AI诊断';
  @override
  String get tabCardInterpretation => '卡牌解读';
  
  // ==================== 兑换码页面 ====================
  @override
  String get redemptionTitle => '兑换码';
  @override
  String get redemptionAbout => '关于兑换码';
  @override
  String get redemptionDescription => '输入从实体卡牌或活动中获得的兑换码，即可免费享受指定天数的高级服务。';
  @override
  String get redemptionInputLabel => '输入兑换码';
  @override
  String get redemptionComplete => '兑换完成！';
  
  // ==================== 订阅相关 ====================
  @override
  String get subscriptionPremiumPlan => '高级计划';
  @override
  String get subscriptionBenefits => '高级特权';
  @override
  String get subscriptionNoAds => '无广告流畅体验';
  @override
  String get subscriptionUnlimitedReading => '无限塔罗解读';
  @override
  String get subscriptionPremiumDesign => '高级卡牌设计';
  @override
  String get subscriptionPrioritySupport => '优先客服支持';
  
  // ==================== 设置页面 ====================
  @override
  String get settingsDeckSelection => '选择牌组';
  @override
  String get settingsSelectDeck => '选择要使用的牌组';
  @override
  String get settingsBackDesign => '背面设计';
  @override
  String get settingsBuyRealDeck => '购买实体牌组';
  @override
  String get settingsBuyDescription => '购买实体塔罗卡牌';
  @override
  String get settingsMusic => '音乐';
  @override
  String get settingsReset => '重置';
  
  // ==================== 按钮文字 ====================
  @override
  String get buttonComplete => '完成';
  @override
  String get buttonCancel => '取消';
  @override
  String get buttonConfirm => '确认';
  @override
  String get buttonNext => '下一步';
  @override
  String get buttonRedeemNow => '立即兑换';
  @override
  String get buttonCheckCode => '检查代码';
  @override
  String get buttonReset => '重置';
  @override
  String get buttonRetry => '重试';
  @override
  String get buttonDelete => '删除';
  @override
  String get buttonDrawAgain => '再占一次';
  @override
  String get buttonDrawTodayCard => '抽取今日卡牌';
  
  // ==================== 状态消息 ====================
  @override
  String get messageAlreadyDrawnToday => '今天已经抽过牌了，请明天再来！';
  @override
  String get messageRedemptionSuccess => '兑换完成！';
  @override
  String get messageLoading => '加载中...';
  @override
  String get messageError => '发生错误';
  @override
  String get messageNoHistory => '还没有历史记录';
  @override
  String get messageCardDrawnToday => '已抽取今日卡牌！';
  @override
  String get waitingAIPreparing => 'AI解读准备中...';
  
  // ==================== 通用文字 ====================
  @override
  String get commonYes => '是';
  @override
  String get commonNo => '否';
  @override
  String get commonOk => '确定';
  @override
  String get commonSave => '保存';
  @override
  String get commonEdit => '编辑';
  @override
  String get commonDelete => '删除';
  @override
  String get commonClose => '关闭';
  @override
  String get labelUpright => '正位置';
  @override
  String get labelReversed => '逆位置';
  @override
  String get labelStory => '故事';
  @override
  String get labelKeywords => '关键词';
  @override
  String get shareTitle => '分享';

  // ==================== 通用对话框/标题 ====================
  @override
  String get dialogDeleteConfirmTitle => '删除确认';
  @override
  String get dialogDeleteConfirmContent => '确定要删除这条历史记录吗？';
  @override
  String get dialogPleaseWaitTillDay => '请等待到那一天';
  @override
  String get shareFeatureComingSoon => '分享功能即将推出';
  @override
  String get adRequiredTitle => '需要观看广告';
  
  // ==================== 路由日志 ====================
  @override
  String get messageRouterRedirectCheck => '路由重定向检查';
  @override
  String get messageLoadingStateNoRedirect => 'Loading状态，不重定向';
  @override
  String get messageOAuthCallbackDetected => '检测到 OAuth 回调';
  @override
  String get messageUnauthenticatedRedirect => '未登录，执行重定向';
  @override
  String get messageAuthenticatedRedirect => '已登录，执行重定向';
  @override
  String get messageNoRedirect => '无需重定向';
  
  // ==================== 主题命名 ====================
  @override
  String get themeOcean => '海洋';
  @override
  String get themeForest => '森林';
  @override
  String get themeNightSky => '夜空';
  @override
  String get themeMoonlight => '月光';
  @override
  String get themeCloud => '云朵';
  @override
  String get themeClearSky => '晴空';
  
  // ==================== 牌阵选择 ====================
  @override
  String get labelOneOracle => '单张牌';
  @override
  String get labelOneOracleDescription => '一张牌直觉提示';
  @override
  String get labelTwoCard => '两张牌';
  @override
  String get labelTwoCardDescription => '比较/对立主题';
  @override
  String get labelThreeCard => '三张牌';
  @override
  String get labelThreeCardDescription => '过去/现在/未来';
  
  // ==================== 画廊 ====================
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
  
  // ==================== 订阅服务（占位） ====================
  @override
  String get messageSimulatedPurchaseSuccess => '';
  @override
  String get messageSimulatedPurchaseFailed => '';
  @override
  String get messageRealPaymentNotImplemented => '';
  @override
  String get messagePurchaseException => '';
  @override
  String get messageActivateSubscriptionWithCode => '';
  @override
  String get messageSubscriptionExtended => '';
  @override
  String get messageRestorePurchasesStart => '';
  @override
  String get messageSimulatedRestorePurchases => '';
  @override
  String get messageNoRestorablePurchases => '';
  @override
  String get messageCancelSubscription => '';
  @override
  String get messageSimulatedCancelSubscriptionSuccess => '';
  @override
  String get messageGetProductsStart => '';
  @override
  String get messageCallSupabaseFunction => '';
  @override
  String get messageSupabaseResponse => '';
  @override
  String get messageResponseType => '';
  @override
  String get messageSuccessfullyGotProducts => '';
  @override
  String get messageProductData => '';
  @override
  String get messageProduct => '';
  @override
  String get messageSupabaseDataFormatIncorrect => '';
  @override
  String get messageGetProductsFailed => '';
  @override
  String get messageErrorType => '';
  @override
  String get messagePostgrestException => '';
  @override
  String get messageFallbackToDefaultProducts => '';
  @override
  String get messageCurrentSubscriptionStatus => '';
  @override
  String get messageSubscriptionExpiry => '';
  @override
  String get messageSubscriptionStatusSaved => '';
  @override
  String get messageCleanupUserSubscriptionData => '';
  @override
  String get messageUserSubscriptionDataCleanupComplete => '';
  @override
  String get messageCleanupUserSubscriptionDataFailed => '';
  @override
  String get messageSyncLocalDataToSupabase => '';
  @override
  String get messageSyncLocalSubscriptionToSupabase => '';
  @override
  String get messageLocalSubscriptionDataSyncedToSupabase => '';
  @override
  String get messageNoLocalSubscriptionDataToSync => '';
  @override
  String get messageSyncLocalSubscriptionDataToSupabaseFailed => '';
  @override
  String get messageGetSubscriptionStatusFromSupabaseFailed => '';
  @override
  String get messageGetSubscriptionExpiryFromSupabaseFailed => '';
  @override
  String get messageCannotSyncToSupabaseUserNotLoggedIn => '';
  @override
  String get messageSubscriptionInfoSyncedToSupabase => '';
  @override
  String get messageSyncSubscriptionInfoToSupabaseFailed => '';
  @override
  String get messageCannotSyncFromSupabaseUserNotLoggedIn => '';
  @override
  String get messageStartSyncSubscriptionStatusFromSupabase => '';
  @override
  String get messageSyncSubscriptionStatusFromSupabaseSuccess => '';
  @override
  String get messageSyncSubscriptionStatusFromSupabaseFailed => '';
  @override
  String get messageUserNotLoggedInExpiryNull => '';
  @override
  String get messageGetSubscriptionExpiryFailed => '';
  @override
  String get messageStartingSubscriptionPurchase => '';
  @override
  String get messagePurchaseFailedUserNotLoggedIn => '';
  @override
  String get messagePurchaseFailedAnonymousUser => '';
  @override
  String get messageSimulatedPurchaseStart => '';
  
  // ==================== 其他新增键（占位） ====================
  @override
  String get messageAdMobInitSuccess => '';
  @override
  String get messageAdMobInitFailed => '';
  @override
  String get messageSubscriptionInitSuccess => '';
  @override
  String get messageSubscriptionInitFailed => '';
  @override
  String get messageSupabaseInitSuccess => '';
  @override
  String get messageExistingUserSession => '';
  @override
  String get messageSupabaseInitFailed => '';
  @override
  String get messageUsingOfflineMode => '';
  @override
  String get messageUserType => '';
  @override
  String get messageNoUserSession => '';
  @override
  String get messageCachedUserId => '';
  @override
  String get messageLoginToRecoverData => '';
  @override
  String get messageDatabaseConnectionSuccess => '';
  @override
  String get messageConnectionFailed => '';
  @override
  String get messageCurrentMode => '';
  @override
  String get labelOfflineMode => '';
  @override
  String get messageOfflineModeDescription => '';
  @override
  String get labelOnlineMode => '';
  @override
  String get messageSupabaseConnectionSuccess => '';
  @override
  String get messageEnterRedemptionCode => '';
  @override
  String get messageCheckFailed => '';
  @override
  String get messageGuestCannotUseRedemptionCode => '';
  @override
  String get messageRedemptionFailed => '';
  @override
  String get messagePremiumServiceObtained => '';
  @override
  String get labelDays => '';
  @override
  String get labelNewExpiry => '';
  @override
  String get messageScanFailed => '';
  @override
  String get messagePasteFailed => '';
  @override
  String get messageRedemptionCodeDescription => '';
  @override
  String get buttonPaste => '';
  @override
  String get buttonScan => '';
  @override
  String get labelUsageInstructions => '';
  @override
  String get messageRedemptionCodeUsageLimit => '';
  @override
  String get messageRedemptionCodeExpiry => '';
  @override
  String get messageLoginRequiredForRedemption => '';
  @override
  String get messageRedemptionDaysAdded => '';
  @override
  String get labelSelectYear => '';
  @override
  String get labelMonday => '';
  @override
  String get labelTuesday => '';
  @override
  String get labelWednesday => '';
  @override
  String get labelThursday => '';
  @override
  String get labelFriday => '';
  @override
  String get labelSaturday => '';
  @override
  String get labelSunday => '';
  @override
  String get labelFavorites => '';
  @override
  String get messageFavoritesComingSoon => '';
  @override
  String get labelMajorArcana => '';
  @override
  String get labelWands => '';
  @override
  String get labelCups => '';
  @override
  String get labelSwords => '';
  @override
  String get labelPentacles => '';
  @override
  String get labelUnknown => '';
  @override
  String get messageAIFailed => '';
  @override
  String get buttonGetAIReading => '';
  @override
  String get labelLanguage => '';
  @override
  String get messageLanguageSwitched => '';
  @override
  String get labelCardDetail => '';
  @override
  String get labelLove => '';
  @override
  String get labelCareer => '';
  @override
  String get labelMoney => '';
  @override
  String get labelInterpersonal => '';
  @override
  String get labelPastPresentFuture => '';
  @override
  String get labelEmotionConsciousness => '';
  @override
  String get labelCauseSolution => '';
  
  // ==================== 抽牌/洗切牌 页面 ====================
  @override
  String get readingPreparing => '准备卡牌';
  @override
  String get readingShuffling => '洗牌中';
  @override
  String get readingCutting => '切牌中';
  @override
  String get readingDrawing => '请抽牌';
  @override
  String get readingResultTitle => '占卜结果';
  @override
  String get readingComplete => '占卜完成';
  @override
  String get hintSwipeUpToPick => '上滑取顶牌';
  @override
  String get hintDragToSlot => '向上拖拽放入槽位';
  @override
  String get errorDrawFailed => '抽牌失败';
  @override
  String get buttonSeeResult => '查看结果';
  @override
  String get readingTitle => '';
  @override
  String get labelSelectCardCount => '';
  @override
  String get buttonShuffle => '';
  @override
  String get buttonCut => '';
  @override
  String get messageStartingGoogleLogin => '';
  @override
  String get messageCurrentPlatform => '';
  @override
  String get messageAlreadyLoggedIn => '';
  @override
  String get messageSkipLoginReturnSuccess => '';
  @override
  String get messageAnonymousUserLogout => '';
  @override
  String get messageGoogleLoginFailed => '';
  @override
  String get messageWebPlatformOAuth => '';
  @override
  String get messageCurrentURL => '';
  @override
  String get messageExpectedRedirectURI => '';
  @override
  String get messageGoogleOAuthResult => '';
  @override
  String get messageWebGoogleLoginUserInfo => '';
  @override
  String get messageUserId => '';
  @override
  String get messageEmail => '';
  @override
  String get messageWebGoogleOAuthError => '';
  @override
  String get messageCheckGoogleCloudConsole => '';
  @override
  String get messageCheckRedirectURI => '';
  @override
  String get messageNativePlatformGoogleSignIn => '';
  @override
  String get messageStartingNativeGoogleLogin => '';
  @override
  String get messageUserCancelledGoogleLogin => '';
  @override
  String get messageGoogleLoginSuccess => '';
  @override
  String get messageCannotGetGoogleAuthToken => '';
  @override
  String get messageGoogleAuthTokenSuccess => '';
  @override
  String get messageSupabaseLoginSuccess => '';
  @override
  String get messageSupabaseLoginFailed => '';
  @override
  String get messageNativeGoogleLoginErrorDetails => '';
  @override
  String get messageErrorInfo => '';
  @override
  String get messageUserCancelledLogin => '';
  @override
  String get messageCheckGoogleConfigBundleId => '';
  @override
  String get messageCheckNetworkConnection => '';
  @override
  String get messageStartingAccountUpgrade => '';
  @override
  String get messageCurrentAnonymousUserId => '';
  @override
  String get messageAccountUpgradeSuccess => '';
  @override
  String get messageUpgradedUserId => '';
  @override
  String get messageAccountUpgradeFailed => '';
  @override
  String get messageSavingDailyCard => '';
  @override
  String get messageDate => '';
  @override
  String get messageCard => '';
  @override
  String get messageAlreadyDrewCardToday => '';
  @override
  String get messageAlreadyDrewCardTodayException => '';
  @override
  String get messageMessage => '';
  @override
  String get messageDailyCardSavedSuccess => '';
  @override
  String get messageRedemptionCodeService => '';
  @override
  String get messageInvalidRedemptionCodeFormat => '';
  @override
  String get messageRedemptionCodeNotFound => '';
  @override
  String get messageRedemptionCodeAlreadyUsed => '';
  @override
  String get messageRedemptionCodeExpired => '';
  @override
  String get messageValidRedemptionCode => '';
  @override
  String get messagePremiumService => '';
  @override
  String get messageCheckRedemptionCodeFailed => '';
  @override
  String get messageNetworkErrorCheckConnection => '';
  // 重复定义已移除：messageLoginRequiredForRedemption / messageGuestCannotUseRedemptionCode
  @override
  String get messageRedemptionComplete => '';
  @override
  String get messageRedemptionCodeUsageFailed => '';
  @override
  String get messageTestCodeGenerationDevModeOnly => '';
  @override
  String get messageGenerationFailed => '';
  @override
  String get labelMonthly => '';
  @override
  String get label3Months => '';
  @override
  String get labelYearly => '';
  @override
  String get labelDiscount => '';
  @override
  String get labelPremiumSubscription => '';
  @override
  String get labelPremiumSubscriptionDescription => '';
  @override
  String get labelPremium3MonthsPlan => '';
  @override
  String get labelPremium3MonthsPlanDescription => '';
  @override
  String get labelPremiumYearlyPlan => '';
  @override
  String get labelPremiumYearlyPlanDescription => '';
  @override
  String get messageSubscriptionServiceInitStart => '';
  @override
  String get messageDevModeSimulatedSubscription => '';
  @override
  String get messageSubscriptionServiceInitComplete => '';
  @override
  String get messageUserNotLoggedInSubscriptionNone => '';
  @override
  String get messageGetSubscriptionStatusFailed => '';
}


