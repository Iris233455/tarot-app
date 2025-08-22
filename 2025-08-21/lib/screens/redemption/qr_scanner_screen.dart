import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mystic_tarot_jp/core/l10n/app_strings_base.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/services/redemption_service.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
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
    final strings = ref.watch(appStringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.redemptionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(strings.redemptionDescription, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.commonOk),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualInputDialog();
            },
            child: Text(strings.redemptionInputLabel),
          ),
        ],
      ),
    );
  }

  /// 显示手动输入对话框
  void _showManualInputDialog() {
    final strings = ref.watch(appStringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.redemptionInputLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.redemptionDescription),
            const SizedBox(height: 16),
            TextFormField(
              controller: _manualController,
              decoration: const InputDecoration(
                hintText: 'TEST0001',
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
            child: Text(strings.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _manualController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop(); // 关闭对话框
                Navigator.of(context).pop(code); // 返回兑换码
              }
            },
            child: Text(strings.buttonConfirm),
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
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.redemptionTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 扫码区域背景
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: _isScanning 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          strings.messageLoading,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 100,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          strings.redemptionDescription,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
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
                  border: Border.all(color: Colors.white, width: 2),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
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
                      label: Text(_isScanning ? strings.messageLoading : strings.buttonCheckCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 替代选项
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.paste, color: Colors.white),
                          label: const Text(
                            '粘贴',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showManualInputDialog,
                          icon: const Icon(Icons.keyboard, color: Colors.white),
                          label: const Text(
                            '手动输入',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 提示文本
                  Text(
                    strings.redemptionDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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
    const cornerColor = Colors.blue;

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
