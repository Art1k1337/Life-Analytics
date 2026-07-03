import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/day_entry.dart';
import '../../core/scoring/day_scoring.dart';
import '../../core/theme/app_colors.dart';

void showDayIndexSheet(BuildContext context, DayEntry entry) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            'Индекс дня: ${entry.lifeIndex}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Продуктивность: ${entry.productivityScore}/100',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
          ),
          const SizedBox(height: 20),
          Text('Состав индекса', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...DayScoring.lifeIndexBreakdown(entry).map((item) => _ScoreRow(item: item)),
          const SizedBox(height: 20),
          Text('Продуктивность', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...DayScoring.productivityBreakdown(entry).map((item) => _ScoreRow(item: item)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Дополнительно', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _DetailRow(icon: Symbols.fitness_center, label: 'Спорт', value: '${entry.sportMinutes} мин'),
                _DetailRow(icon: Symbols.smartphone, label: 'Экранное время', value: '${entry.screenMinutes} мин'),
                _DetailRow(icon: Symbols.sports_esports, label: 'Развлечения', value: '${entry.gameMinutes} мин'),
                _DetailRow(icon: Symbols.work, label: 'Работа / учёба', value: '${entry.workStudyMinutes} мин'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.item});

  final ScoreItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isPenalty ? AppColors.coral : AppColors.blue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Text(
                item.isPenalty ? '−${item.points.toStringAsFixed(1)}' : '+${item.points.toStringAsFixed(1)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          if (item.detail != null)
            Text(item.detail!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: item.ratio,
              color: color,
              minHeight: 5,
              backgroundColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .05),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
