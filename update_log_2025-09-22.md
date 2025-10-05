# 更新日志（2025-09-22）

- 顶部导航（阅读流程统一）
  - `/reading` 选择页：居中显示 `AppLogo`（可点击回首页）。
  - `/reading/intro|question|shuffle|result` 子页：居中仅显示返回箭头，隐藏 `AppLogo`；点击按层级返回（基于当前路由 `switch` → `context.go(...)`）。
  - 资源与组件：`assets/icons/return.svg`，`AppReturnIcon(size: 36)` 使用主题色着色；点击区域用 `GestureDetector` 包裹。
  - AppBar 统一：背景色、2 阶阴影、1px 分割线（与底部导航一致）。

- SVG 资源管理
  - 在 `pubspec.yaml` 声明 `assets/icons/` 目录；执行 `flutter clean && flutter pub get` 确保打包。
  - `AppLogo`：`SvgPicture.asset` 保留原色（不加 colorFilter）。
  - 返回箭头：`ColorFilter.mode(dt.primaryColor, BlendMode.srcIn)` 按主题色着色。

- 启动与环境
  - 后端：`cd ai_backend && source .venv/bin/activate && uvicorn app.api:app --reload --host 0.0.0.0 --port 8000`。
  - 前端（macOS）：`flutter run -d macos`。
  - 若被许可阻塞：执行 `sudo xcodebuild -license` 同意条款；必要时 `xcodebuild -runFirstLaunch` 一次性初始化。

- 离线模式与 Supabase
  - 启动时会探测数据库连接，失败则 `DataService.setOfflineMode(true)`，首页顶部呈现“离线提示”。
  - 当前配置 `supabaseUrl`（`wpblulcekjnhwccrjqlg.supabase.co`）不可解析，导致进入离线；需替换为正确的 Supabase 项目 URL 与 anon key。
  - 首页离线提示：
    - 文案改为 `appStringsProvider` 多语言；按钮使用 `strings.buttonRetry`。
    - 顶部统一留白 `SizedBox(height: 20)`；样式用 `DynamicTokens` 中性黑（非主题色）。

- 日历 UX 优化（今日未抽）
  - 点击当天且未抽时，弹窗显示“无履历”并新增“本日のカードを引く”按钮；点击后直接触发今日抽卡。
  - 新增 i18n 键 `buttonDrawTodayCard`（日/英/简/繁已补齐），并补齐 `FallbackStrings` 实现。
  - 弹窗文本/按钮颜色统一用中性黑、字重区分（不使用主题主色）。

- 其他一致性项
  - 详情弹窗背景与描边随主题 `surface/primary` 同步；标签统一使用 `AppTag(useTheme: true, overlay: true)`。
  - `ReadingFlowShell` 与首页等页面顶部/底部视觉样式一致；内容区顶部 `Padding/SizedBox` 维持 20。

