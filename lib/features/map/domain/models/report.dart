class Report {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String crop;
  final String category;
  final String transcript;
  final String? translatedTranscript;
  final String? englishText;
  final String type; // 'question' or 'knowledge'
  final String status; // 'open', 'solved', 'verified'
  final String? originalLanguage;
  final String? audioUrl;
  final bool aiGenerated;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.crop,
    required this.category,
    required this.transcript,
    this.translatedTranscript,
    this.originalLanguage,
    this.audioUrl,
    required this.aiGenerated,
    required this.createdAt,
    this.englishText,
    this.type = 'question',
    this.status = 'open',
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      crop: json['crop'] as String? ?? 'Unknown Crop',
      category: json['category'] as String? ?? 'General',
      transcript: json['original_text'] as String? ?? '', // Mapped from DB 'original_text'
      translatedTranscript: json['translated_transcript'] as String?,
      originalLanguage: json['language'] as String?, // Mapped from DB 'language'
      audioUrl: json['audio_url'] as String?,
      aiGenerated: json['ai_generated'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      englishText: json['english_text'] as String?,
      type: json['type'] as String? ?? 'question',
      status: json['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'crop': crop,
      'category': category,
      'original_text': transcript, // Mapped to DB 'original_text'
      'translated_transcript': translatedTranscript,
      'language': originalLanguage, // Mapped to DB 'language'
      'audio_url': audioUrl,
      'ai_generated': aiGenerated,
      'created_at': createdAt.toIso8601String(),
      'english_text': englishText,
      'type': type,
      'status': status,
    };
  }
}



