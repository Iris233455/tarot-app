import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// AI タロット解読サービス
class AIService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  
  /// タロット解読を取得
  /// 
  /// [readingType]: 解読タイプ ("daily", "one", "two", "three")
  /// [cards]: カードリスト [{"name": "愚者", "orientation": "upright"}]
  /// [question]: ユーザーの質問 (dailyの場合は空文字)
  /// [user]: ユーザー情報 {"name": "Yuki", "birthday": "1995-10-05", ...}
  static Future<String> getTarotReading({
    required String readingType,
    required List<Map<String, String>> cards,
    String question = '',
    Map<String, String>? user,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reading'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'reading_type': readingType,
          'question': question,
          'cards': cards,
          'user': user ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? '解読結果が取得できませんでした';
      } else {
        throw AIServiceException(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on SocketException {
      throw AIServiceException(
        'ネットワーク接続エラーです。AIサーバーに接続できません。',
      );
    } on FormatException {
      throw AIServiceException(
        'レスポンスの解析に失敗しました。',
      );
    } catch (e) {
      throw AIServiceException(
        '予期しないエラーが発生しました: $e',
      );
    }
  }

  /// 毎日の抽牌解読
  static Future<String> getDailyReading({
    required Map<String, String> card,
    Map<String, String>? user,
  }) async {
    return getTarotReading(
      readingType: 'daily',
      cards: [card],
      user: user,
    );
  }

  /// ワンオラクル解読
  static Future<String> getOneCardReading({
    required String question,
    required Map<String, String> card,
    Map<String, String>? user,
  }) async {
    return getTarotReading(
      readingType: 'one',
      question: question,
      cards: [card],
      user: user,
    );
  }

  /// 二択解読
  static Future<String> getTwoCardsReading({
    required String question,
    required Map<String, String> cardA,
    required Map<String, String> cardB,
    Map<String, String>? user,
    String? optionA,
    String? optionB,
  }) async {
    final requestBody = {
      'reading_type': 'two',
      'question': question,
      'cards': [cardA, cardB],
      'user': user ?? {},
    };
    
    // 選択肢A/Bが指定されている場合は追加
    if (optionA != null && optionA.isNotEmpty) {
      requestBody['option_a'] = optionA;
    }
    if (optionB != null && optionB.isNotEmpty) {
      requestBody['option_b'] = optionB;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reading'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? '解読結果が取得できませんでした';
      } else {
        throw AIServiceException(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on SocketException {
      throw AIServiceException(
        'ネットワーク接続エラーです。AIサーバーに接続できません。',
      );
    } on FormatException {
      throw AIServiceException(
        'レスポンスの解析に失敗しました。',
      );
    } catch (e) {
      throw AIServiceException(
        '予期しないエラーが発生しました: $e',
      );
    }
  }

  /// 三枚読み（過去・現在・未来）
  static Future<String> getThreeCardsReading({
    required String question,
    required Map<String, String> pastCard,
    required Map<String, String> presentCard,
    required Map<String, String> futureCard,
    Map<String, String>? user,
  }) async {
    return getTarotReading(
      readingType: 'three',
      question: question,
      cards: [pastCard, presentCard, futureCard],
      user: user,
    );
  }

  /// サーバー接続テスト
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/docs'),
        headers: {'Accept': 'text/html'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// AI サービス例外クラス
class AIServiceException implements Exception {
  final String message;
  
  const AIServiceException(this.message);
  
  @override
  String toString() => 'AIServiceException: $message';
}