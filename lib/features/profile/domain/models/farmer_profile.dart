/// Model representing a farmer's profile.
class FarmerProfile {
  final String id;
  final String name;
  final String city;
  final String state;
  final int karma;
  final int totalPosts;
  final int solutionsVerified;
  final String language;
  final String avatarUrl;
  final List<String> badges;

  const FarmerProfile({
    required this.id,
    required this.name,
    required this.city,
    this.state = '',
    required this.karma,
    required this.totalPosts,
    this.solutionsVerified = 0,
    required this.language,
    this.avatarUrl = '',
    this.badges = const [],
  });

  FarmerProfile copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    int? karma,
    int? totalPosts,
    int? solutionsVerified,
    String? language,
    String? avatarUrl,
    List<String>? badges,
  }) {
    return FarmerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      karma: karma ?? this.karma,
      totalPosts: totalPosts ?? this.totalPosts,
      solutionsVerified: solutionsVerified ?? this.solutionsVerified,
      language: language ?? this.language,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      badges: badges ?? this.badges,
    );
  }
}
