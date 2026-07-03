import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/ai_insight.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';

class AiScreen extends ConsumerWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final analysis = state.analysis;
    final history = ref.watch(appRepositoryProvider).analysisHistory();
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
                'AI Аналитика',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Обновить анализ',
                onPressed: () => ref.read(appStateProvider.notifier).refreshAnalysis(),
                icon: const Icon(Symbols.refresh_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSummaryCard(context, analysis, isDark),
                const SizedBox(height: 12),
                if (analysis != null) ...[
                  _buildScoresRow(context, analysis, isDark),
                  const SizedBox(height: 12),
                  _buildPersonaCard(context, analysis, isDark),
                  const SizedBox(height: 12),
                ],
                _buildDimensionsSection(context, analysis, isDark),
                const SizedBox(height: 12),
                _Section(title: 'Положительные факторы', insights: analysis?.positive ?? const [], color: AppColors.mint, icon: Symbols.sentiment_satisfied, isDark: isDark),
                _Section(title: 'Отрицательные факторы', insights: analysis?.negative ?? const [], color: AppColors.coral, icon: Symbols.sentiment_dissatisfied, isDark: isDark),
                _Section(title: 'Советы', insights: analysis?.advice ?? const [], color: AppColors.blue, icon: Symbols.lightbulb, isDark: isDark),
                _Section(title: 'Прогноз недели', insights: analysis?.forecast ?? const [], color: AppColors.amber, icon: Symbols.trending_up, isDark: isDark),
                if (analysis != null && analysis.patterns.isNotEmpty)
                  _Section(title: 'Закономерности', insights: analysis.patterns, color: const Color(0xFF9B8AFF), icon: Symbols.pattern, isDark: isDark),
                if (analysis != null && analysis.records.isNotEmpty)
                  _Section(title: 'Рекорды', insights: analysis.records, color: const Color(0xFFFFD700), icon: Symbols.emoji_events, isDark: isDark),
                const SizedBox(height: 12),
                _buildHistoryCard(context, history, isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresRow(BuildContext context, AiAnalysis analysis, bool isDark) {
    return Row(
      children: [
        Expanded(child: _ScoreCard(label: 'Здоровье', score: analysis.healthScore, color: AppColors.mint, isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(child: _ScoreCard(label: 'Стабильность', score: analysis.stabilityScore, color: AppColors.blue, isDark: isDark)),
      ],
    );
  }

  Widget _buildPersonaCard(BuildContext context, AiAnalysis analysis, bool isDark) {
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
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.psychology, color: AppColors.amber, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Дневной профиль', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  analysis.dayPersona,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsSection(BuildContext context, AiAnalysis? analysis, bool isDark) {
    if (analysis == null || analysis.dimensions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Оценка по направлениям', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...analysis.dimensions.map((dim) => _DimensionRow(dim: dim, isDark: isDark)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AiAnalysis? analysis, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.auto_awesome, color: AppColors.blue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis == null ? 'Локальный анализ' : analysis.summary,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (analysis != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(analysis.generatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, List<String> history, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('История анализа', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (history.isEmpty)
            Text(
              'История появится после обновления анализа.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
            )
          else
            for (final raw in history.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  raw,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.label, required this.score, required this.color, required this.isDark});

  final String label;
  final int score;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 5,
                  backgroundColor: color.withValues(alpha: .15),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$score',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({required this.dim, required this.isDark});

  final DimensionScore dim;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = _colorForRatio(dim.ratio);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForLabel(dim.label), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(dim.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Text(
                dim.detail ?? '',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
              ),
              const SizedBox(width: 8),
              Text(
                dim.grade,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dim.ratio,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForRatio(double ratio) {
    if (ratio >= 0.75) return AppColors.mint;
    if (ratio >= 0.55) return AppColors.blue;
    if (ratio >= 0.35) return AppColors.amber;
    return AppColors.coral;
  }

  IconData _iconForLabel(String label) {
    return switch (label) {
      'Сон' => Symbols.bedtime,
      'Настроение' => Symbols.sentiment_satisfied,
      'Продуктивность' => Symbols.trending_up,
      'Энергия' => Symbols.bolt,
      'Стресс' => Symbols.psychology,
      'Активность' => Symbols.fitness_center,
      'Шаги' => Symbols.directions_walk,
      'Привычки' => Symbols.check_circle,
      _ => Symbols.circle,
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.insights, required this.color, required this.icon, required this.isDark});

  final String title;
  final List<AiInsight> insights;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
          boxShadow: [
            if (!isDark)
              BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              Text(
                'Пока нет устойчивого сигнала.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
              )
            else
              for (final insight in insights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 3),
                            Text(
                              insight.description,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Уверенность ${(insight.confidence * 100).round()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
