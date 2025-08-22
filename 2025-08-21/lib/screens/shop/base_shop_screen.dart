import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BaseShopScreen extends StatefulWidget {
  final String shopUrl;
  
  const BaseShopScreen({
    super.key,
    required this.shopUrl,
  });

  @override
  State<BaseShopScreen> createState() => _BaseShopScreenState();
}

class _BaseShopScreenState extends State<BaseShopScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentTitle = 'Base Shop';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 更新加载进度
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // 获取页面标题
            _controller.getTitle().then((title) {
              if (title != null && mounted) {
                setState(() {
                  _currentTitle = title;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Builder(builder: (context) {
                  return Consumer(builder: (context, ref, _) {
                    final strings = ref.watch(appStringsProvider);
                    return Text('${strings.messageError}: ${error.description}');
                  });
                }),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.shopUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          // 快速登录按钮
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _navigateToLogin(),
          ),
          // 在外部浏览器中打开
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _showOpenInBrowserDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),
          
          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Consumer(builder: (context, ref, _) {
                      final strings = ref.watch(appStringsProvider);
                      return Text(
                        strings.messageLoading,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
      // 底部导航栏（可选）
      bottomNavigationBar: Container(
        height: 60,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 返回按钮
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () async {
                if (await _controller.canGoBack()) {
                  await _controller.goBack();
                }
              },
            ),
            // 前进按钮
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () async {
                if (await _controller.canGoForward()) {
                  await _controller.goForward();
                }
              },
            ),
            // 主页按钮
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _controller.loadRequest(Uri.parse(widget.shopUrl)),
            ),
            // 分享按钮
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showShareDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenInBrowserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('外部ブラウザで開く'),
        content: const Text('この店舗を外部ブラウザで開きますか？'),
        actions: [
          Builder(builder: (context) {
            return Consumer(builder: (context, ref, _) {
              final strings = ref.watch(appStringsProvider);
              return TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings.buttonCancel),
              );
            });
          }),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // 使用url_launcher在外部浏览器打开
              try {
                final Uri url = Uri.parse(widget.shopUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('エラー: $e')),
                  );
                }
              }
            },
            child: Consumer(builder: (context, ref, _) {
              final strings = ref.watch(appStringsProvider);
              return Text(strings.commonOk);
            }),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer(builder: (context, ref, _) {
          final strings = ref.watch(appStringsProvider);
          return Text(strings.shareTitle);
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('この店舗のURLを共有しますか？'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.shopUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          Consumer(builder: (context, ref, _) {
            final strings = ref.watch(appStringsProvider);
            return TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.buttonCancel),
            );
          }),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 将URL复制到剪贴板
              _copyToClipboard(widget.shopUrl);
            },
            child: Consumer(builder: (context, ref, _) {
              final strings = ref.watch(appStringsProvider);
              return Text(strings.commonOk);
            }),
          ),
        ],
      ),
    );
  }

  /// Base登录页面へナビゲート
  void _navigateToLogin() {
    // Base的登录页面URL - 根据实际Base店铺调整
    String loginUrl = widget.shopUrl;
    if (!loginUrl.contains('/account/login')) {
      // 如果URL不包含登录路径，尝试添加通用登录路径
      if (loginUrl.contains('base.shop')) {
        loginUrl = loginUrl.replaceAll(RegExp(r'/$'), '') + '/account/login';
      } else {
        // 对于自定义域名，尝试通用登录路径
        loginUrl = loginUrl.replaceAll(RegExp(r'/$'), '') + '/login';
      }
    }
    
    _controller.loadRequest(Uri.parse(loginUrl));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Consumer(builder: (context, ref, _) {
          final strings = ref.watch(appStringsProvider);
          return Text(strings.messageLoading);
        }),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// URLをクリップボードにコピー
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer(builder: (context, ref, _) {
            final strings = ref.watch(appStringsProvider);
            return Text(strings.commonOk);
          }),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
