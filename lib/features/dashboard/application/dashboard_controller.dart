import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/school_repository.dart';
import '../domain/school_model.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository(Supabase.instance.client);
});

final schoolListProvider = FutureProvider<List<School>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getSchools();
});
