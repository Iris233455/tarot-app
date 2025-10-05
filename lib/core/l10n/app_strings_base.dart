import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

/// 文本基类 - 定义所有需要国际化的文本接口
/// 所有语言的文本类都必须继承此基类并实现所有抽象方法
abstract class AppStringsBase {
  
  // ==================== 系统主标题 ====================
  String get appName;
  String get appSubtitle;
  
  // ==================== 首页相关 ====================
  String get homeDailyCard;
  String get homeTarotCalendar;
  String get homeTodayMessage;
  String get homeLongPressToDraw;
  
  // ==================== 占卜流程 ====================
  String get readingSelectSpread;
  String get readingTarotReading;
  String get readingExplanation;
  String get readingQuestion;
  String get readingInterpretation;
  String get labelQuestionPoints;

  // ==================== 页面标题/标签 ====================
  String get historyTitle; // 履歴 / History
  String get tabAI; // AI诊断
  String get tabCardInterpretation; // カードの解釈
  
  // ==================== 兑换码页面 ====================
  String get redemptionTitle;
  String get redemptionAbout;
  String get redemptionDescription;
  String get redemptionInputLabel;
  String get redemptionComplete;
  
  // ==================== 订阅相关 ====================
  String get subscriptionPremiumPlan;
  String get subscriptionBenefits;
  String get subscriptionNoAds;
  String get subscriptionUnlimitedReading;
  String get subscriptionPremiumDesign;
  String get subscriptionPrioritySupport;
  
  // ==================== 设置页面 ====================
  String get myDeckTitle; // 我的牌组 / マイデッキ / My Deck
  String get settingsDeckSelection;
  String get settingsSelectDeck;
  String get settingsBackDesign;
  String get settingsBuyRealDeck;
  String get settingsBuyDescription;
  String get settingsMusic;
  String get settingsReset;
  
  // ==================== 按钮文字 ====================
  String get buttonComplete;
  String get buttonCancel;
  String get buttonConfirm;
  String get buttonNext;
  String get buttonRedeemNow;
  String get buttonCheckCode;
  String get buttonReset;
  String get buttonRetry;
  String get buttonDelete;
  String get buttonDrawAgain; // もう一度占う
  String get buttonDrawTodayCard; // 本日のカードを引く
  
  // ==================== 状态消息 ====================
  String get messageAlreadyDrawnToday;
  String get messageRedemptionSuccess;
  String get messageLoading;
  String get messageError;
  String get messageNoHistory;
  String get messageCardDrawnToday;
  String get waitingAIPreparing; // AI解读准备中
  
  // ==================== 通用文字 ====================
  String get commonYes;
  String get commonNo;
  String get commonOk;
  String get commonSave;
  String get commonEdit;
  String get commonDelete;
  String get commonClose;
  String get labelUpright; // 正位置
  String get labelReversed; // 逆位置
  String get labelStory; // 物語り / 故事
  String get labelKeywords; // キーワード / 关键词
  String get shareTitle; // シェア / Share
  
  // ==================== 路由调试/重定向日志 ====================
  String get messageRouterRedirectCheck;
  String get messageLoadingStateNoRedirect;
  String get messageOAuthCallbackDetected;
  String get messageUnauthenticatedRedirect;
  String get messageAuthenticatedRedirect;
  String get messageNoRedirect;

  // ==================== 通用对话框/标题 ====================
  String get dialogDeleteConfirmTitle;
  String get dialogDeleteConfirmContent;
  String get dialogPleaseWaitTillDay;
  String get shareFeatureComingSoon; // シェア機能は近日実装予定です
  String get adRequiredTitle; // 広告視聴が必要です
  
  // ==================== 主题（Theme）命名 ====================
  String get themeOcean;
  String get themeForest;
  String get themeNightSky;
  String get themeMoonlight;
  String get themeCloud;
  String get themeClearSky;
  
  // ==================== Spread/牌阵选择 ====================
  String get labelOneOracle;
  String get labelOneOracleDescription;
  String get labelTwoCard;
  String get labelTwoCardDescription;
  String get labelThreeCard;
  String get labelThreeCardDescription;
  
  // ==================== Gallery/画廊 ====================
  String get galleryTitle;
  String get labelSearchCard;
  String get labelMinorArcana;
  String get labelTarotExperts;
  String get labelWaite;
  String get labelSmith;
  String get labelCrowley;
  String get labelTarotBooks;
  String get labelPictorialKey;
  String get labelBookOfThoth;
  String get labelMeaning;
  String get messageNoKeywords;
  
  // ==================== 文本样式统一管理 ====================
  
  /// 创建带样式的文本组件 - 主标题
  Widget createMainTitle(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeHeadlineMedium,
        fontWeight: DynamicTokens.fontWeightBlack,
        fontFamily: DynamicTokens.fontFamilyHeadline,
        color: color,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 次标题
  Widget createSubTitle(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeTitleLarge,
        fontWeight: DynamicTokens.fontWeightBold,
        fontFamily: DynamicTokens.fontFamilyHeadline,
        color: color,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 小标题
  Widget createSmallTitle(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeTitleMedium,
        fontWeight: DynamicTokens.fontWeightSemiBold,
        fontFamily: DynamicTokens.fontFamilyHeadline,
        color: color,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 正文
  Widget createBodyText(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeBodyMedium,
        fontWeight: DynamicTokens.fontWeightRegular,
        fontFamily: DynamicTokens.fontFamilyBody,
        color: color,
        height: 1.5,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 强调文本
  Widget createEmphasisText(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeBodyMedium,
        fontWeight: DynamicTokens.fontWeightMedium,
        fontFamily: DynamicTokens.fontFamilyBody,
        color: color,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 按钮文字
  Widget createButtonText(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeBodyMedium,
        fontWeight: DynamicTokens.fontWeightBold,
        fontFamily: DynamicTokens.fontFamilyBody,
        color: color,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 说明文字
  Widget createCaptionText(String text, {Color? color}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeCaption,
        fontWeight: DynamicTokens.fontWeightRegular,
        fontFamily: DynamicTokens.fontFamilyBody,
        color: color,
        height: 1.4,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 错误消息
  Widget createErrorText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeBodySmall,
        fontWeight: DynamicTokens.fontWeightMedium,
        fontFamily: DynamicTokens.fontFamilyBody,
        color: DynamicTokens.textError,
      ),
    );
  }
  
  /// 创建带样式的文本组件 - 成功消息
  Widget createSuccessText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: DynamicTokens.fontSizeBodySmall,
        fontWeight: DynamicTokens.fontWeightMedium,
        fontFamily: DynamicTokens.fontFamilyBody,
        color: DynamicTokens.textSuccess,
      ),
    );
  }
  
  // ==================== 预定义的样式化文本组件 ====================
  
  /// 首页 - "本日のカード" 标题
  Widget get homeDailyCardTitle => createMainTitle(homeDailyCard);
  
  /// 首页 - "タロットカレンダー" 标题  
  Widget get homeTarotCalendarTitle => createSubTitle(homeTarotCalendar);
  
  /// 应用名称标题
  Widget get appNameTitle => createMainTitle(appName);
  
  /// 应用副标题
  Widget get appSubtitleText => createCaptionText(appSubtitle);
  
  /// 占卜流程标题
  Widget get readingSelectSpreadTitle => createSubTitle(readingSelectSpread);
  
  /// 兑换码页面标题
  Widget get redemptionPageTitle => createSubTitle(redemptionTitle);
  
  /// 完成按钮
  Widget get completeButton => createButtonText(buttonComplete);
  
  /// 取消按钮
  Widget get cancelButton => createButtonText(buttonCancel);
  
  /// 加载中消息
  Widget get loadingMessage => createCaptionText(messageLoading);
  
  /// 错误消息
  Widget get errorMessage => createErrorText(messageError);
  
  // ==================== 订阅服务相关 ====================
  String get messageSimulatedPurchaseSuccess;
  String get messageSimulatedPurchaseFailed;
  String get messageRealPaymentNotImplemented;
  String get messagePurchaseException;
  String get messageActivateSubscriptionWithCode;
  String get messageSubscriptionExtended;
  String get messageRestorePurchasesStart;
  String get messageSimulatedRestorePurchases;
  String get messageNoRestorablePurchases;
  String get messageCancelSubscription;
  String get messageSimulatedCancelSubscriptionSuccess;
  String get messageGetProductsStart;
  String get messageCallSupabaseFunction;
  String get messageSupabaseResponse;
  String get messageResponseType;
  String get messageSuccessfullyGotProducts;
  String get messageProductData;
  String get messageProduct;
  String get messageSupabaseDataFormatIncorrect;
  String get messageGetProductsFailed;
  String get messageErrorType;
  String get messagePostgrestException;
  String get messageFallbackToDefaultProducts;
  String get messageCurrentSubscriptionStatus;
  String get messageSubscriptionExpiry;
  String get messageSubscriptionStatusSaved;
  String get messageCleanupUserSubscriptionData;
  String get messageUserSubscriptionDataCleanupComplete;
  String get messageCleanupUserSubscriptionDataFailed;
  String get messageSyncLocalDataToSupabase;
  String get messageSyncLocalSubscriptionToSupabase;
  String get messageLocalSubscriptionDataSyncedToSupabase;
  String get messageNoLocalSubscriptionDataToSync;
  String get messageSyncLocalSubscriptionDataToSupabaseFailed;
  String get messageGetSubscriptionStatusFromSupabaseFailed;
  String get messageGetSubscriptionExpiryFromSupabaseFailed;
  String get messageCannotSyncToSupabaseUserNotLoggedIn;
  String get messageSubscriptionInfoSyncedToSupabase;
  String get messageSyncSubscriptionInfoToSupabaseFailed;
  String get messageCannotSyncFromSupabaseUserNotLoggedIn;
  String get messageStartSyncSubscriptionStatusFromSupabase;
  String get messageSyncSubscriptionStatusFromSupabaseSuccess;
  String get messageSyncSubscriptionStatusFromSupabaseFailed;
  String get messageUserNotLoggedInExpiryNull;
  String get messageGetSubscriptionExpiryFailed;
  String get messageStartingSubscriptionPurchase;
  String get messagePurchaseFailedUserNotLoggedIn;
  String get messagePurchaseFailedAnonymousUser;
  String get messageSimulatedPurchaseStart;
  
  // ==================== 其他缺失的键 ====================
  String get messageAdMobInitSuccess;
  String get messageAdMobInitFailed;
  String get messageSubscriptionInitSuccess;
  String get messageSubscriptionInitFailed;
  String get messageSupabaseInitSuccess;
  String get messageExistingUserSession;
  String get messageSupabaseInitFailed;
  String get messageUsingOfflineMode;
  String get messageUserType;
  String get messageNoUserSession;
  String get messageCachedUserId;
  String get messageLoginToRecoverData;
  String get messageDatabaseConnectionSuccess;
  String get messageConnectionFailed;
  String get messageCurrentMode;
  String get labelOfflineMode;
  String get messageOfflineModeDescription;
  String get labelOnlineMode;
  String get messageSupabaseConnectionSuccess;
  String get messageEnterRedemptionCode;
  String get messageCheckFailed;
  String get messageGuestCannotUseRedemptionCode;
  String get messageRedemptionFailed;
  String get messagePremiumServiceObtained;
  String get labelDays;
  String get labelNewExpiry;
  String get messageScanFailed;
  String get messagePasteFailed;
  String get messageRedemptionCodeDescription;
  String get buttonPaste;
  String get buttonScan;
  String get labelUsageInstructions;
  String get messageRedemptionCodeUsageLimit;
  String get messageRedemptionCodeExpiry;
  String get messageLoginRequiredForRedemption;
  String get messageRedemptionDaysAdded;
  String get labelSelectYear;
  String get labelMonday;
  String get labelTuesday;
  String get labelWednesday;
  String get labelThursday;
  String get labelFriday;
  String get labelSaturday;
  String get labelSunday;
  String get labelFavorites;
  String get messageFavoritesComingSoon;
  String get labelMajorArcana;
  String get labelWands;
  String get labelCups;
  String get labelSwords;
  String get labelPentacles;
  String get labelUnknown;
  String get messageAIFailed;
  String get buttonGetAIReading;
  String get labelLanguage;
  String get messageLanguageSwitched;
  String get labelCardDetail;
  String get labelLove;
  String get labelCareer;
  String get labelMoney;
  String get labelInterpersonal;
  String get labelPastPresentFuture;
  String get labelEmotionConsciousness;
  String get labelCauseSolution;
  
  // ==================== 抽牌/洗切牌 页面（Shuffle/Draw） ====================
  String get readingPreparing; // 准备卡牌
  String get readingShuffling; // 洗牌中
  String get readingCutting;   // 切牌中
  String get readingDrawing;   // 请抽牌
  String get readingResultTitle; // 占卜结果
  String get readingComplete;  // 占卜完成
  
  String get hintSwipeUpToPick; // 上滑取顶牌
  String get hintDragToSlot;    // 向上拖拽放入槽位
  String get errorDrawFailed;   // 抽牌失败
  
  String get buttonSeeResult;   // 查看结果
  String get readingTitle;
  String get labelSelectCardCount;
  String get buttonShuffle;
  String get buttonCut;
  String get messageStartingGoogleLogin;
  String get messageCurrentPlatform;
  String get messageAlreadyLoggedIn;
  String get messageSkipLoginReturnSuccess;
  String get messageAnonymousUserLogout;
  String get messageGoogleLoginFailed;
  String get messageWebPlatformOAuth;
  String get messageCurrentURL;
  String get messageExpectedRedirectURI;
  String get messageGoogleOAuthResult;
  String get messageWebGoogleLoginUserInfo;
  String get messageUserId;
  String get messageEmail;
  String get messageWebGoogleOAuthError;
  String get messageCheckGoogleCloudConsole;
  String get messageCheckRedirectURI;
  String get messageNativePlatformGoogleSignIn;
  String get messageStartingNativeGoogleLogin;
  String get messageUserCancelledGoogleLogin;
  String get messageGoogleLoginSuccess;
  String get messageCannotGetGoogleAuthToken;
  String get messageGoogleAuthTokenSuccess;
  String get messageSupabaseLoginSuccess;
  String get messageSupabaseLoginFailed;
  String get messageNativeGoogleLoginErrorDetails;
  String get messageErrorInfo;
  String get messageUserCancelledLogin;
  String get messageCheckGoogleConfigBundleId;
  String get messageCheckNetworkConnection;
  String get messageStartingAccountUpgrade;
  String get messageCurrentAnonymousUserId;
  String get messageAccountUpgradeSuccess;
  String get messageUpgradedUserId;
  String get messageAccountUpgradeFailed;
  String get messageSavingDailyCard;
  String get messageDate;
  String get messageCard;
  String get messageAlreadyDrewCardToday;
  String get messageAlreadyDrewCardTodayException;
  String get messageMessage;
  String get messageDailyCardSavedSuccess;
  String get messageRedemptionCodeService;
  String get messageInvalidRedemptionCodeFormat;
  String get messageRedemptionCodeNotFound;
  String get messageRedemptionCodeAlreadyUsed;
  String get messageRedemptionCodeExpired;
  String get messageValidRedemptionCode;
  String get messagePremiumService;
  String get messageCheckRedemptionCodeFailed;
  String get messageNetworkErrorCheckConnection;
  String get messageRedemptionComplete;
  String get messageRedemptionCodeUsageFailed;
  String get messageTestCodeGenerationDevModeOnly;
  String get messageGenerationFailed;
  String get labelMonthly;
  String get label3Months;
  String get labelYearly;
  String get labelDiscount;
  String get labelPremiumSubscription;
  String get labelPremiumSubscriptionDescription;
  String get labelPremium3MonthsPlan;
  String get labelPremium3MonthsPlanDescription;
  String get labelPremiumYearlyPlan;
  String get labelPremiumYearlyPlanDescription;
  String get messageSubscriptionServiceInitStart;
  String get messageDevModeSimulatedSubscription;
  String get messageSubscriptionServiceInitComplete;
  String get messageUserNotLoggedInSubscriptionNone;
  String get messageGetSubscriptionStatusFailed;
}


