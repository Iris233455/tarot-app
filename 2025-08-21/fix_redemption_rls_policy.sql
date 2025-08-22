-- 修复兑换码RLS策略，允许查询已使用的兑换码
BEGIN;

-- 删除现有策略
DROP POLICY IF EXISTS "Users can check unused redemption codes" ON redemption_codes;
DROP POLICY IF EXISTS "Anyone can check unused codes" ON redemption_codes;

-- 创建新策略：允许查询所有兑换码（用于验证）
CREATE POLICY "Users can check redemption codes" ON redemption_codes
    FOR SELECT USING (true);

-- 更新函数以正确处理已使用的情况
CREATE OR REPLACE FUNCTION redeem_code(
    redemption_code TEXT,
    user_id UUID
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    code_record redemption_codes%ROWTYPE;
BEGIN
    -- 首先检查兑换码是否存在（不管是否已使用）
    SELECT * INTO code_record 
    FROM redemption_codes 
    WHERE code = redemption_code;
    
    IF NOT FOUND THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'invalid_code',
            'message', '引き換えコードが見つかりません。入力内容をご確認ください'
        );
    END IF;
    
    -- 检查是否已使用
    IF code_record.is_used = TRUE THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'already_used',
            'message', 'この引き換えコードは既に使用されています'
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
    
    -- 检查用户是否已经使用过此兑换码（双重保护）
    IF EXISTS (
        SELECT 1 FROM user_redemption_history 
        WHERE user_redemption_history.user_id = redeem_code.user_id 
        AND user_redemption_history.redemption_code = redeem_code.redemption_code
    ) THEN
        RETURN JSON_BUILD_OBJECT(
            'success', FALSE,
            'error', 'already_used_by_user',
            'message', 'あなたは既にこの引き換えコードを使用しています'
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

COMMIT;

SELECT 'RLS策略とredeem_code関数を更新しました' as status;
