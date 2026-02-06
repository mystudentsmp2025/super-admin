class Expense {
  final String id;
  final DateTime date;
  final String category; // 'Common' or 'School-Specific'
  final double amount;
  final String? description;
  final String transactionType; // 'Credit' or 'Debit'
  final String? attachmentUrl;
  final String? schoolId;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.description,
    this.transactionType = 'Debit',
    this.attachmentUrl,
    this.schoolId,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      transactionType: json['transaction_type'] as String? ?? 'Debit',
      attachmentUrl: json['attachment_url'] as String?,
      schoolId: json['school_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
      'transaction_type': transactionType,
      'attachment_url': attachmentUrl,
      'school_id': schoolId,
    };
  }
}
