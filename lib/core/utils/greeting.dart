String timeGreeting(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 12) return 'Доброе утро';
  if (hour >= 12 && hour < 17) return 'Добрый день';
  if (hour >= 17 && hour < 23) return 'Добрый вечер';
  return 'Доброй ночи';
}

String personalizedGreeting(String name, [DateTime? now]) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return timeGreeting(now ?? DateTime.now());
  return '${timeGreeting(now ?? DateTime.now())}, $trimmed';
}
