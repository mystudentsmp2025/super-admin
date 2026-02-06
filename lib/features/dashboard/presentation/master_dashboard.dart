import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../auth/application/auth_controller.dart';
import '../application/dashboard_controller.dart';
import '../domain/school_model.dart';
import '../../expenses/application/expense_controller.dart';
import '../../expenses/domain/expense_model.dart';
import '../../billing/application/billing_controller.dart';

class MasterDashboard extends ConsumerWidget {
  const MasterDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final schoolsAsync = ref.watch(schoolListProvider);
    final expensesAsync = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PRISM MATRIX',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Log Expense',
            onPressed: () {
               _showExpenseDialog(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            tooltip: 'Feedback Hub',
            onPressed: () {
              context.go('/dashboard/feedback');
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards Placeholder
            Consumer(
              builder: (context, ref, child) {
                 final expenses = expensesAsync.asData?.value ?? [];
                 final totalExpenses = expenses.fold(0.0, (sum, e) {
                   if (e.transactionType == 'Credit') {
                     return sum - e.amount;
                   } else {
                     return sum + e.amount;
                   }
                 });
                 // Note: Revenue requires aggregating snapshots. For now, referencing placeholder or injected value.
                 // In a real app we'd need a provider for "Total Revenue".
                 final revenueAsync = ref.watch(totalProjectedRevenueProvider);
                 final totalRevenue = revenueAsync.asData?.value ?? 0.0;
                 final netProfit = totalRevenue - totalExpenses;

                 return Row(
                  children: [
                    _buildKpiCard('Total Schools', schoolsAsync.asData?.value.length.toString() ?? '...'),
                    const SizedBox(width: 16),
                    _buildKpiCard('Gross Revenue', '₹${totalRevenue.toStringAsFixed(2)}'),
                    const SizedBox(width: 16),
                    _buildKpiCard('Unadjusted Expenses', '₹${totalExpenses.toStringAsFixed(2)}'),
                    const SizedBox(width: 16),
                    _buildKpiCard('Net Profit', '₹${netProfit.toStringAsFixed(2)}'),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),
            
            Text(
              'Client Portfolio',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: schoolsAsync.when(
                data: (schools) => GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: schools.length,
                  itemBuilder: (context, index) {
                    final school = schools[index];
                    return _SchoolCard(school: school);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, WidgetRef ref) {
    // Ensure you import:
    // import 'package:file_picker/file_picker.dart';
    // import 'package:intl/intl.dart';
    
    // Note: Since method is inside the class, manual imports might be needed at top of file.
    // I will add imports in a separate edit if needed, or assume they are added.
    // Adding imports here is tricky without viewing top.
    
    // Controllers & State
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    
    String category = 'Common';
    String? selectedSchoolId;
    String transactionType = 'Debit';
    DateTime selectedDate = DateTime.now();
    
    // File State
    String? selectedFileName;
    dynamic selectedFileBytes; // Uint8List

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Expense'),
              content: SizedBox(
                width: 500, // wider dialog
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       // 1. Date Field
                      InkWell(
                        onTap: () async {
                           final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => selectedDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat.yMMMd().format(selectedDate)),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Transaction Type (Credit/Debit)
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Debit'),
                              value: 'Debit',
                              groupValue: transactionType,
                              onChanged: (v) => setState(() => transactionType = v!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Credit'),
                              value: 'Credit',
                              groupValue: transactionType,
                              onChanged: (v) => setState(() => transactionType = v!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      
                      // 3. Category & School
                      DropdownButtonFormField<String>(
                        value: category,
                        items: ['Common', 'School-Specific'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => category = v!),
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      if (category == 'School-Specific')
                        Consumer(
                          builder: (context, ref, child) {
                            final schoolsAsync = ref.watch(schoolListProvider);
                            return schoolsAsync.when(
                              data: (schools) => DropdownButtonFormField<String>(
                                value: selectedSchoolId,
                                items: schools.map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) {
                                   setState(() => selectedSchoolId = v);
                                },
                                decoration: const InputDecoration(labelText: 'Select School'),
                                isExpanded: true,
                              ),
                              loading: () => const Center(child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )),
                              error: (e, s) => Text('Error loading schools: $e', style: const TextStyle(color: Colors.red)),
                            );
                          }
                        ),
                      
                      const SizedBox(height: 16),
                      // 4. Amount & Description
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      
                      const SizedBox(height: 16),
                      // 5. File Upload
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
                                withData: true, // Needed for web to get bytes
                              );
                              
                              if (result != null) {
                                setState(() {
                                  selectedFileName = result.files.single.name;
                                  selectedFileBytes = result.files.single.bytes;
                                });
                              }
                            }, 
                            // Note: Logic placeholder, will implement after adding import
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Attach Receipt'),
                          ),
                          const SizedBox(width: 12),
                          if (selectedFileName != null)
                            Expanded(child: Text(selectedFileName!, overflow: TextOverflow.ellipsis))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (amountController.text.isEmpty) return;
                    
                    await ref.read(expenseControllerProvider.notifier).addExpense(
                      date: selectedDate,
                      category: category,
                      amount: double.tryParse(amountController.text) ?? 0.0,
                      description: descriptionController.text,
                      schoolId: selectedSchoolId,
                      transactionType: transactionType,
                      fileBytes: selectedFileBytes,
                      fileName: selectedFileName,
                    );
                    
                    if (context.mounted) Navigator.pop(context);
                    ref.invalidate(expenseListProvider);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final School school;

  const _SchoolCard({required this.school});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          context.go('/dashboard/school/${school.id}', extra: school);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: school.logoUrl != null ? NetworkImage(school.logoUrl!) : null,
                    backgroundColor: Colors.grey[800],
                    child: school.logoUrl == null ? const Icon(Icons.school) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      school.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text('ID: ${school.id.substring(0, 8)}...', style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
