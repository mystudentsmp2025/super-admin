import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/feedback_controller.dart';
import '../domain/feedback_model.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends ConsumerWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(feedbackListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback & Fine-Tuning Hub', style: GoogleFonts.inter()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFeedbackDialog(context, ref),
        label: const Text('New Issue/Idea'),
        icon: const Icon(Icons.add_comment),
      ),
      body: feedbackAsync.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No feedback recorded yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                 color: Colors.white.withOpacity(0.05),
                 child: ListTile(
                   leading: _buildTypeIcon(item.type),
                   title: Text(item.description),
                   subtitle: Text('Status: ${item.status} • Priority: ${item.priority}\nReported: ${DateFormat.yMMMd().format(item.createdAt)}'),
                   isThreeLine: true,
                 ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    switch (type) {
      case 'Bug':
        return const Icon(Icons.bug_report, color: Colors.redAccent);
      case 'Feature':
        return const Icon(Icons.lightbulb, color: Colors.amberAccent);
      default:
        return const Icon(Icons.feedback, color: Colors.blueAccent);
    }
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
    String type = 'Feedback';
    String priority = 'Medium';
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Submit Feedback'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   DropdownButtonFormField<String>(
                    value: type,
                    items: ['Bug', 'Feature', 'Feedback'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => type = v!),
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                   DropdownButtonFormField<String>(
                    value: priority,
                    items: ['Low', 'Medium', 'High', 'Critical'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => priority = v!),
                    decoration: const InputDecoration(labelText: 'Priority'),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                 ElevatedButton(
                  onPressed: () async {
                    if (descriptionController.text.isEmpty) return;
                    
                    await ref.read(feedbackControllerProvider.notifier).submitFeedback(
                      type: type,
                      priority: priority,
                      description: descriptionController.text,
                    );
                    
                    if (context.mounted) Navigator.pop(context);
                    ref.invalidate(feedbackListProvider);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
