import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/day_entry.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/greeting.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/metric_tile.dart';
import 'day_index_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static List<DayEntry> _lastDays(List<DayEntry> entries, int count) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length <= count) return sorted;
    return sorted.sublist(sorted.length - count);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final today = state.today;
    final name = state.profile?.name ?? '';
    final greeting = personalizedGreeting(name);
    final tip = state.analysis?.advice.firstOrNull;
    final tipText = tip?.description ?? 'Закончи день, чтобы получить персональный совет.';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(appStateProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                title: Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              actions: [
                const SizedBox(width: 4),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.coral.withValues(alpha: .2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Symbols.error, color: AppColors.coral, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: const TextStyle(fontSize: 13, color: AppColors.coral),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _buildFinishDayButton(context, ref, state, isDark),
                  const SizedBox(height: 20),
                  if (state.hasTodayEntry) ...[
                    _buildDayIndexCard(context, state, today, isDark),
                    const SizedBox(height: 20),
                    _buildMetricsGrid(context, today!, isDark),
                  ] else
                    _buildEmptyDayCard(context, isDark),
                  const SizedBox(height: 20),
                  RecommendationTile(title: tip?.title ?? 'Совет дня', text: tipText),
                  const SizedBox(height: 16),
                  _buildChartCard(context, state, isDark),
                  const SizedBox(height: 16),
                  _buildGoalsCard(context, state, isDark),
                  const SizedBox(height: 16),
                  _buildWeeklyReportButton(context, isDark),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishDayButton(BuildContext context, WidgetRef ref, AppState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.violet],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/finish-day'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Symbols.nightlight_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.hasTodayEntry ? 'Изменить день' : 'Закончить день',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        state.hasTodayEntry ? 'Обновить данные за сегодня' : 'Записать сон, настроение и активность',
                        style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Symbols.arrow_forward_rounded, color: Colors.white.withValues(alpha: .7), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayIndexCard(BuildContext context, AppState state, DayEntry? today, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showDayIndexSheet(context, today!),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: state.currentIndex / 100),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          backgroundColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .05),
                          color: state.currentIndex >= 75 ? AppColors.mint : AppColors.blue,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.currentIndex}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'индекс',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Индекс дня',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Нажми для подробного разбора',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniStat(label: 'Сон', value: '${today!.sleepHours.toStringAsFixed(1)}ч', color: AppColors.violet),
                        const SizedBox(width: 12),
                        _MiniStat(label: 'Настр.', value: '${today.mood}/10', color: AppColors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDayCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.wb_sunny_rounded, color: AppColors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'День ещё не завершён',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Нажми «Закончить день», чтобы записать сон, настроение и активность.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DayEntry today, bool isDark) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      children: [
        MetricTile(title: 'Сон', value: '${today.sleepHours.toStringAsFixed(1)} ч', icon: Symbols.bedtime_rounded, color: AppColors.violet),
        MetricTile(title: 'Настроение', value: '${today.mood}/10', icon: Symbols.mood, color: AppColors.amber),
        MetricTile(title: 'Продуктивность', value: '${today.productivityScore}', icon: Symbols.bolt_rounded, color: AppColors.cyan),
        MetricTile(title: 'Шаги', value: _formatSteps(today.steps), icon: Symbols.directions_walk, color: AppColors.mint),
      ],
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}к';
    return '$steps';
  }

  Widget _buildChartCard(BuildContext context, AppState state, bool isDark) {
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
          Row(
            children: [
              Text(
                'Динамика недели',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/analytics'),
                child: Text(
                  'Вся аналитика',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LifeLineChart(
            entries: _lastDays(state.entries, 7),
            selector: (entry) => entry.lifeIndex.toDouble(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(BuildContext context, AppState state, bool isDark) {
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
          Row(
            children: [
              Text(
                'Цели',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (state.streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.local_fire_department, size: 15, color: AppColors.coral),
                      const SizedBox(width: 4),
                      Text(
                        '${state.streak} дн.',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.goals.isEmpty)
            Text(
              'Добавь цель из шаблонов',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
            )
          else
            for (final goal in state.goals.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              decoration: goal.achieved ? TextDecoration.lineThrough : null,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: goal.achieved ? .4 : .85),
                            ),
                          ),
                        ),
                        Text(
                          '${(goal.progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: goal.achieved ? AppColors.mint : AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 5,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .05),
                        color: goal.achieved ? AppColors.mint : AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportButton(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/weekly-report'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Symbols.assessment, color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Недельный отчёт', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      'Сводка за неделю с трендами и советами',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Symbols.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
