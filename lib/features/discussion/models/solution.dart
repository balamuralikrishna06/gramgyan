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
}
