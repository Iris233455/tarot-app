import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

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
                content: Text('読み込みエラー: ${error.description}'),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '店舗を読み込み中...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
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
            child: const Text('開く'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗を共有'),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 将URL复制到剪贴板
              _copyToClipboard(widget.shopUrl);
            },
            child: const Text('コピー'),
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
      const SnackBar(
        content: Text('ログインページに移動しています...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// URLをクリップボードにコピー
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URLがクリップボードにコピーされました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
