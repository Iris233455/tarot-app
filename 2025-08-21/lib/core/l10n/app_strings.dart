import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

/// 应用文本统一管理
/// 所有硬编码的界面文字都应该通过这个类管理
/// 同时提供统一的文本样式管理
class AppStrings {
  
  // ==================== 系统主标题 ====================
  static const String appName = 'Mystic Tarot';
  static const String appSubtitle = 'あなたの運命を占います';
  
  // ==================== 首页相关 ====================
  static const String homeDailyCard = '本日のカード';
  static const String homeTarotCalendar = 'タロットカレンダー';
  static const String homeTodayMessage = '今日のメッセージ';
  
  // ==================== 占卜流程 ====================
  static const String readingSelectSpread = 'スプレットを選択';
  static const String readingTarotReading = 'タロット占い';
  static const String readingExplanation = '説明';
  static const String readingQuestion = '質問';
  static const String readingInterpretation = '解釈';
  
  // ==================== 兑换码页面 ====================
  static const String redemptionTitle = '引き換えコード';
  static const String redemptionAbout = '引き換えコードについて';
  static const String redemptionDescription = '実物カードやイベントで入手した引き換えコードを入力すると、指定日数のプレミアムサービスを無料でご利用いただけます。';
  static const String redemptionInputLabel = '引き換えコードを入力';
  static const String redemptionComplete = '引き換え完了！';
  
  // ==================== 订阅相关 ====================
  static const String subscriptionPremiumPlan = 'プレミアムプラン';
  static const String subscriptionBenefits = 'プレミアム特典';
  static const String subscriptionNoAds = '広告なしでスムーズな体験';
  static const String subscriptionUnlimitedReading = '無制限のタロット解読';
  static const String subscriptionPremiumDesign = 'プレミアムカードデザイン';
  static const String subscriptionPrioritySupport = '優先サポート';
  
  // ==================== 设置页面 ====================
  static const String settingsDeckSelection = 'デッキを選択';
  static const String settingsSelectDeck = '使用するデッキを選択';
  static const String settingsBackDesign = '背面デザイン';
  static const String settingsBuyRealDeck = 'リアルデッキを購入';
  static const String settingsBuyDescription = '実物のタロットカードを購入';
  static const String settingsMusic = '音楽';
  static const String settingsReset = 'リセット';
  
  // ==================== 按钮文字 ====================
  static const String buttonComplete = '完了';
  static const String buttonCancel = 'キャンセル';
  static const String buttonConfirm = '確認';
  static const String buttonRedeemNow = '今すぐ引き換える';
  static const String buttonCheckCode = 'コードを確認';
  static const String buttonReset = 'リセット';
  
  // ==================== 状态消息 ====================
  static const String messageAlreadyDrawnToday = '今天已经抽过牌了，请明天再来！';
  static const String messageRedemptionSuccess = '引き換え完了！';
  static const String messageLoading = '読み込み中...';
  static const String messageError = 'エラーが発生しました';
  
  // ==================== 通用文字 ====================
  static const String commonYes = 'はい';
  static const String commonNo = 'いいえ';
  static const String commonOk = 'OK';
  static const String commonSave = '保存';
  static const String commonEdit = '編集';
  static const String commonDelete = '削除';
  static const String commonClose = '閉じる';
  
  // ==================== 文本样式统一管理 ====================
  
  /// 创建带样式的文本组件 - 主标题
  static Widget createMainTitle(String text, {Color? color}) {
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
  static Widget createSubTitle(String text, {Color? color}) {
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
  static Widget createSmallTitle(String text, {Color? color}) {
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
  static Widget createBodyText(String text, {Color? color}) {
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
  static Widget createEmphasisText(String text, {Color? color}) {
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
  static Widget createButtonText(String text, {Color? color}) {
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
  static Widget createCaptionText(String text, {Color? color}) {
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
  static Widget createErrorText(String text) {
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
  static Widget createSuccessText(String text) {
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
  static Widget get homeDailyCardTitle => createMainTitle(homeDailyCard);
  
  /// 首页 - "タロットカレンダー" 标题  
  static Widget get homeTarotCalendarTitle => createSubTitle(homeTarotCalendar);
  
  /// 应用名称标题
  static Widget get appNameTitle => createMainTitle(appName);
  
  /// 应用副标题
  static Widget get appSubtitleText => createCaptionText(appSubtitle);
  
  /// 占卜流程标题
  static Widget get readingSelectSpreadTitle => createSubTitle(readingSelectSpread);
  
  /// 兑换码页面标题
  static Widget get redemptionPageTitle => createSubTitle(redemptionTitle);
  
  /// 完成按钮
  static Widget get completeButton => createButtonText(buttonComplete);
  
  /// 取消按钮
  static Widget get cancelButton => createButtonText(buttonCancel);
  
  /// 加载中消息
  static Widget get loadingMessage => createCaptionText(messageLoading);
  
  /// 错误消息
  static Widget get errorMessage => createErrorText(messageError);
}
