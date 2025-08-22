import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 修复iOS滑动问题的包装器
class ScrollFixWrapper extends StatelessWidget {
  final Widget child;
  
  const ScrollFixWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 确保触摸事件能够正常传播
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // 轻触时确保焦点正确
        FocusScope.of(context).unfocus();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // 监听滑动事件，确保正常传播
          return false;
        },
        child: child,
      ),
    );
  }
}
