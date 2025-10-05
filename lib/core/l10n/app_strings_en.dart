import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'app_strings_base.dart';

/// 英文文本定义
class AppStringsEn extends AppStringsBase {
  @override
  String get myDeckTitle => 'My Deck';
  
  // ==================== 系统主标题 ====================
  @override
  String get appName => 'Mystic Tarot';
  @override
  String get appSubtitle => 'Discover Your Destiny';
  
  // ==================== 首页相关 ====================
  @override
  String get homeDailyCard => 'Daily Card';
  @override
  String get homeTarotCalendar => 'Tarot Calendar';
  @override
  String get homeTodayMessage => 'Today\'s Message';
  @override
  String get homeLongPressToDraw => 'Long press to draw a card';
  
  // ==================== 占卜流程 ====================
  @override
  String get readingSelectSpread => 'Select Spread';
  @override
  String get readingTarotReading => 'Tarot Reading';
  @override
  String get readingExplanation => 'Explanation';
  @override
  String get readingQuestion => 'Question';
  @override
  String get readingInterpretation => 'Interpretation';
  @override
  String get labelQuestionPoints => 'Question Points';

  // ==================== Titles/Tabs ====================
  @override
  String get historyTitle => 'History';
  @override
  String get tabAI => 'AI Diagnosis';
  @override
  String get tabCardInterpretation => 'Card Interpretation';
  
  // ==================== 兑换码页面 ====================
  @override
  String get redemptionTitle => 'Redemption Code';
  @override
  String get redemptionAbout => 'About Redemption Code';
  @override
  String get redemptionDescription => 'Enter the redemption code obtained from physical cards or events to enjoy premium services for free for a specified number of days.';
  @override
  String get redemptionInputLabel => 'Enter Redemption Code';
  @override
  String get redemptionComplete => 'Redemption Complete!';
  
  // ==================== 订阅相关 ====================
  @override
  String get subscriptionPremiumPlan => 'Premium Plan';
  @override
  String get subscriptionBenefits => 'Premium Benefits';
  @override
  String get subscriptionNoAds => 'Ad-free Smooth Experience';
  @override
  String get subscriptionUnlimitedReading => 'Unlimited Tarot Readings';
  @override
  String get subscriptionPremiumDesign => 'Premium Card Designs';
  @override
  String get subscriptionPrioritySupport => 'Priority Support';
  
  // ==================== 设置页面 ====================
  @override
  String get settingsDeckSelection => 'Select Deck';
  @override
  String get settingsSelectDeck => 'Choose Deck to Use';
  @override
  String get settingsBackDesign => 'Back Design';
  @override
  String get settingsBuyRealDeck => 'Buy Physical Deck';
  @override
  String get settingsBuyDescription => 'Purchase Physical Tarot Cards';
  @override
  String get settingsMusic => 'Music';
  @override
  String get settingsReset => 'Reset';
  
  // ==================== 按钮文字 ====================
  @override
  String get buttonComplete => 'Complete';
  @override
  String get buttonCancel => 'Cancel';
  @override
  String get buttonConfirm => 'Confirm';
  @override
  String get buttonNext => 'Next';
  @override
  String get buttonRedeemNow => 'Redeem Now';
  @override
  String get buttonCheckCode => 'Check Code';
  @override
  String get buttonReset => 'Reset';
  @override
  String get buttonRetry => 'Retry';
  @override
  String get buttonDelete => 'Delete';
  @override
  String get buttonDrawAgain => 'Draw Again';
  @override
  String get buttonDrawTodayCard => 'Draw today\'s card';
  
  // ==================== 状态消息 ====================
  @override
  String get messageAlreadyDrawnToday => 'You have already drawn a card today. Please come back tomorrow!';
  @override
  String get messageRedemptionSuccess => 'Redemption Complete!';
  @override
  String get messageLoading => 'Loading...';
  @override
  String get messageError => 'An error occurred';
  @override
  String get messageNoHistory => 'No reading history yet';
  @override
  String get messageCardDrawnToday => 'Card drawn for today!';
  @override
  String get waitingAIPreparing => 'Preparing AI reading...';
  
  // ==================== 通用文字 ====================
  @override
  String get commonYes => 'Yes';
  @override
  String get commonNo => 'No';
  @override
  String get commonOk => 'OK';
  @override
  String get commonSave => 'Save';
  @override
  String get commonEdit => 'Edit';
  @override
  String get commonDelete => 'Delete';
  @override
  String get commonClose => 'Close';
  @override
  String get labelUpright => 'Upright';
  @override
  String get labelReversed => 'Reversed';
  @override
  String get labelStory => 'Story';
  @override
  String get labelKeywords => 'Keywords';
  @override
  String get shareTitle => 'Share';

  // ==================== Common Dialog/Title ====================
  @override
  String get dialogDeleteConfirmTitle => 'Delete Confirmation';
  @override
  String get dialogDeleteConfirmContent => 'Do you want to delete this history?';
  @override
  String get dialogPleaseWaitTillDay => 'Please wait until that day';
  @override
  String get shareFeatureComingSoon => 'Share feature will be available soon';
  @override
  String get adRequiredTitle => 'Ad viewing required';
  
  // ==================== Router logs (stubs) ====================
  @override
  String get messageRouterRedirectCheck => '';
  @override
  String get messageLoadingStateNoRedirect => '';
  @override
  String get messageOAuthCallbackDetected => '';
  @override
  String get messageUnauthenticatedRedirect => '';
  @override
  String get messageAuthenticatedRedirect => '';
  @override
  String get messageNoRedirect => '';
  
  // ==================== Theme names (stubs) ====================
  @override
  String get themeOcean => '';
  @override
  String get themeForest => '';
  @override
  String get themeNightSky => '';
  @override
  String get themeMoonlight => '';
  @override
  String get themeCloud => '';
  @override
  String get themeClearSky => '';
  
  // ==================== Spread select (stubs) ====================
  @override
  String get labelOneOracle => '';
  @override
  String get labelOneOracleDescription => '';
  @override
  String get labelTwoCard => '';
  @override
  String get labelTwoCardDescription => '';
  @override
  String get labelThreeCard => '';
  @override
  String get labelThreeCardDescription => '';
  
  // ==================== Gallery (stubs) ====================
  @override
  String get galleryTitle => '';
  @override
  String get labelSearchCard => '';
  @override
  String get labelMinorArcana => '';
  @override
  String get labelTarotExperts => '';
  @override
  String get labelWaite => '';
  @override
  String get labelSmith => '';
  @override
  String get labelCrowley => '';
  @override
  String get labelTarotBooks => '';
  @override
  String get labelPictorialKey => '';
  @override
  String get labelBookOfThoth => '';
  @override
  String get labelMeaning => '';
  @override
  String get messageNoKeywords => '';
  
  // ==================== Subscription Service (stubs) ====================
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
  
  // ==================== Additional Keys (stubs) ====================
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
  
  // ==================== Shuffle/Draw page ====================
  @override
  String get readingPreparing => 'Preparing cards';
  @override
  String get readingShuffling => 'Shuffling cards';
  @override
  String get readingCutting => 'Cutting cards';
  @override
  String get readingDrawing => 'Please draw cards';
  @override
  String get readingResultTitle => 'Reading Result';
  @override
  String get readingComplete => 'Reading complete';
  @override
  String get hintSwipeUpToPick => 'Swipe up to pick the top card';
  @override
  String get hintDragToSlot => 'Drag upward to place into slot';
  @override
  String get errorDrawFailed => 'Failed to draw cards';
  @override
  String get buttonSeeResult => 'See Result';
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


