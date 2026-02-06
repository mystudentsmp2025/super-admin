import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/snapshot_model.dart';

class BillingRepository {
  final SupabaseClient _supabase;

  BillingRepository(this._supabase);

  Future<List<MonthlySnapshot>> getSnapshots(String schoolId) async {
    final response = await _supabase
        .schema('super_admin')
        .from('monthly_snapshots')
        .select()
        .eq('school_id', schoolId)
        .order('snapshot_date', ascending: false);

    final data = response as List<dynamic>;
    return data.map((e) => MonthlySnapshot.fromJson(e)).toList();
  }

  Future<void> generateSnapshot(String schoolId, DateTime date) async {
    await _supabase.schema('super_admin').rpc('generate_monthly_snapshot', params: {
      'p_school_id': schoolId,
      'p_date': date.toIso8601String(),
    });
  }

  Future<List<MonthlySnapshot>> getLatestSnapshotsForAllSchools() async {
    final response = await _supabase.schema('super_admin').rpc('get_latest_snapshots_for_all_schools');
    final data = response as List<dynamic>;
    return data.map((e) => MonthlySnapshot.fromJson(e)).toList();
  }
}
