import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_tarot_jp/services/supabase_service.dart';

/// 占卜履歴一覧（現在ログイン中のユーザー）
final readingHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // 避免缓存老数据：每次订阅时强制从服务端拉取
  final data = await SupabaseService.getReadingHistoryLite(limit: 100);
  return data;
});


