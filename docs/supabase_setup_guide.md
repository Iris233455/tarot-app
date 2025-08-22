# Supabase 设置指南

## 1. 认证配置

### 启用认证方式
1. 打开 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择你的项目
3. 左侧菜单 → **Authentication** → **Settings**
4. 在 **Auth Providers** 部分确认：
   - ✅ **Email** - 已启用
   - ✅ **Anonymous** - 已启用 (用于匿名登录)
   - ✅ **Google** - 可选启用 (推荐)

### 配置Google登录 (推荐)
1. **创建Google项目**
   - 访问 [Google Cloud Console](https://console.cloud.google.com/)
   - 创建新项目或选择现有项目
   - 启用 "Google+ API" 或 "People API"

2. **创建OAuth凭据**
   - 凭据 → 创建凭据 → OAuth 2.0 客户端ID
   - 应用类型：Web应用
   - 授权重定向URI：
     ```
     https://你的项目ID.supabase.co/auth/v1/callback
     ```
   - 复制 Client ID 和 Client Secret

3. **配置Supabase**
   - 在Google Provider设置中：
   - Client ID: 粘贴你的Google Client ID
   - Client Secret: 粘贴你的Google Client Secret
   - 点击Save

### 邮箱确认设置
在 **Email** 部分：
- **Enable email confirmations**: 可以选择启用或禁用
  - 启用：用户注册后需要确认邮箱 (更安全)
  - 禁用：用户注册后立即可用 (更便捷)

### URL 配置
在 **URL Configuration** 部分：
- **Site URL**: `http://localhost:3000` (开发环境)
- **Redirect URLs**: 添加你的应用URL

## 2. 数据库迁移

### 必须执行的迁移文件

#### 2.1 Profile字段迁移
```sql
-- 003_add_detailed_user_profile_simple.sql
-- 为用户配置表添加详细的profile字段

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS birth_date DATE,
ADD COLUMN IF NOT EXISTS occupation TEXT,
ADD COLUMN IF NOT EXISTS relationship_status TEXT;

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_user_profiles_name ON user_profiles(name);
CREATE INDEX IF NOT EXISTS idx_user_profiles_birth_date ON user_profiles(birth_date);
```

#### 2.2 占卜方式数据迁移
```sql
-- 004_add_basic_spreads.sql
-- 插入基础的占卜方式数据

INSERT INTO tarot_spreads (spread_id, spread_name_jp, spread_name_en, steps, card_count, difficulty_level) 
VALUES 
  ('one', 'ワンオラクル', 'One Oracle', '一枚のカードを引いて運勢を占います', 1, 1),
  ('two', 'ツーカード', 'Two Card', '二枚のカードを引いて選択肢を占います', 2, 1),
  ('three', 'スリーカード', 'Three Card', '三枚のカードを引いて過去・現在・未来を占います', 3, 2)
ON CONFLICT (spread_id) DO NOTHING;
```

#### 2.3 每日抽牌消息字段迁移
```sql
-- 005_add_daily_card_message.sql
-- 为每日抽牌表添加消息字段

ALTER TABLE daily_cards 
ADD COLUMN IF NOT EXISTS message TEXT;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_daily_cards_user_date ON daily_cards(user_id, date DESC);

-- 添加注释
COMMENT ON COLUMN daily_cards.message IS '每日卡片的消息内容（今日のメッセージ）';
```

## 3. 安全策略 (RLS)

### 检查数据访问策略
确保以下策略存在：

#### user_profiles 表
```sql
-- 查看现有策略
SELECT * FROM pg_policies WHERE tablename = 'user_profiles';

-- 如果缺少，添加策略
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
```

#### daily_cards 表
```sql
CREATE POLICY "Users can view own daily cards" ON daily_cards
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily cards" ON daily_cards
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily cards" ON daily_cards
  FOR UPDATE USING (auth.uid() = user_id);
```

#### readings 表
```sql
CREATE POLICY "Users can view own readings" ON readings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own readings" ON readings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## 4. 测试配置

### 测试邮箱认证
1. 在应用中尝试注册新账户
2. 检查是否收到确认邮件（如果启用了邮箱确认）
3. 尝试登录刚注册的账户

### 测试匿名登录
1. 在应用中选择"ゲストとして利用"
2. 验证匿名用户可以使用基本功能
3. 测试从匿名用户升级为邮箱用户

### 测试数据保存
1. 登录账户后，填写profile信息
2. 进行每日抽牌
3. 进行复杂占卜
4. 检查数据是否正确保存到数据库

## 5. 常见问题

### 邮箱认证失败
- 检查邮箱格式是否正确
- 确认认证服务已启用
- 查看Network标签页的错误信息

### 数据无法保存
- 确认数据库迁移已执行
- 检查RLS策略是否正确
- 验证用户已正确登录

### 匿名登录失败
- 确认Anonymous认证已启用
- 检查项目配置是否正确