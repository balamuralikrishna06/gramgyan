import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ai_insight.dart';

/// Provides mock AI insight data for a given question ID.
final aiInsightProvider =
    FutureProvider.family<AiInsight, String>((ref, questionId) async {
  // Simulate API delay
  await Future.delayed(const Duration(milliseconds: 1200));

  // Return mock data based on question
  return AiInsight(
    id: 'ai_$questionId',
    questionId: questionId,
    possibleCause: 'Leaf Blight caused by fungal infection (Alternaria solani). '
        'Typically occurs after prolonged humid conditions combined with '
        'warm temperatures above 25°C.',
    confidence: 0.87,
    suggestedSolutions: [
      'Apply Mancozeb 75% WP at 2.5g/L as foliar spray',
      'Remove and destroy infected leaves to prevent spread',
      'Ensure proper spacing between plants for air circulation',
      'Apply neem oil (5ml/L) as organic preventive measure',
      'Rotate crops in the next season to break disease cycle',
    ],
    similarCases: const [
      SimilarCase(
        farmerName: 'Suresh Patel',
        location: 'Nashik, Maharashtra',
        crop: 'Tomato',
        solution: 'Used Mancozeb spray, recovered in 10 days',
        wasEffective: true,
      ),
      SimilarCase(
        farmerName: 'Lakshmi Devi',
        location: 'Kolar, Karnataka',
        crop: 'Tomato',
        solution: 'Applied neem oil + copper fungicide',
        wasEffective: true,
      ),
      SimilarCase(
        farmerName: 'Ramesh Yadav',
        location: 'Indore, Madhya Pradesh',
        crop: 'Potato',
        solution: 'Removed infected plants, applied Bordeaux mixture',
        wasEffective: false,
      ),
    ],
    weatherCorrelation:
        'Recent weather data shows 85% humidity and 28°C average temperature '
        'in your area over the past week. These conditions strongly favour '
        'fungal growth, especially Alternaria species. Expect continued risk '
        'for the next 3-5 days until humidity drops below 70%.',
    severity: 'High',
  );
});
