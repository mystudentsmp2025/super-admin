-- RPC: Get Latest Snapshot for All Schools
-- Returns the most recent snapshot for each school to calculate current total revenue.

CREATE OR REPLACE FUNCTION super_admin.get_latest_snapshots_for_all_schools()
RETURNS SETOF super_admin.monthly_snapshots
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT ON (school_id) *
  FROM super_admin.monthly_snapshots
  ORDER BY school_id, snapshot_date DESC;
$$;

GRANT EXECUTE ON FUNCTION super_admin.get_latest_snapshots_for_all_schools() TO authenticated;
GRANT EXECUTE ON FUNCTION super_admin.get_latest_snapshots_for_all_schools() TO service_role;
