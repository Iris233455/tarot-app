import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';
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
                content: Text('読み込みエラー: ${error.description}'),
                backgroundColor: DynamicTokens.textError,
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
          icon: const Icon(AppIcons.arrowBack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer(builder: (context, ref, __) {
            final dt = ref.watch(dynamicTokensProvider);
            return Row(children: [
              IconButton(
                icon: const Icon(AppIcons.refresh),
                onPressed: () => _controller.reload(),
                style: IconButton.styleFrom(foregroundColor: dt.textPrimary),
              ),
              IconButton(
                icon: const Icon(AppIcons.accountCircle),
                onPressed: () => _navigateToLogin(),
                style: IconButton.styleFrom(foregroundColor: dt.textPrimary),
              ),
              IconButton(
                icon: const Icon(AppIcons.openInBrowser),
                onPressed: () => _showOpenInBrowserDialog(),
                style: IconButton.styleFrom(foregroundColor: dt.primaryColor),
              ),
            ]);
          }),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),
          
          // 加载指示器
          if (_isLoading)
            Consumer(
              builder: (context, ref, __) {
                final dt = ref.watch(dynamicTokensProvider);
                return Container(
                  color: (dt.isDark || dt.backgroundImage != null)
                      ? Colors.black.withOpacity(0.35)
                      : dt.surfaceColor.withOpacity(0.85),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(dt.primaryColor),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '店舗を読み込み中...',
                          style: TextStyle(
                            fontSize: 16,
                            color: dt.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      // 底部导航栏（可选）
      bottomNavigationBar: Container(
        height: 60,
        color: DynamicTokens.textWhite,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 返回按钮
            IconButton(
              icon: const Icon(AppIcons.arrowBack),
              onPressed: () async {
                if (await _controller.canGoBack()) {
                  await _controller.goBack();
                }
              },
            ),
            // 前进按钮
            IconButton(
              icon: const Icon(AppIcons.arrowForwardIos),
              onPressed: () async {
                if (await _controller.canGoForward()) {
                  await _controller.goForward();
                }
              },
            ),
            // 主页按钮
            IconButton(
              icon: const Icon(AppIcons.home),
              onPressed: () => _controller.loadRequest(Uri.parse(widget.shopUrl)),
            ),
            // 分享按钮
            IconButton(
              icon: const Icon(AppIcons.share),
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
      builder: (context) => Consumer(builder: (context, ref, __) {
        final dt = ref.watch(dynamicTokensProvider);
        return AlertDialog(
          backgroundColor: dt.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('外部ブラウザで開く', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
          content: const Text('この店舗を外部ブラウザで開きますか？', style: TextStyle(color: DynamicTokens.textBlack87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: DynamicTokens.textBlack87),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final Uri url = Uri.parse(widget.shopUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('エラーが発生しました'), backgroundColor: DynamicTokens.textError),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dt.primaryColor,
                foregroundColor: DynamicTokens.textWhite,
              ),
              child: const Text('開く'),
            ),
          ],
        );
      }),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer(builder: (context, ref, __) {
        final dt = ref.watch(dynamicTokensProvider);
        return AlertDialog(
        backgroundColor: dt.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('店舗を共有', style: TextStyle(color: DynamicTokens.textBlack87, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('この店舗のURLを共有しますか？', style: TextStyle(color: DynamicTokens.textBlack87)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DynamicTokens.textGrey500.withOpacity(0.1),
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
            style: TextButton.styleFrom(foregroundColor: DynamicTokens.textBlack87),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToClipboard(widget.shopUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dt.primaryColor,
              foregroundColor: DynamicTokens.textWhite,
            ),
            child: const Text('コピー'),
          ),
        ],
      );
      }),
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
