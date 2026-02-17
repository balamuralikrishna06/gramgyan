/// Model representing an AI-generated insight for a farmer's problem.
class AiInsight {
  final String id;
  final String questionId;
  final String possibleCause;
  final double confidence;
  final List<String> suggestedSolutions;
  final List<SimilarCase> similarCases;
  final String weatherCorrelation;
  final String severity;

  const AiInsight({
    required this.id,
    required this.questionId,
    required this.possibleCause,
    required this.confidence,
    required this.suggestedSolutions,
    required this.similarCases,
    required this.weatherCorrelation,
    this.severity = 'Medium',
  });
}

/// A past case similar to the farmer's current problem.
class SimilarCase {
  final String farmerName;
  final String location;
  final String crop;
  final String solution;
  final bool wasEffective;

  const SimilarCase({
    required this.farmerName,
    required this.location,
    required this.crop,
    required this.solution,
    required this.wasEffective,
  });
}
