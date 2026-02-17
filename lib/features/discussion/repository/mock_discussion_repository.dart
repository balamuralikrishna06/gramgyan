import '../models/question.dart';
import '../models/solution.dart';

/// Mock repository for the Q&A discussion feature.
/// Stores questions and solutions in-memory with simulated API delays.
class MockDiscussionRepository {
  // ── In-Memory Stores ──
  final List<Question> _questions = List.from(_seedQuestions);
  final List<Solution> _solutions = List.from(_seedSolutions);

  // ── Questions ──

  Future<List<Question>> getQuestions() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // Return copies sorted by newest first
    return List.from(_questions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Question> addQuestion({
    required String transcript,
    required String crop,
    required String category,
    required String authorId,
    required String farmerName,
    required String location,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final question = Question(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      farmerName: farmerName,
      location: location,
      crop: crop,
      category: category,
      transcript: transcript,
      audioUrl: 'mock_question_audio.mp3',
      status: QuestionStatus.open,
      replyCount: 0,
      karma: 0,
      createdAt: DateTime.now(),
    );
    _questions.insert(0, question);
    return question;
  }

  // ── Solutions ──

  Future<List<Solution>> getSolutions(String questionId) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final solutions =
        _solutions.where((s) => s.questionId == questionId).toList()
          ..sort((a, b) => b.karma.compareTo(a.karma)); // highest karma first
    return solutions;
  }

  Future<Solution> addSolution({
    required String questionId,
    required String transcript,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final solution = Solution(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      questionId: questionId,
      farmerName: 'You',
      transcript: transcript,
      audioUrl: 'mock_solution_audio.mp3',
      karma: 10, // +10 karma for answering
      isVerified: false,
      createdAt: DateTime.now(),
    );
    _solutions.add(solution);

    // Increment reply count on the question
    final qi = _questions.indexWhere((q) => q.id == questionId);
    if (qi != -1) {
      _questions[qi] = _questions[qi].copyWith(
        replyCount: _questions[qi].replyCount + 1,
      );
    }
    return solution;
  }

  Future<void> upvoteSolution(String solutionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final si = _solutions.indexWhere((s) => s.id == solutionId);
    if (si != -1) {
      _solutions[si] = _solutions[si].copyWith(
        karma: _solutions[si].karma + 5, // +5 per upvote
      );
    }
  }

  // ── Seed Data ──

  static final List<Question> _seedQuestions = [
    Question(
      id: 'q1',
      authorId: 'user1',
      farmerName: 'Ravi Kumar',
      location: 'Salem, TN',
      crop: 'Tomato',
      category: 'Crops',
      transcript:
          'My tomato plant leaves are turning yellow from the bottom. I tried adding nitrogen fertilizer but no improvement. What could be the cause and how to fix it?',
      audioUrl: 'mock_q1.mp3',
      status: QuestionStatus.open,
      replyCount: 3,
      karma: 18,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Question(
      id: 'q2',
      authorId: 'user2',
      farmerName: 'Lakshmi Devi',
      location: 'Madurai, TN',
      crop: 'Paddy',
      category: 'Crops',
      transcript:
          'Brown plant hopper is attacking my paddy field. I have tried spraying insecticide but they keep coming back. Need a long-term solution.',
      audioUrl: 'mock_q2.mp3',
      status: QuestionStatus.solved,
      replyCount: 5,
      karma: 42,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Question(
      id: 'q3',
      authorId: 'user3',
      farmerName: 'Suresh Patel',
      location: 'Coimbatore, TN',
      crop: 'Cow',
      category: 'Livestock',
      transcript:
          'My cow has developed lumps on her skin and is not eating properly. The local vet is unavailable. What should I do as a first aid measure?',
      audioUrl: 'mock_q3.mp3',
      status: QuestionStatus.verified,
      replyCount: 7,
      karma: 56,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Question(
      id: 'q4',
      authorId: 'user4',
      farmerName: 'Anitha Raj',
      location: 'Thanjavur, TN',
      crop: 'Wheat',
      category: 'Soil',
      transcript:
          'The soil in my wheat field has become very hard and compacted. Water is not draining properly. How can I improve the soil structure organically?',
      audioUrl: 'mock_q4.mp3',
      status: QuestionStatus.open,
      replyCount: 1,
      karma: 12,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Question(
      id: 'q5',
      authorId: 'user5',
      farmerName: 'Murugan S',
      location: 'Erode, TN',
      crop: 'Cotton',
      category: 'Weather',
      transcript:
          'There is heavy rain forecast for the next week. My cotton is ready for harvesting. Should I harvest now or wait? Will early harvest affect quality?',
      audioUrl: 'mock_q5.mp3',
      status: QuestionStatus.solved,
      replyCount: 4,
      karma: 31,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Question(
      id: 'q6',
      authorId: 'user6',
      farmerName: 'Kavitha M',
      location: 'Tirunelveli, TN',
      crop: 'Goat',
      category: 'Livestock',
      transcript:
          'My goat herd has been losing weight despite good feeding. I noticed some of them have dull coat and diarrhea. Could this be worm infestation?',
      audioUrl: 'mock_q6.mp3',
      status: QuestionStatus.open,
      replyCount: 2,
      karma: 15,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  static final List<Solution> _seedSolutions = [
    // Solutions for q1 (Tomato yellowing)
    Solution(
      id: 's1',
      questionId: 'q1',
      farmerName: 'Senthil K',
      transcript:
          'Yellow leaves from bottom usually means magnesium deficiency, not nitrogen. Try Epsom salt spray — 2 tablespoons per litre of water. Spray every week.',
      audioUrl: 'mock_s1.mp3',
      karma: 24,
      isVerified: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Solution(
      id: 's2',
      questionId: 'q1',
      farmerName: 'Priya N',
      transcript:
          'Check for overwatering first. Tomato roots rot easily and the first sign is yellowing from the bottom. Reduce watering and check drainage.',
      audioUrl: 'mock_s2.mp3',
      karma: 15,
      isVerified: false,
      createdAt:
          DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    Solution(
      id: 's3',
      questionId: 'q1',
      farmerName: 'Rajesh V',
      transcript:
          'Could be early blight fungal infection. Remove the affected leaves and apply copper-based fungicide. Also improve air circulation between plants.',
      audioUrl: 'mock_s3.mp3',
      karma: 8,
      isVerified: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),

    // Solutions for q2 (BPH in paddy)
    Solution(
      id: 's4',
      questionId: 'q2',
      farmerName: 'Devi P',
      transcript:
          'Drain the water from the field for 3-4 days. BPH thrives in standing water. After draining, apply neem oil spray. This worked in my field.',
      audioUrl: 'mock_s4.mp3',
      karma: 38,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Solution(
      id: 's5',
      questionId: 'q2',
      farmerName: 'Murugan S',
      transcript:
          'Use light traps at night to reduce the adult population. Also plant resistant varieties like CO-51 or ADT-45 next season.',
      audioUrl: 'mock_s5.mp3',
      karma: 22,
      isVerified: false,
      createdAt:
          DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
    ),

    // Solutions for q3 (Cow lumps)
    Solution(
      id: 's6',
      questionId: 'q3',
      farmerName: 'Anitha Raj',
      transcript:
          'This sounds like Lumpy Skin Disease. Keep the cow isolated from others immediately. Apply potassium permanganate solution on the lumps and give Paracetamol for fever.',
      audioUrl: 'mock_s6.mp3',
      karma: 45,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 20)),
    ),
    Solution(
      id: 's7',
      questionId: 'q3',
      farmerName: 'Ravi Kumar',
      transcript:
          'Turmeric paste mixed with coconut oil applied on the lumps will reduce swelling. Also give neem water to drink. But please consult a vet as soon as possible.',
      audioUrl: 'mock_s7.mp3',
      karma: 30,
      isVerified: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),

    // Solutions for q4 (Compacted soil)
    Solution(
      id: 's8',
      questionId: 'q4',
      farmerName: 'Kavitha M',
      transcript:
          'Add farmyard manure and green manure crops like dhaincha. Grow them for 45 days and plow them back into the soil. This will loosen the soil naturally.',
      audioUrl: 'mock_s8.mp3',
      karma: 18,
      isVerified: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),

    // Solutions for q6 (Goat weight loss)
    Solution(
      id: 's9',
      questionId: 'q6',
      farmerName: 'Lakshmi Devi',
      transcript:
          'Yes, dull coat and weight loss with diarrhea is classic worm infestation. Deworm all goats with Albendazole. Repeat after 21 days.',
      audioUrl: 'mock_s9.mp3',
      karma: 20,
      isVerified: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Solution(
      id: 's10',
      questionId: 'q6',
      farmerName: 'Suresh Patel',
      transcript:
          'Along with deworming, give them mineral mixture supplement and clean water. Rotate grazing area every week to break the worm cycle.',
      audioUrl: 'mock_s10.mp3',
      karma: 12,
      isVerified: false,
      createdAt:
          DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
    ),
  ];
}
