## Mystic Tarot JP（2025-08-21）UI/UX 改修边界说明

本文件面向负责 UI/UX 的同学，明确「可以改」与「不可以改 / 需谨慎改」的范围，避免破坏现有数据、服务与导航契约。

### 技术概览（关键信息）
- **框架**: Flutter (Material 3) + Riverpod（`hooks_riverpod`/`flutter_riverpod`）+ GoRouter
- **主题与设计令牌**:
  - 固定设计令牌: `lib/themes/tokens.dart`
  - 动态令牌/主题切换: `lib/themes/dynamic_tokens.dart` + `lib/providers/theme_provider.dart`
  - 全局主题（MaterialApp用）: `lib/core/theme/app_theme.dart`
- **导航/路由**: `lib/routers/app_router.dart`
- **数据源切换**: `lib/services/data_service.dart`（在线/离线自动切换）
- **后端**:
  - Supabase（认证/数据表）: `lib/services/supabase_service.dart`
  - 本地数据（JSON）: `assets/data/*.json` + `lib/services/local_data_service.dart`
  - AI 解读服务（本地 FastAPI 默认）: `lib/services/ai_service.dart`（默认 `http://127.0.0.1:8000`）
- **主要页面/组件**: `lib/screens/**`, `lib/widgets/**`

---

### 可以改（UI/UX 层，安全改动）
- **配色/圆角/阴影/间距/排版**
  - `lib/themes/tokens.dart` 的常量（如颜色、圆角、阴影、间距、字体族名）。
  - `lib/core/theme/app_theme.dart` 中的 `ThemeData`（`textTheme`、`cardTheme`、`ElevatedButtonTheme`、`AppBarTheme`、`BottomNavigationBarTheme` 等）。
  - `lib/themes/dynamic_tokens.dart` 的渐变/透明度常量（保持对外 Getter 名称不变）。

- **主题风格扩展/切换**
  - 在 `lib/providers/theme_provider.dart` 的 `AppThemes.themes` 中新增主题项（`name`、`primaryColor`、`backgroundColor`、`surfaceColor`、可选 `backgroundImage`、文字颜色与 `isDark`）。
  - `lib/widgets/themed_background.dart` 的渐变遮罩与纹理呈现逻辑，可按主题调整观感。

- **页面布局与动效**
  - `lib/screens/**` 所有页面的布局、间距、字体样式、图标、动画（如 `home/`, `reading/` 下的页面）。
  - `lib/widgets/**` 组件的视觉与交互（如 `tarot_card_widget.dart` 卡片翻转/缩放动效、卡面信息展示）。
  - 可优化切换动画（如 `CustomTransitionPage`），但请保留既有路由路径与名称（见下方「禁止修改」）。

- **资源与插图（不改路径结构）**
  - 可以替换图片资源（保持原路径与文件名不变）。
  - 可为新增主题添加新背景图；建议放在 `assets/images/`，并在 `theme_provider.dart` 中引用。

- **文案/本地化（前提：不改变数据结构）**
  - 页面内文案与提示语、按钮文本、空状态说明等（`lib/screens/**`、`lib/widgets/**`）。
  - 不涉及模型/JSON 字段名的文案可自由调整。

---

### 需要谨慎改（改前请确认影响范围）
- **底部导航与路由编排**
  - `lib/routers/app_router.dart` 中的路径与路由名（如 `/`, `/reading`, `/gallery`, `/mydeck`, `/auth` 等）与认证重定向逻辑。建议只做过渡动画/`pageBuilder` 的视觉调整；如需新增路由请遵循既有命名风格，避免更改现有路径。

- **页面到页面的返回逻辑**
  - `lib/screens/reading/reading_flow_shell.dart` 中根据当前路径的返回行为，若变更路径或栈结构需同步更新对应分支。

- **主题 Provider 的对外接口**
  - `lib/themes/dynamic_tokens.dart` 与 `lib/providers/theme_provider.dart` 的对外 Getter/Provider 名称。新增字段可以，避免重命名/删除现有字段，防止下游组件取不到值。

- **Tarot 卡片展示的尺寸/比例**
  - `lib/widgets/tarot_card_widget.dart` 中卡面宽高与裁剪方式可改，但请确保翻转/悬停/缩放动画仍然流畅，且 `imageUrl` 仍按资产路径工作。

- **Spreads（占卜阵列）的展示数据**
  - `lib/screens/reading/format_select_page.dart` 中展示卡片与说明可改；但如果改动 `spreads` 的 ID 映射或数据来源，需要同步 `DataService.getSpreadMeta()` 的读取逻辑与资产图片路径。

---

### 不可以改（或需后端/数据联动一起改）
- **数据模型与字段命名（前后端契约）**
  - `lib/models/tarot_card.dart` 及其 `*.freezed.dart`、`*.g.dart` 自动生成文件。
  - 卡片 ID/文件名约定：大阿尔卡纳以 `major_\d+_` 开头；小阿尔卡纳 ID 末尾包含 `ace|2..10|page|knight|queen|king`，且花色包含 `wands|cups|swords|pentacles`（多处排序/分组依赖此命名）。
  - 本地 JSON 结构：`assets/data/tarot_books_contents.json`（`LocalDataService` 解析强依赖字段名）。

- **服务层方法签名与返回结构**
  - `lib/services/data_service.dart`：在线/离线模式切换、随机抽牌/分组/搜索的函数签名与语义。
  - `lib/services/local_data_service.dart`：JSON 解析、字段清洗、排序规则与缓存键。
  - `lib/services/supabase_service.dart`：认证/表结构/字段名/查询条件（与 Supabase 数据库强绑定）。
  - `lib/services/ai_service.dart`：请求体字段（`reading_type`, `question`, `cards`, `user`, 以及 two-cards 的 `option_a`/`option_b`）。

- **初始化顺序与关键开关**
  - `lib/main.dart` 中 `DataService.initialize()` → Ad/Subscription → Supabase 初始化与离线模式判定顺序，避免导致启动态/认证态异常。

- **路由路径与名称（深链/返回逻辑依赖）**
  - `lib/routers/app_router.dart` 的现有路径与路由名称，不得随意更名或删除。

- **资产路径结构/文件名（代码直接引用）**
  - `assets/images/tarot/**`、`assets/images/spreads/**` 等现有文件名与目录层级。可以替换图片但请保持相同路径与文件名。

- **后端连接信息/安全配置**
  - Supabase URL/Anon Key 请在 `lib/core/config/supabase_config.dart` 统一管理，不在 UI 代码中硬编码或修改。
  - AI 服务基础 URL（`ai_service.dart`）改动需与后端联动。

---

### 常见 UI/UX 任务建议（如何安全改）
- **新增主题**
  1) 在 `theme_provider.dart` 的 `AppThemes.themes` 新增一项（可选指定 `backgroundImage`）。
  2) 若有定制渐变，更新 `widgets/themed_background.dart` 的 `_getGradientColors` 分支。

- **统一调色/间距/圆角**
  - 改 `lib/themes/tokens.dart` 的常量；或在 `app_theme.dart` 的 `ThemeData` 中覆盖组件主题。

- **调整卡片视觉与动效**
  - 改 `lib/widgets/tarot_card_widget.dart` 的尺寸、阴影、悬停/翻转/缩放动画时长与曲线，保持对外参数不变。

- **改阅读流程页面的观感**
  - 改 `lib/screens/reading/**` 的排版/动效/插图；保留路由路径与 Provider 交互。

---

### 依赖与联动注意
- 多处排序/分组依赖卡片 ID/文件名模式（`major_XX_`、花色与等级后缀），请勿变更。
- 路由返回逻辑依赖具体路径字符串，请勿变更现有路径；新增路径需同步返回分支。
- 本地 JSON 字段名与 Supabase 表字段名是「后端契约」，请勿在 UI 层修改。

---

### 目录速查（与 UI/UX 最相关）
- 全局主题: `lib/core/theme/app_theme.dart`
- 设计令牌（固定）: `lib/themes/tokens.dart`
- 动态令牌/主题切换: `lib/themes/dynamic_tokens.dart`, `lib/providers/theme_provider.dart`
- 背景与渐变: `lib/widgets/themed_background.dart`
- 卡片组件: `lib/widgets/tarot_card_widget.dart`
- 首页（每日卡/AI 区块/日历）: `lib/screens/home/home_screen.dart`
- 阅读流程 Shell/页面: `lib/screens/reading/**`
- 路由: `lib/routers/app_router.dart`

如需进行超出上述「可以改」范围的变更，请先与后端/数据负责同学确认后再实施。



