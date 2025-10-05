## 前端文本 i18n 迁移计划（Plan）

目标：逐步将“前端可见文本”全部接入 i18n（AppStrings），调试日志/打印信息不纳入本次范围。

### 0) 范围说明（Scope）
- 包含：
  - UI 元素展示的所有文案：按钮、标题、提示、占位、对话框、SnackBar、Tab、标签、空状态、错误提示等。
  - 代码中直接传入到 `Text(...)`、`hintText:`、`labelText:`、`title: Text(...)`、`content: Text(...)` 等的硬编码字符串。
- 不包含：
  - `print/debugPrint/log` 等调试日志、开发用控制台输出。
  - 非面向用户的内部常量、枚举名、键名等。

### 1) 统一入口（已存在）
- 基类与多语言实现：`lib/core/l10n/`
  - `app_strings_base.dart`：抽象接口（新增键必须先加到这里）
  - `app_strings_ja.dart / en.dart / zh.dart / zh_tw.dart`：语言实现
  - `app_strings_fallback.dart`：回退包装（主语言缺失/空时回退到日文）
  - `localization_service.dart`：`appStringsProvider` 入口（Riverpod）

### 2) 迁移步骤（每次提交的工作流）
1. 定位硬编码文本：
   - 搜索模式：`const Text('...')`、`Text('...')`、`hintText: '...'`、`labelText: '...'`、`title: Text('...')` 等。
   - 确认该文本“对用户可见”。若仅用于日志输出，跳过。
2. 建键与实现：
   - 若 `AppStringsBase` 没有对应键：在其中新增 Getter。
   - 在 `ja/en/zh_CN/zh_TW` 中添加实现。若暂缺翻译，可先返回空字符串，依靠 `FallbackStrings` 回退到日文，保证可编译运行。
3. 替换调用：
   - 在 UI 中通过 `final strings = ref.watch(appStringsProvider);` 获取，然后使用 `strings.xxx`。
   - 示例：`Text(strings.buttonRetry)`、`hintText: strings.labelSearchCard`。
4. 编译校验：
   - `flutter analyze` 无新增错误。
   - 运行页面验证基础渲染（无需一次性覆盖全站）。
5. 提交与备注：
   - 提交信息包含：文件列表、键名清单、是否包含临时占位翻译（空串→回退）。

### 3) 组件/页面模版（示例）
```dart
class ExampleWidget extends ConsumerWidget {
  const ExampleWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.historyTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(strings.messageNoHistory, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: strings.labelEmail,
            hintText: strings.messageEnterYourQuestion,
          ),
        ),
      ],
    );
  }
}
```

### 4) 键名命名规范（建议）
- 以用途分组：`buttonXxx`、`labelXxx`、`messageXxx`、`shareXxx`、`readingXxx`、`tabXxx`、`dialogXxx`。
- 避免过度语义细节，保持稳定性；文案变化不改键名。

### 5) 多语言回退策略
- 若某语言暂未提供文案或返回空字符串，`FallbackStrings` 会回退到日文，确保 UI 不出现空白。

### 6) 校验清单（每次合并前）
- [ ] 未改动调试日志（print/debugPrint）→ 不做 i18n。
- [ ] 新增键已在 `AppStringsBase` 与四种语言中实现。
- [ ] UI 替换均通过 `ref.watch(appStringsProvider)` 获取。
- [ ] 构建/静态检查通过。

### 7) 渐进式推进顺序（建议）
1. 高曝光页：`home/reading/result/history`。
2. 关键流程页：登录、抽牌、扫码/兑换、订阅/购买、图库/牌库。
3. 辅助页：设置、主题/牌背选择、我的牌组、AI 解读等。

### 8) 常见问题（FAQ）
Q: 常量组件 `const Text('...')` 报错怎么办？
A: 改成非常量（移除 const），使用 `Text(strings.xxx)` 即可。

Q: 如何确认是否仍有硬编码文本？
A: 搜索 `Text('`、`const Text('`、`hintText:`、`labelText:` 等模式；或在本 README 执行的扫描报告中查看（如有脚本）。

—— 以上 Plan 仅覆盖“前端可见文本”。调试日志输出不纳入本次 i18n 范围。


