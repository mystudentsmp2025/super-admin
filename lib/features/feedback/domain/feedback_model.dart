class FeedbackItem {
  final String id;
  final String type; // Bug, Feature, Feedback
  final String priority; // Low, Medium, High, Critical
  final String status; // Open, In Progress, Resolved, Closed
  final String description;
  final String reportedBy;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.status,
    required this.description,
    required this.reportedBy,
    required this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] as String,
      type: json['type'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      reportedBy: json['reported_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'priority': priority,
      'status': status,
      'description': description,
      'reported_by': reportedBy,
    };
  }
}
