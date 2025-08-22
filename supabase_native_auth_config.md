# Supabase原生Google认证配置

## 🎯 在Supabase Dashboard中配置

### 当前情况
- **Web客户端ID**: `21880803705-080iippdh2l4k305lgrrik4d36dnhfr5.apps.googleusercontent.com` ✅
- **原生客户端ID**: `21880803705-aqnabs2k58lam4fbth4qtknmuse5etq2.apps.googleusercontent.com` ❌ 未配置

### 解决方案：支持多个客户端ID

在 **Authentication** → **Providers** → **Google** 中：

1. **Client ID** 字段支持多个ID，用逗号分隔：
   ```
   21880803705-080iippdh2l4k305lgrrik4d36dnhfr5.apps.googleusercontent.com,21880803705-aqnabs2k58lam4fbth4qtknmuse5etq2.apps.googleusercontent.com
   ```

2. **或者，创建单独的环境**：
   - 保持Web客户端ID用于Web版本
   - 在另一个环境中配置原生客户端ID

### 如果Supabase不支持多客户端ID
那么我们需要创建专门的RPC函数来处理原生Google登录。
