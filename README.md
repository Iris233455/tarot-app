# Mystic Tarot JP

一个基于 Flutter 的塔罗牌占卜应用，支持日语和英语界面。

## 🎯 项目状态

✅ **已完成功能：**
- Flutter 3.22 环境配置
- Riverpod 状态管理
- Go Router 路由管理
- Supabase 后端集成
- Material 3 主题设计
- 多语言支持（日语/英语）
- 完整的屏幕架构
- 动画效果
- 代码生成（Freezed + JSON）

✅ **已实现屏幕：**
- 首页 (Home Screen)
- 每日卡 (Daily Card)
- 抽牌流程 (Reading Flow)
- 卡片详情 (Card Detail)
- 历史记录 (History)
- 图书馆 (Library)
- 我的牌组 (My Deck)

## 🚀 快速开始

### 环境要求
- Flutter 3.22+
- Dart 3.4+
- Chrome 浏览器（Web 预览）

### 安装和运行

1. **克隆项目**
```bash
git clone <repository-url>
cd project
```

2. **安装依赖**
```bash
flutter pub get
```

3. **生成代码**
```bash
dart run build_runner build
```

4. **运行项目**
```bash
# Web 预览
flutter run -d chrome

# iOS 模拟器
flutter run -d ios

# Android 模拟器
flutter run -d android
```

## 📱 功能特性

### 核心功能
- **每日塔罗牌**: 每日获取一张塔罗牌及其解读
- **占卜流程**: 完整的抽牌、洗牌、解读流程
- **卡片库**: 浏览所有塔罗牌及其含义
- **历史记录**: 保存和查看占卜历史
- **个性化设置**: 主题、音效、背景音乐设置

### 技术特性
- **响应式设计**: 支持多种屏幕尺寸
- **流畅动画**: 卡片翻转、洗牌、过渡动画
- **离线支持**: 本地数据缓存
- **多语言**: 日语和英语界面
- **无障碍**: 支持屏幕阅读器

## 🎨 设计系统

### 颜色主题
- **主色调**: 深紫色 (#6B46C1)
- **辅助色**: 金色 (#F59E0B)
- **背景色**: 深灰色 (#1F2937)
- **文字色**: 白色 (#FFFFFF)

### 字体
- **日语**: Noto Sans JP
- **英语**: Roboto
- **装饰**: Noto Serif JP

### 间距系统
- **xs**: 4px
- **sm**: 8px
- **md**: 16px
- **lg**: 24px
- **xl**: 32px
- **xxl**: 48px

## 🏗️ 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用配置
├── models/                   # 数据模型
│   └── tarot_card.dart      # 塔罗牌模型
├── providers/                # 状态管理
│   ├── daily_card_provider.dart
│   └── tarot_providers.dart
├── screens/                  # 屏幕页面
│   ├── home/                # 首页
│   ├── daily_card/          # 每日卡
│   ├── reading/             # 占卜流程
│   ├── library/             # 图书馆
│   └── mydeck/              # 我的牌组
├── widgets/                  # 可复用组件
│   ├── hero_card.dart       # 卡片组件
│   └── calendar_list.dart   # 日历组件
├── services/                 # 服务层
│   └── supabase_service.dart
├── themes/                   # 主题配置
│   ├── theme.dart
│   └── tokens.dart
└── core/                     # 核心配置
    ├── l10n/                # 本地化
    └── router/              # 路由配置
```

## 🔧 开发指南

### 代码生成
项目使用 Freezed 和 JSON 序列化，修改模型后需要重新生成代码：

```bash
dart run build_runner build
```

### 添加新功能
1. 在 `models/` 中定义数据模型
2. 在 `providers/` 中创建状态管理
3. 在 `screens/` 中实现 UI 界面
4. 在 `services/` 中添加 API 调用
5. 在 `router/` 中配置路由

### 主题定制
修改 `themes/tokens.dart` 中的设计令牌来定制应用外观。

## 📦 依赖包

### 核心依赖
- `flutter_riverpod`: 状态管理
- `go_router`: 路由管理
- `supabase_flutter`: 后端服务
- `freezed`: 数据类生成
- `json_annotation`: JSON 序列化

### UI 依赖
- `animate_do`: 动画效果
- `just_audio`: 音频播放
- `flutter_hooks`: 钩子函数

### 开发依赖
- `build_runner`: 代码生成
- `freezed`: 数据类生成器
- `json_serializable`: JSON 序列化生成器

## 🐛 已知问题

1. **图片资源**: 目前使用占位图片，需要添加真实的塔罗牌图片
2. **Supabase 配置**: 需要配置真实的 Supabase 项目
3. **音频文件**: 需要添加背景音乐和音效文件

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- Flutter 团队提供的优秀框架
- Supabase 提供的后端服务
- 所有开源贡献者

---

**注意**: 这是一个 MVP 版本，功能正在持续开发中。欢迎提出建议和反馈！ 