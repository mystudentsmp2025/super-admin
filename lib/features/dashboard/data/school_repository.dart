import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/school_model.dart';

class SchoolRepository {
  final SupabaseClient _supabase;

  SchoolRepository(this._supabase);

  Future<List<School>> getSchools() async {
    // Determine which schema/table to query. 
    // Assuming 'school_shared' schema and 'schools' table.
    // Note: The Supabase client by default targets the 'public' schema unless configured otherwise 
    // or if we use the .from('table') syntax which maps to the default schema.
    // To target a format 'schema.table', we might need to change how we query or use RPC if direct access isn't straightforward in the client SDK without schema configuration.
    // However, Supabase Flutter SDK supports schema selection via .schema('school_shared') or directly if exposed.
    // Let's try to query the table directly assuming the user has access.
    
    // NOTE: Supabase client usually doesn't support "schema.table" in .from() directly.
    // You typically use client.schema('school_shared').from('schools').
    
    final response = await _supabase
        .schema('school_shared')
        .from('schools')
        .select();

    final data = response as List<dynamic>;
    return data.map((e) => School.fromJson(e)).toList();
  }

  Future<int> getActiveStudentCount(String schoolId, DateTime date) async {
    final response = await _supabase.schema('super_admin').rpc('get_active_student_count', params: {
      'p_school_id': schoolId,
      'p_date': date.toIso8601String(),
    });
    return response as int;
  }
}
