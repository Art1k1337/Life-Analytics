import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/elo_progress.dart';

class EloService {
  static const _key = 'elo_progress';

  late SharedPreferences _prefs;
  EloProgress _progress = EloProgress.initial();

  EloProgress get progress => _progress;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    final json = _prefs.getString(_key);
    if (json != null) {
      _progress = EloProgress.fromMap(jsonDecode(json) as Map<String, dynamic>);
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(_progress.toMap()));
  }

  Future<EloHistoryEntry> recordDay(int index) async {
    if (_progress.calibrationStartDate == null) {
      _progress = EloProgress(
        currentElo: _progress.currentElo,
        calibrationStartDate: DateTime.now(),
        history: _progress.history,
      );
    }

    final delta = EloProgress.calculateDelta(index, _progress.isCalibrating);
    final newElo = _progress.currentElo + delta;

    final entry = EloHistoryEntry(
      date: DateTime.now(),
      index: index,
      deltaElo: delta,
      eloAfter: newElo,
    );

    _progress = EloProgress(
      currentElo: newElo,
      calibrationStartDate: _progress.calibrationStartDate,
      history: [..._progress.history, entry],
    );

    await _save();
    return entry;
  }
}
