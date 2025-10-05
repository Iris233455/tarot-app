import 'package:flutter/material.dart';
import 'package:mystic_tarot_jp/core/ui/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:mystic_tarot_jp/services/redemption_service.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TextEditingController _manualController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  /// 模拟扫码功能（当前为演示实现）
  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    // 模拟扫码过程
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isScanning = false;
      });

      // 显示模拟扫码结果对话框
      _showScanResultDialog();
    }
  }

  /// 显示扫码结果对话框（演示用）
  void _showScanResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('扫码演示'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.infoOutline, size: 48, color: DynamicTokens.textInfo),
            SizedBox(height: DynamicTokens.spacingSm),
            Text(
              '扫码功能需要相机权限和QR码库支持。\n\n当前为演示模式，请手动输入兑换码测试功能。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualInputDialog();
            },
            child: const Text('手动输入'),
          ),
        ],
      ),
    );
  }

  /// 显示手动输入对话框
  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动输入兑换码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入从二维码中获得的兑换码：'),
            const SizedBox(height: DynamicTokens.spacingSm),
            TextFormField(
              controller: _manualController,
              decoration: const InputDecoration(
                hintText: '例如: TEST0001',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                _manualController.text = RedemptionService.formatCode(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _manualController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop(); // 关闭对话框
                Navigator.of(context).pop(code); // 返回兑换码
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 粘贴剪贴板内容
  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      if (data?.text != null && data!.text!.isNotEmpty) {
        final code = RedemptionService.formatCode(data.text!);
        Navigator.of(context).pop(code);
      } else {
        _showError('剪贴板为空');
      }
    } catch (e) {
      _showError('粘贴失败');
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DynamicTokens.textError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描兑换码'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: DynamicTokens.textWhite,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      backgroundColor: DynamicTokens.textBlack87,
      body: Stack(
        children: [
          // 扫码区域背景
          Container(
            width: double.infinity,
            height: double.infinity,
            color: DynamicTokens.textBlack87,
            child: _isScanning 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: DynamicTokens.textWhite),
                        SizedBox(height: DynamicTokens.spacingMd),
                        Text(
                          '正在扫描...',
                          style: TextStyle(color: DynamicTokens.textWhite),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 100,
                          color: DynamicTokens.textWhite54,
                        ),
                        SizedBox(height: DynamicTokens.spacingLg),
                        Text(
                          '将二维码放入扫描框内',
                          style: TextStyle(
                            color: DynamicTokens.textWhite,
                            fontSize: DynamicTokens.fontSizeTitleMedium,
                          ),
                        ),
                        SizedBox(height: DynamicTokens.spacingSm),
                        Text(
                          '支持兑换码二维码扫描',
                          style: TextStyle(
                            color: DynamicTokens.textWhite70,
                            fontSize: DynamicTokens.fontSizeBodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // 扫描框
          if (!_isScanning) ...[
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: DynamicTokens.textWhite, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // 四角装饰
                    ..._buildCornerDecorations(),
                  ],
                ),
              ),
            ),
          ],
          
          // 底部操作区域
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(DynamicTokens.spacingLg),
              decoration: BoxDecoration(
                color: DynamicTokens.textBlack87.withOpacity(0.8),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DynamicTokens.radiusMd),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 主要扫码按钮
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScanning,
                      icon: Icon(_isScanning ? Icons.hourglass_empty : Icons.qr_code_scanner),
                      label: Text(_isScanning ? '扫描中...' : '开始扫描'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DynamicTokens.textInfo,
                        foregroundColor: DynamicTokens.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: DynamicTokens.spacingMd),
                  
                  // 替代选项
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(AppIcons.paste, color: DynamicTokens.textWhite),
                          label: const Text(
                            '粘贴',
                            style: TextStyle(color: DynamicTokens.textWhite),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: DynamicTokens.textWhite54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: DynamicTokens.spacingSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showManualInputDialog,
                          icon: const Icon(AppIcons.keyboard, color: DynamicTokens.textWhite),
                          label: const Text(
                            '手动输入',
                            style: TextStyle(color: DynamicTokens.textWhite),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: DynamicTokens.textWhite54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: DynamicTokens.spacingMd),
                  
                  // 提示文本
                  Text(
                    '扫描实体卡片上的二维码\n或手动输入兑换码',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DynamicTokens.textWhite70,
                      fontSize: DynamicTokens.fontSizeBodyMedium,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建扫描框四角装饰
  List<Widget> _buildCornerDecorations() {
    const cornerSize = 30.0;
    const cornerThickness = 4.0;
    const cornerColor = DynamicTokens.textInfo;

    return [
      // 左上角
      Positioned(
        top: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: cornerColor, width: cornerThickness),
              left: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // 右上角
      Positioned(
        top: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: cornerColor, width: cornerThickness),
              right: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // 左下角
      Positioned(
        bottom: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cornerColor, width: cornerThickness),
              left: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
      // 右下角
      Positioned(
        bottom: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cornerColor, width: cornerThickness),
              right: BorderSide(color: cornerColor, width: cornerThickness),
            ),
          ),
        ),
      ),
    ];
  }
}
