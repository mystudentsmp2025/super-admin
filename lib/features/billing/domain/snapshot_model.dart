class MonthlySnapshot {
  final String id;
  final String schoolId;
  final DateTime snapshotDate;
  final int activeStudentCount;
  final double projectedRevenue;
  final DateTime createdAt;

  MonthlySnapshot({
    required this.id,
    required this.schoolId,
    required this.snapshotDate,
    required this.activeStudentCount,
    required this.projectedRevenue,
    required this.createdAt,
  });

  factory MonthlySnapshot.fromJson(Map<String, dynamic> json) {
    return MonthlySnapshot(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      snapshotDate: DateTime.parse(json['snapshot_date'] as String),
      activeStudentCount: json['active_student_count'] as int,
      projectedRevenue: (json['projected_revenue'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
