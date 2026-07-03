import '../models/analytics_summary.dart';
import '../models/day_entry.dart';

enum AnalyticsPeriod { day, week, month, year }

class AnalyticsService {
  AnalyticsSummary summarize(List<DayEntry> entries, AnalyticsPeriod period) {
    final now = DateTime.now();
    final filtered = entries.where((entry) {
      final diff = now.difference(entry.date).inDays;
      return switch (period) {
        AnalyticsPeriod.day => diff <= 1,
        AnalyticsPeriod.week => diff < 7,
        AnalyticsPeriod.month => diff < 31,
        AnalyticsPeriod.year => diff < 366,
      };
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (filtered.isEmpty) {
      return const AnalyticsSummary(
        entries: [],
        averageIndex: 0,
        averageSleep: 0,
        averageProductivity: 0,
        bestDay: null,
        worstDay: null,
      );
    }

    final best = filtered.reduce((a, b) => a.lifeIndex >= b.lifeIndex ? a : b);
    final worst = filtered.reduce((a, b) => a.lifeIndex <= b.lifeIndex ? a : b);
    return AnalyticsSummary(
      entries: filtered,
      averageIndex: filtered.map((e) => e.lifeIndex).average,
      averageSleep: filtered.map((e) => e.sleepHours).average,
      averageProductivity: filtered.map((e) => e.productivityScore).average,
      bestDay: best,
      worstDay: worst,
    );
  }

  WeeklyReport weeklyReport(List<DayEntry> entries) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));

    final thisWeek = entries.where((e) => e.date.isAfter(weekStart.subtract(const Duration(days: 1)))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final prevWeek = entries.where((e) =>
        e.date.isAfter(prevWeekStart.subtract(const Duration(days: 1))) &&
        e.date.isBefore(weekStart)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (thisWeek.isEmpty) {
      return const WeeklyReport(
        days: 0,
        averageIndex: 0,
        averageSleep: 0,
        averageMood: 0,
        averageSteps: 0,
        totalSport: 0,
        bestDay: null,
        worstDay: null,
        indexDiff: 0,
        sleepDiff: 0,
        stepsDiff: 0,
      );
    }

    final avgIndex = thisWeek.map((e) => e.lifeIndex).average;
    final avgSleep = thisWeek.map((e) => e.sleepHours).average;
    final avgMood = thisWeek.map((e) => e.mood).average;
    final avgSteps = thisWeek.map((e) => e.steps).average;
    final totalSport = thisWeek.fold<int>(0, (s, e) => s + e.sportMinutes);
    final best = thisWeek.reduce((a, b) => a.lifeIndex >= b.lifeIndex ? a : b);
    final worst = thisWeek.reduce((a, b) => a.lifeIndex <= b.lifeIndex ? a : b);

    double indexDiff = 0, sleepDiff = 0, stepsDiff = 0;
    if (prevWeek.isNotEmpty) {
      indexDiff = avgIndex - prevWeek.map((e) => e.lifeIndex).average;
      sleepDiff = avgSleep - prevWeek.map((e) => e.sleepHours).average;
      stepsDiff = avgSteps - prevWeek.map((e) => e.steps).average;
    }

    return WeeklyReport(
      days: thisWeek.length,
      averageIndex: avgIndex,
      averageSleep: avgSleep,
      averageMood: avgMood,
      averageSteps: avgSteps,
      totalSport: totalSport,
      bestDay: best,
      worstDay: worst,
      indexDiff: indexDiff,
      sleepDiff: sleepDiff,
      stepsDiff: stepsDiff,
    );
  }

  double correlation(Iterable<num> left, Iterable<num> right) {
    final x = left.map((e) => e.toDouble()).toList();
    final y = right.map((e) => e.toDouble()).toList();
    if (x.length != y.length || x.length < 2) return 0;
    final mx = x.average;
    final my = y.average;
    var numerator = 0.0;
    var dx = 0.0;
    var dy = 0.0;
    for (var i = 0; i < x.length; i++) {
      numerator += (x[i] - mx) * (y[i] - my);
      dx += (x[i] - mx) * (x[i] - mx);
      dy += (y[i] - my) * (y[i] - my);
    }
    if (dx == 0 || dy == 0) return 0;
    return numerator / (dx * dy).sqrt();
  }
}

extension _Average on Iterable<num> {
  double get average => isEmpty ? 0 : fold<double>(0, (sum, value) => sum + value) / length;
}

extension _Sqrt on double {
  double sqrt() {
    var guess = this / 2;
    for (var i = 0; i < 12; i++) {
      guess = (guess + this / guess) / 2;
    }
    return guess;
  }
}
