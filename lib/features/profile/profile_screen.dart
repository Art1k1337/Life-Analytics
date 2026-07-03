import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/elo_progress.dart';
import '../../core/models/user_profile.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final profile = state.profile;
    final completedGoals = state.goals.where((goal) => goal.achieved).length;
    final elo = state.eloProgress;
    final levelIdx = eloLevels.indexOf(elo.currentLevel) + 1;
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
                'Профиль',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Редактировать',
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Symbols.edit),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileCard(context, profile, isDark),
                const SizedBox(height: 16),
                _buildEloCard(context, elo, levelIdx, isDark),
                const SizedBox(height: 16),
                _buildStatsCard(context, state, completedGoals, isDark),
                if (!elo.isCalibrating && elo.history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildEloHistoryCard(context, elo, isDark),
                ],
                const SizedBox(height: 16),
                _buildDayHistoryCard(context, state, isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserProfile? profile, bool isDark) {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name.isNotEmpty == true ? profile!.name : 'Профиль',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (profile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${profile.age} лет · ${profile.gender.label}',
                    style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 13),
                  ),
                  Text(
                    '${profile.weightKg.toStringAsFixed(1)} кг · ${profile.heightCm} см',
                    style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEloCard(BuildContext context, EloProgress elo, int levelIdx, bool isDark) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (elo.isCalibrating ? AppColors.amber : AppColors.blue).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  elo.isCalibrating ? Icons.hourglass_top_rounded : Icons.trending_up_rounded,
                  color: elo.isCalibrating ? AppColors.amber : AppColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elo.isCalibrating ? 'Калибровка' : 'ELO рейтинг',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                      ),
                    ),
                    Text(
                      elo.isCalibrating
                          ? 'День ${elo.calibrationDay}/7'
                          : '${elo.currentElo}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (elo.isCalibrating) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: elo.calibrationDay / 7,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .05),
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Осталось ${elo.daysLeft} дней до открытия рейтинга',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Уровень $levelIdx',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    elo.currentLevel.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.violet),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: elo.levelProgress,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .05),
                color: AppColors.blue,
              ),
            ),
            if (elo.nextLevel != null) ...[
              const SizedBox(height: 6),
              Text(
                'до ${elo.nextLevel!.title} (${elo.nextLevel!.minElo})',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AppState state, int completedGoals, bool isDark) {
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
          Text(
            'Статистика',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(value: '${state.entries.length}', label: 'Записей', color: AppColors.blue),
              _StatItem(value: '${state.habits.length}', label: 'Привычек', color: AppColors.mint),
              _StatItem(value: '$completedGoals', label: 'Достижений', color: AppColors.amber),
              _StatItem(value: '${state.streak}', label: 'Серия', color: AppColors.coral),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEloHistoryCard(BuildContext context, EloProgress elo, bool isDark) {
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
          Text(
            'История ELO',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final entry in elo.history.reversed.take(10))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text(
                      'idx ${entry.index}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.deltaElo >= 0 ? '+' : ''}${entry.deltaElo}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: entry.deltaElo >= 0 ? AppColors.mint : AppColors.coral,
                      ),
                    ),
                  ),
                  Text(
                    '→ ${entry.eloAfter}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayHistoryCard(BuildContext context, AppState state, bool isDark) {
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
          Text(
            'История дней',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (state.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: EmptyState(
                icon: Symbols.calendar_month,
                title: 'Пока нет записей',
                subtitle: 'Заполни свой первый день, и он появится здесь.',
              ),
            )
          else
            for (final entry in state.entries.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      entry.dayKey,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (entry.lifeIndex >= 75 ? AppColors.mint : entry.lifeIndex >= 55 ? AppColors.amber : AppColors.coral)
                            .withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.lifeIndex}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: entry.lifeIndex >= 75
                              ? AppColors.mint
                              : entry.lifeIndex >= 55
                                  ? AppColors.amber
                                  : AppColors.coral,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }
}
