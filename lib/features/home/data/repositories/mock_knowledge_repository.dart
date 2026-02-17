import 'dart:math';

import '../../domain/models/knowledge_post.dart';
import '../../../../core/constants/app_constants.dart';

/// Mock repository simulating backend API calls.
/// Returns dummy knowledge posts with a realistic delay.
class MockKnowledgeRepository {
  // ── Mock Farmer Data ──
  static final List<Map<String, dynamic>> _mockData = [
    {
      'id': '1',
      'farmerName': 'Ravi Kumar',
      'location': 'Salem, TN',
      'crop': 'Tomato',
      'transcript': 'After heavy rain, the tomato leaves turned yellow. I used neem spray and it recovered in a week.',
      'audioUrl': 'mock_audio_1.mp3',
      'karma': 24,
      'verified': true,
      'latitude': 11.6643,
      'longitude': 78.1460,
      'category': 'Crops',
    },
    {
      'id': '2',
      'farmerName': 'Lakshmi Devi',
      'location': 'Madurai, TN',
      'crop': 'Paddy',
      'transcript': 'Heavy rain prediction for next week. I am planning to harvest paddy early to avoid damage.',
      'audioUrl': 'mock_audio_2.mp3',
      'karma': 42,
      'verified': true,
      'latitude': 9.9252,
      'longitude': 78.1198,
      'category': 'Weather',
    },
    {
      'id': '3',
      'farmerName': 'Suresh Patel',
      'location': 'Coimbatore, TN',
      'crop': 'Wheat',
      'transcript': 'My wheat crop has brown spots on the leaves. Neighbour suggested fungicide but I want an organic solution.',
      'audioUrl': 'mock_audio_3.mp3',
      'karma': 18,
      'verified': false,
      'latitude': 11.0168,
      'longitude': 76.9558,
      'category': 'Crops',
    },
    {
      'id': '4',
      'farmerName': 'Anitha Raj',
      'location': 'Thanjavur, TN',
      'crop': 'Sugarcane',
      'transcript': 'Started intercropping with legumes in my sugarcane field. Soil fertility improved noticeably.',
      'audioUrl': 'mock_audio_4.mp3',
      'karma': 56,
      'verified': true,
      'latitude': 10.7870,
      'longitude': 79.1378,
      'category': 'Soil',
    },
    {
      'id': '5',
      'farmerName': 'Murugan S',
      'location': 'Erode, TN',
      'crop': 'Turmeric',
      'transcript': 'The soil pH in my field is too acidic. I added lime and saw improvement in plant growth after two weeks.',
      'audioUrl': 'mock_audio_5.mp3',
      'karma': 31,
      'verified': false,
      'latitude': 11.3410,
      'longitude': 77.7172,
      'category': 'Soil',
    },
    {
      'id': '6',
      'farmerName': 'Kavitha M',
      'location': 'Tirunelveli, TN',
      'crop': 'Goat',
      'transcript': 'My goat stopped eating after the vaccination. The vet said it is normal and will recover in 2-3 days.',
      'audioUrl': 'mock_audio_6.mp3',
      'karma': 15,
      'verified': true,
      'latitude': 8.7139,
      'longitude': 77.7567,
      'category': 'Livestock',
    },
    {
      'id': '7',
      'farmerName': 'Rajesh V',
      'location': 'Trichy, TN',
      'crop': 'Maize',
      'transcript': 'Maize borers destroyed half my field. Using bio-control agents like Trichogramma helped reduce damage.',
      'audioUrl': 'mock_audio_7.mp3',
      'karma': 38,
      'verified': true,
      'latitude': 10.7905,
      'longitude': 78.7047,
      'category': 'Crops',
    },
    {
      'id': '8',
      'farmerName': 'Priya N',
      'location': 'Vellore, TN',
      'crop': 'Groundnut',
      'transcript': 'The bore well water level dropped significantly this summer. Planning to build a rainwater harvesting tank.',
      'audioUrl': 'mock_audio_8.mp3',
      'karma': 22,
      'verified': false,
      'latitude': 12.9165,
      'longitude': 79.1325,
      'category': 'Weather',
    },
    {
      'id': '9',
      'farmerName': 'Senthil K',
      'location': 'Dindigul, TN',
      'crop': 'Cotton',
      'transcript': 'Pink bollworm infestation in cotton. Pheromone traps reduced the pest population by 60% in my field.',
      'audioUrl': 'mock_audio_9.mp3',
      'karma': 47,
      'verified': true,
      'latitude': 10.3624,
      'longitude': 77.9695,
      'category': 'Crops',
    },
    {
      'id': '10',
      'farmerName': 'Devi P',
      'location': 'Kanchipuram, TN',
      'crop': 'Cow',
      'transcript': 'My cow\'s milk yield dropped after changing feed. Mixing jaggery water with regular feed helped recover production.',
      'audioUrl': 'mock_audio_10.mp3',
      'karma': 29,
      'verified': false,
      'latitude': 12.8342,
      'longitude': 79.7036,
      'category': 'Livestock',
    },
  ];

  /// Fetch all posts with simulated network delay.
  Future<List<KnowledgePost>> fetchPosts() async {
    await Future.delayed(AppConstants.mockApiDelay);
    return _mockData.map((json) => KnowledgePost.fromJson(json)).toList();
  }

  /// Fetch posts filtered by category.
  Future<List<KnowledgePost>> fetchPostsByCategory(String category) async {
    await Future.delayed(AppConstants.mockApiDelay);
    if (category == 'All') {
      return _mockData.map((json) => KnowledgePost.fromJson(json)).toList();
    }
    return _mockData
        .where((json) => json['category'] == category)
        .map((json) => KnowledgePost.fromJson(json))
        .toList();
  }

  /// Simulate submitting a new knowledge post.
  Future<KnowledgePost> submitPost({
    required String transcript,
    required String crop,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final random = Random();
    return KnowledgePost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      farmerName: 'You',
      location: 'Your Village',
      crop: crop,
      transcript: transcript,
      audioUrl: 'mock_new_audio.mp3',
      karma: 0,
      verified: false,
      latitude: 11.0 + random.nextDouble(),
      longitude: 78.0 + random.nextDouble(),
      category: 'Crops',
      createdAt: DateTime.now(),
    );
  }
}
