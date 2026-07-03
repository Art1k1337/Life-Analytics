import 'package:uuid/uuid.dart';

import '../models/day_entry.dart';

enum GoalMetric {
  custom,
  steps,
  studyMinutes,
  workStudyMinutes,
  sportMinutes,
  sleepHours,
  mood,
  lifeIndex,
  productivity,
}

extension GoalMetricLabel on GoalMetric {
  String get label => switch (this) {
        GoalMetric.custom => 'Своё',
        GoalMetric.steps => 'Шаги',
        GoalMetric.studyMinutes => 'Учёба',
        GoalMetric.workStudyMinutes => 'Работа / учёба',
        GoalMetric.sportMinutes => 'Спорт',
        GoalMetric.sleepHours => 'Сон',
        GoalMetric.mood => 'Настроение',
        GoalMetric.lifeIndex => 'Индекс дня',
        GoalMetric.productivity => 'Продуктивность',
      };

  static GoalMetric fromString(String? value) => GoalMetric.values.firstWhere(
        (m) => m.name == value,
        orElse: () => GoalMetric.custom,
      );
}

class LifeGoal {
  LifeGoal({
    String? id,
    required this.title,
    required this.target,
    required this.current,
    required this.unit,
    required this.dueDate,
    this.metric = GoalMetric.custom,
    this.autoTrack = false,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String title;
  final double target;
  final double current;
  final String unit;
  final DateTime dueDate;
  final GoalMetric metric;
  final bool autoTrack;

  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);
  bool get achieved => current >= target;

  double valueFromEntry(DayEntry entry) => switch (metric) {
        GoalMetric.steps => entry.steps.toDouble(),
        GoalMetric.studyMinutes => entry.studyMinutes.toDouble(),
        GoalMetric.workStudyMinutes => entry.workStudyMinutes.toDouble(),
        GoalMetric.sportMinutes => entry.sportMinutes.toDouble(),
        GoalMetric.sleepHours => entry.sleepHours,
        GoalMetric.mood => entry.mood.toDouble(),
        GoalMetric.lifeIndex => entry.lifeIndex.toDouble(),
        GoalMetric.productivity => entry.productivityScore.toDouble(),
        GoalMetric.custom => current,
      };

  LifeGoal copyWith({double? current}) => LifeGoal(
        id: id,
        title: title,
        target: target,
        current: current ?? this.current,
        unit: unit,
        dueDate: dueDate,
        metric: metric,
        autoTrack: autoTrack,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'target': target,
        'current': current,
        'unit': unit,
        'dueDate': dueDate.toIso8601String(),
        'metric': metric.name,
        'autoTrack': autoTrack ? 1 : 0,
      };

  factory LifeGoal.fromMap(Map<String, Object?> map) => LifeGoal(
        id: map['id'] as String,
        title: map['title'] as String,
        target: (map['target'] as num).toDouble(),
        current: (map['current'] as num).toDouble(),
        unit: map['unit'] as String,
        dueDate: DateTime.parse(map['dueDate'] as String),
        metric: GoalMetricLabel.fromString(map['metric'] as String?),
        autoTrack: (map['autoTrack'] as int? ?? 0) == 1,
      );

  static List<LifeGoal> templates(DateTime dueDate) => [
        LifeGoal(
          title: '8000 шагов в день',
          target: 8000,
          current: 0,
          unit: 'шагов',
          dueDate: dueDate,
          metric: GoalMetric.steps,
          autoTrack: true,
        ),
        LifeGoal(
          title: '2 часа учёбы',
          target: 120,
          current: 0,
          unit: 'мин',
          dueDate: dueDate,
          metric: GoalMetric.studyMinutes,
          autoTrack: true,
        ),
        LifeGoal(
          title: '45 минут спорта',
          target: 45,
          current: 0,
          unit: 'мин',
          dueDate: dueDate,
          metric: GoalMetric.sportMinutes,
          autoTrack: true,
        ),
        LifeGoal(
          title: '7+ часов сна',
          target: 7,
          current: 0,
          unit: 'ч',
          dueDate: dueDate,
          metric: GoalMetric.sleepHours,
          autoTrack: true,
        ),
        LifeGoal(
          title: '4 часа работы / учёбы',
          target: 240,
          current: 0,
          unit: 'мин',
          dueDate: dueDate,
          metric: GoalMetric.workStudyMinutes,
          autoTrack: true,
        ),
        LifeGoal(
          title: 'Индекс дня 70+',
          target: 70,
          current: 0,
          unit: 'баллов',
          dueDate: dueDate,
          metric: GoalMetric.lifeIndex,
          autoTrack: true,
        ),
      ];
}
