# 🔧 修复Google认证配置指南

## 问题诊断
错误信息：`Unacceptable audience in id_token`
原因：原生应用的Google客户端ID与Supabase配置不匹配

## 解决方案

### 方案1：使用Web客户端ID（推荐）

1. **在Google Cloud Console创建Web客户端**：
   - 访问：https://console.cloud.google.com/apis/credentials
   - 点击"+ 创建凭据" → "OAuth 2.0 客户端ID"
   - 应用类型：Web应用
   - 名称：`Tarot Web Client`
   - 已获授权的重定向URI：`https://your-project.supabase.co/auth/v1/callback`

2. **在Supabase中配置Web客户端ID**：
   - Dashboard → Authentication → Providers → Google
   - 使用Web客户端的Client ID和Client Secret

### 方案2：在Supabase中添加iOS客户端ID

1. **在Supabase中配置**：
   - Client ID: `21880803705-aqnabs2k58lam4fbth4qtknmuse5etq2.apps.googleusercontent.com`
   - 获取对应的Client Secret（如果有）

## 当前配置信息

- **iOS客户端ID**: `21880803705-aqnabs2k58lam4fbth4qtknmuse5etq2.apps.googleusercontent.com`
- **Bundle ID**: `com.bendang.tarot.dev`

## 下一步

请选择上述方案之一，完成配置后重新测试Google登录。
