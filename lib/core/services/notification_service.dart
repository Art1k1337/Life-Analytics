import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _keyFillDay = 'notif_fill_day';
  static const _keySleep = 'notif_sleep';
  static const _keyWater = 'notif_water';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    await _createChannel();
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      'life_analytics_reminders',
      'Life Analytics reminders',
      description: 'Daily health, habits and productivity recommendations.',
      importance: Importance.high,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(channel);
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  bool get fillDayEnabled => _prefs.getBool(_keyFillDay) ?? true;
  bool get sleepEnabled => _prefs.getBool(_keySleep) ?? true;
  bool get waterEnabled => _prefs.getBool(_keyWater) ?? false;

  Future<void> setFillDay(bool value) async {
    await _prefs.setBool(_keyFillDay, value);
    if (value) {
      await _scheduleDaily(21, 0, 0, 'Заполни день', 'Не забудь записать сон, настроение и активность за сегодня.');
    } else {
      await _plugin.cancel(0);
    }
  }

  Future<void> setSleep(bool value) async {
    await _prefs.setBool(_keySleep, value);
    if (value) {
      await _scheduleDaily(23, 0, 1, 'Пора спать', 'Рекомендуется лечь до 23:30 для лучшего восстановления.');
    } else {
      await _plugin.cancel(1);
    }
  }

  Future<void> setWater(bool value) async {
    await _prefs.setBool(_keyWater, value);
    if (value) {
      await _scheduleDaily(9, 0, 2, 'Пей воду', 'Начни день со стакана воды. Цель: 2 литра.');
      await _scheduleDaily(11, 0, 3, 'Пей воду', 'Прошло 2 часа — время выпить стакан воды.');
      await _scheduleDaily(13, 0, 4, 'Пей воду', 'Обед = стакан воды.');
      await _scheduleDaily(15, 0, 5, 'Пей воду', 'Полдник — выпей воды.');
      await _scheduleDaily(17, 0, 6, 'Пей воду', 'Вечерний стакан воды.');
      await _scheduleDaily(19, 0, 7, 'Пей воду', 'Перед ужином — стакан воды.');
    } else {
      for (var i = 2; i <= 7; i++) {
        await _plugin.cancel(i);
      }
    }
  }

  Future<void> _scheduleDaily(int hour, int minute, int id, String title, String body) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'life_analytics_reminders',
          'Life Analytics reminders',
          channelDescription: 'Daily health, habits and productivity recommendations.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );

      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> showNow(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'life_analytics_reminders',
        'Life Analytics reminders',
        channelDescription: 'Daily health, habits and productivity recommendations.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  Future<void> scheduleAll() async {
    if (fillDayEnabled) await setFillDay(true);
    if (sleepEnabled) await setSleep(true);
    if (waterEnabled) await setWater(true);
  }
}
