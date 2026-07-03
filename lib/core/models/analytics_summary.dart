import 'day_entry.dart';

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.entries,
    required this.averageIndex,
    required this.averageSleep,
    required this.averageProductivity,
    required this.bestDay,
    required this.worstDay,
  });

  final List<DayEntry> entries;
  final double averageIndex;
  final double averageSleep;
  final double averageProductivity;
  final DayEntry? bestDay;
  final DayEntry? worstDay;

  bool get isEmpty => entries.isEmpty;
}

class WeeklyReport {
  const WeeklyReport({
    required this.days,
    required this.averageIndex,
    required this.averageSleep,
    required this.averageMood,
    required this.averageSteps,
    required this.totalSport,
    required this.bestDay,
    required this.worstDay,
    required this.indexDiff,
    required this.sleepDiff,
    required this.stepsDiff,
  });

  final int days;
  final double averageIndex;
  final double averageSleep;
  final double averageMood;
  final double averageSteps;
  final int totalSport;
  final DayEntry? bestDay;
  final DayEntry? worstDay;
  final double indexDiff;
  final double sleepDiff;
  final double stepsDiff;

  bool get isEmpty => days == 0;
}
