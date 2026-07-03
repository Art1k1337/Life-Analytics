import 'dart:io';

import 'package:usage_stats/usage_stats.dart';

class ScreenTimeService {
  Future<int> fetchTodayScreenMinutes() async {
    if (!Platform.isAndroid) return 0;
    try {
      final granted = await UsageStats.checkUsagePermission() ?? false;
      if (!granted) return 0;

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final stats = await UsageStats.queryUsageStats(start, now);
      if (stats.isEmpty) return 0;

      int totalMs = 0;
      for (final stat in stats) {
        final ms = int.tryParse('${stat.totalTimeInForeground ?? 0}') ?? 0;
        // Cap per-app at 24h to filter stale data after reboot
        totalMs += ms.clamp(0, 86400000);
      }
      // Cap total at 24h (1440 min)
      return (totalMs ~/ 60000).clamp(0, 1440);
    } catch (_) {
      return 0;
    }
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      await UsageStats.grantUsagePermission();
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> get hasPermission async {
    if (!Platform.isAndroid) return false;
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }
}
