## UI/UX 设计与文本样式规范（开发者指引）

本指引用于新建/维护模块时快速对齐视觉规范：只需选择“文本样式类别”，程序会基于 Design Tokens 自动配置字体、字号、字重与字体族，并统一颜色/间距策略。

### 1) 设计令牌入口
- 颜色/间距/排版基线：`lib/themes/tokens.dart`（DesignTokens）
- 动态令牌（跟随主题/模式）：`lib/themes/dynamic_tokens.dart`（DynamicTokens）
- 全局 TextTheme 绑定：`lib/themes/theme.dart`、`lib/core/theme/app_theme.dart`

约束与默认：
- 最大字重上限：不超过 w600（SemiBold）。
- 取消所有文本/容器阴影：不再使用 Shadow/BoxShadow。
- 字体统一：NotoSansJP（Headline/Body 一致）。

### 2) 文本样式“类别”与默认映射
按重要度选择类别；程序会自动给到合适字号/字重/字体族，可用少量 copyWith 做细节调整（颜色、行高等）。

- 页面主标题（TitleXL）
  - 对应：`Theme.of(context).textTheme.headlineLarge`
  - 默认：24 / w600
- 区块/卡片标题（TitleL）
  - 对应：`textTheme.headlineMedium` 或 `textTheme.titleLarge`
  - 默认：24 / w600 或 20 / w600
- 次级标题（TitleM）
  - 对应：`textTheme.titleMedium`
  - 默认：18 / w600
- 正文（BodyL）
  - 对应：`textTheme.bodyLarge`
  - 默认：16 / w400
- 说明（BodyM）
  - 对应：`textTheme.bodyMedium`
  - 默认：14 / w400
- 标签/徽章（Label/Badge）
  - 对应：`textTheme.bodySmall`
  - 默认：12 / w500 或 10 / w600（视对比度选择其一）

提示：如需统一“类别命名”，建议在文件局部以常量别名标注，但实际渲染仍以 `TextTheme` 为主。

### 3) 快速用法示例（推荐）
最简单的使用方式：选类别 → 用 TextTheme → 可选 copyWith 微调颜色/行高。

```dart
// 标题（TitleL）
Text(
  strings.historyTitle,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.w600,
    color: DesignTokens.textPrimary,
  ),
)

// 正文（BodyL）
Text(
  strings.messageLoading,
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: DesignTokens.textSecondary,
  ),
)

// 徽章（Badge 10/w600）
Text(
  strings.labelUpright,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: DesignTokens.primaryColor,
  ),
)
```

可选（现成辅助组件）：`AppStringsBase` 提供了若干样式化文本方法，能自动套用字号/字体族：

```dart
final strings = ref.watch(appStringsProvider);
// 主标题
strings.createMainTitle(strings.appName);
// 次标题
strings.createSubTitle(strings.readingSelectSpread);
// 正文
strings.createBodyText(strings.messageError);
// 强调/按钮文本
strings.createButtonText(strings.buttonRetry);
```

### 4) 颜色与对比
- 统一使用 DesignTokens：
  - 主要文字：`DesignTokens.textPrimary`
  - 次要文字：`DesignTokens.textSecondary`
  - 主题色：`DesignTokens.primaryColor`
  - 背景/表面：`DesignTokens.backgroundColor` / `DesignTokens.surfaceColor`
- 禁止直接使用任意 `Colors.*`，除非是语义色（如状态反馈）且在 Token 未覆盖的情况下。

### 5) 间距与圆角
- 间距统一：`DesignTokens.spacingXs/Sm/Md/Lg/Xl/Xxl`
- 圆角统一：`DesignTokens.radiusXs/Sm/Md/Lg`

示例：
```dart
const SizedBox(height: DesignTokens.spacingMd);
Container(
  padding: const EdgeInsets.all(DesignTokens.spacingMd),
  margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
  decoration: BoxDecoration(
    color: DesignTokens.surfaceColor,
    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
  ),
  child: ...,
)
```

### 6) 禁止项（Do/Don't）
- 不使用：文本阴影（Shadow）、容器阴影（BoxShadow）。
- 不超过：`FontWeight.w600`。
- 不手写：`fontFamily: '...'
  - 字体族由 Token 与主题统一管理。
- 尽量避免：硬编码 `fontSize`、`Colors.*`、任意数字间距；优先 Token。

### 7) 新模块落地清单（Checklist）
1. 为每个文本挑选“类别”：TitleXL/TitleL/TitleM/BodyL/BodyM/Label/Badge。
2. 采用 `TextTheme` + `copyWith`：最多调色/行高，不突破 w600。
3. 颜色/间距/圆角使用 `DesignTokens`。
4. 不使用阴影；不手写字体族；避免零散魔法数。
5. 组件复用：能用已有组件（如 `strings.create*`）优先使用。

按以上规范，你只需“告诉类别”，其余（字号/字重/字体族）由主题与 Token 自动配置；再通过少量 `copyWith` 完成场景色与间距微调。


