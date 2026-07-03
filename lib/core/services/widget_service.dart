import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../models/day_entry.dart';

class WidgetService {
  static const _androidClassName = 'com.lifeanalytics.app.LifeIndexWidgetProvider';

  static Future<void> updateWidget(DayEntry? entry) async {
    if (!Platform.isAndroid) return;

    try {
      if (entry == null) {
        await HomeWidget.saveWidgetData<int>('life_index', -1).timeout(const Duration(seconds: 3));
        await HomeWidget.saveWidgetData<String>('sleep_hours', '—').timeout(const Duration(seconds: 3));
        await HomeWidget.saveWidgetData<String>('mood', '—').timeout(const Duration(seconds: 3));
        await HomeWidget.saveWidgetData<String>('steps', '—').timeout(const Duration(seconds: 3));
      } else {
        await HomeWidget.saveWidgetData<int>('life_index', entry.lifeIndex).timeout(const Duration(seconds: 3));
        await HomeWidget.saveWidgetData<String>('sleep_hours', '${entry.sleepHours.toStringAsFixed(1)}ч').timeout(const Duration(seconds: 3));
        await HomeWidget.saveWidgetData<String>('mood', '${entry.mood}/10').timeout(const Duration(seconds: 3));
        await HomeWidget.saveWidgetData<String>('steps', _formatSteps(entry.steps)).timeout(const Duration(seconds: 3));
      }

      await HomeWidget.updateWidget(
        androidName: _androidClassName,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static String _formatSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}к';
    return '$steps';
  }
}
