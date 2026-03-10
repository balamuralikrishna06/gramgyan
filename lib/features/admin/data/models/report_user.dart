/// Data model for a person stored in the [report_users] Supabase table.
class ReportUser {
  final String id;
  final String name;
  final String email;
  final String position;
  final DateTime createdAt;

  const ReportUser({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.createdAt,
  });

  factory ReportUser.fromJson(Map<String, dynamic> json) {
    return ReportUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      position: json['position'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'position': position,
        'created_at': createdAt.toIso8601String(),
      };
}
