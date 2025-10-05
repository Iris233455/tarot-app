import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'tarot_card.freezed.dart';
part 'tarot_card.g.dart';

enum Arcana { major, wands, cups, swords, pentacles }

@freezed
abstract class TarotCard with _$TarotCard {
  const TarotCard._();

  const factory TarotCard({
    @JsonKey(name: 'card_id') required String id,
    @JsonKey(name: 'name_jp') required String nameJa,
    @JsonKey(name: 'name_en') required String nameEn,
    required String filename,
    @JsonKey(name: 'deck_id') @Default('rider_waite') String deckId,
    @JsonKey(name: 'page_number') num? pageNumber,
    required String story,
    @JsonKey(name: 'meaning_upright') required String meaningUpright,
    @JsonKey(name: 'meaning_reversed') required String meaningReversed,
    @JsonKey(name: 'keywords_upright') String? keywordsUpright,
    @JsonKey(name: 'keywords_reversed') String? keywordsReversed,
    
    // Past/Present/Future messages
    @JsonKey(name: 'message_past_present_future_upright') required String messagePastPresentFutureUpright,
    @JsonKey(name: 'message_past_present_future_reversed') required String messagePastPresentFutureReversed,
    
    // Emotion/Consciousness messages
    @JsonKey(name: 'message_emotion_consciousness_upright') required String messageEmotionConsciousnessUpright,
    @JsonKey(name: 'message_emotion_consciousness_reversed') required String messageEmotionConsciousnessReversed,
    
    // Cause/Solution messages
    @JsonKey(name: 'message_cause_solution_upright') required String messageCauseSolutionUpright,
    @JsonKey(name: 'message_cause_solution_reversed') required String messageCauseSolutionReversed,
    
    // Theme-based interpretations
    @JsonKey(name: 'theme_interpersonal_upright') required String themeInterpersonalUpright,
    @JsonKey(name: 'theme_interpersonal_reversed') required String themeInterpersonalReversed,
    @JsonKey(name: 'theme_money_upright') required String themeMoneyUpright,
    @JsonKey(name: 'theme_money_reversed') required String themeMoneyReversed,
    @JsonKey(name: 'theme_career_upright') required String themeCareerUpright,
    @JsonKey(name: 'theme_career_reversed') required String themeCareerReversed,
    @JsonKey(name: 'theme_love_upright') required String themeLoveUpright,
    @JsonKey(name: 'theme_love_reversed') required String themeLoveReversed,
    
    // Keyword arrays for different contexts
    @JsonKey(name: 'message_past_present_future_upright_keywords') required List<String> messagePastPresentFutureUprightKeywords,
    @JsonKey(name: 'message_past_present_future_reversed_keywords') required List<String> messagePastPresentFutureReversedKeywords,
    @JsonKey(name: 'message_emotion_consciousness_upright_keywords') required List<String> messageEmotionConsciousnessUprightKeywords,
    @JsonKey(name: 'message_emotion_consciousness_reversed_keywords') required List<String> messageEmotionConsciousnessReversedKeywords,
    @JsonKey(name: 'message_cause_solution_upright_keywords') required List<String> messageCauseSolutionUprightKeywords,
    @JsonKey(name: 'message_cause_solution_reversed_keywords') required List<String> messageCauseSolutionReversedKeywords,
    @JsonKey(name: 'theme_interpersonal_upright_keywords') required List<String> themeInterpersonalUprightKeywords,
    @JsonKey(name: 'theme_interpersonal_reversed_keywords') required List<String> themeInterpersonalReversedKeywords,
    @JsonKey(name: 'theme_money_upright_keywords') required List<String> themeMoneyUprightKeywords,
    @JsonKey(name: 'theme_money_reversed_keywords') required List<String> themeMoneyReversedKeywords,
    @JsonKey(name: 'theme_career_upright_keywords') required List<String> themeCareerUprightKeywords,
    @JsonKey(name: 'theme_career_reversed_keywords') required List<String> themeCareerReversedKeywords,
    @JsonKey(name: 'theme_love_upright_keywords') required List<String> themeLoveUprightKeywords,
    @JsonKey(name: 'theme_love_reversed_keywords') required List<String> themeLoveReversedKeywords,
  }) = _TarotCard;

  factory TarotCard.fromJson(Map<String, dynamic> json) =>
      _$TarotCardFromJson(json);
  
  String get imageUrl => 'assets/images/tarot/$deckId/$filename';

  List<String> get uprightKeywordsList {
    if (keywordsUpright != null && keywordsUpright!.isNotEmpty) {
      try {
        // 尝试解析JSON数组字符串
        final decoded = json.decode(keywordsUpright!);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
      } catch (e) {
        // 如果JSON解析失败，回退到字符串处理
        final cleaned = keywordsUpright!.replaceAll(RegExp("[\\[\\]'\"]"), '');
        if (cleaned.isNotEmpty) {
          return cleaned
              .split(',')
              .map((e) => e.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    }
    
    // 如果没有基本keywords，为小阿尔卡纳牌使用情感意识keywords作为备用
    if (messagePastPresentFutureUprightKeywords.isNotEmpty) {
      return messagePastPresentFutureUprightKeywords.take(3).toList();
    }
    
    return [];
  }

  List<String> get reversedKeywordsList {
    if (keywordsReversed != null && keywordsReversed!.isNotEmpty) {
      try {
        // 尝试解析JSON数组字符串
        final decoded = json.decode(keywordsReversed!);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
      } catch (e) {
        // 如果JSON解析失败，回退到字符串处理
        final cleaned = keywordsReversed!.replaceAll(RegExp("[\\[\\]'\"]"), '');
        if (cleaned.isNotEmpty) {
          return cleaned
              .split(',')
              .map((e) => e.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    }
    
    // 如果没有基本keywords，为小阿尔卡纳牌使用情感意识keywords作为备用
    if (messagePastPresentFutureReversedKeywords.isNotEmpty) {
      return messagePastPresentFutureReversedKeywords.take(3).toList();
    }
    
    return [];
  }
}

// 添加花色信息模型
@freezed
abstract class SuitInfo with _$SuitInfo {
  const factory SuitInfo({
    @JsonKey(name: 'suit_name_jp') required String nameJp,
    @JsonKey(name: 'suit_name_en') required String nameEn,
    @JsonKey(name: 'suit_story') required String story,
    @JsonKey(name: 'suit_symbolism') required String symbolism,
  }) = _SuitInfo;

  factory SuitInfo.fromJson(Map<String, dynamic> json) =>
      _$SuitInfoFromJson(json);
}

// 添加占卜展开方式模型
@freezed
abstract class SpreadInfo with _$SpreadInfo {
  const factory SpreadInfo({
    required String name,
    String? description,
    required List<String> steps,
  }) = _SpreadInfo;

  factory SpreadInfo.fromJson(Map<String, dynamic> json) =>
      _$SpreadInfoFromJson(json);
}

// 添加塔罗牌套牌模型
@freezed
abstract class TarotDeck with _$TarotDeck {
  const TarotDeck._();
  
  const factory TarotDeck({
    @JsonKey(name: 'deck_id') required String deckId,
    @JsonKey(name: 'deck_name_jp') required String nameJp,
    @JsonKey(name: 'deck_name_en') required String nameEn,
    @JsonKey(name: 'deck_description') required String description,
    @JsonKey(name: 'deck_author') required String author,
    @JsonKey(name: 'deck_year') required String year,
    @JsonKey(name: 'image_path') required String imagePath,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'card_data_file') required String cardDataFile,
    @JsonKey(name: 'back_image') @Default('back.png') String backImage,
  }) = _TarotDeck;

  factory TarotDeck.fromJson(Map<String, dynamic> json) =>
      _$TarotDeckFromJson(json);
      
  /// 获取套牌的默认背面图片路径
  String get defaultBackImageUrl => 'assets/images/tarot/$imagePath/$backImage';
}

// 扩展塔罗牌数据模型以支持多套牌
@freezed
abstract class TarotDecksData with _$TarotDecksData {
  const factory TarotDecksData({
    required List<TarotDeck> decks,
  }) = _TarotDecksData;

  factory TarotDecksData.fromJson(Map<String, dynamic> json) =>
      _$TarotDecksDataFromJson(json);
}

// 完整的塔罗牌数据模型
@freezed
abstract class TarotData with _$TarotData {
  const factory TarotData({
    required List<TarotCard> cards,
    required Map<String, SuitInfo> suits,
    @JsonKey(name: 'daily_spread') required SpreadInfo dailySpread,
    required Map<String, SpreadInfo> spreads,
  }) = _TarotData;

  factory TarotData.fromJson(Map<String, dynamic> json) =>
      _$TarotDataFromJson(json);
}

@freezed
abstract class ReadingResult with _$ReadingResult {
  const factory ReadingResult({
    required String id,
    required String type,
    required String question,
    required List<TarotCard> cards,
    required List<bool> orientations, // true = upright, false = reversed
    required String guidance,
    required DateTime createdAt,
  }) = _ReadingResult;

  factory ReadingResult.fromJson(Map<String, dynamic> json) =>
      _$ReadingResultFromJson(json);
}

@freezed
abstract class DailyCard with _$DailyCard {
  const factory DailyCard({
    required String id,
    required TarotCard card,
    required bool isUpright,
    required DateTime date,
  }) = _DailyCard;

  factory DailyCard.fromJson(Map<String, dynamic> json) =>
      _$DailyCardFromJson(json);
}

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    required String theme,
    required List<String> favoriteCards,
    required String bgmTrack,
    required String backDesign,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
} 