import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/expense_model.dart';

class ExpenseRepository {
  final SupabaseClient _supabase;

  ExpenseRepository(this._supabase);

  Future<List<Expense>> getExpenses() async {
    final response = await _supabase
        .schema('super_admin')
        .from('expenses')
        .select()
        .order('date', ascending: false);

    final data = response as List<dynamic>;
    return data.map((e) => Expense.fromJson(e)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    try {
      if (expense.id.isEmpty) {
        await _supabase
            .schema('super_admin')
            .from('expenses')
            .insert({
              'date': expense.date.toIso8601String(),
              'category': expense.category,
              'amount': expense.amount,
              'description': expense.description,
              'transaction_type': expense.transactionType,
              'attachment_url': expense.attachmentUrl,
              'school_id': expense.schoolId,
            });
        print('DEBUG: Expense inserted successfully');
      } else {
         await _supabase
          .schema('super_admin')
          .from('expenses')
          .insert(expense.toJson());
         print('DEBUG: Expense inserted successfully (existing ID)');
      }
    } catch (e) {
      print('DEBUG: Failed to insert expense: $e');
      rethrow;
    }
  }

  Future<String?> uploadReceipt(dynamic fileBytes, String fileName) async {
    try {
      final path = 'receipts/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _supabase.storage.from('super_admin_expenses').uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return _supabase.storage.from('super_admin_expenses').getPublicUrl(path);
    } catch (e) {
      // Handle upload error (e.g., bucket not found, permission denied)
      rethrow;
    }
  }
}
