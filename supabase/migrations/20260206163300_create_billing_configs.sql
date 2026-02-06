-- 1. Create Billing Configs Table in super_admin schema
CREATE TABLE IF NOT EXISTS super_admin.school_billing_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES school_shared.schools(id) ON DELETE CASCADE,
  pricing_model TEXT NOT NULL DEFAULT 'Per Student' CHECK (pricing_model IN ('Per Student', 'Flat Fee')),
  pricing_value NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id)
);

-- Enable RLS
ALTER TABLE super_admin.school_billing_configs ENABLE ROW LEVEL SECURITY;

-- Policies (Simplified for now, similar to other tables)
CREATE POLICY "Enable full access for authenticated users"
ON super_admin.school_billing_configs FOR ALL
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Grant permissions
GRANT ALL ON TABLE super_admin.school_billing_configs TO authenticated;
GRANT ALL ON TABLE super_admin.school_billing_configs TO service_role;

-- 2. Update RPC to use this new table
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

  -- Get pricing model from super_admin.school_billing_configs
  SELECT pricing_model, pricing_value
  INTO v_pricing_model, v_pricing_value
  FROM super_admin.school_billing_configs
  WHERE school_id = p_school_id;

  -- Default fallback if no config exists for this school
  IF v_pricing_model IS NULL THEN
     v_pricing_model := 'Per Student';
     v_pricing_value := 100.00;
  END IF;

  -- Calculate Revenue
  IF v_pricing_model = 'Per Student' THEN
    v_projected_revenue := v_student_count * v_pricing_value;
  ELSIF v_pricing_model = 'Flat Fee' THEN
    v_projected_revenue := v_pricing_value;
  ELSE
    v_projected_revenue := 0; 
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
