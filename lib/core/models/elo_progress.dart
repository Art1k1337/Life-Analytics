class EloHistoryEntry {
  const EloHistoryEntry({
    required this.date,
    required this.index,
    required this.deltaElo,
    required this.eloAfter,
  });

  final DateTime date;
  final int index;
  final int deltaElo;
  final int eloAfter;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'index': index,
        'deltaElo': deltaElo,
        'eloAfter': eloAfter,
      };

  factory EloHistoryEntry.fromMap(Map<String, dynamic> map) => EloHistoryEntry(
        date: DateTime.parse(map['date'] as String),
        index: map['index'] as int,
        deltaElo: map['deltaElo'] as int,
        eloAfter: map['eloAfter'] as int,
      );
}

class EloLevel {
  const EloLevel(this.minElo, this.maxElo, this.title);

  final int minElo;
  final int maxElo;
  final String title;

  bool contains(int elo) => elo >= minElo && (maxElo == -1 ? true : elo < maxElo);

  double progress(int elo) {
    if (maxElo == -1) return 1.0;
    final range = maxElo - minElo;
    return ((elo - minElo) / range).clamp(0.0, 1.0);
  }
}

const eloLevels = [
  EloLevel(0, 800, 'Start Chaos'),
  EloLevel(800, 1200, 'Новичок'),
  EloLevel(1200, 1600, 'Стабильный'),
  EloLevel(1600, 2000, 'Дисциплинированный'),
  EloLevel(2000, 2400, 'Фокусированный'),
  EloLevel(2400, 2800, 'Продвинутый'),
  EloLevel(2800, 3200, 'Мастер'),
  EloLevel(3200, 3800, 'Элита'),
  EloLevel(3800, 4500, 'Легенда'),
  EloLevel(4500, -1, 'Трансцендент'),
];

class EloProgress {
  const EloProgress({
    required this.currentElo,
    required this.calibrationStartDate,
    required this.history,
  });

  static const int startElo = 2000;
  static const int calibrationDays = 7;

  final int currentElo;
  final DateTime? calibrationStartDate;
  final List<EloHistoryEntry> history;

  bool get isCalibrating {
    if (calibrationStartDate == null) return true;
    return daysSinceCalibrationStart < calibrationDays;
  }

  int get daysSinceCalibrationStart {
    if (calibrationStartDate == null) return 0;
    return DateTime.now().difference(calibrationStartDate!).inDays;
  }

  int get calibrationDay => daysSinceCalibrationStart + 1;

  int get daysLeft => calibrationDays - calibrationDay;

  EloLevel get currentLevel {
    for (final level in eloLevels) {
      if (level.contains(currentElo)) return level;
    }
    return eloLevels.last;
  }

  double get levelProgress => currentLevel.progress(currentElo);

  EloLevel? get nextLevel {
    final idx = eloLevels.indexOf(currentLevel);
    if (idx < eloLevels.length - 1) return eloLevels[idx + 1];
    return null;
  }

  static int calculateDelta(int index, bool isCalibrating) {
    final raw = isCalibrating ? (index - 50) * 3.5 : (index - 50) * 0.6;
    var delta = raw.round();
    if (isCalibrating) {
      delta = delta.clamp(-80, 120);
    }
    return delta;
  }

  static EloProgress initial() => EloProgress(
        currentElo: startElo,
        calibrationStartDate: null,
        history: const [],
      );

  Map<String, dynamic> toMap() => {
        'currentElo': currentElo,
        'calibrationStartDate': calibrationStartDate?.toIso8601String(),
        'history': history.map((e) => e.toMap()).toList(),
      };

  factory EloProgress.fromMap(Map<String, dynamic> map) => EloProgress(
        currentElo: map['currentElo'] as int,
        calibrationStartDate: map['calibrationStartDate'] != null
            ? DateTime.parse(map['calibrationStartDate'] as String)
            : null,
        history: (map['history'] as List)
            .map((e) => EloHistoryEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}
