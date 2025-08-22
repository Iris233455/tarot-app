# 订阅功能设置指南

## 🚨 重要：必须先执行数据库设置

在测试订阅功能之前，需要在Supabase中创建订阅产品表和函数。

### 第一步：在Supabase Dashboard中执行SQL

1. 打开 Supabase Dashboard
2. 进入 `SQL Editor`
3. 执行以下SQL脚本：

```sql
-- 创建订阅产品表和函数
BEGIN;

-- 1. 创建订阅产品表
CREATE TABLE IF NOT EXISTS subscription_products (
    id TEXT PRIMARY KEY,                          -- 产品ID (如: premium_monthly, premium_3months, premium_yearly)
    name_ja TEXT NOT NULL,                       -- 日文产品名称
    name_en TEXT NOT NULL,                       -- 英文产品名称
    description_ja TEXT,                         -- 日文描述
    description_en TEXT,                         -- 英文描述
    price_jpy INTEGER NOT NULL,                  -- 日元价格
    price_usd DECIMAL(10,2),                     -- 美元价格（可选）
    duration_days INTEGER NOT NULL,             -- 订阅天数
    duration_type TEXT NOT NULL CHECK (duration_type IN ('monthly', 'quarterly', '3months', 'yearly', 'lifetime')), -- 订阅类型
    is_active BOOLEAN DEFAULT TRUE,              -- 是否启用
    sort_order INTEGER DEFAULT 0,               -- 排序顺序
    features JSONB,                              -- 功能特性 (JSON格式)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 约束
    CONSTRAINT valid_price CHECK (price_jpy > 0),
    CONSTRAINT valid_duration CHECK (duration_days > 0)
);

-- 2. 创建订阅购买记录表
CREATE TABLE IF NOT EXISTS subscription_purchases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id TEXT REFERENCES subscription_products(id) NOT NULL,
    purchase_method TEXT NOT NULL CHECK (purchase_method IN ('test', 'apple_store', 'google_play', 'stripe', 'redemption_code')),
    
    -- 价格信息（记录购买时的价格）
    paid_amount_jpy INTEGER,
    paid_amount_usd DECIMAL(10,2),
    currency TEXT DEFAULT 'JPY',
    
    -- 订阅期间
    subscription_start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    subscription_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- 支付信息
    transaction_id TEXT,                         -- 第三方支付平台的交易ID
    receipt_data TEXT,                           -- 收据数据（用于验证）
    is_verified BOOLEAN DEFAULT FALSE,           -- 是否已验证
    
    -- 状态
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'refunded')),
    
    -- 时间戳
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(user_id, transaction_id)
);

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_subscription_products_active ON subscription_products(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_subscription_products_type ON subscription_products(duration_type);

CREATE INDEX IF NOT EXISTS idx_subscription_purchases_user_id ON subscription_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_purchases_status ON subscription_purchases(status);
CREATE INDEX IF NOT EXISTS idx_subscription_purchases_dates ON subscription_purchases(subscription_start_date, subscription_end_date);
CREATE INDEX IF NOT EXISTS idx_subscription_purchases_product ON subscription_purchases(product_id);

-- 4. 插入默认订阅产品
INSERT INTO subscription_products (id, name_ja, name_en, description_ja, description_en, price_jpy, price_usd, duration_days, duration_type, sort_order, features) VALUES
('premium_monthly', 'プレミアム月額プラン', 'Premium Monthly Plan', '月額プレミアムサービス', 'Monthly Premium Service', 1000, 6.67, 30, 'monthly', 1, 
 '{"ads_free": true, "unlimited_readings": true, "premium_spreads": true, "ai_insights": true, "priority_support": true}'::jsonb),

('premium_3months', 'プレミアム3ヶ月プラン', 'Premium 3-Month Plan', '3ヶ月プレミアムサービス（10%割引）', '3-Month Premium Service (10% off)', 2700, 18.00, 90, '3months', 2,
 '{"ads_free": true, "unlimited_readings": true, "premium_spreads": true, "ai_insights": true, "priority_support": true, "discount": "10%"}'::jsonb),

('premium_yearly', 'プレミアム年額プラン', 'Premium Yearly Plan', '年額プレミアムサービス（33%割引）', 'Yearly Premium Service (33% off)', 8000, 53.33, 365, 'yearly', 3,
 '{"ads_free": true, "unlimited_readings": true, "premium_spreads": true, "ai_insights": true, "priority_support": true, "discount": "33%", "best_value": true}'::jsonb);

-- 5. 启用行级安全策略
ALTER TABLE subscription_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_purchases ENABLE ROW LEVEL SECURITY;

-- 6. 创建RLS策略

-- 订阅产品表：所有人都可以查看启用的产品
CREATE POLICY "Anyone can view active subscription products" ON subscription_products
    FOR SELECT USING (is_active = true);

-- 订阅购买记录表：用户只能查看自己的购买记录
CREATE POLICY "Users can view own purchases" ON subscription_purchases
    FOR SELECT USING (auth.uid() = user_id);

-- 订阅购买记录表：用户可以插入自己的购买记录
CREATE POLICY "Users can insert own purchases" ON subscription_purchases
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 订阅购买记录表：用户可以更新自己的购买记录状态
CREATE POLICY "Users can update own purchases" ON subscription_purchases
    FOR UPDATE USING (auth.uid() = user_id);

-- 7. 创建购买订阅的数据库函数
CREATE OR REPLACE FUNCTION purchase_subscription(
    product_id_param TEXT,
    user_id_param UUID,
    purchase_method_param TEXT DEFAULT 'test',
    transaction_id_param TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    product_record subscription_products%ROWTYPE;
    purchase_id UUID;
    subscription_start TIMESTAMP WITH TIME ZONE;
    subscription_end TIMESTAMP WITH TIME ZONE;
    result JSON;
BEGIN
    -- 检查用户是否存在
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_id_param) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'user_not_found',
            'message', 'ユーザーが見つかりません'
        );
    END IF;
    
    -- 获取产品信息
    SELECT * INTO product_record FROM subscription_products 
    WHERE id = product_id_param AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'product_not_found',
            'message', '指定されたプランが見つかりません'
        );
    END IF;
    
    -- 计算订阅期间
    subscription_start := NOW();
    subscription_end := subscription_start + (product_record.duration_days || ' days')::INTERVAL;
    
    -- 生成唯一的交易ID（如果未提供）
    IF transaction_id_param IS NULL THEN
        transaction_id_param := 'test_' || extract(epoch from NOW())::bigint || '_' || user_id_param;
    END IF;
    
    -- 插入购买记录
    INSERT INTO subscription_purchases (
        user_id, 
        product_id, 
        purchase_method,
        paid_amount_jpy,
        paid_amount_usd,
        subscription_start_date,
        subscription_end_date,
        transaction_id,
        is_verified
    ) VALUES (
        user_id_param,
        product_id_param,
        purchase_method_param,
        product_record.price_jpy,
        product_record.price_usd,
        subscription_start,
        subscription_end,
        transaction_id_param,
        CASE WHEN purchase_method_param = 'test' THEN true ELSE false END
    ) RETURNING id INTO purchase_id;
    
    -- 更新用户profile的订阅状态
    SELECT activate_user_subscription(user_id_param, product_record.duration_days, 'purchase') INTO result;
    
    IF (result->>'success')::boolean THEN
        RETURN json_build_object(
            'success', true,
            'purchase_id', purchase_id,
            'product_name', product_record.name_ja,
            'duration_days', product_record.duration_days,
            'price_jpy', product_record.price_jpy,
            'subscription_end', subscription_end,
            'transaction_id', transaction_id_param,
            'message', product_record.name_ja || 'の購入が完了しました'
        );
    ELSE
        -- 如果激活订阅失败，删除购买记录
        DELETE FROM subscription_purchases WHERE id = purchase_id;
        RETURN result;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'database_error',
            'message', 'データベースエラーが発生しました: ' || SQLERRM
        );
END;
$$;

-- 8. 创建获取订阅产品列表的函数
CREATE OR REPLACE FUNCTION get_subscription_products()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    products_json JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', id,
            'name_ja', name_ja,
            'name_en', name_en,
            'description_ja', description_ja,
            'description_en', description_en,
            'price_jpy', price_jpy,
            'price_usd', price_usd,
            'duration_days', duration_days,
            'duration_type', duration_type,
            'features', features,
            'sort_order', sort_order
        ) ORDER BY sort_order ASC
    ) INTO products_json
    FROM subscription_products 
    WHERE is_active = true;
    
    RETURN COALESCE(products_json, '[]'::json);
END;
$$;

-- 9. 授予必要的权限
GRANT SELECT ON subscription_products TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON subscription_purchases TO authenticated;
GRANT EXECUTE ON FUNCTION purchase_subscription(TEXT, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscription_products() TO anon, authenticated;

COMMIT;
```

### 第二步：验证设置

执行SQL后，可以运行以下查询验证：

```sql
-- 检查产品表
SELECT * FROM subscription_products;

-- 检查函数
SELECT get_subscription_products();
```

应该看到三个产品：
- premium_monthly (¥1,000/月)
- premium_3months (¥2,700/3个月, 10%折扣)  
- premium_yearly (¥8,000/年, 33%折扣)

### 第三步：测试应用

1. 重启Flutter应用
2. 进入MyDeck页面
3. 点击"プレミアムにアップグレード"或"プレミアム管理" → "プレミアムサービスを購入"
4. 应该能看到三个不同的订阅选项
5. 选择任意一个进行测试购买
6. 购买成功后检查"プレミアム管理"中的到期时间

### 故障排除

如果仍然只显示默认的¥1,000选项：

1. 检查Flutter控制台的日志，查看"🛒 开始获取订阅产品列表..."相关的输出
2. 确认Supabase中的表和函数已正确创建
3. 在应用中进入MyDeck → 开发者工具 → 诊断实行，查看连接状态

### 已修复的问题

✅ **问题1**: 购买面板中无法选择plan - 需要先执行上述SQL设置  
✅ **问题2**: 购买后期间不会更新 - 已添加自动刷新机制  
✅ **问题3**: 初始加载时显示"读取中" - 已优化Provider初始化时序
