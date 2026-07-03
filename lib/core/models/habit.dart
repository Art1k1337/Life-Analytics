import 'package:uuid/uuid.dart';

class Habit {
  Habit({
    String? id,
    required this.title,
    required this.colorValue,
    required this.createdAt,
    List<String>? completedDayKeys,
  })  : id = id ?? const Uuid().v4(),
        completedDayKeys = completedDayKeys ?? <String>[];

  final String id;
  final String title;
  final int colorValue;
  final DateTime createdAt;
  final List<String> completedDayKeys;

  int get totalCompletions => completedDayKeys.length;

  int streak(DateTime now) {
    var cursor = DateTime(now.year, now.month, now.day);
    var count = 0;
    while (completedDayKeys.contains(_key(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  Habit toggle(String dayKey) {
    final next = [...completedDayKeys];
    next.contains(dayKey) ? next.remove(dayKey) : next.add(dayKey);
    return copyWith(completedDayKeys: next);
  }

  Habit copyWith({String? title, int? colorValue, List<String>? completedDayKeys}) => Habit(
        id: id,
        title: title ?? this.title,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
        completedDayKeys: completedDayKeys ?? this.completedDayKeys,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'completedDayKeys': completedDayKeys.join(','),
      };

  factory Habit.fromMap(Map<String, Object?> map) => Habit(
        id: map['id'] as String,
        title: map['title'] as String,
        colorValue: (map['colorValue'] as num).round(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        completedDayKeys: ((map['completedDayKeys'] as String?) ?? '')
            .split(',')
            .where((value) => value.isNotEmpty)
            .toList(),
      );

  static String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
