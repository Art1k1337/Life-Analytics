import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/day_entry.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/empty_state.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(appStateProvider).entries;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                'Календарь',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (entries.isEmpty)
                  EmptyState(
                    icon: Symbols.calendar_month,
                    title: 'Нет данных',
                    subtitle: 'Заполняй дневник — и календарь покажет твои дни.',
                  )
                else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04),
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 12, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Последние 35 дней',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      CalendarHeatMap(entries: entries, onDayTap: (entry) => _showDay(context, entry, isDark)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: AppColors.mint, label: 'Отлично'),
                          const SizedBox(width: 16),
                          _LegendDot(color: AppColors.amber, label: 'Норма'),
                          const SizedBox(width: 16),
                          _LegendDot(color: AppColors.coral, label: 'Низко'),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDay(BuildContext context, DayEntry entry, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.dayKey,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _DayStat(label: 'Индекс', value: '${entry.lifeIndex}', color: AppColors.blue),
                _DayStat(label: 'Продуктивность', value: '${entry.productivityScore}', color: AppColors.cyan),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _DayStat(label: 'Сон', value: '${entry.sleepHours.toStringAsFixed(1)} ч', color: AppColors.violet),
                _DayStat(label: 'Шаги', value: '${entry.steps}', color: AppColors.mint),
                _DayStat(label: 'Настроение', value: '${entry.mood}/10', color: AppColors.amber),
              ],
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.note,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
      ],
    );
  }
}

class _DayStat extends StatelessWidget {
  const _DayStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
          ],
        ),
      ),
    );
  }
}
