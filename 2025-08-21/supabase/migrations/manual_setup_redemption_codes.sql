-- 手动创建兑换码数据库表和测试数据
-- 如果自动迁移失败，请在 Supabase Dashboard 的 SQL Editor 中执行此脚本

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

-- 2. 创建用户兑换记录表
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

-- 5. 删除可能存在的旧策略
DROP POLICY IF EXISTS "Users can check unused redemption codes" ON redemption_codes;
DROP POLICY IF EXISTS "Users can view own redemption history" ON user_redemption_history;
DROP POLICY IF EXISTS "Users can insert own redemption history" ON user_redemption_history;

-- 6. 创建RLS策略
CREATE POLICY "Users can check unused redemption codes" ON redemption_codes
    FOR SELECT USING (is_used = FALSE);

CREATE POLICY "Users can view own redemption history" ON user_redemption_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own redemption history" ON user_redemption_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 7. 删除可能存在的旧函数
DROP FUNCTION IF EXISTS redeem_code(TEXT, UUID);

-- 8. 创建兑换码验证和使用函数
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
            'message', '引き換えコードが見つかりません。入力内容をご確認ください'
        );
    END IF;
    
    -- 检查兑换码是否过期
    IF code_record.expires_at IS NOT NULL AND code_record.expires_at < NOW() THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'expired_code',
            'message', 'この引き換えコードは期限切れです'
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
            'message', 'この引き換えコードは既に使用されています'
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
        'message', FORMAT('%s日間のプレミアムサービスの引き換えが完了しました', code_record.days)
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'database_error',
            'message', '引き換え処理中にエラーが発生しました。しばらくしてから再度お試しください'
        );
END;
$$;

-- 9. 授予必要的权限
GRANT EXECUTE ON FUNCTION redeem_code(TEXT, UUID) TO authenticated;

-- 10. 插入测试数据
INSERT INTO redemption_codes (code, days, description, batch_name) VALUES
    ('TEST0001', 7, 'テスト引き換えコード - 7日間トライアル', 'test_batch'),
    ('TEST0002', 30, 'テスト引き換えコード - 30日間購読', 'test_batch'),
    ('DEMO001A', 7, 'デモ引き換えコード - 7日間', 'demo_batch'),
    ('DEMO002B', 14, 'デモ引き換えコード - 14日間', 'demo_batch'),
    ('CARD001X', 30, '実物カード付属 - 30日間', 'physical_card_v1'),
    ('TRIAL7DY', 7, 'トライアル用7日間コード', 'trial'),
    ('PROMO30D', 30, 'プロモーション30日間コード', 'promotion')
ON CONFLICT (code) DO NOTHING;

COMMIT;

-- 11. 显示创建结果
SELECT 'Redemption code system setup completed!' as status;
SELECT '利用可能なテストコード:' as info;
SELECT code, days, description FROM redemption_codes WHERE batch_name IN ('test_batch', 'demo_batch', 'trial') ORDER BY code;
