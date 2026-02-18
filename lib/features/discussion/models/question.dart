/// Status of a farmer question in the discussion system.
enum QuestionStatus {
  open,
  solved,
  verified;

  String get label {
    switch (this) {
      case QuestionStatus.open:
        return 'Needs Solution';
      case QuestionStatus.solved:
        return 'Solved';
      case QuestionStatus.verified:
        return 'Verified';
    }
  }

  String get emoji {
    switch (this) {
      case QuestionStatus.open:
        return '🔴';
      case QuestionStatus.solved:
        return '🟢';
      case QuestionStatus.verified:
        return '⭐';
    }
  }

  static QuestionStatus fromString(String value) {
    switch (value) {
      case 'solved':
        return QuestionStatus.solved;
      case 'verified':
        return QuestionStatus.verified;
      default:
        return QuestionStatus.open;
    }
  }
}

/// Model representing a farmer's question / problem in the discussion system.
class Question {
  final String id;
  final String authorId; // Added authorId
  final String farmerName;
  final String location;
  final String crop;
  final String category;
  final String transcript;
  final String audioUrl;
  final QuestionStatus status;
  final int replyCount;
  final int karma;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.authorId,
    required this.farmerName,
    required this.location,
    required this.crop,
    required this.category,
    required this.transcript,
    required this.audioUrl,
    required this.status,
    required this.replyCount,
    required this.karma,
    required this.createdAt,
  });

  Question copyWith({
    String? id,
    String? authorId,
    String? farmerName,
    String? location,
    String? crop,
    String? category,
    String? transcript,
    String? audioUrl,
    QuestionStatus? status,
    int? replyCount,
    int? karma,
    DateTime? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      farmerName: farmerName ?? this.farmerName,
      location: location ?? this.location,
      crop: crop ?? this.crop,
      category: category ?? this.category,
      transcript: transcript ?? this.transcript,
      audioUrl: audioUrl ?? this.audioUrl,
      status: status ?? this.status,
      replyCount: replyCount ?? this.replyCount,
      karma: karma ?? this.karma,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      authorId: json['user_id'] as String? ?? json['authorId'] as String? ?? 'unknown',
      farmerName: json['farmer_name'] as String? ?? json['farmerName'] as String? ?? 'Farmer',
      location: json['location'] as String? ?? 'Unknown',
      crop: json['crop'] as String? ?? 'General',
      category: json['category'] as String? ?? 'Crops',
      transcript: json['original_text'] as String? ?? json['transcript'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? json['audioUrl'] as String? ?? '',
      status: QuestionStatus.fromString(json['status'] as String? ?? 'open'),
      replyCount: json['reply_count'] as int? ?? json['replyCount'] as int? ?? 0,
      karma: json['karma'] as int? ?? 0,
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
      'user_id': authorId,
      'farmer_name': farmerName,
      'location': location,
      'crop': crop,
      'category': category,
      'original_text': transcript,
      'audio_url': audioUrl,
      'status': status.name,
      'reply_count': replyCount,
      'karma': karma,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
