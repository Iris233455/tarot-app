## Mystic Tarot JP（2025-08-21）本地启动与开发流程

本指南覆盖 Flutter 前端与 AI 后端（FastAPI）的本地启动步骤，以及 Supabase 连接注意事项。建议按顺序执行，首次运行完成后，后续只需执行少量命令即可启动。

### 一、环境准备
- Flutter 3.22+ / Dart 3.4+
- Python 3.9+（用于 AI 后端）
- iOS/Android 模拟器或 Chrome（用于前端）

### 二、AI 后端（FastAPI）
路径：`2025-08-21/ai_backend`

1) 进入目录并安装依赖
```bash
cd ai_backend
pip install -r requirements.txt
```

2) 环境变量
- 在 `ai_backend/.env` 设置 Gemini/GG API Key（支持 `GEMINI_API_KEY` 或 `GOOGLE_API_KEY`），示例：
```bash
echo "GEMINI_API_KEY=your_api_key_here" > .env
```

3) 构建（如向量库需要，可按 `ai_backend/README.md` 执行）。当前后端已改为基于 `card_content.py` + LLM 直读，无需预构建向量库即可运行。

4) 启动服务（默认端口 8000）
```bash
uvicorn app.api:app --reload --host 0.0.0.0 --port 8000
```

5) 健康检查
```bash
curl http://127.0.0.1:8000/test | cat
```
返回包含 `api_key_loaded` 字段即表示后端正常。前端会通过 `lib/services/ai_service.dart` 的 `http://127.0.0.1:8000` 调用该服务。

### 三、Supabase（可选，联机模式）
前端默认会在启动时初始化 Supabase 并尝试访问数据库：
- 配置文件：`lib/core/config/supabase_config.dart`
- 若不修改，应用会尝试连接预设项目；连接失败则自动切换至离线模式（本地 JSON 数据）。

如需使用你自己的 Supabase：
1) 在 Supabase 控制台创建项目，获取 `Project URL` 与 `anon` 公钥。
2) 更新 `lib/core/config/supabase_config.dart`：
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```
3) 运行后，控制台会打印在线/离线模式状态。

### 四、Flutter 前端
根目录：`2025-08-21/`

0) 进入正确目录（非常重要）
```bash
cd /Users/toshunmei/Desktop/Tarot/Tarot_Card_App/2025-08-21
# 验证：应能看到 pubspec.yaml
ls pubspec.yaml
```

1) 获取依赖
```bash
flutter pub get
```

2) 生成代码（模型有改动时执行）
```bash
dart run build_runner build
```

3) 运行
```bash
# Web Server（推荐，本地可直接访问）
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5175
```
访问：
- 首页: http://127.0.0.1:5175
- 设计令牌可视化: http://127.0.0.1:5175/#/design-tokens
 - 语言演示页面: http://127.0.0.1:5175/#/language-demo

如需使用 Chrome 设备：
```bash
# Web 预览（调试便捷）
flutter run -d chrome

# iOS 模拟器（先打开 Xcode 模拟器）
flutter run -d ios

# Android 模拟器（确保有已启动的 AVD）
flutter run -d android
```

4) 启动顺序建议
- 先启动 AI 后端（步骤二）。
- 再启动前端应用（步骤四）。
- 首次运行时，前端会：
  - 初始化本地数据与服务（广告/订阅可忽略失败）。
  - 初始化 Supabase（失败则自动切离线）。
  - 进入首页（每日卡）。

提示：如 Chrome 设备方式（`-d chrome`）出现端口不可访问或空白页，优先改用上面的 Web Server 方式（`-d web-server`）。

### 五、常见问题
- No pubspec.yaml file found
  - 原因：在错误目录运行了 `flutter run`（比如在 `Tarot_Card_App/` 根目录）。
  - 解决：`cd /Users/toshunmei/Desktop/Tarot/Tarot_Card_App/2025-08-21` 后重试。

- 前端报 AI 连接失败：确认 `ai_backend` 已在本机 `8000` 端口运行，或修改 `lib/services/ai_service.dart` 的 `_baseUrl` 指向你的后端。
- Supabase 报未认证并跳转 `/auth`：按页面提示完成登录；或保持离线模式（仍可使用本地 JSON 数据和大部分功能）。
- 资源加载失败（图片/背景）：保持原有资产路径和文件名，替换资源内容即可。

#### 语言切换无变化 / 页面未刷新
- 确认访问端口是否正确：本项目推荐使用 `5175`；若端口被占用可改用 `5176`。
  - 启动示例：`flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5176`
  - 杀端口（macOS）：`lsof -ti tcp:5175 | xargs -n1 kill -9`
- 浏览器强制刷新（Cmd+Shift+R）清缓存。
- 在 flutter run 控制台按 `R`（热重启）或 `q` 后重启。
- 语言演示页验证路径：`http://127.0.0.1:5175/#/language-demo`（或 5176）。
- 如果被路由拦截到 `/auth`，确保 `/language-demo` 已加入路由白名单。

#### SnackBar 报错（语言切换时）
- 现已将语言切换提示从 `ScaffoldMessenger.of(ref.context)` 改为 `ScaffoldMessenger.of(context)` 以避免在部分上下文中无法找到 `Scaffold` 的问题。

#### Provider 未随语言切换触发重建
- 我们将 `appStringsProvider` 与 `currentStringsProvider` 改为监听语言状态：
  ```dart
  // 关键：watch 语言枚举，read Notifier 提供 strings
  final _ = ref.watch(localizationServiceProvider);
  final svc = ref.read(localizationServiceProvider.notifier);
  return svc.strings;
  ```
  这样切换语言后，依赖 `strings` 的页面会自动重建并更新文案。

### 设计令牌相关编译错误修复指南：

**1. Constant evaluation error（常量求值错误）**
- **问题**：`const` 与运行时令牌混用
- **解决**：移除相关 Widget 上的 `const` 关键字
- **示例**：`const SizedBox(height: AppTheme.spacingM)` → `SizedBox(height: AppTheme.spacingM)`
- **常见场景**：`const TextStyle(fontSize: DynamicTokens.fontSizeXxx)` → `TextStyle(fontSize: DynamicTokens.fontSizeXxx)`

**2. dynamicTokens 未定义错误**
- **问题**：在非 ConsumerWidget/ConsumerState 中使用 `dynamicTokens`
- **解决方案**：
  - 确保类继承 `ConsumerWidget` 或 `ConsumerState`
  - 在 `build` 方法中获取：`final dynamicTokens = ref.watch(dynamicTokensProvider);`
  - 对于独立方法，通过参数传递：`void _method(DynamicTokens dynamicTokens)`
  - 对于无法访问 `ref` 的地方，使用静态版本：`DynamicTokens.textError` 而非 `dynamicTokens.textError`

**3. Member not found 错误**
- **问题**：`DynamicTokens` 类缺少静态成员
- **解决**：在 `lib/themes/dynamic_tokens.dart` 中添加对应的静态常量
- **示例**：添加 `static const Color textSuccess = Color(0xFF388E3C);`

**4. 重复声明错误**
- **问题**：同时存在实例方法和静态常量
- **解决**：保留静态常量，移除实例方法，或使用不同的命名

**5. 作用域问题**
- **问题**：在嵌套方法中无法访问 `dynamicTokens`
- **解决**：
  - 修改方法签名接受 `DynamicTokens` 参数
  - 在调用处传递 `dynamicTokens`
  - 或使用静态版本 `DynamicTokens.xxx`

**6. 批量修复技巧**
- 使用 Python 脚本批量替换硬编码样式（项目根目录下的 `*.py` 脚本）
- 优先修复编译阻断错误（红色错误）
- 逐步替换 `dynamicTokens.xxx` 为 `DynamicTokens.xxx`（静态版本）
- 移除不必要的 `const` 关键字
- 修复完成后可删除临时脚本文件：`rm *.py`

**调试步骤**：
1. 运行 `flutter run` 查看具体错误信息
2. 根据错误类型选择对应解决方案
3. 优先修复 "Member not found" 和 "Undefined name" 错误
4. 再处理 "Constant evaluation error"
5. 最后处理作用域相关问题

### 六、开发建议（配合 UI/UX 改修）
- 改代码前，先阅读 `README_UIUX.md` 中的「可改/不可改」边界。
- 主题/令牌改动优先在 `lib/themes/tokens.dart` / `lib/core/theme/app_theme.dart` / `lib/themes/dynamic_tokens.dart` 完成。
- 路由路径与服务层方法签名避免修改，以免影响流程与数据契约。

### 七、目录速查
- 前端入口：`lib/main.dart`、`lib/app.dart`
- 路由：`lib/routers/app_router.dart`
- 主题：`lib/core/theme/app_theme.dart`、`lib/themes/`
- 数据服务：`lib/services/data_service.dart`、`lib/services/local_data_service.dart`
- 后端服务：`ai_backend/app/api.py`、`ai_backend/app/config.py`

### 八、日志与一键命令（可选）
- 后端日志：`/tmp/tarot_ai_uvicorn.log`
- 前端（Web Server）日志：`/tmp/tarot_flutter_webserver.log`
- 前端（Chrome 设备）日志：`/tmp/tarot_flutter_run.log`

一键启动（示例，先后端后前端）：
```bash
# 后端（确保 .env 已包含 GEMINI_API_KEY 或 GOOGLE_API_KEY）
cd ai_backend && uvicorn app.api:app --reload --host 0.0.0.0 --port 8000 &

# 前端（推荐 Web Server）
cd .. && flutter pub get && flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5175
```

如需一键脚本（同时启动后端与前端），我可以添加 `scripts/dev.sh` 脚本供本地开发使用。



