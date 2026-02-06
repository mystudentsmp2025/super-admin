class School {
  final String id;
  final String name;
  final String? logoUrl;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime enrollmentDate;
  // Add other fields as necessary from school_shared.schools

  School({
    required this.id,
    required this.name,
    this.logoUrl,
    this.contactEmail,
    this.contactPhone,
    required this.enrollmentDate,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      contactEmail: json['email'] as String?,
      contactPhone: json['phone'] as String?,
      enrollmentDate: DateTime.parse(json['created_at'] as String), // Assuming created_at is enrollment
    );
  }
}
