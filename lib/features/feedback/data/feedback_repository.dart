import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/feedback_model.dart';

class FeedbackRepository {
  final SupabaseClient _supabase;

  FeedbackRepository(this._supabase);

  Future<List<FeedbackItem>> getFeedback() async {
    final response = await _supabase
        .schema('super_admin')
        .from('feedback')
        .select()
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((e) => FeedbackItem.fromJson(e)).toList();
  }

  Future<void> submitFeedback(String type, String priority, String description) async {
    await _supabase.schema('super_admin').from('feedback').insert({
      'type': type,
      'priority': priority,
      'status': 'Open',
      'description': description,
      // 'reported_by' is defaulted to auth.uid() in DB, but if we need to pass it explicitly we can.
      // Assuming RLS handles the default.
    });
  }
}
