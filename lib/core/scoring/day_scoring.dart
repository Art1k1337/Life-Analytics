import '../models/day_entry.dart';

class ScoreItem {
  const ScoreItem({
    required this.label,
    required this.points,
    required this.maxPoints,
    this.detail,
    this.isPenalty = false,
  });

  final String label;
  final double points;
  final double maxPoints;
  final String? detail;
  final bool isPenalty;

  double get ratio => maxPoints <= 0 ? 0 : (points / maxPoints).clamp(0, 1);
}

class DayScoring {
  const DayScoring._();

  static int workStudyMinutes(DayEntry e) => e.workMinutes + e.studyMinutes;

  static double workStudyPoints(DayEntry e) =>
      (workStudyMinutes(e) / 360 * 40).clamp(0, 40);

  static double sportPoints(DayEntry e) => (e.sportMinutes / 60 * 25).clamp(0, 25);

  static double entertainmentPenalty(DayEntry e) =>
      (e.gameMinutes / 240 * 30).clamp(0, 30);

  static double screenPenalty(DayEntry e) =>
      ((e.screenMinutes - 180) / 300 * 35).clamp(0, 35);

  static int productivityScore(DayEntry e) =>
      (workStudyPoints(e) + sportPoints(e) - entertainmentPenalty(e) - screenPenalty(e))
          .clamp(0, 100)
          .round();

  static double sleepPoints(DayEntry e) {
    final h = e.sleepHours;
    if (h >= 7 && h <= 9) return 20;
    if (h >= 6 && h < 7) return 14;
    if (h > 9 && h <= 10) return 16;
    if (h >= 5 && h < 6) return 8;
    if (h < 5) return 4;
    return 10;
  }

  static double moodPoints(DayEntry e) => (e.mood / 10 * 25).clamp(0, 25);

  static double stepsPoints(DayEntry e) => (e.steps / 10000 * 15).clamp(0, 15);

  static int lifeIndex(DayEntry e) {
    final productivity = productivityScore(e) * 0.40;
    return (productivity + moodPoints(e) + sleepPoints(e) + stepsPoints(e)).clamp(0, 100).round();
  }

  static List<ScoreItem> productivityBreakdown(DayEntry e) => [
        ScoreItem(
          label: 'Работа / учёба',
          points: workStudyPoints(e),
          maxPoints: 40,
          detail: '${workStudyMinutes(e)} мин',
        ),
        ScoreItem(
          label: 'Спорт',
          points: sportPoints(e),
          maxPoints: 25,
          detail: '${e.sportMinutes} мин',
        ),
        ScoreItem(
          label: 'Развлечения',
          points: entertainmentPenalty(e),
          maxPoints: 30,
          detail: '${e.gameMinutes} мин',
          isPenalty: true,
        ),
        ScoreItem(
          label: 'Экранное время',
          points: screenPenalty(e),
          maxPoints: 35,
          detail: '${e.screenMinutes} мин',
          isPenalty: true,
        ),
      ];

  static List<ScoreItem> lifeIndexBreakdown(DayEntry e) => [
        ScoreItem(
          label: 'Продуктивность',
          points: productivityScore(e) * 0.40,
          maxPoints: 40,
          detail: '${productivityScore(e)}/100',
        ),
        ScoreItem(
          label: 'Настроение',
          points: moodPoints(e),
          maxPoints: 25,
          detail: '${e.mood}/10',
        ),
        ScoreItem(
          label: 'Сон',
          points: sleepPoints(e),
          maxPoints: 20,
          detail: '${e.sleepHours.toStringAsFixed(1)} ч',
        ),
        ScoreItem(
          label: 'Шаги',
          points: stepsPoints(e),
          maxPoints: 15,
          detail: '${e.steps}',
        ),
      ];
}

int calculateDayStreak(List<DayEntry> entries) {
  if (entries.isEmpty) return 0;
  final keys = entries.map((e) => e.dayKey).toSet();
  var streak = 0;
  var day = DateTime.now();
  final todayKey = DayEntry.keyFor(day);
  if (!keys.contains(todayKey)) {
    day = day.subtract(const Duration(days: 1));
  }
  while (keys.contains(DayEntry.keyFor(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
