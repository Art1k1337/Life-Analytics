import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepsService {
  StreamSubscription<StepCount>? _subscription;
  int _todaySteps = 0;
  bool _available = false;

  int _baseline = 0;
  String _baselineDate = '';

  int get steps => _todaySteps;
  bool get available => _available;

  Future<int> fetchTodaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseline = prefs.getInt('steps_baseline') ?? 0;
      _baselineDate = prefs.getString('steps_baseline_date') ?? '';

      final today = _dateKey(DateTime.now());

      final completer = Completer<int>();
      late StreamSubscription<StepCount> sub;
      sub = Pedometer.stepCountStream.listen(
        (event) {
          _available = true;
          final cumulative = event.steps;

          // Detect reboot: sensor reset (cumulative dropped below baseline)
          if (cumulative < _baseline) {
            _baseline = 0;
          }

          if (_baselineDate != today) {
            _baseline = cumulative;
            _baselineDate = today;
          }

          _todaySteps = (cumulative - _baseline).clamp(0, 999999);

          // Persist updated baseline
          prefs.setInt('steps_baseline', _baseline);
          prefs.setString('steps_baseline_date', _baselineDate);

          if (!completer.isCompleted) completer.complete(_todaySteps);
        },
        onError: (_) {
          _available = false;
          if (!completer.isCompleted) completer.complete(_todaySteps);
        },
      );
      _subscription = sub;
      return completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => _todaySteps,
      );
    } catch (_) {
      _available = false;
      return _todaySteps;
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void dispose() {
    _subscription?.cancel();
  }
}
