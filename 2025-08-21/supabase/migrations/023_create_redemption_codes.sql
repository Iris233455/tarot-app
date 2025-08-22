-- 023_create_redemption_codes.sql
-- 创建兑换码系统相关表

BEGIN;

-- 1. 创建兑换码表
CREATE TABLE IF NOT EXISTS redemption_codes (
    code TEXT PRIMARY KEY,                    -- 兑换码（8-12位字符）
    days INTEGER NOT NULL,                   -- 兑换天数（7/30等）
    is_used BOOLEAN DEFAULT FALSE,           -- 是否已使用
    used_by UUID REFERENCES auth.users(id),  -- 使用者ID
    used_at TIMESTAMP WITH TIME ZONE,       -- 使用时间
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,    -- 兑换码过期时间（可选）
    description TEXT,                        -- 描述/批次信息
    batch_name TEXT DEFAULT 'manual',       -- 批次名称
    
    -- 约束
    CONSTRAINT valid_days CHECK (days > 0 AND days <= 365),
    CONSTRAINT valid_usage CHECK (
        (is_used = FALSE AND used_by IS NULL AND used_at IS NULL) OR
        (is_used = TRUE AND used_by IS NOT NULL AND used_at IS NOT NULL)
    )
);

-- 2. 创建用户订阅记录表（可选，用于跟踪兑换历史）
CREATE TABLE IF NOT EXISTS user_redemption_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    redemption_code TEXT REFERENCES redemption_codes(code) NOT NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    days_granted INTEGER NOT NULL,
    
    UNIQUE(user_id, redemption_code)
);

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_redemption_codes_used ON redemption_codes(is_used);
CREATE INDEX IF NOT EXISTS idx_redemption_codes_created_at ON redemption_codes(created_at);
CREATE INDEX IF NOT EXISTS idx_redemption_codes_batch ON redemption_codes(batch_name);
CREATE INDEX IF NOT EXISTS idx_user_redemption_history_user_id ON user_redemption_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_redemption_history_redeemed_at ON user_redemption_history(redeemed_at);

-- 4. 启用行级安全策略 (RLS)
ALTER TABLE redemption_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_redemption_history ENABLE ROW LEVEL SECURITY;

-- 5. 创建RLS策略

-- 兑换码表：只允许用户查询未使用的兑换码（用于验证）
CREATE POLICY "Users can check unused redemption codes" ON redemption_codes
    FOR SELECT USING (is_used = FALSE);

-- 用户兑换历史表：用户只能查看自己的兑换历史
CREATE POLICY "Users can view own redemption history" ON user_redemption_history
    FOR SELECT USING (auth.uid() = user_id);

-- 用户兑换历史表：用户可以插入自己的兑换记录
CREATE POLICY "Users can insert own redemption history" ON user_redemption_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6. 创建兑换码验证和使用的数据库函数
CREATE OR REPLACE FUNCTION redeem_code(
    redemption_code TEXT,
    user_id UUID
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    code_record redemption_codes%ROWTYPE;
    result JSON;
BEGIN
    -- 检查兑换码是否存在且未使用
    SELECT * INTO code_record 
    FROM redemption_codes 
    WHERE code = redemption_code AND is_used = FALSE;
    
    IF NOT FOUND THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'invalid_code',
            'message', '兑换码无效或已被使用'
        );
    END IF;
    
    -- 检查兑换码是否过期
    IF code_record.expires_at IS NOT NULL AND code_record.expires_at < NOW() THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'expired_code',
            'message', '兑换码已过期'
        );
    END IF;
    
    -- 检查用户是否已经使用过此兑换码
    IF EXISTS (
        SELECT 1 FROM user_redemption_history 
        WHERE user_redemption_history.user_id = redeem_code.user_id 
        AND user_redemption_history.redemption_code = redeem_code.redemption_code
    ) THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'already_used',
            'message', '您已经使用过此兑换码'
        );
    END IF;
    
    -- 开始事务：标记兑换码为已使用，并记录兑换历史
    UPDATE redemption_codes 
    SET is_used = TRUE, used_by = user_id, used_at = NOW()
    WHERE code = redemption_code;
    
    INSERT INTO user_redemption_history (user_id, redemption_code, days_granted)
    VALUES (user_id, redemption_code, code_record.days);
    
    -- 返回成功结果
    RETURN JSON_BUILD_OBJECT(
        'success', TRUE,
        'days', code_record.days,
        'message', FORMAT('成功兑换 %s 天订阅', code_record.days)
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'database_error',
            'message', '兑换过程中发生错误，请稍后重试'
        );
END;
$$;

-- 7. 创建生成兑换码的管理员函数
CREATE OR REPLACE FUNCTION generate_redemption_codes(
    count INTEGER,
    days INTEGER,
    batch_name TEXT DEFAULT 'manual',
    expires_in_days INTEGER DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    i INTEGER;
    new_code TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
    generated_codes TEXT[] := '{}';
BEGIN
    -- 检查参数
    IF count <= 0 OR count > 1000 THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'invalid_count',
            'message', '生成数量必须在1-1000之间'
        );
    END IF;
    
    IF days <= 0 OR days > 365 THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'invalid_days',
            'message', '天数必须在1-365之间'
        );
    END IF;
    
    -- 计算过期时间
    IF expires_in_days IS NOT NULL THEN
        expires_at := NOW() + INTERVAL '1 day' * expires_in_days;
    END IF;
    
    -- 生成兑换码
    FOR i IN 1..count LOOP
        -- 生成8位随机字符串（大写字母+数字，排除容易混淆的字符）
        new_code := SUBSTRING(
            REPLACE(REPLACE(REPLACE(
                ENCODE(gen_random_bytes(6), 'base64'),
                '/', ''
            ), '+', ''), '=', ''),
            1, 8
        );
        
        -- 确保兑换码唯一
        WHILE EXISTS (SELECT 1 FROM redemption_codes WHERE code = new_code) LOOP
            new_code := SUBSTRING(
                REPLACE(REPLACE(REPLACE(
                    ENCODE(gen_random_bytes(6), 'base64'),
                    '/', ''
                ), '+', ''), '=', ''),
                1, 8
            );
        END LOOP;
        
        -- 插入兑换码
        INSERT INTO redemption_codes (code, days, expires_at, batch_name)
        VALUES (new_code, days, expires_at, batch_name);
        
        generated_codes := array_append(generated_codes, new_code);
    END LOOP;
    
    RETURN JSON_BUILD_OBJECT(
        'success', TRUE,
        'count', count,
        'codes', generated_codes,
        'days', days,
        'batch_name', batch_name,
        'expires_at', expires_at
    );
END;
$$;

-- 8. 授予必要的权限
GRANT EXECUTE ON FUNCTION redeem_code(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_redemption_codes(INTEGER, INTEGER, TEXT, INTEGER) TO service_role;

-- 9. 插入一些测试数据
INSERT INTO redemption_codes (code, days, description, batch_name) VALUES
    ('TEST0001', 7, '测试兑换码 - 7天试用', 'test_batch'),
    ('TEST0002', 30, '测试兑换码 - 30天订阅', 'test_batch'),
    ('DEMO001A', 7, '演示兑换码 - 7天', 'demo_batch'),
    ('DEMO002B', 14, '演示兑换码 - 14天', 'demo_batch'),
    ('CARD001X', 30, '实体卡片附赠 - 30天', 'physical_card_v1')
ON CONFLICT (code) DO NOTHING;

COMMIT;

-- 显示创建结果
SELECT 'Redemption code system created successfully!' as status;
SELECT 'Test codes available:' as info;
SELECT code, days, description FROM redemption_codes WHERE batch_name IN ('test_batch', 'demo_batch') ORDER BY code;
