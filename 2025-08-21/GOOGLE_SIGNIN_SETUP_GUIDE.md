# Google登录配置指南（iOS/macOS原生支持）

## 🎯 Bundle ID信息
- **iOS Bundle ID**: `com.bendang.tarot.dev`
- **macOS Bundle ID**: `com.bendang.tarot.dev`

## 📋 第一步：Google Cloud Console配置

### 1. 创建项目（如果没有）
1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建新项目或选择现有项目

### 2. 启用Google Sign-In API
1. 在项目中搜索"Google Sign-In API"
2. 点击"启用"

### 3. 配置OAuth同意画面
1. 进入 **APIs & Services** → **OAuth consent screen**
2. 选择 **External**
3. 填写必要信息：
   - **App name**: Mystic Tarot JP
   - **User support email**: 你的邮箱
   - **Developer contact information**: 你的邮箱

### 4. 创建OAuth 2.0客户端ID

#### A. iOS客户端ID
1. 进入 **APIs & Services** → **Credentials**
2. 点击 **+ CREATE CREDENTIALS** → **OAuth client ID**
3. 选择 **iOS**
4. 填写：
   - **Name**: Mystic Tarot JP iOS
   - **Bundle ID**: `com.bendang.tarot.dev`
5. 点击 **Create**
6. **重要**：记录下 **Client ID**

#### B. macOS客户端ID（可选，建议与iOS共用）
1. 如需单独配置，重复上述步骤
2. 选择 **macOS** 平台
3. 使用相同的Bundle ID

## 📋 第二步：下载配置文件

### iOS配置
1. 在Credentials页面，找到你创建的iOS客户端
2. 点击下载按钮，下载 `GoogleService-Info.plist`
3. 将文件放到 `ios/Runner/` 目录下

### macOS配置（可选）
- 如果创建了单独的macOS客户端，下载相应的配置文件
- 将文件放到 `macos/Runner/` 目录下

## 📋 第三步：修改代码中的配置

在 `lib/services/supabase_service.dart` 中，你需要用实际的Client ID替换：

```dart
// 在 _signInWithGoogleNative() 方法中
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // iOS需要设置Client ID（从GoogleService-Info.plist自动读取）
  // 或者可以手动指定：
  // clientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
);
```

## 📋 第四步：更新项目配置

### iOS URL Scheme配置
需要在 `ios/Runner/Info.plist` 中添加URL Scheme（我会帮你自动添加）

### macOS URL Scheme配置  
需要在 `macos/Runner/Info.plist` 中添加类似配置

## 🚨 重要提示

1. **保密Client ID**：不要将配置文件提交到公开仓库
2. **Bundle ID匹配**：确保Google Console中的Bundle ID与项目完全一致
3. **测试用户**：在开发阶段，将测试邮箱添加到OAuth同意画面的测试用户列表

## ✅ 完成配置后

1. 将 `GoogleService-Info.plist` 放到 `ios/Runner/` 目录
2. 告诉我，我会帮你更新Info.plist配置
3. 重新构建应用测试Google登录

---

**请先完成Google Cloud Console的配置，然后将配置文件放到指定位置！**
