-- 024_add_subscription_to_user_profiles.sql
-- 将订阅信息整合到 user_profiles 表中

BEGIN;

-- 1. 添加订阅相关字段到 user_profiles 表
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'none' CHECK (subscription_status IN ('none', 'active', 'expired', 'cancelled')),
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS subscription_activated_by TEXT DEFAULT 'purchase' CHECK (subscription_activated_by IN ('purchase', 'redemption_code', 'trial')),
ADD COLUMN IF NOT EXISTS subscription_activated_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS subscription_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_status ON user_profiles(subscription_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_expires_at ON user_profiles(subscription_expires_at);

-- 3. 创建触发器：自动更新 subscription_updated_at
CREATE OR REPLACE FUNCTION update_subscription_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    -- 只有当订阅相关字段发生变化时才更新时间戳
    IF (NEW.subscription_status IS DISTINCT FROM OLD.subscription_status) OR
       (NEW.subscription_expires_at IS DISTINCT FROM OLD.subscription_expires_at) OR
       (NEW.subscription_activated_by IS DISTINCT FROM OLD.subscription_activated_by) OR
       (NEW.subscription_activated_at IS DISTINCT FROM OLD.subscription_activated_at) THEN
        NEW.subscription_updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_updated_at_trigger
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_updated_at();

-- 4. 创建订阅管理函数
CREATE OR REPLACE FUNCTION activate_user_subscription(
    target_user_id UUID,
    days INTEGER,
    activation_type TEXT DEFAULT 'redemption_code'
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_expiry TIMESTAMP WITH TIME ZONE;
    new_expiry TIMESTAMP WITH TIME ZONE;
    result JSON;
BEGIN
    -- 检查用户是否存在
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = target_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'user_not_found',
            'message', 'ユーザーが見つかりません'
        );
    END IF;
    
    -- 确保用户profile存在
    INSERT INTO user_profiles (user_id) 
    VALUES (target_user_id) 
    ON CONFLICT (user_id) DO NOTHING;
    
    -- 获取当前订阅状态
    SELECT subscription_expires_at INTO current_expiry
    FROM user_profiles 
    WHERE user_id = target_user_id;
    
    -- 计算新的到期时间
    IF current_expiry IS NULL OR current_expiry < NOW() THEN
        -- 没有订阅或已过期，从现在开始计算
        new_expiry := NOW() + (days || ' days')::INTERVAL;
    ELSE
        -- 有有效订阅，延长现有时间
        new_expiry := current_expiry + (days || ' days')::INTERVAL;
    END IF;
    
    -- 更新订阅信息
    UPDATE user_profiles 
    SET 
        subscription_status = 'active',
        subscription_expires_at = new_expiry,
        subscription_activated_by = activation_type,
        subscription_activated_at = CASE 
            WHEN subscription_status = 'none' OR subscription_status = 'expired' 
            THEN NOW() 
            ELSE subscription_activated_at 
        END
    WHERE user_id = target_user_id;
    
    RETURN json_build_object(
        'success', true,
        'new_expiry', new_expiry,
        'days_added', days,
        'message', days || '日間のサブスクリプションが追加されました'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'database_error',
            'message', 'データベースエラーが発生しました: ' || SQLERRM
        );
END;
$$;

-- 5. 创建订阅状态检查函数
CREATE OR REPLACE FUNCTION get_user_subscription_status(target_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_profile RECORD;
    result JSON;
BEGIN
    -- 获取用户订阅信息
    SELECT 
        subscription_status,
        subscription_expires_at,
        subscription_activated_by,
        subscription_activated_at
    INTO user_profile
    FROM user_profiles 
    WHERE user_id = target_user_id;
    
    -- 如果没有profile记录，返回默认状态
    IF NOT FOUND THEN
        RETURN json_build_object(
            'status', 'none',
            'expires_at', null,
            'is_active', false,
            'days_remaining', 0
        );
    END IF;
    
    -- 检查是否过期
    IF user_profile.subscription_status = 'active' AND 
       user_profile.subscription_expires_at IS NOT NULL AND 
       user_profile.subscription_expires_at < NOW() THEN
        
        -- 自动更新为过期状态
        UPDATE user_profiles 
        SET subscription_status = 'expired'
        WHERE user_id = target_user_id;
        
        user_profile.subscription_status := 'expired';
    END IF;
    
    -- 计算剩余天数
    DECLARE
        days_remaining INTEGER := 0;
    BEGIN
        IF user_profile.subscription_status = 'active' AND 
           user_profile.subscription_expires_at IS NOT NULL THEN
            days_remaining := EXTRACT(DAY FROM (user_profile.subscription_expires_at - NOW()));
            IF days_remaining < 0 THEN days_remaining := 0; END IF;
        END IF;
        
        RETURN json_build_object(
            'status', user_profile.subscription_status,
            'expires_at', user_profile.subscription_expires_at,
            'is_active', user_profile.subscription_status = 'active',
            'days_remaining', days_remaining,
            'activated_by', user_profile.subscription_activated_by,
            'activated_at', user_profile.subscription_activated_at
        );
    END;
END;
$$;

-- 6. 修改兑换码函数以使用新的订阅系统
CREATE OR REPLACE FUNCTION redeem_code(
    redemption_code TEXT,
    user_id UUID
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    code_record redemption_codes%ROWTYPE;
    subscription_result JSON;
    result JSON;
BEGIN
    -- 检查兑换码是否存在且未使用
    SELECT * INTO code_record
    FROM redemption_codes 
    WHERE code = redemption_code AND is_used = false;
    
    IF NOT FOUND THEN
        SELECT * INTO code_record FROM redemption_codes WHERE code = redemption_code;
        IF FOUND AND code_record.is_used THEN
            RETURN json_build_object(
                'success', false,
                'error', 'already_used',
                'message', '引き換えコードは既に使用されています'
            );
        ELSE
            RETURN json_build_object(
                'success', false,
                'error', 'not_found',
                'message', '引き換えコードが見つかりません'
            );
        END IF;
    END IF;
    
    -- 检查是否过期
    IF code_record.expires_at IS NOT NULL AND code_record.expires_at < NOW() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'expired',
            'message', '引き換えコードは期限切れです'
        );
    END IF;
    
    -- 激活订阅
    SELECT activate_user_subscription(user_id, code_record.days, 'redemption_code') INTO subscription_result;
    
    IF (subscription_result->>'success')::boolean THEN
        -- 标记兑换码为已使用
        UPDATE redemption_codes 
        SET 
            is_used = true,
            used_by = user_id,
            used_at = NOW()
        WHERE code = redemption_code;
        
        -- 记录兑换历史
        INSERT INTO user_redemption_history (user_id, redemption_code, days_granted)
        VALUES (user_id, redemption_code, code_record.days);
        
        RETURN json_build_object(
            'success', true,
            'days', code_record.days,
            'message', code_record.days || '日間のプレミアムサービスが追加されました',
            'new_expiry', subscription_result->>'new_expiry'
        );
    ELSE
        RETURN subscription_result;
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

-- 7. 授予必要的权限
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON user_profiles TO anon, authenticated;
GRANT EXECUTE ON FUNCTION activate_user_subscription(UUID, INTEGER, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_user_subscription_status(UUID) TO anon, authenticated;

COMMIT;
