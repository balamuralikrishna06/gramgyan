/// Model representing a knowledge post from a farmer.
class KnowledgePost {
  final String id;
  final String farmerName;
  final String location;
  final String crop;
  final String transcript;
  final String audioUrl;
  final int karma;
  final bool verified;
  final double latitude;
  final double longitude;
  final String category;
  final DateTime createdAt;

  const KnowledgePost({
    required this.id,
    required this.farmerName,
    required this.location,
    required this.crop,
    required this.transcript,
    required this.audioUrl,
    required this.karma,
    required this.verified,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.createdAt,
  });

  /// Create a copy with modified fields (for karma update, etc.)
  KnowledgePost copyWith({
    String? id,
    String? farmerName,
    String? location,
    String? crop,
    String? transcript,
    String? audioUrl,
    int? karma,
    bool? verified,
    double? latitude,
    double? longitude,
    String? category,
    DateTime? createdAt,
  }) {
    return KnowledgePost(
      id: id ?? this.id,
      farmerName: farmerName ?? this.farmerName,
      location: location ?? this.location,
      crop: crop ?? this.crop,
      transcript: transcript ?? this.transcript,
      audioUrl: audioUrl ?? this.audioUrl,
      karma: karma ?? this.karma,
      verified: verified ?? this.verified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Parse from JSON map (for mock data and Supabase).
  factory KnowledgePost.fromJson(Map<String, dynamic> json) {
    return KnowledgePost(
      id: json['id'] as String,
      farmerName: (json['farmer_name'] ?? json['farmerName'] ?? 'Unknown Farmer') as String,
      location: (json['location'] ?? 'Unknown Location') as String,
      crop: (json['crop'] ?? 'Other') as String,
      transcript: (json['original_text'] ?? json['transcript'] ?? '') as String,
      audioUrl: (json['audio_url'] ?? json['audioUrl'] ?? '') as String,
      karma: (json['karma'] as num?)?.toInt() ?? 0,
      verified: (json['is_verified'] ?? json['verified'] ?? false) as bool,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      category: (json['category'] ?? 'Crops') as String,
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
      'farmerName': farmerName,
      'location': location,
      'crop': crop,
      'transcript': transcript,
      'audioUrl': audioUrl,
      'karma': karma,
      'verified': verified,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
