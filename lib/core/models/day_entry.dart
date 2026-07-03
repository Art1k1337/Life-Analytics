import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../scoring/day_scoring.dart';

class DayEntry {
  DayEntry({
    String? id,
    required this.date,
    required this.sleepHours,
    required this.waterLiters,
    required this.calories,
    required this.weightKg,
    required this.steps,
    required this.sportMinutes,
    required this.studyMinutes,
    required this.workMinutes,
    required this.gameMinutes,
    required this.screenMinutes,
    required this.mood,
    required this.stress,
    required this.energy,
    required this.note,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final DateTime date;
  final double sleepHours;
  final double waterLiters;
  final int calories;
  final double weightKg;
  final int steps;
  final int sportMinutes;
  final int studyMinutes;
  final int workMinutes;
  final int gameMinutes;
  final int screenMinutes;
  final int mood;
  final int stress;
  final int energy;
  final String note;

  int get productivityScore => DayScoring.productivityScore(this);
  int get lifeIndex => DayScoring.lifeIndex(this);
  int get workStudyMinutes => DayScoring.workStudyMinutes(this);

  String get dayKey => DateFormat('yyyy-MM-dd').format(date);

  static String keyFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DayEntry copyWith({
    String? id,
    DateTime? date,
    double? sleepHours,
    double? waterLiters,
    int? calories,
    double? weightKg,
    int? steps,
    int? sportMinutes,
    int? studyMinutes,
    int? workMinutes,
    int? gameMinutes,
    int? screenMinutes,
    int? mood,
    int? stress,
    int? energy,
    String? note,
  }) =>
      DayEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        sleepHours: sleepHours ?? this.sleepHours,
        waterLiters: waterLiters ?? this.waterLiters,
        calories: calories ?? this.calories,
        weightKg: weightKg ?? this.weightKg,
        steps: steps ?? this.steps,
        sportMinutes: sportMinutes ?? this.sportMinutes,
        studyMinutes: studyMinutes ?? this.studyMinutes,
        workMinutes: workMinutes ?? this.workMinutes,
        gameMinutes: gameMinutes ?? this.gameMinutes,
        screenMinutes: screenMinutes ?? this.screenMinutes,
        mood: mood ?? this.mood,
        stress: stress ?? this.stress,
        energy: energy ?? this.energy,
        note: note ?? this.note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'sleepHours': sleepHours,
        'waterLiters': waterLiters,
        'calories': calories,
        'weightKg': weightKg,
        'steps': steps,
        'sportMinutes': sportMinutes,
        'studyMinutes': studyMinutes,
        'workMinutes': workMinutes,
        'gameMinutes': gameMinutes,
        'screenMinutes': screenMinutes,
        'mood': mood,
        'stress': stress,
        'energy': energy,
        'note': note,
      };

  factory DayEntry.fromMap(Map<String, Object?> map) => DayEntry(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        sleepHours: (map['sleepHours'] as num).toDouble(),
        waterLiters: (map['waterLiters'] as num).toDouble(),
        calories: (map['calories'] as num).round(),
        weightKg: (map['weightKg'] as num).toDouble(),
        steps: (map['steps'] as num).round(),
        sportMinutes: (map['sportMinutes'] as num).round(),
        studyMinutes: (map['studyMinutes'] as num).round(),
        workMinutes: (map['workMinutes'] as num).round(),
        gameMinutes: (map['gameMinutes'] as num).round(),
        screenMinutes: (map['screenMinutes'] as num).round(),
        mood: (map['mood'] as num).round(),
        stress: (map['stress'] as num).round(),
        energy: (map['energy'] as num).round(),
        note: map['note'] as String? ?? '',
      );
}
