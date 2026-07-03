import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final samples = const [
      ('Не забудь заполнить день', Symbols.edit_calendar, AppColors.blue),
      ('Сегодня мало активности', Symbols.directions_walk, AppColors.amber),
      ('Рекомендуется раньше лечь спать', Symbols.bedtime, AppColors.violet),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: samples.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final (text, icon, color) = samples[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                IconButton(
                  tooltip: 'Показать',
                  onPressed: () => ref.read(appRepositoryProvider).notifications.showNow('Life Analytics', text),
                  icon: Icon(Symbols.send_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
