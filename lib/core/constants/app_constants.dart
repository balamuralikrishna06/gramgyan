// No external imports needed — all secrets live on the Render backend.

/// App-wide constants for GramGyan.
class AppConstants {
  AppConstants._();

  // ── App Identity ──
  static const String appName = 'GramGyan';
  static const String appTagline = 'Voice of the Farmer';

  // ── Timing ──
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration mockApiDelay = Duration(milliseconds: 1500);
  static const Duration snackBarDuration = Duration(seconds: 2);

  // ── Hive Boxes ──
  static const String settingsBox = 'settings';
  static const String postsBox = 'posts';
  static const String profileBox = 'profile';

  // ── Hive Keys ──
  static const String languageKey = 'selected_language';
  static const String darkModeKey = 'dark_mode';
  static const String onboardedKey = 'onboarded';
  static const String profileCompletedKey = 'profile_completed';

  // ── Feed Categories ──
  static const List<String> categories = [
    'All',
    'Crops',
    'Livestock',
    'Weather',
    'Soil',
  ];

  // ── Discussion Status Tabs ──
  static const List<String> discussionTabs = [
    'All',
    'Questions',
    'Solved',
    'Verified',
  ];

  // ── Unified Filter Chips (for home screen) ──
  static const List<String> feedFilters = [
    'All',
    'Questions',
    'Solved',
    'Verified',
  ];

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'ta', 'name': 'தமிழ்', 'english': 'Tamil', 'icon': '🇮🇳'},
    {'code': 'hi', 'name': 'हिन्दी', 'english': 'Hindi', 'icon': '🇮🇳'},
    {'code': 'te', 'name': 'తెలుగు', 'english': 'Telugu', 'icon': '🇮🇳'},
    {'code': 'pa', 'name': 'ਪੰਜਾਬੀ', 'english': 'Punjabi', 'icon': '🇮🇳'},
    {'code': 'mr', 'name': 'मराठी', 'english': 'Marathi', 'icon': '🇮🇳'},
    {'code': 'or', 'name': 'ଓଡ଼ିଆ', 'english': 'Odia', 'icon': '🇮🇳'},
    {'code': 'bn', 'name': 'বাংলা', 'english': 'Bengali', 'icon': '🇮🇳'},
    {'code': 'gu', 'name': 'ગુજરાતી', 'english': 'Gujarati', 'icon': '🇮🇳'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ', 'english': 'Kannada', 'icon': '🇮🇳'},
    {'code': 'ml', 'name': 'മലയാളം', 'english': 'Malayalam', 'icon': '🇮🇳'},
    {'code': 'en', 'name': 'English', 'english': 'English', 'icon': '🌐'},
  ];

  // ── Indian States (for profile completion) ──
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Bihar',
    'Gujarat',
    'Haryana',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
  ];

  // ── Crop Types ──
  static const List<String> cropTypes = [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Tomato',
    'Potato',
    'Onion',
    'Soybean',
    'Groundnut',
    'Millet',
    'Other',
  ];

  // ── Mock Transcripts ──
  static const List<String> mockTranscripts = [
    'After heavy rain, the tomato leaves turned yellow. I used neem spray and it recovered in a week.',
    'My wheat crop has brown spots on the leaves. Neighbour suggested using fungicide but I want organic solution.',
    'The soil pH in my field is too acidic. I added lime and saw improvement in plant growth after two weeks.',
    'My goat stopped eating after the vaccination. The vet said it is normal and will recover in 2-3 days.',
    'Heavy rain prediction for next week. I am planning to harvest paddy early to avoid damage.',
    'Maize borers destroyed half my field. Using bio-control agents like Trichogramma helped reduce damage.',
    'The bore well water level dropped significantly this summer. Planning to build a rainwater harvesting tank.',
    'Started intercropping with legumes in my sugarcane field. Soil fertility improved noticeably.',
  ];

  // ── Profile Badges ──
  static const List<Map<String, String>> badgeDefinitions = [
    {'id': 'top_contributor', 'label': 'Top Contributor', 'icon': '🏆'},
    {'id': 'expert_verified', 'label': 'Expert Verified', 'icon': '✅'},
    {'id': 'early_responder', 'label': 'Early Responder', 'icon': '⚡'},
    {'id': 'crop_specialist', 'label': 'Crop Specialist', 'icon': '🌾'},
    {'id': 'community_helper', 'label': 'Community Helper', 'icon': '🤝'},
  ];

  // ── GramGyan Backend (Render primary, Railway fallback) ──
  static const String backendPrimaryUrl = 'https://gramgyan-backend.onrender.com';
  static const String backendFallbackUrl = 'https://gramgyan-production.up.railway.app';

  // ── Crop Prediction ML Model (Render primary, Railway fallback) ──
  static const String cropPredictionPrimaryUrl = 'https://crop-prediction-1-2xcu.onrender.com';
  static const String cropPredictionFallbackUrl = 'https://crop-prediction-production-54d1.up.railway.app';
}
