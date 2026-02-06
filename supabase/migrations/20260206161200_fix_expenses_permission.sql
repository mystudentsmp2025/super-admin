-- Fix Permissions for Super Admin Expenses

-- 1. Ensure usage on schema
GRANT USAGE ON SCHEMA super_admin TO authenticated;
GRANT USAGE ON SCHEMA super_admin TO service_role;

-- 2. Grant access to expenses table explicitly
GRANT ALL ON TABLE super_admin.expenses TO authenticated;
GRANT ALL ON TABLE super_admin.expenses TO service_role;

-- 3. Grant access to sequences (if any, though UUID is used)
GRANT ALL ON ALL SEQUENCES IN SCHEMA super_admin TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA super_admin TO service_role;

-- 4. Verify RLS Policy for Insert
-- Drop existing policy if it exists to avoid conflict/confusion, then recreate
DROP POLICY IF EXISTS "Enable full access for authenticated users" ON super_admin.expenses;

CREATE POLICY "Enable full access for authenticated users"
ON super_admin.expenses
FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');
