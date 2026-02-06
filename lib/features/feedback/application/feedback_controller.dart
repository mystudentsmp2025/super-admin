import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/feedback_repository.dart';
import '../domain/feedback_model.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(Supabase.instance.client);
});

final feedbackListProvider = FutureProvider<List<FeedbackItem>>((ref) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getFeedback();
});

class FeedbackController extends AsyncNotifier<void> {
  late final FeedbackRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(feedbackRepositoryProvider);
  }

  Future<void> submitFeedback({
    required String type,
    required String priority,
    required String description,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.submitFeedback(type, priority, description));
  }
}

final feedbackControllerProvider = AsyncNotifierProvider<FeedbackController, void>(FeedbackController.new);
