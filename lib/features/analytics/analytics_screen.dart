import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/analytics_summary.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/charts.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final repository = ref.watch(appRepositoryProvider);
    final summary = repository.analytics.summarize(state.entries, _period);
    final sleepCorrelation = repository.analytics.correlation(
      summary.entries.map((e) => e.sleepHours),
      summary.entries.map((e) => e.productivityScore),
    );
    final formatter = DateFormat('dd MMM');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(appStateProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                title: Text(
                  'Аналитика',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPeriodSelector(context, isDark),
                const SizedBox(height: 16),
                _buildChartSection(context, 'Сон', summary, (e) => e.sleepHours, isDark, maxY: 12, yLabels: [0, 3, 6, 9, 12]),
                const SizedBox(height: 12),
                _buildChartSection(context, 'Продуктивность', summary, (e) => e.productivityScore.toDouble(), isDark),
                const SizedBox(height: 12),
                _buildCorrelationsCard(context, sleepCorrelation, summary, isDark),
                const SizedBox(height: 12),
                _buildBestWorstRow(context, summary, formatter, isDark),
                const SizedBox(height: 12),
                _buildHeatmapCard(context, state, isDark),
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PeriodTab('Неделя', AnalyticsPeriod.week, isDark),
          _PeriodTab('Месяц', AnalyticsPeriod.month, isDark),
          _PeriodTab('Год', AnalyticsPeriod.year, isDark),
        ],
      ),
    );
  }

  Widget _PeriodTab(String label, AnalyticsPeriod period, bool isDark) {
    final isSelected = _period == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withValues(alpha: .1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isDark
                ? [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    String title,
    AnalyticsSummary summary,
    double Function(dynamic) selector,
    bool isDark, {
    double maxY = 100,
    List<double>? yLabels,
  }) {
    return Container(
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
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          LifeLineChart(entries: summary.entries, selector: selector, maxY: maxY, yLabels: yLabels),
        ],
      ),
    );
  }

  Widget _buildCorrelationsCard(BuildContext context, double corr, AnalyticsSummary summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Корреляции', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _CorrelationRow(label: 'Сон ↔ продуктивность', value: corr, isDark: isDark),
          const SizedBox(height: 8),
          _InfoRow(label: 'Средний индекс', value: summary.averageIndex.toStringAsFixed(1)),
          const SizedBox(height: 6),
          _InfoRow(label: 'Средний сон', value: '${summary.averageSleep.toStringAsFixed(1)} ч'),
        ],
      ),
    );
  }

  Widget _buildBestWorstRow(BuildContext context, AnalyticsSummary summary, DateFormat formatter, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.arrow_upward_rounded,
            color: AppColors.mint,
            title: 'Лучший день',
            value: summary.bestDay == null ? '-' : '${formatter.format(summary.bestDay!.date)} • ${summary.bestDay?.lifeIndex ?? 0}',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.arrow_downward_rounded,
            color: AppColors.coral,
            title: 'Худший день',
            value: summary.worstDay == null ? '-' : '${formatter.format(summary.worstDay!.date)} • ${summary.worstDay?.lifeIndex ?? 0}',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapCard(BuildContext context, AppState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Тепловая карта', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          CalendarHeatMap(entries: state.entries),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.mint, label: 'Отлично'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.amber, label: 'Норма'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.coral, label: 'Низко'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CorrelationRow extends StatelessWidget {
  const _CorrelationRow({required this.label, required this.value, required this.isDark});
  final String label;
  final double value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = value > 0.3 ? AppColors.mint : value < -0.3 ? AppColors.coral : AppColors.amber;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7), fontSize: 13)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6), fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.title, required this.value, required this.isDark});
  final IconData icon;
  final Color color;
  final String title;
  final String value;
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
          Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
      ],
    );
  }
}
