class AiInsight {
  const AiInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.confidence,
    this.category,
  });

  final String title;
  final String description;
  final InsightType type;
  final double confidence;
  final InsightCategory? category;
}

enum InsightType {
  positive,
  negative,
  advice,
  forecast,
  pattern,
  record,
  goal,
}

enum InsightCategory {
  sleep,
  mood,
  productivity,
  sport,
  nutrition,
  screenTime,
  stress,
  energy,
  steps,
  habits,
  goals,
  general,
}

class DimensionScore {
  const DimensionScore({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.icon,
    this.detail,
  });

  final String label;
  final double score;
  final double maxScore;
  final String icon;
  final String? detail;

  double get ratio => maxScore <= 0 ? 0 : (score / maxScore).clamp(0, 1);
  String get grade {
    final r = ratio;
    if (r >= 0.9) return 'Отлично';
    if (r >= 0.75) return 'Хорошо';
    if (r >= 0.55) return 'Норма';
    if (r >= 0.35) return 'Ниже нормы';
    return 'Критично';
  }
}

class AiAnalysis {
  const AiAnalysis({
    required this.generatedAt,
    required this.positive,
    required this.negative,
    required this.advice,
    required this.forecast,
    required this.patterns,
    required this.records,
    required this.dimensions,
    required this.summary,
    required this.dayPersona,
    required this.healthScore,
    required this.stabilityScore,
  });

  final DateTime generatedAt;
  final List<AiInsight> positive;
  final List<AiInsight> negative;
  final List<AiInsight> advice;
  final List<AiInsight> forecast;
  final List<AiInsight> patterns;
  final List<AiInsight> records;
  final List<DimensionScore> dimensions;
  final String summary;
  final String dayPersona;
  final int healthScore;
  final int stabilityScore;
}
