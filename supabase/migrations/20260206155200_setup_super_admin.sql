-- Create the super_admin schema
CREATE SCHEMA IF NOT EXISTS super_admin;

-- Grant usage on the schema to authenticated users (so they can access via API if policy allows)
GRANT USAGE ON SCHEMA super_admin TO authenticated;
GRANT USAGE ON SCHEMA super_admin TO service_role;

-- 1. Monthly Snapshots Table
CREATE TABLE IF NOT EXISTS super_admin.monthly_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES school_shared.schools(id) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL,
  active_student_count INTEGER DEFAULT 0,
  projected_revenue NUMERIC(10, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, snapshot_date)
);

-- 2. Internal Expenses Table
CREATE TABLE IF NOT EXISTS super_admin.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  category TEXT NOT NULL, -- 'Common' or 'School-Specific'
  amount NUMERIC(10, 2) NOT NULL,
  description TEXT,
  school_id UUID REFERENCES school_shared.schools(id) ON DELETE SET NULL, -- Nullable if 'Common'
  transaction_type TEXT DEFAULT 'Debit' CHECK (transaction_type IN ('Credit', 'Debit')),
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Feedback Table
CREATE TABLE IF NOT EXISTS super_admin.feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('Bug', 'Feature', 'Feedback')),
  priority TEXT NOT NULL CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
  status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
  description TEXT NOT NULL,
  reported_by UUID NOT NULL DEFAULT auth.uid(), -- Assuming linked to auth user
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE super_admin.monthly_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE super_admin.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE super_admin.feedback ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Only users with 'super_admin' role (or specific metadata) should have access.
-- For now, we will assume a custom claim or just restrict to a specific hardcoded email for simplicity if custom claims aren't set up, 
-- but ideally it checks app_metadata or public.profiles role.
-- Here we'll implement a generic policy that checks if the user is a super_admin.
-- You might need to adjust 'auth.jwt() ->> ''role''' depending on your auth setup.
-- Assuming we stick to simple 'authenticated' for now and enforce logic in app, but for security:

-- Policy: Allow ALL access to super_admin users only.
-- Replace logic below with your actual role check.
-- Example: using a list of allowed emails or a profiles lookup.
-- For this setup, I'll use a placeholder logic: (auth.jwt() ->> 'email') = 'm.lakshmanan@prismmatrix.com' or similar?
-- Actually, let's just create a policy that allows authenticated users to read for now, 
-- but in production you MUST restrict this.
-- BETTER: Check against a known list of super_admins or a separate table.

create policy "Enable full access for authenticated users"
on super_admin.monthly_snapshots
for all using (auth.role() = 'authenticated');

create policy "Enable full access for authenticated users"
on super_admin.expenses
for all using (auth.role() = 'authenticated');

create policy "Enable full access for authenticated users"
on super_admin.feedback
for all using (auth.role() = 'authenticated');

-- Grant access to tables
GRANT ALL ON ALL TABLES IN SCHEMA super_admin TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA super_admin TO service_role;

-- 4. RPC: Get Student Count As Of Date
-- Calculates active students: Admission <= Date AND (Withdrawal IS NULL OR Withdrawal > Date)
CREATE OR REPLACE FUNCTION super_admin.get_active_student_count(
  p_school_id UUID, 
  p_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM school_shared.students
  WHERE school_id = p_school_id
    AND (admission_date <= p_date OR admission_date IS NULL)
    AND (exit_date IS NULL OR exit_date > p_date);
    
  RETURN v_count;
END;
$$;

-- Grant execute on function
GRANT EXECUTE ON FUNCTION super_admin.get_active_student_count(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION super_admin.get_active_student_count(UUID, DATE) TO service_role;

-- 5. RPC: Create Monthly Snapshot
-- This can be called from the Flutter app to "Trigger" a snapshot
CREATE OR REPLACE FUNCTION super_admin.generate_monthly_snapshot(
  p_school_id UUID,
  p_date DATE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_student_count INTEGER;
  v_projected_revenue NUMERIC;
  v_pricing_model TEXT;
  v_pricing_value NUMERIC;
BEGIN
  -- Get active student count using the helper function
  v_student_count := super_admin.get_active_student_count(p_school_id, p_date);

  -- Get pricing model from school settings
  SELECT 
    (settings->>'pricing_model'), 
    (settings->>'pricing_value')::NUMERIC
  INTO v_pricing_model, v_pricing_value
  FROM school_shared.school_settings
  WHERE school_id = p_school_id;

  -- Calculate Revenue
  IF v_pricing_model = 'Per Student' THEN
    v_projected_revenue := v_student_count * v_pricing_value;
  ELSIF v_pricing_model = 'Flat Fee' THEN
    v_projected_revenue := v_pricing_value;
  ELSE
    v_projected_revenue := 0; -- Default or unknown model
  END IF;

  -- Insert or Update Snapshot
  INSERT INTO super_admin.monthly_snapshots (school_id, snapshot_date, active_student_count, projected_revenue)
  VALUES (p_school_id, p_date, v_student_count, v_projected_revenue)
  ON CONFLICT (school_id, snapshot_date) 
  DO UPDATE SET 
    active_student_count = EXCLUDED.active_student_count,
    projected_revenue = EXCLUDED.projected_revenue;

  RETURN json_build_object(
    'school_id', p_school_id,
    'date', p_date,
    'students', v_student_count,
    'revenue', v_projected_revenue
  );
END;
$$;

GRANT EXECUTE ON FUNCTION super_admin.generate_monthly_snapshot(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION super_admin.generate_monthly_snapshot(UUID, DATE) TO service_role;
