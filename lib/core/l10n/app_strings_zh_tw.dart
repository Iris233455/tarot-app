import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'app_strings_base.dart';

/// 繁體中文文本定義
class AppStringsZhTW extends AppStringsBase {
  @override
  String get myDeckTitle => '我的牌組';
  
  // ==================== 系統主標題 ====================
  @override
  String get appName => '神秘塔羅';
  @override
  String get appSubtitle => '探索你的命運';
  
  // ==================== 首頁相關 ====================
  @override
  String get homeDailyCard => '每日卡牌';
  @override
  String get homeTarotCalendar => '塔羅日曆';
  @override
  String get homeTodayMessage => '今日訊息';
  
  // ==================== 占卜流程 ====================
  @override
  String get readingSelectSpread => '選擇牌陣';
  @override
  String get readingTarotReading => '塔羅占卜';
  @override
  String get readingExplanation => '說明';
  @override
  String get readingQuestion => '問題';
  @override
  String get readingInterpretation => '解讀';

  // ==================== 頁面標題/標籤 ====================
  @override
  String get historyTitle => '歷史記錄';
  @override
  String get tabAI => 'AI診斷';
  @override
  String get tabCardInterpretation => '卡牌解讀';
  
  // ==================== 兌換碼頁面 ====================
  @override
  String get redemptionTitle => '兌換碼';
  @override
  String get redemptionAbout => '關於兌換碼';
  @override
  String get redemptionDescription => '輸入從實體卡牌或活動中獲得的兌換碼，即可免費享受指定天數的高級服務。';
  @override
  String get redemptionInputLabel => '輸入兌換碼';
  @override
  String get redemptionComplete => '兌換完成！';
  
  // ==================== 訂閱相關 ====================
  @override
  String get subscriptionPremiumPlan => '高級計劃';
  @override
  String get subscriptionBenefits => '高級特權';
  @override
  String get subscriptionNoAds => '無廣告流暢體驗';
  @override
  String get subscriptionUnlimitedReading => '無限塔羅解讀';
  @override
  String get subscriptionPremiumDesign => '高級卡牌設計';
  @override
  String get subscriptionPrioritySupport => '優先客服支持';
  
  // ==================== 設定頁面 ====================
  @override
  String get settingsDeckSelection => '選擇牌組';
  @override
  String get settingsSelectDeck => '選擇要使用的牌組';
  @override
  String get settingsBackDesign => '背面設計';
  @override
  String get settingsBuyRealDeck => '購買實體牌組';
  @override
  String get settingsBuyDescription => '購買實體塔羅卡牌';
  @override
  String get settingsMusic => '音樂';
  @override
  String get settingsReset => '重置';
  
  // ==================== 按鈕文字 ====================
  @override
  String get buttonComplete => '完成';
  @override
  String get buttonCancel => '取消';
  @override
  String get buttonConfirm => '確認';
  @override
  String get buttonRedeemNow => '立即兌換';
  @override
  String get buttonCheckCode => '檢查代碼';
  @override
  String get buttonReset => '重置';
  @override
  String get buttonRetry => '重試';
  @override
  String get buttonDelete => '刪除';
  @override
  String get buttonDrawAgain => '再占一次';
  
  // ==================== 狀態消息 ====================
  @override
  String get messageAlreadyDrawnToday => '今天已經抽過牌了，請明天再來！';
  @override
  String get messageRedemptionSuccess => '兌換完成！';
  @override
  String get messageLoading => '載入中...';
  @override
  String get messageError => '發生錯誤';
  @override
  String get messageNoHistory => '尚無歷史記錄';
  @override
  String get messageCardDrawnToday => '已抽取今日卡牌！';
  @override
  String get waitingAIPreparing => 'AI解讀準備中...';
  
  // ==================== 通用文字 ====================
  @override
  String get commonYes => '是';
  @override
  String get commonNo => '否';
  @override
  String get commonOk => '確定';
  @override
  String get commonSave => '儲存';
  @override
  String get commonEdit => '編輯';
  @override
  String get commonDelete => '刪除';
  @override
  String get commonClose => '關閉';
  @override
  String get labelUpright => '正位置';
  @override
  String get labelReversed => '逆位置';
  @override
  String get labelStory => '故事';
  @override
  String get labelKeywords => '關鍵詞';
  @override
  String get shareTitle => '分享';

  // ==================== 通用對話框/標題 ====================
  @override
  String get dialogDeleteConfirmTitle => '刪除確認';
  @override
  String get dialogDeleteConfirmContent => '確定要刪除此歷史記錄嗎？';
  @override
  String get dialogPleaseWaitTillDay => '請等待到那一天';
  @override
  String get shareFeatureComingSoon => '分享功能即將推出';
  @override
  String get adRequiredTitle => '需要觀看廣告';
  
  // ==================== 路由日誌 ====================
  @override
  String get messageRouterRedirectCheck => '路由重新導向檢查';
  @override
  String get messageLoadingStateNoRedirect => '載入狀態：不重新導向';
  @override
  String get messageOAuthCallbackDetected => '偵測到 OAuth 回呼';
  @override
  String get messageUnauthenticatedRedirect => '未登入，執行重新導向';
  @override
  String get messageAuthenticatedRedirect => '已登入，執行重新導向';
  @override
  String get messageNoRedirect => '不需要重新導向';
  
  // ==================== 主題命名 ====================
  @override
  String get themeOcean => '海洋';
  @override
  String get themeForest => '森林';
  @override
  String get themeNightSky => '夜空';
  @override
  String get themeMoonlight => '月光';
  @override
  String get themeCloud => '雲朵';
  @override
  String get themeClearSky => '晴空';
  
  // ==================== 牌陣選擇 ====================
  @override
  String get labelOneOracle => '單張牌';
  @override
  String get labelOneOracleDescription => '一張牌直覺提示';
  @override
  String get labelTwoCard => '兩張牌';
  @override
  String get labelTwoCardDescription => '比較/對立主題';
  @override
  String get labelThreeCard => '三張牌';
  @override
  String get labelThreeCardDescription => '過去/現在/未來';
  
  // ==================== 畫廊 ====================
  @override
  String get galleryTitle => '圖庫';
  @override
  String get labelSearchCard => '搜尋卡牌...';
  @override
  String get labelMinorArcana => '小阿爾克那';
  @override
  String get labelTarotExperts => '塔羅大師';
  @override
  String get labelWaite => 'A.E. Waite';
  @override
  String get labelSmith => 'Pamela Colman Smith';
  @override
  String get labelCrowley => 'Aleister Crowley';
  @override
  String get labelTarotBooks => '塔羅書籍';
  @override
  String get labelPictorialKey => 'Pictorial Key to the Tarot';
  @override
  String get labelBookOfThoth => 'Book of Thoth';
  @override
  String get labelMeaning => '的意義';
  @override
  String get messageNoKeywords => '沒有關鍵字資料';
  
  // ==================== 訂閱服務（佔位） ====================
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
  
  // ==================== 其他新增鍵（佔位） ====================
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


