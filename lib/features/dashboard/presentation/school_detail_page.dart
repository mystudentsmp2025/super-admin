import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/school_repository.dart';
import '../domain/school_model.dart';
import '../application/dashboard_controller.dart';
import '../../billing/application/billing_controller.dart';

// Provider for active student count
final activeStudentCountProvider = FutureProvider.family<int, ({String schoolId, DateTime date})>((ref, params) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getActiveStudentCount(params.schoolId, params.date);
});

class SchoolDetailPage extends ConsumerStatefulWidget {
  final School school;

  const SchoolDetailPage({super.key, required this.school});

  @override
  ConsumerState<SchoolDetailPage> createState() => _SchoolDetailPageState();
}

class _SchoolDetailPageState extends ConsumerState<SchoolDetailPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final activeCountAsync = ref.watch(activeStudentCountProvider((
      schoolId: widget.school.id,
      date: _selectedDate,
    )));

    // Trial Logic
    final daysSinceEnrollment = DateTime.now().difference(widget.school.enrollmentDate).inDays;
    final trialDaysTotal = 150;
    final trialDaysRemaining = trialDaysTotal - daysSinceEnrollment;
    final isTrialActive = trialDaysRemaining > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.school.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              children: [
                if (widget.school.logoUrl != null) 
                  CircleAvatar(radius: 40, backgroundImage: NetworkImage(widget.school.logoUrl!)),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.school.name,
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text('Contact: ${widget.school.contactEmail ?? 'N/A'}'),
                  ],
                ),
                const Spacer(),
                // Trial Tracker Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isTrialActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    border: Border.all(color: isTrialActive ? Colors.green : Colors.red),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isTrialActive ? 'TRIAL ACTIVE' : 'TRIAL EXPIRED',
                        style: TextStyle(
                          color: isTrialActive ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTrialActive ? '$trialDaysRemaining Days Remaining' : 'Expired on ${DateFormat.yMMMd().format(widget.school.enrollmentDate.add(Duration(days: 150)))}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Dynamic Strength Engine
            Text(
              'Dynamic Strength Engine',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student Count As Of:',
                        style: GoogleFonts.inter(fontSize: 18),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat.yMMMd().format(_selectedDate),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 48),
                  activeCountAsync.when(
                    data: (count) => Column(
                      children: [
                        Text(
                          '$count',
                          style: GoogleFonts.outfit(fontSize: 64, fontWeight: FontWeight.bold),
                        ),
                        const Text('Active Students', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            
            // Billing Ledger
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'Billing Ledger',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      // Trigger Snapshot for today
                      final date = DateTime.now();
                      await ref.read(snapshotControllerProvider.notifier).generateSnapshot(widget.school.id, date);
                      
                      // Check for errors in the controller state
                      final state = ref.read(snapshotControllerProvider);
                      if (state.hasError) {
                        throw state.error!;
                      }

                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Snapshot generated successfully!'), backgroundColor: Colors.green),
                      );
                      
                      ref.invalidate(schoolSnapshotsProvider(widget.school.id)); // Refresh list
                      // Invalidate global revenue so Dashboard updates
                      ref.invalidate(totalProjectedRevenueProvider);
                      
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Failed to generate snapshot: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Trigger Snapshot Now'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final snapshotsAsync = ref.watch(schoolSnapshotsProvider(widget.school.id));
                return snapshotsAsync.when(
                  data: (snapshots) {
                    if (snapshots.isEmpty) return const Text('No snapshots recorded.');
                    
                    return Container(
                       decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Date')),
                             DataColumn(label: Text('Active Students')),
                             DataColumn(label: Text('Projected Revenue')),
                             DataColumn(label: Text('Generated At')),
                          ],
                          rows: snapshots.map((s) {
                            return DataRow(cells: [
                              DataCell(Text(DateFormat.yMMMd().format(s.snapshotDate))),
                              DataCell(Text(s.activeStudentCount.toString())),
                              DataCell(Text('₹${s.projectedRevenue.toStringAsFixed(2)}')),
                              DataCell(Text(DateFormat('MM/dd/yyyy HH:mm').format(s.createdAt))),
                            ]);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error loading ledger: $err'),
                );
              },
            ),

            const SizedBox(height: 48),
            // Placeholders for Feedback
          ],
        ),
      ),
    );
  }
}
