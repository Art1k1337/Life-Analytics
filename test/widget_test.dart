import 'package:flutter_test/flutter_test.dart';
import 'package:life_analytics/core/models/day_entry.dart';

void main() {
  test('DayEntry calculates bounded lifestyle indexes', () {
    final entry = DayEntry(
      date: DateTime(2026, 6, 24),
      sleepHours: 8,
      waterLiters: 2.2,
      calories: 2200,
      weightKg: 72,
      steps: 10000,
      sportMinutes: 45,
      studyMinutes: 120,
      workMinutes: 300,
      gameMinutes: 30,
      screenMinutes: 240,
      mood: 8,
      stress: 3,
      energy: 8,
      note: 'Good day',
    );

    expect(entry.productivityScore, inInclusiveRange(0, 100));
    expect(entry.lifeIndex, inInclusiveRange(0, 100));
  });
}
