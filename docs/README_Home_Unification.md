# 首页 UI/UX 统一化管理说明

本说明记录当前“首页（Home）”以及相关弹窗/日历模块完成的统一化改造，包含设计 Token、i18n、动画、标签与导航栏等规范，便于后续维护与扩展。

## 目标
- 文本/颜色/间距/边框等视觉风格由 Design/Dynamic Tokens 管理
- 业务文案全部走 i18n Provider（不再硬编码）
- 动画集中管理，可通过 Provider 切换
- 标签（Tag）组件规范化复用
- 详情弹窗与首页模块背景、描边风格一致且随主题变化
- 日历单元视觉与交互统一
- 顶部导航栏（AppBar）与底部导航一致用 Token，Logo 可点击回首页

---

## 关键文件
- 首页页面：`lib/screens/home/home_screen.dart`
- 标签组件：`lib/widgets/app_tag.dart`
- 动画集中管理：`lib/core/ui/animations.dart`
- AI 结果组件：`lib/widgets/ai_reading_widget.dart`
- 日历：`lib/widgets/calendar_list.dart`
- 主题与 Token：
  - 动态 Token：`lib/themes/dynamic_tokens.dart`
  - 基础 Token：`lib/themes/tokens.dart`
  - 主题：`lib/themes/theme.dart`
- 国际化：
  - 基类与语言：`lib/core/l10n/app_strings_base.dart`、`app_strings_ja.dart`、`app_strings_en.dart`
  - Provider：`appStringsProvider`（在各页面使用 `ref.watch(appStringsProvider)` 取文案）
- 图标别名：`lib/core/ui/app_icons.dart`
- 顶部 Logo：`lib/core/ui/app_logo.dart`

---

## 设计 Token 与主题用法
- 背景容器统一使用渐变与主题描边：
  - 无背景图（正常主题）：
    - 渐变：`dt.surfaceColor.withOpacity(0.8/0.6)`
    - 边框：`dt.primaryColor.withOpacity(0.2)`，宽度 1
  - 有背景图/暗背景：
    - 渐变：`DesignTokens.surfaceColor.withOpacity(0.95/0.90)`
    - 边框：`dt.primaryColor.withOpacity(0.6)`，宽度 2
- 新增/使用的 Token（节选）：
  - 标签灰：`DynamicTokens.tagFillGrey(#F2F2F2)`、`tagBorderGrey(#D9D9D9)`
  - 日历底盘色：`bgWarningSoft(#FFCC0D)`、`bgErrorSoft(#FF5F7E)`、`bgSuccessSoft(#01B9AC)`、`bgNeutralSoft(#757575)`
  - 字号：`fontSizeBodySmall = 13.0`（用于较小标签/说明）

---

## 文本与 i18n
- 首页/弹窗/标签的所有文案通过 `appStringsProvider` 获取：
  - 例如：`strings.labelUpright`、`strings.labelReversed`、`strings.labelStory`、`strings.labelMeaning`、`strings.messageNoKeywords`
- 正文样式统一：`Theme.of(context).textTheme.bodyMedium`（14 / w400）

---

## 动画集中管理
- 文件：`lib/core/ui/animations.dart`
- 枚举：`AiTextAnimationStyle`（fadeInUp/fadeIn/slideIn*/zoomIn/elasticIn/none）
- Provider：`aiTextAnimationStyleProvider`（默认 `fadeIn`）
- 用法：`wrapAiTextAnimation(child, style: ref.watch(aiTextAnimationStyleProvider))`
- 首页 AI 输出统一为 `fadeIn`

---

## 标签组件（AppTag）
- 文件：`lib/widgets/app_tag.dart`
- 默认（灰标签）：
  - 填充 `#F2F2F2`，描边 `#D9D9D9`
  - 文字 `DynamicTokens.textBlack87`，14 / w400
- 主题态（useTheme: true）：
  - overlay: true → 主题色叠加渐变（当前为 20%→10%，描边 45%），表达“Overlap”效果
  - overlay: false → 主题色 14% 填充 + 45% 描边
- 用法示例：
  ```dart
  AppTag(strings.labelUpright, useTheme: true, overlay: true)
  ```

---

## 详情弹窗（Dialog）
- 跟随首页模块的背景渐变与描边逻辑（随主题/背景图变换）
- 标题与结构：
  - 卡名：仅显示一个本地化名称（根据语言切换）
  - 方向标签：与首页一致使用 `AppTag`
  - 内容模块：`Story` 与 `Meaning`
    - 容器：`dt.primaryColor.withOpacity(0.08)` 填充 + `0.22` 边框
    - 标题：`textBlack87`、w600、`fontSizeBodyMedium`
    - 文本：正文统一 14 / 1.4 行距
- 关闭按钮右上角 `X`，半透明底色

---

## 日历（MonthCalendar/CalendarList）
- 图标与底盘统一：
  - 尺寸：圆盘 24×24，图标 14，白色图标 + 白色描边 1
  - 未来未抽：锁（`AppIcons.lock`）+ 灰底（`bgNeutralSoft`），保留 0.2 卡背
  - 过去未抽：仅显示圆盘 + 禁止（`AppIcons.block`），不显示卡背
  - 今天未抽：感叹号（`AppIcons.priorityHigh`）+ 红底（`bgErrorSoft`）
  - 已抽：勾（`AppIcons.check`）+ 绿底（`bgSuccessSoft`）
- 月份切换动画移除（避免干扰信息层级）
- 卡背亮度：未抽卡背统一 `Opacity(0.2)`

---

## 顶部导航栏（AppBar）与 Logo
- AppBar 与底栏一致使用 Token：
  - 背景：`dynamicTokens.backgroundColor`
  - 阴影：`elevation=2 / scrolledUnderElevation=2 / shadowColor=黑色8%`
  - 底部分隔线：1px，主题色 20%（有背景图/暗背景时 60%）
- 首页 Logo：`lib/core/ui/app_logo.dart`
  - 尺寸：36×36
  - 外层形状：填充主题色
  - 中心小方块：加深主题色（约 18%）
- 其它页面（Gallery / MyPage）顶部也应用同款 Logo，并支持点击 Logo 回到首页

---

## AI 阅读组件（AIReadingWidget）
- 修复 `context`、`ref` 传递问题
- 移除正文左侧竖条装饰
- 正文统一使用 `textTheme.bodyMedium`（14 / w400）
- 接入 `wrapAiTextAnimation` 完成态动画

---

## 实施指南（新增/调整时）
1. 文本：使用 `appStringsProvider` 获取文案
2. 颜色与样式：优先使用 `DynamicTokens` / `DesignTokens`
3. 背景容器：按“主题/有无背景图”选择对应渐变与描边透明度
4. 标签：统一用 `AppTag`，需要主题表达时 `useTheme: true`，是否叠加用 `overlay`
5. 动画：统一从 `animations.dart` 选择并包裹
6. 日历：圆盘/图标尺寸与颜色遵循本说明；过去未抽不再显示卡背
7. AppBar：保持 token 配置一致；其他页面顶部也可用 `AppLogo` 并支持点击回首页

---

## 变更记录（重点）
- AI 正文样式统一，移除竖条装饰
- 动画集中管理，AI 输出切到 `fadeIn`
- 详情弹窗结构统一，跟随主题背景与描边
- 标签组件 `AppTag` 统一灰样式与主题叠加样式
- 日历单元视觉与状态图标统一；过去未抽不再显示卡背
- 顶部导航栏风格与底栏统一；新增 `AppLogo`（主题色填充 + 加深中心方块）

---

如需扩展到其它页面，请复用上述组件与规范；新增 Token 或 i18n Key 时，分别更新 `dynamic_tokens.dart` 与 `app_strings_*`。




