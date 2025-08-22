-- 022_remove_id_from_user_profiles.sql
-- 删除 user_profiles 表的 id 列，使用 user_id 作为主键

BEGIN;

-- 1. 显示当前表结构（调试用）
SELECT 'Before modification - user_profiles structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;

-- 2. 检查并删除旧的主键约束
DO $$
DECLARE
  pk_name text;
BEGIN
  SELECT conname
  INTO   pk_name
  FROM   pg_constraint
  WHERE  conrelid = 'public.user_profiles'::regclass
    AND  contype  = 'p';

  IF pk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE user_profiles DROP CONSTRAINT %I', pk_name);
    RAISE NOTICE 'Dropped primary key constraint: %', pk_name;
  ELSE
    RAISE NOTICE 'No primary key constraint found';
  END IF;
END
$$;

-- 3. 删除可能存在的索引
DROP INDEX IF EXISTS idx_user_profiles_id_unique;
DROP INDEX IF EXISTS user_profiles_id_idx;

-- 4. 删除 id 列及其序列
ALTER TABLE user_profiles DROP COLUMN IF EXISTS id CASCADE;
DROP SEQUENCE IF EXISTS user_profiles_id_seq CASCADE;

-- 5. 确保 user_id 列约束正确
ALTER TABLE user_profiles 
  ALTER COLUMN user_id SET NOT NULL;

-- 6. 删除可能重复的 user_id 索引（因为即将成为主键）
DROP INDEX IF EXISTS idx_user_profiles_user_id_unique;

-- 7. 将 user_id 设为主键
ALTER TABLE user_profiles 
  ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id);

-- 8. 确保外键约束存在（引用 auth.users）
ALTER TABLE user_profiles 
  DROP CONSTRAINT IF EXISTS user_profiles_user_id_fkey;

ALTER TABLE user_profiles 
  ADD CONSTRAINT user_profiles_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 9. 显示修改后的表结构
SELECT 'After modification - user_profiles structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;

-- 10. 显示约束信息
SELECT 'Constraints on user_profiles:' as info;
SELECT conname, contype, 
       CASE contype 
         WHEN 'p' THEN 'PRIMARY KEY'
         WHEN 'f' THEN 'FOREIGN KEY'
         WHEN 'u' THEN 'UNIQUE'
         WHEN 'c' THEN 'CHECK'
         ELSE contype::text
       END as constraint_type
FROM pg_constraint 
WHERE conrelid = 'user_profiles'::regclass;

COMMIT;