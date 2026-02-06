import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/expense_repository.dart';
import '../domain/expense_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(Supabase.instance.client);
});

final expenseListProvider = FutureProvider<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses();
});

class ExpenseController extends AsyncNotifier<void> {
  late final ExpenseRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(expenseRepositoryProvider);
  }

  Future<void> addExpense({
    required DateTime date,
    required String category,
    required double amount,
    String? description,
    String? schoolId,
    String transactionType = 'Debit',
    dynamic fileBytes, // Uint8List
    String? fileName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      String? attachmentUrl;
      if (fileBytes != null && fileName != null) {
        attachmentUrl = await _repository.uploadReceipt(fileBytes, fileName);
      }

      final expense = Expense(
        id: '', // Supabase will generate
        date: date,
        category: category,
        amount: amount,
        description: description,
        schoolId: schoolId,
        transactionType: transactionType,
        attachmentUrl: attachmentUrl,
        createdAt: DateTime.now(),
      );
      
      await _repository.addExpense(expense);
    });
  }
}

final expenseControllerProvider = AsyncNotifierProvider<ExpenseController, void>(ExpenseController.new);
