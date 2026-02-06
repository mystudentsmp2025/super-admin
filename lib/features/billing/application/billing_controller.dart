import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/billing_repository.dart';
import '../domain/snapshot_model.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(Supabase.instance.client);
});

final schoolSnapshotsProvider = FutureProvider.family<List<MonthlySnapshot>, String>((ref, schoolId) async {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getSnapshots(schoolId);
});

final totalProjectedRevenueProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(billingRepositoryProvider);
  final snapshots = await repo.getLatestSnapshotsForAllSchools();
  return snapshots.fold<double>(0.0, (sum, snapshot) => sum + snapshot.projectedRevenue);
});

class SnapshotController extends AsyncNotifier<void> {
  late final BillingRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(billingRepositoryProvider);
  }

  Future<void> generateSnapshot(String schoolId, DateTime date) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.generateSnapshot(schoolId, date));
  }
}

final snapshotControllerProvider = AsyncNotifierProvider<SnapshotController, void>(SnapshotController.new);
