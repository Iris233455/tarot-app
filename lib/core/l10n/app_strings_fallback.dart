import 'package:flutter/material.dart';
import 'app_strings_base.dart';

/// i18n 回退包装：当主语言文本为空时，回退到日语实现
class FallbackStrings extends AppStringsBase {
  final AppStringsBase primary;
  final AppStringsBase fallback;

  FallbackStrings({required this.primary, required this.fallback});

  String _orFallback(String value, String fallbackValue) {
    return (value.trim().isEmpty) ? fallbackValue : value;
  }

  // ==================== 系统主标题 ====================
  @override
  String get appName => _orFallback(primary.appName, fallback.appName);
  @override
  String get appSubtitle => _orFallback(primary.appSubtitle, fallback.appSubtitle);

  // ==================== 首页相关 ====================
  @override
  String get homeDailyCard => _orFallback(primary.homeDailyCard, fallback.homeDailyCard);
  @override
  String get homeTarotCalendar => _orFallback(primary.homeTarotCalendar, fallback.homeTarotCalendar);
  @override
  String get homeTodayMessage => _orFallback(primary.homeTodayMessage, fallback.homeTodayMessage);
  @override
  String get homeLongPressToDraw => _orFallback(primary.homeLongPressToDraw, fallback.homeLongPressToDraw);

  // ==================== 占卜流程 ====================
  @override
  String get readingSelectSpread => _orFallback(primary.readingSelectSpread, fallback.readingSelectSpread);
  @override
  String get readingTarotReading => _orFallback(primary.readingTarotReading, fallback.readingTarotReading);
  @override
  String get readingExplanation => _orFallback(primary.readingExplanation, fallback.readingExplanation);
  @override
  String get readingQuestion => _orFallback(primary.readingQuestion, fallback.readingQuestion);
  @override
  String get readingInterpretation => _orFallback(primary.readingInterpretation, fallback.readingInterpretation);
  @override
  String get labelQuestionPoints => _orFallback(primary.labelQuestionPoints, fallback.labelQuestionPoints);

  // ==================== 页面标题/标签 ====================
  @override
  String get historyTitle => _orFallback(primary.historyTitle, fallback.historyTitle);
  @override
  String get tabAI => _orFallback(primary.tabAI, fallback.tabAI);
  @override
  String get tabCardInterpretation => _orFallback(primary.tabCardInterpretation, fallback.tabCardInterpretation);

  // ==================== 兑换码页面 ====================
  @override
  String get redemptionTitle => _orFallback(primary.redemptionTitle, fallback.redemptionTitle);
  @override
  String get redemptionAbout => _orFallback(primary.redemptionAbout, fallback.redemptionAbout);
  @override
  String get redemptionDescription => _orFallback(primary.redemptionDescription, fallback.redemptionDescription);
  @override
  String get redemptionInputLabel => _orFallback(primary.redemptionInputLabel, fallback.redemptionInputLabel);
  @override
  String get redemptionComplete => _orFallback(primary.redemptionComplete, fallback.redemptionComplete);

  // ==================== 订阅相关 ====================
  @override
  String get subscriptionPremiumPlan => _orFallback(primary.subscriptionPremiumPlan, fallback.subscriptionPremiumPlan);
  @override
  String get subscriptionBenefits => _orFallback(primary.subscriptionBenefits, fallback.subscriptionBenefits);
  @override
  String get subscriptionNoAds => _orFallback(primary.subscriptionNoAds, fallback.subscriptionNoAds);
  @override
  String get subscriptionUnlimitedReading => _orFallback(primary.subscriptionUnlimitedReading, fallback.subscriptionUnlimitedReading);
  @override
  String get subscriptionPremiumDesign => _orFallback(primary.subscriptionPremiumDesign, fallback.subscriptionPremiumDesign);
  @override
  String get subscriptionPrioritySupport => _orFallback(primary.subscriptionPrioritySupport, fallback.subscriptionPrioritySupport);

  // ==================== 设置页面 ====================
  @override
  String get myDeckTitle => _orFallback(primary.myDeckTitle, fallback.myDeckTitle);
  @override
  String get settingsDeckSelection => _orFallback(primary.settingsDeckSelection, fallback.settingsDeckSelection);
  @override
  String get settingsSelectDeck => _orFallback(primary.settingsSelectDeck, fallback.settingsSelectDeck);
  @override
  String get settingsBackDesign => _orFallback(primary.settingsBackDesign, fallback.settingsBackDesign);
  @override
  String get settingsBuyRealDeck => _orFallback(primary.settingsBuyRealDeck, fallback.settingsBuyRealDeck);
  @override
  String get settingsBuyDescription => _orFallback(primary.settingsBuyDescription, fallback.settingsBuyDescription);
  @override
  String get settingsMusic => _orFallback(primary.settingsMusic, fallback.settingsMusic);
  @override
  String get settingsReset => _orFallback(primary.settingsReset, fallback.settingsReset);

  // ==================== 按钮文字 ====================
  @override
  String get buttonComplete => _orFallback(primary.buttonComplete, fallback.buttonComplete);
  @override
  String get buttonCancel => _orFallback(primary.buttonCancel, fallback.buttonCancel);
  @override
  String get buttonConfirm => _orFallback(primary.buttonConfirm, fallback.buttonConfirm);
  @override
  String get buttonNext => _orFallback(primary.buttonNext, fallback.buttonNext);
  @override
  String get buttonRedeemNow => _orFallback(primary.buttonRedeemNow, fallback.buttonRedeemNow);
  @override
  String get buttonCheckCode => _orFallback(primary.buttonCheckCode, fallback.buttonCheckCode);
  @override
  String get buttonReset => _orFallback(primary.buttonReset, fallback.buttonReset);
  @override
  String get buttonRetry => _orFallback(primary.buttonRetry, fallback.buttonRetry);
  @override
  String get buttonDelete => _orFallback(primary.buttonDelete, fallback.buttonDelete);
  @override
  String get buttonDrawAgain => _orFallback(primary.buttonDrawAgain, fallback.buttonDrawAgain);
  @override
  String get buttonDrawTodayCard => _orFallback(primary.buttonDrawTodayCard, fallback.buttonDrawTodayCard);

  // ==================== 状态消息 ====================
  @override
  String get messageAlreadyDrawnToday => _orFallback(primary.messageAlreadyDrawnToday, fallback.messageAlreadyDrawnToday);
  @override
  String get messageRedemptionSuccess => _orFallback(primary.messageRedemptionSuccess, fallback.messageRedemptionSuccess);
  @override
  String get messageLoading => _orFallback(primary.messageLoading, fallback.messageLoading);
  @override
  String get messageError => _orFallback(primary.messageError, fallback.messageError);
  @override
  String get messageNoHistory => _orFallback(primary.messageNoHistory, fallback.messageNoHistory);
  @override
  String get messageCardDrawnToday => _orFallback(primary.messageCardDrawnToday, fallback.messageCardDrawnToday);
  @override
  String get waitingAIPreparing => _orFallback(primary.waitingAIPreparing, fallback.waitingAIPreparing);

  // ==================== 通用文字 ====================
  @override
  String get commonYes => _orFallback(primary.commonYes, fallback.commonYes);
  @override
  String get commonNo => _orFallback(primary.commonNo, fallback.commonNo);
  @override
  String get commonOk => _orFallback(primary.commonOk, fallback.commonOk);
  @override
  String get commonSave => _orFallback(primary.commonSave, fallback.commonSave);
  @override
  String get commonEdit => _orFallback(primary.commonEdit, fallback.commonEdit);
  @override
  String get commonDelete => _orFallback(primary.commonDelete, fallback.commonDelete);
  @override
  String get commonClose => _orFallback(primary.commonClose, fallback.commonClose);
  @override
  String get labelUpright => _orFallback(primary.labelUpright, fallback.labelUpright);
  @override
  String get labelReversed => _orFallback(primary.labelReversed, fallback.labelReversed);
  @override
  String get labelStory => _orFallback(primary.labelStory, fallback.labelStory);
  @override
  String get labelKeywords => _orFallback(primary.labelKeywords, fallback.labelKeywords);
  @override
  String get shareTitle => _orFallback(primary.shareTitle, fallback.shareTitle);
  
  // ==================== 路由调试/重定向日志 ====================
  @override
  String get messageRouterRedirectCheck => _orFallback(primary.messageRouterRedirectCheck, fallback.messageRouterRedirectCheck);
  @override
  String get messageLoadingStateNoRedirect => _orFallback(primary.messageLoadingStateNoRedirect, fallback.messageLoadingStateNoRedirect);
  @override
  String get messageOAuthCallbackDetected => _orFallback(primary.messageOAuthCallbackDetected, fallback.messageOAuthCallbackDetected);
  @override
  String get messageUnauthenticatedRedirect => _orFallback(primary.messageUnauthenticatedRedirect, fallback.messageUnauthenticatedRedirect);
  @override
  String get messageAuthenticatedRedirect => _orFallback(primary.messageAuthenticatedRedirect, fallback.messageAuthenticatedRedirect);
  @override
  String get messageNoRedirect => _orFallback(primary.messageNoRedirect, fallback.messageNoRedirect);
  
  // ==================== 通用对话框/标题 ====================
  @override
  String get dialogDeleteConfirmTitle => _orFallback(primary.dialogDeleteConfirmTitle, fallback.dialogDeleteConfirmTitle);
  @override
  String get dialogDeleteConfirmContent => _orFallback(primary.dialogDeleteConfirmContent, fallback.dialogDeleteConfirmContent);
  @override
  String get dialogPleaseWaitTillDay => _orFallback(primary.dialogPleaseWaitTillDay, fallback.dialogPleaseWaitTillDay);
  @override
  String get shareFeatureComingSoon => _orFallback(primary.shareFeatureComingSoon, fallback.shareFeatureComingSoon);
  @override
  String get adRequiredTitle => _orFallback(primary.adRequiredTitle, fallback.adRequiredTitle);
  
  // ==================== 主题（Theme）命名 ====================
  @override
  String get themeOcean => _orFallback(primary.themeOcean, fallback.themeOcean);
  @override
  String get themeForest => _orFallback(primary.themeForest, fallback.themeForest);
  @override
  String get themeNightSky => _orFallback(primary.themeNightSky, fallback.themeNightSky);
  @override
  String get themeMoonlight => _orFallback(primary.themeMoonlight, fallback.themeMoonlight);
  @override
  String get themeCloud => _orFallback(primary.themeCloud, fallback.themeCloud);
  @override
  String get themeClearSky => _orFallback(primary.themeClearSky, fallback.themeClearSky);
  
  // ==================== Spread/牌阵选择 ====================
  @override
  String get labelOneOracle => _orFallback(primary.labelOneOracle, fallback.labelOneOracle);
  @override
  String get labelOneOracleDescription => _orFallback(primary.labelOneOracleDescription, fallback.labelOneOracleDescription);
  @override
  String get labelTwoCard => _orFallback(primary.labelTwoCard, fallback.labelTwoCard);
  @override
  String get labelTwoCardDescription => _orFallback(primary.labelTwoCardDescription, fallback.labelTwoCardDescription);
  @override
  String get labelThreeCard => _orFallback(primary.labelThreeCard, fallback.labelThreeCard);
  @override
  String get labelThreeCardDescription => _orFallback(primary.labelThreeCardDescription, fallback.labelThreeCardDescription);
  
  // ==================== Gallery/画廊 ====================
  @override
  String get galleryTitle => _orFallback(primary.galleryTitle, fallback.galleryTitle);
  @override
  String get labelSearchCard => _orFallback(primary.labelSearchCard, fallback.labelSearchCard);
  @override
  String get labelMinorArcana => _orFallback(primary.labelMinorArcana, fallback.labelMinorArcana);
  @override
  String get labelTarotExperts => _orFallback(primary.labelTarotExperts, fallback.labelTarotExperts);
  @override
  String get labelWaite => _orFallback(primary.labelWaite, fallback.labelWaite);
  @override
  String get labelSmith => _orFallback(primary.labelSmith, fallback.labelSmith);
  @override
  String get labelCrowley => _orFallback(primary.labelCrowley, fallback.labelCrowley);
  @override
  String get labelTarotBooks => _orFallback(primary.labelTarotBooks, fallback.labelTarotBooks);
  @override
  String get labelPictorialKey => _orFallback(primary.labelPictorialKey, fallback.labelPictorialKey);
  @override
  String get labelBookOfThoth => _orFallback(primary.labelBookOfThoth, fallback.labelBookOfThoth);
  @override
  String get labelMeaning => _orFallback(primary.labelMeaning, fallback.labelMeaning);
  @override
  String get messageNoKeywords => _orFallback(primary.messageNoKeywords, fallback.messageNoKeywords);
  
  // ==================== 订阅服务相关 ====================
  @override
  String get messageSimulatedPurchaseSuccess => _orFallback(primary.messageSimulatedPurchaseSuccess, fallback.messageSimulatedPurchaseSuccess);
  @override
  String get messageSimulatedPurchaseFailed => _orFallback(primary.messageSimulatedPurchaseFailed, fallback.messageSimulatedPurchaseFailed);
  @override
  String get messageRealPaymentNotImplemented => _orFallback(primary.messageRealPaymentNotImplemented, fallback.messageRealPaymentNotImplemented);
  @override
  String get messagePurchaseException => _orFallback(primary.messagePurchaseException, fallback.messagePurchaseException);
  @override
  String get messageActivateSubscriptionWithCode => _orFallback(primary.messageActivateSubscriptionWithCode, fallback.messageActivateSubscriptionWithCode);
  @override
  String get messageSubscriptionExtended => _orFallback(primary.messageSubscriptionExtended, fallback.messageSubscriptionExtended);
  @override
  String get messageRestorePurchasesStart => _orFallback(primary.messageRestorePurchasesStart, fallback.messageRestorePurchasesStart);
  @override
  String get messageSimulatedRestorePurchases => _orFallback(primary.messageSimulatedRestorePurchases, fallback.messageSimulatedRestorePurchases);
  @override
  String get messageNoRestorablePurchases => _orFallback(primary.messageNoRestorablePurchases, fallback.messageNoRestorablePurchases);
  @override
  String get messageCancelSubscription => _orFallback(primary.messageCancelSubscription, fallback.messageCancelSubscription);
  @override
  String get messageSimulatedCancelSubscriptionSuccess => _orFallback(primary.messageSimulatedCancelSubscriptionSuccess, fallback.messageSimulatedCancelSubscriptionSuccess);
  @override
  String get messageGetProductsStart => _orFallback(primary.messageGetProductsStart, fallback.messageGetProductsStart);
  @override
  String get messageCallSupabaseFunction => _orFallback(primary.messageCallSupabaseFunction, fallback.messageCallSupabaseFunction);
  @override
  String get messageSupabaseResponse => _orFallback(primary.messageSupabaseResponse, fallback.messageSupabaseResponse);
  @override
  String get messageResponseType => _orFallback(primary.messageResponseType, fallback.messageResponseType);
  @override
  String get messageSuccessfullyGotProducts => _orFallback(primary.messageSuccessfullyGotProducts, fallback.messageSuccessfullyGotProducts);
  @override
  String get messageProductData => _orFallback(primary.messageProductData, fallback.messageProductData);
  @override
  String get messageProduct => _orFallback(primary.messageProduct, fallback.messageProduct);
  @override
  String get messageSupabaseDataFormatIncorrect => _orFallback(primary.messageSupabaseDataFormatIncorrect, fallback.messageSupabaseDataFormatIncorrect);
  @override
  String get messageGetProductsFailed => _orFallback(primary.messageGetProductsFailed, fallback.messageGetProductsFailed);
  @override
  String get messageErrorType => _orFallback(primary.messageErrorType, fallback.messageErrorType);
  @override
  String get messagePostgrestException => _orFallback(primary.messagePostgrestException, fallback.messagePostgrestException);
  @override
  String get messageFallbackToDefaultProducts => _orFallback(primary.messageFallbackToDefaultProducts, fallback.messageFallbackToDefaultProducts);
  @override
  String get messageCurrentSubscriptionStatus => _orFallback(primary.messageCurrentSubscriptionStatus, fallback.messageCurrentSubscriptionStatus);
  @override
  String get messageSubscriptionExpiry => _orFallback(primary.messageSubscriptionExpiry, fallback.messageSubscriptionExpiry);
  @override
  String get messageSubscriptionStatusSaved => _orFallback(primary.messageSubscriptionStatusSaved, fallback.messageSubscriptionStatusSaved);
  @override
  String get messageCleanupUserSubscriptionData => _orFallback(primary.messageCleanupUserSubscriptionData, fallback.messageCleanupUserSubscriptionData);
  @override
  String get messageUserSubscriptionDataCleanupComplete => _orFallback(primary.messageUserSubscriptionDataCleanupComplete, fallback.messageUserSubscriptionDataCleanupComplete);
  @override
  String get messageCleanupUserSubscriptionDataFailed => _orFallback(primary.messageCleanupUserSubscriptionDataFailed, fallback.messageCleanupUserSubscriptionDataFailed);
  @override
  String get messageSyncLocalDataToSupabase => _orFallback(primary.messageSyncLocalDataToSupabase, fallback.messageSyncLocalDataToSupabase);
  @override
  String get messageSyncLocalSubscriptionToSupabase => _orFallback(primary.messageSyncLocalSubscriptionToSupabase, fallback.messageSyncLocalSubscriptionToSupabase);
  @override
  String get messageLocalSubscriptionDataSyncedToSupabase => _orFallback(primary.messageLocalSubscriptionDataSyncedToSupabase, fallback.messageLocalSubscriptionDataSyncedToSupabase);
  @override
  String get messageNoLocalSubscriptionDataToSync => _orFallback(primary.messageNoLocalSubscriptionDataToSync, fallback.messageNoLocalSubscriptionDataToSync);
  @override
  String get messageSyncLocalSubscriptionDataToSupabaseFailed => _orFallback(primary.messageSyncLocalSubscriptionDataToSupabaseFailed, fallback.messageSyncLocalSubscriptionDataToSupabaseFailed);
  @override
  String get messageGetSubscriptionStatusFromSupabaseFailed => _orFallback(primary.messageGetSubscriptionStatusFromSupabaseFailed, fallback.messageGetSubscriptionStatusFromSupabaseFailed);
  @override
  String get messageGetSubscriptionExpiryFromSupabaseFailed => _orFallback(primary.messageGetSubscriptionExpiryFromSupabaseFailed, fallback.messageGetSubscriptionExpiryFromSupabaseFailed);
  @override
  String get messageCannotSyncToSupabaseUserNotLoggedIn => _orFallback(primary.messageCannotSyncToSupabaseUserNotLoggedIn, fallback.messageCannotSyncToSupabaseUserNotLoggedIn);
  @override
  String get messageSubscriptionInfoSyncedToSupabase => _orFallback(primary.messageSubscriptionInfoSyncedToSupabase, fallback.messageSubscriptionInfoSyncedToSupabase);
  @override
  String get messageSyncSubscriptionInfoToSupabaseFailed => _orFallback(primary.messageSyncSubscriptionInfoToSupabaseFailed, fallback.messageSyncSubscriptionInfoToSupabaseFailed);
  @override
  String get messageCannotSyncFromSupabaseUserNotLoggedIn => _orFallback(primary.messageCannotSyncFromSupabaseUserNotLoggedIn, fallback.messageCannotSyncFromSupabaseUserNotLoggedIn);
  @override
  String get messageStartSyncSubscriptionStatusFromSupabase => _orFallback(primary.messageStartSyncSubscriptionStatusFromSupabase, fallback.messageStartSyncSubscriptionStatusFromSupabase);
  @override
  String get messageSyncSubscriptionStatusFromSupabaseSuccess => _orFallback(primary.messageSyncSubscriptionStatusFromSupabaseSuccess, fallback.messageSyncSubscriptionStatusFromSupabaseSuccess);
  @override
  String get messageSyncSubscriptionStatusFromSupabaseFailed => _orFallback(primary.messageSyncSubscriptionStatusFromSupabaseFailed, fallback.messageSyncSubscriptionStatusFromSupabaseFailed);
  @override
  String get messageUserNotLoggedInExpiryNull => _orFallback(primary.messageUserNotLoggedInExpiryNull, fallback.messageUserNotLoggedInExpiryNull);
  @override
  String get messageGetSubscriptionExpiryFailed => _orFallback(primary.messageGetSubscriptionExpiryFailed, fallback.messageGetSubscriptionExpiryFailed);
  @override
  String get messageStartingSubscriptionPurchase => _orFallback(primary.messageStartingSubscriptionPurchase, fallback.messageStartingSubscriptionPurchase);
  @override
  String get messagePurchaseFailedUserNotLoggedIn => _orFallback(primary.messagePurchaseFailedUserNotLoggedIn, fallback.messagePurchaseFailedUserNotLoggedIn);
  @override
  String get messagePurchaseFailedAnonymousUser => _orFallback(primary.messagePurchaseFailedAnonymousUser, fallback.messagePurchaseFailedAnonymousUser);
  @override
  String get messageSimulatedPurchaseStart => _orFallback(primary.messageSimulatedPurchaseStart, fallback.messageSimulatedPurchaseStart);
  
  // ==================== 其他缺失的键 ====================
  @override
  String get messageAdMobInitSuccess => _orFallback(primary.messageAdMobInitSuccess, fallback.messageAdMobInitSuccess);
  @override
  String get messageAdMobInitFailed => _orFallback(primary.messageAdMobInitFailed, fallback.messageAdMobInitFailed);
  @override
  String get messageSubscriptionInitSuccess => _orFallback(primary.messageSubscriptionInitSuccess, fallback.messageSubscriptionInitSuccess);
  @override
  String get messageSubscriptionInitFailed => _orFallback(primary.messageSubscriptionInitFailed, fallback.messageSubscriptionInitFailed);
  @override
  String get messageSupabaseInitSuccess => _orFallback(primary.messageSupabaseInitSuccess, fallback.messageSupabaseInitSuccess);
  @override
  String get messageExistingUserSession => _orFallback(primary.messageExistingUserSession, fallback.messageExistingUserSession);
  @override
  String get messageSupabaseInitFailed => _orFallback(primary.messageSupabaseInitFailed, fallback.messageSupabaseInitFailed);
  @override
  String get messageUsingOfflineMode => _orFallback(primary.messageUsingOfflineMode, fallback.messageUsingOfflineMode);
  @override
  String get messageUserType => _orFallback(primary.messageUserType, fallback.messageUserType);
  @override
  String get messageNoUserSession => _orFallback(primary.messageNoUserSession, fallback.messageNoUserSession);
  @override
  String get messageCachedUserId => _orFallback(primary.messageCachedUserId, fallback.messageCachedUserId);
  @override
  String get messageLoginToRecoverData => _orFallback(primary.messageLoginToRecoverData, fallback.messageLoginToRecoverData);
  @override
  String get messageDatabaseConnectionSuccess => _orFallback(primary.messageDatabaseConnectionSuccess, fallback.messageDatabaseConnectionSuccess);
  @override
  String get messageConnectionFailed => _orFallback(primary.messageConnectionFailed, fallback.messageConnectionFailed);
  @override
  String get messageCurrentMode => _orFallback(primary.messageCurrentMode, fallback.messageCurrentMode);
  @override
  String get labelOfflineMode => _orFallback(primary.labelOfflineMode, fallback.labelOfflineMode);
  @override
  String get messageOfflineModeDescription => _orFallback(primary.messageOfflineModeDescription, fallback.messageOfflineModeDescription);
  @override
  String get labelOnlineMode => _orFallback(primary.labelOnlineMode, fallback.labelOnlineMode);
  @override
  String get messageSupabaseConnectionSuccess => _orFallback(primary.messageSupabaseConnectionSuccess, fallback.messageSupabaseConnectionSuccess);
  @override
  String get messageEnterRedemptionCode => _orFallback(primary.messageEnterRedemptionCode, fallback.messageEnterRedemptionCode);
  @override
  String get messageCheckFailed => _orFallback(primary.messageCheckFailed, fallback.messageCheckFailed);
  @override
  String get messageGuestCannotUseRedemptionCode => _orFallback(primary.messageGuestCannotUseRedemptionCode, fallback.messageGuestCannotUseRedemptionCode);
  @override
  String get messageRedemptionFailed => _orFallback(primary.messageRedemptionFailed, fallback.messageRedemptionFailed);
  @override
  String get messagePremiumServiceObtained => _orFallback(primary.messagePremiumServiceObtained, fallback.messagePremiumServiceObtained);
  @override
  String get labelDays => _orFallback(primary.labelDays, fallback.labelDays);
  @override
  String get labelNewExpiry => _orFallback(primary.labelNewExpiry, fallback.labelNewExpiry);
  @override
  String get messageScanFailed => _orFallback(primary.messageScanFailed, fallback.messageScanFailed);
  @override
  String get messagePasteFailed => _orFallback(primary.messagePasteFailed, fallback.messagePasteFailed);
  @override
  String get messageRedemptionCodeDescription => _orFallback(primary.messageRedemptionCodeDescription, fallback.messageRedemptionCodeDescription);
  @override
  String get buttonPaste => _orFallback(primary.buttonPaste, fallback.buttonPaste);
  @override
  String get buttonScan => _orFallback(primary.buttonScan, fallback.buttonScan);
  @override
  String get labelUsageInstructions => _orFallback(primary.labelUsageInstructions, fallback.labelUsageInstructions);
  @override
  String get messageRedemptionCodeUsageLimit => _orFallback(primary.messageRedemptionCodeUsageLimit, fallback.messageRedemptionCodeUsageLimit);
  @override
  String get messageRedemptionCodeExpiry => _orFallback(primary.messageRedemptionCodeExpiry, fallback.messageRedemptionCodeExpiry);
  @override
  String get messageLoginRequiredForRedemption => _orFallback(primary.messageLoginRequiredForRedemption, fallback.messageLoginRequiredForRedemption);
  @override
  String get messageRedemptionDaysAdded => _orFallback(primary.messageRedemptionDaysAdded, fallback.messageRedemptionDaysAdded);
  @override
  String get labelSelectYear => _orFallback(primary.labelSelectYear, fallback.labelSelectYear);
  @override
  String get labelMonday => _orFallback(primary.labelMonday, fallback.labelMonday);
  @override
  String get labelTuesday => _orFallback(primary.labelTuesday, fallback.labelTuesday);
  @override
  String get labelWednesday => _orFallback(primary.labelWednesday, fallback.labelWednesday);
  @override
  String get labelThursday => _orFallback(primary.labelThursday, fallback.labelThursday);
  @override
  String get labelFriday => _orFallback(primary.labelFriday, fallback.labelFriday);
  @override
  String get labelSaturday => _orFallback(primary.labelSaturday, fallback.labelSaturday);
  @override
  String get labelSunday => _orFallback(primary.labelSunday, fallback.labelSunday);
  @override
  String get labelFavorites => _orFallback(primary.labelFavorites, fallback.labelFavorites);
  @override
  String get messageFavoritesComingSoon => _orFallback(primary.messageFavoritesComingSoon, fallback.messageFavoritesComingSoon);
  @override
  String get labelMajorArcana => _orFallback(primary.labelMajorArcana, fallback.labelMajorArcana);
  @override
  String get labelWands => _orFallback(primary.labelWands, fallback.labelWands);
  @override
  String get labelCups => _orFallback(primary.labelCups, fallback.labelCups);
  @override
  String get labelSwords => _orFallback(primary.labelSwords, fallback.labelSwords);
  @override
  String get labelPentacles => _orFallback(primary.labelPentacles, fallback.labelPentacles);
  @override
  String get labelUnknown => _orFallback(primary.labelUnknown, fallback.labelUnknown);
  @override
  String get messageAIFailed => _orFallback(primary.messageAIFailed, fallback.messageAIFailed);
  @override
  String get buttonGetAIReading => _orFallback(primary.buttonGetAIReading, fallback.buttonGetAIReading);
  @override
  String get labelLanguage => _orFallback(primary.labelLanguage, fallback.labelLanguage);
  @override
  String get messageLanguageSwitched => _orFallback(primary.messageLanguageSwitched, fallback.messageLanguageSwitched);
  @override
  String get labelCardDetail => _orFallback(primary.labelCardDetail, fallback.labelCardDetail);
  @override
  String get labelLove => _orFallback(primary.labelLove, fallback.labelLove);
  @override
  String get labelCareer => _orFallback(primary.labelCareer, fallback.labelCareer);
  @override
  String get labelMoney => _orFallback(primary.labelMoney, fallback.labelMoney);
  @override
  String get labelInterpersonal => _orFallback(primary.labelInterpersonal, fallback.labelInterpersonal);
  @override
  String get labelPastPresentFuture => _orFallback(primary.labelPastPresentFuture, fallback.labelPastPresentFuture);
  @override
  String get labelEmotionConsciousness => _orFallback(primary.labelEmotionConsciousness, fallback.labelEmotionConsciousness);
  @override
  String get labelCauseSolution => _orFallback(primary.labelCauseSolution, fallback.labelCauseSolution);
  
  // ==================== 抽牌/洗切牌 页面（Shuffle/Draw） ====================
  @override
  String get readingPreparing => _orFallback(primary.readingPreparing, fallback.readingPreparing);
  @override
  String get readingShuffling => _orFallback(primary.readingShuffling, fallback.readingShuffling);
  @override
  String get readingCutting => _orFallback(primary.readingCutting, fallback.readingCutting);
  @override
  String get readingDrawing => _orFallback(primary.readingDrawing, fallback.readingDrawing);
  @override
  String get readingResultTitle => _orFallback(primary.readingResultTitle, fallback.readingResultTitle);
  @override
  String get readingComplete => _orFallback(primary.readingComplete, fallback.readingComplete);
  @override
  String get hintSwipeUpToPick => _orFallback(primary.hintSwipeUpToPick, fallback.hintSwipeUpToPick);
  @override
  String get hintDragToSlot => _orFallback(primary.hintDragToSlot, fallback.hintDragToSlot);
  @override
  String get errorDrawFailed => _orFallback(primary.errorDrawFailed, fallback.errorDrawFailed);
  @override
  String get buttonSeeResult => _orFallback(primary.buttonSeeResult, fallback.buttonSeeResult);
  @override
  String get readingTitle => _orFallback(primary.readingTitle, fallback.readingTitle);
  @override
  String get labelSelectCardCount => _orFallback(primary.labelSelectCardCount, fallback.labelSelectCardCount);
  @override
  String get buttonShuffle => _orFallback(primary.buttonShuffle, fallback.buttonShuffle);
  @override
  String get buttonCut => _orFallback(primary.buttonCut, fallback.buttonCut);
  @override
  String get messageStartingGoogleLogin => _orFallback(primary.messageStartingGoogleLogin, fallback.messageStartingGoogleLogin);
  @override
  String get messageCurrentPlatform => _orFallback(primary.messageCurrentPlatform, fallback.messageCurrentPlatform);
  @override
  String get messageAlreadyLoggedIn => _orFallback(primary.messageAlreadyLoggedIn, fallback.messageAlreadyLoggedIn);
  @override
  String get messageSkipLoginReturnSuccess => _orFallback(primary.messageSkipLoginReturnSuccess, fallback.messageSkipLoginReturnSuccess);
  @override
  String get messageAnonymousUserLogout => _orFallback(primary.messageAnonymousUserLogout, fallback.messageAnonymousUserLogout);
  @override
  String get messageGoogleLoginFailed => _orFallback(primary.messageGoogleLoginFailed, fallback.messageGoogleLoginFailed);
  @override
  String get messageWebPlatformOAuth => _orFallback(primary.messageWebPlatformOAuth, fallback.messageWebPlatformOAuth);
  @override
  String get messageCurrentURL => _orFallback(primary.messageCurrentURL, fallback.messageCurrentURL);
  @override
  String get messageExpectedRedirectURI => _orFallback(primary.messageExpectedRedirectURI, fallback.messageExpectedRedirectURI);
  @override
  String get messageGoogleOAuthResult => _orFallback(primary.messageGoogleOAuthResult, fallback.messageGoogleOAuthResult);
  @override
  String get messageWebGoogleLoginUserInfo => _orFallback(primary.messageWebGoogleLoginUserInfo, fallback.messageWebGoogleLoginUserInfo);
  @override
  String get messageUserId => _orFallback(primary.messageUserId, fallback.messageUserId);
  @override
  String get messageEmail => _orFallback(primary.messageEmail, fallback.messageEmail);
  @override
  String get messageWebGoogleOAuthError => _orFallback(primary.messageWebGoogleOAuthError, fallback.messageWebGoogleOAuthError);
  @override
  String get messageCheckGoogleCloudConsole => _orFallback(primary.messageCheckGoogleCloudConsole, fallback.messageCheckGoogleCloudConsole);
  @override
  String get messageCheckRedirectURI => _orFallback(primary.messageCheckRedirectURI, fallback.messageCheckRedirectURI);
  @override
  String get messageNativePlatformGoogleSignIn => _orFallback(primary.messageNativePlatformGoogleSignIn, fallback.messageNativePlatformGoogleSignIn);
  @override
  String get messageStartingNativeGoogleLogin => _orFallback(primary.messageStartingNativeGoogleLogin, fallback.messageStartingNativeGoogleLogin);
  @override
  String get messageUserCancelledGoogleLogin => _orFallback(primary.messageUserCancelledGoogleLogin, fallback.messageUserCancelledGoogleLogin);
  @override
  String get messageGoogleLoginSuccess => _orFallback(primary.messageGoogleLoginSuccess, fallback.messageGoogleLoginSuccess);
  @override
  String get messageCannotGetGoogleAuthToken => _orFallback(primary.messageCannotGetGoogleAuthToken, fallback.messageCannotGetGoogleAuthToken);
  @override
  String get messageGoogleAuthTokenSuccess => _orFallback(primary.messageGoogleAuthTokenSuccess, fallback.messageGoogleAuthTokenSuccess);
  @override
  String get messageSupabaseLoginSuccess => _orFallback(primary.messageSupabaseLoginSuccess, fallback.messageSupabaseLoginSuccess);
  @override
  String get messageSupabaseLoginFailed => _orFallback(primary.messageSupabaseLoginFailed, fallback.messageSupabaseLoginFailed);
  @override
  String get messageNativeGoogleLoginErrorDetails => _orFallback(primary.messageNativeGoogleLoginErrorDetails, fallback.messageNativeGoogleLoginErrorDetails);
  @override
  String get messageErrorInfo => _orFallback(primary.messageErrorInfo, fallback.messageErrorInfo);
  @override
  String get messageUserCancelledLogin => _orFallback(primary.messageUserCancelledLogin, fallback.messageUserCancelledLogin);
  @override
  String get messageCheckGoogleConfigBundleId => _orFallback(primary.messageCheckGoogleConfigBundleId, fallback.messageCheckGoogleConfigBundleId);
  @override
  String get messageCheckNetworkConnection => _orFallback(primary.messageCheckNetworkConnection, fallback.messageCheckNetworkConnection);
  @override
  String get messageStartingAccountUpgrade => _orFallback(primary.messageStartingAccountUpgrade, fallback.messageStartingAccountUpgrade);
  @override
  String get messageCurrentAnonymousUserId => _orFallback(primary.messageCurrentAnonymousUserId, fallback.messageCurrentAnonymousUserId);
  @override
  String get messageAccountUpgradeSuccess => _orFallback(primary.messageAccountUpgradeSuccess, fallback.messageAccountUpgradeSuccess);
  @override
  String get messageUpgradedUserId => _orFallback(primary.messageUpgradedUserId, fallback.messageUpgradedUserId);
  @override
  String get messageAccountUpgradeFailed => _orFallback(primary.messageAccountUpgradeFailed, fallback.messageAccountUpgradeFailed);
  @override
  String get messageSavingDailyCard => _orFallback(primary.messageSavingDailyCard, fallback.messageSavingDailyCard);
  @override
  String get messageDate => _orFallback(primary.messageDate, fallback.messageDate);
  @override
  String get messageCard => _orFallback(primary.messageCard, fallback.messageCard);
  @override
  String get messageAlreadyDrewCardToday => _orFallback(primary.messageAlreadyDrewCardToday, fallback.messageAlreadyDrewCardToday);
  @override
  String get messageAlreadyDrewCardTodayException => _orFallback(primary.messageAlreadyDrewCardTodayException, fallback.messageAlreadyDrewCardTodayException);
  @override
  String get messageMessage => _orFallback(primary.messageMessage, fallback.messageMessage);
  @override
  String get messageDailyCardSavedSuccess => _orFallback(primary.messageDailyCardSavedSuccess, fallback.messageDailyCardSavedSuccess);
  @override
  String get messageRedemptionCodeService => _orFallback(primary.messageRedemptionCodeService, fallback.messageRedemptionCodeService);
  @override
  String get messageInvalidRedemptionCodeFormat => _orFallback(primary.messageInvalidRedemptionCodeFormat, fallback.messageInvalidRedemptionCodeFormat);
  @override
  String get messageRedemptionCodeNotFound => _orFallback(primary.messageRedemptionCodeNotFound, fallback.messageRedemptionCodeNotFound);
  @override
  String get messageRedemptionCodeAlreadyUsed => _orFallback(primary.messageRedemptionCodeAlreadyUsed, fallback.messageRedemptionCodeAlreadyUsed);
  @override
  String get messageRedemptionCodeExpired => _orFallback(primary.messageRedemptionCodeExpired, fallback.messageRedemptionCodeExpired);
  @override
  String get messageValidRedemptionCode => _orFallback(primary.messageValidRedemptionCode, fallback.messageValidRedemptionCode);
  @override
  String get messagePremiumService => _orFallback(primary.messagePremiumService, fallback.messagePremiumService);
  @override
  String get messageCheckRedemptionCodeFailed => _orFallback(primary.messageCheckRedemptionCodeFailed, fallback.messageCheckRedemptionCodeFailed);
  @override
  String get messageNetworkErrorCheckConnection => _orFallback(primary.messageNetworkErrorCheckConnection, fallback.messageNetworkErrorCheckConnection);
  @override
  String get messageRedemptionComplete => _orFallback(primary.messageRedemptionComplete, fallback.messageRedemptionComplete);
  @override
  String get messageRedemptionCodeUsageFailed => _orFallback(primary.messageRedemptionCodeUsageFailed, fallback.messageRedemptionCodeUsageFailed);
  @override
  String get messageTestCodeGenerationDevModeOnly => _orFallback(primary.messageTestCodeGenerationDevModeOnly, fallback.messageTestCodeGenerationDevModeOnly);
  @override
  String get messageGenerationFailed => _orFallback(primary.messageGenerationFailed, fallback.messageGenerationFailed);
  @override
  String get labelMonthly => _orFallback(primary.labelMonthly, fallback.labelMonthly);
  @override
  String get label3Months => _orFallback(primary.label3Months, fallback.label3Months);
  @override
  String get labelYearly => _orFallback(primary.labelYearly, fallback.labelYearly);
  @override
  String get labelDiscount => _orFallback(primary.labelDiscount, fallback.labelDiscount);
  @override
  String get labelPremiumSubscription => _orFallback(primary.labelPremiumSubscription, fallback.labelPremiumSubscription);
  @override
  String get labelPremiumSubscriptionDescription => _orFallback(primary.labelPremiumSubscriptionDescription, fallback.labelPremiumSubscriptionDescription);
  @override
  String get labelPremium3MonthsPlan => _orFallback(primary.labelPremium3MonthsPlan, fallback.labelPremium3MonthsPlan);
  @override
  String get labelPremium3MonthsPlanDescription => _orFallback(primary.labelPremium3MonthsPlanDescription, fallback.labelPremium3MonthsPlanDescription);
  @override
  String get labelPremiumYearlyPlan => _orFallback(primary.labelPremiumYearlyPlan, fallback.labelPremiumYearlyPlan);
  @override
  String get labelPremiumYearlyPlanDescription => _orFallback(primary.labelPremiumYearlyPlanDescription, fallback.labelPremiumYearlyPlanDescription);
  @override
  String get messageSubscriptionServiceInitStart => _orFallback(primary.messageSubscriptionServiceInitStart, fallback.messageSubscriptionServiceInitStart);
  @override
  String get messageDevModeSimulatedSubscription => _orFallback(primary.messageDevModeSimulatedSubscription, fallback.messageDevModeSimulatedSubscription);
  @override
  String get messageSubscriptionServiceInitComplete => _orFallback(primary.messageSubscriptionServiceInitComplete, fallback.messageSubscriptionServiceInitComplete);
  @override
  String get messageUserNotLoggedInSubscriptionNone => _orFallback(primary.messageUserNotLoggedInSubscriptionNone, fallback.messageUserNotLoggedInSubscriptionNone);
  @override
  String get messageGetSubscriptionStatusFailed => _orFallback(primary.messageGetSubscriptionStatusFailed, fallback.messageGetSubscriptionStatusFailed);
}


