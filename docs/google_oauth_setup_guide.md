# Google OAuth 设置指南

## 🎯 Flutter Web + Supabase 的完整配置

### 1. Google Cloud Console 配置

#### OAuth 同意画面设置：
1. **ユーザータイプ**: 外部 (External)
2. **公開ステータス**: 
   - 开发阶段：テスト中
   - 生产阶段：本番環境用に公開
3. **テストユーザー**: 添加你的 Gmail 地址
4. **スコープ**: 
   - `userinfo.email`
   - `userinfo.profile` 
   - `openid`

#### OAuth 2.0 クライアント ID 设置：
1. **アプリケーションの種類**: ウェブアプリケーション
2. **承認済みの JavaScript 生成元**:
   ```
   http://localhost:3000
   https://localhost:3000
   ```
3. **承認済みのリダイレクト URI**:
   ```
   https://wpblulcekjnhwccrjqlg.supabase.co/auth/v1/callback
   ```

### 2. Supabase 配置

#### Authentication → Providers → Google:
1. **Enable Google provider**: ✅ 启用
2. **Client ID**: 从 Google Cloud Console 复制
3. **Client Secret**: 从 Google Cloud Console 复制

### 3. 常见问题解决

#### 问题 1: "unauthorized_client"
- 检查 Client ID 是否正确
- 检查 Redirect URI 是否完全匹配

#### 问题 2: "access_denied" 
- 检查 OAuth 同意画面是否设置为"公開済み"
- 或者确保测试用户已添加到"テストユーザー"列表

#### 问题 3: "redirect_uri_mismatch"
- 确保 Google Cloud Console 中的 Redirect URI 与 Supabase 完全一致
- 注意 `http` vs `https` 的区别

#### 问题 4: 显示 "This app isn't verified"
- 开发阶段：点击"詳細設定" → "安全ではないページに移動"
- 生产阶段：完成 Google 的应用验证流程

### 4. 调试技巧

#### 检查网络请求：
1. 打开浏览器开发者工具
2. 查看 Network 标签页
3. 查找包含 "oauth" 或 "callback" 的请求
4. 检查返回的错误信息

#### 检查 Console 日志：
- Flutter Web Console 中的认证状态日志
- Supabase Dashboard 中的 Authentication 日志

### 5. 端口相关注意事项

对于 Flutter Web 开发，确保：
- 使用固定端口：`flutter run -d chrome --web-port=3000`
- Google Cloud Console 中的 JavaScript 生成元包含该端口