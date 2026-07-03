import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/analytics_summary.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final repository = ref.watch(appRepositoryProvider);
    final report = repository.analytics.weeklyReport(state.entries);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = DateFormat('dd.MM');

    return Scaffold(
      appBar: AppBar(title: const Text('Недельный отчёт')),
      body: report.isEmpty
          ? EmptyState(
              icon: Symbols.calendar_month,
              title: 'Нет данных за неделю',
              subtitle: 'Заполняй дневник каждый день, и здесь появится отчёт.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildSummaryCard(context, report, isDark, ref),
                const SizedBox(height: 12),
                _buildDiffCard(context, report, isDark),
                const SizedBox(height: 12),
                _buildMetricsGrid(context, report, isDark),
                if (report.bestDay != null && report.worstDay != null) ...[
                  const SizedBox(height: 12),
                  _buildBestWorstRow(context, report, formatter, isDark),
                ],
                const SizedBox(height: 12),
                _buildAdviceCard(context, report, isDark, ref),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WeeklyReport report, bool isDark, WidgetRef ref) {
    final analysis = ref.watch(appStateProvider).analysis;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${report.averageIndex.round()}',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const Text(
            'средний индекс за неделю',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.days} ${_dayLabel(report.days)}',
            style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 12),
          ),
          if (analysis != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreBadge(label: 'Здоровье', score: analysis.healthScore),
                const SizedBox(width: 16),
                _ScoreBadge(label: 'Стабильность', score: analysis.stabilityScore),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffCard(BuildContext context, WeeklyReport report, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сравнение с прошлой неделей',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _DiffRow(label: 'Индекс', value: report.indexDiff, isPercent: false),
          const SizedBox(height: 8),
          _DiffRow(label: 'Сон', value: report.sleepDiff, suffix: 'ч', isPercent: false),
          const SizedBox(height: 8),
          _DiffRow(label: 'Шаги', value: report.stepsDiff, isPercent: false),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, WeeklyReport report, bool isDark) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      children: [
        _MetricCard(
          icon: Symbols.bedtime_rounded,
          color: AppColors.violet,
          label: 'Сон',
          value: '${report.averageSleep.toStringAsFixed(1)} ч',
          isDark: isDark,
        ),
        _MetricCard(
          icon: Symbols.mood,
          color: AppColors.amber,
          label: 'Настроение',
          value: '${report.averageMood.toStringAsFixed(1)}/10',
          isDark: isDark,
        ),
        _MetricCard(
          icon: Symbols.directions_walk,
          color: AppColors.mint,
          label: 'Шаги',
          value: _formatSteps(report.averageSteps.round()),
          isDark: isDark,
        ),
        _MetricCard(
          icon: Symbols.fitness_center,
          color: AppColors.cyan,
          label: 'Спорт',
          value: '${report.totalSport} мин',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBestWorstRow(BuildContext context, WeeklyReport report, DateFormat formatter, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _DayCard(
            icon: Symbols.arrow_upward_rounded,
            color: AppColors.mint,
            title: 'Лучший день',
            date: formatter.format(report.bestDay!.date),
            index: report.bestDay!.lifeIndex,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DayCard(
            icon: Symbols.arrow_downward_rounded,
            color: AppColors.coral,
            title: 'Худший день',
            date: formatter.format(report.worstDay!.date),
            index: report.worstDay!.lifeIndex,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceCard(BuildContext context, WeeklyReport report, bool isDark, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final analysis = state.analysis;

    final adviceLines = <String>[];
    if (analysis != null) {
      for (final a in analysis.advice.take(2)) {
        adviceLines.add(a.description);
      }
    }
    if (adviceLines.isEmpty) {
      if (report.averageIndex >= 75) {
        adviceLines.add('Отличная неделя! Сохрани текущий режим сна и активности.');
      } else if (report.averageIndex >= 55) {
        adviceLines.add('Нормальная неделя. Попробуй увеличить сон до 8 часов и добавить 30 минут спорта.');
      } else {
        adviceLines.add('Сложная неделя. Начни с малого: ложись на 30 минут раньше и сделай короткую прогулку.');
      }
    }
    final advice = adviceLines.join('\n');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2548), const Color(0xFF1A1D2E)]
              : [const Color(0xFFEEF2FF), const Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: .06) : AppColors.blue.withValues(alpha: .1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Symbols.auto_awesome, color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Совет на следующую неделю', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}к';
    return '$steps';
  }

  String _dayLabel(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'дня';
    return 'дней';
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .7)),
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.label, required this.value, this.suffix = '', required this.isPercent});

  final String label;
  final double value;
  final String suffix;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final color = value.abs() < 1 ? Colors.grey : (isPositive ? AppColors.mint : AppColors.coral);
    final sign = isPositive ? '+' : '';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$sign${value.toStringAsFixed(1)}$suffix',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.date,
    required this.index,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String date;
  final int index;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
          const SizedBox(height: 2),
          Text('$date • $index', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
