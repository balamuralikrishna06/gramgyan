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

  /// Parse from JSON map (for mock data).
  factory KnowledgePost.fromJson(Map<String, dynamic> json) {
    return KnowledgePost(
      id: json['id'] as String,
      farmerName: json['farmerName'] as String,
      location: json['location'] as String,
      crop: json['crop'] as String,
      transcript: json['transcript'] as String,
      audioUrl: json['audioUrl'] as String,
      karma: json['karma'] as int,
      verified: json['verified'] as bool,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String? ?? 'Crops',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
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
