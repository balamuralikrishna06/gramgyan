/// Model representing a solution / reply to a farmer's question.
class Solution {
  final String id;
  final String questionId;
  final String farmerName;
  final String transcript;
  final String audioUrl;
  final int karma;
  final bool isVerified;
  final DateTime createdAt;

  const Solution({
    required this.id,
    required this.questionId,
    required this.farmerName,
    required this.transcript,
    required this.audioUrl,
    required this.karma,
    required this.isVerified,
    required this.createdAt,
  });

  Solution copyWith({
    String? id,
    String? questionId,
    String? farmerName,
    String? transcript,
    String? audioUrl,
    int? karma,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return Solution(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      farmerName: farmerName ?? this.farmerName,
      transcript: transcript ?? this.transcript,
      audioUrl: audioUrl ?? this.audioUrl,
      karma: karma ?? this.karma,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Solution.fromJson(Map<String, dynamic> json) {
    return Solution(
      id: json['id'] as String,
      questionId: json['question_id'] as String? ?? json['questionId'] as String? ?? '',
      farmerName: json['farmer_name'] as String? ?? json['farmerName'] as String? ?? 'Farmer',
      transcript: json['answer_text'] as String? ?? json['transcript'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? json['audioUrl'] as String? ?? '',
      karma: json['karma'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'farmer_name': farmerName,
      'answer_text': transcript,
      'audio_url': audioUrl,
      'karma': karma,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
