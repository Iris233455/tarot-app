import 'package:flutter/foundation.dart';
import 'package:uni_links/uni_links.dart';

/// 深链服务（开发期：用于原生 iOS/macOS 自定义 URL Scheme）
class DeepLinkService {
  static Uri? _initialUri;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        _initialUri = uri;
      }
    } catch (_) {
      // 忽略解析异常
    }
  }

  static Uri? get initialUri => _initialUri;

  /// 取出并清空初始 Deep Link（避免后续重复触发）
  static Uri? consumeInitialUri() {
    final uri = _initialUri;
    _initialUri = null;
    return uri;
  }

  /// 简单判断是否为密码恢复相关的 Deep Link
  static bool looksLikeRecoveryUri(Uri uri) {
    final href = uri.toString();
    final qp = uri.queryParameters;
    final frag = uri.fragment;
    if (href.contains('password-reset-complete')) return true;
    if (qp['type'] == 'recovery') return true;
    if (qp.containsKey('access_token') || qp.containsKey('code') || qp.containsKey('state')) return true;
    if (frag.contains('access_token') || frag.contains('type=recovery')) return true;
    return false;
  }
}


