import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/habit.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(appStateProvider).habits;
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
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
                'Привычки',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showTemplates(context, ref),
                icon: const Icon(Symbols.library_add_rounded, size: 22),
              ),
              IconButton(
                onPressed: () => _showCreateHabit(context, ref),
                icon: const Icon(Symbols.add_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: habits.isEmpty
                ? SliverFillRemaining(
                    child: _buildEmptyState(context),
                  )
                : SliverList.separated(
                    itemCount: habits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final done = habit.completedDayKeys.contains(todayKey);
                      final color = Color(habit.colorValue);

                      return Dismissible(
                        key: ValueKey(habit.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Symbols.delete_rounded, color: AppColors.coral, size: 22),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Удалить привычку?'),
                              content: Text('"${habit.title}" будет удалена.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          ref.read(appStateProvider.notifier).deleteHabit(habit.id);
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => ref.read(appStateProvider.notifier).toggleHabit(habit, todayKey),
                            onLongPress: () => _showEditHabit(context, ref, habit),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
                                border: Border.all(
                                  color: done
                                      ? color.withValues(alpha: .3)
                                      : isDark
                                          ? Colors.white.withValues(alpha: .06)
                                          : Colors.black.withValues(alpha: .04),
                                ),
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 10, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: done ? color : color.withValues(alpha: .1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          done ? Symbols.check_rounded : Symbols.radio_button_unchecked,
                                          color: done ? Colors.white : color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              habit.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                decoration: done ? TextDecoration.lineThrough : null,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: done ? .5 : .9),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Серия: ${habit.streak(DateTime.now())} · Всего: ${habit.totalCompletions}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: CircularProgressIndicator(
                                          value: (habit.totalCompletions / 30).clamp(0, 1),
                                          color: color,
                                          backgroundColor: color.withValues(alpha: .1),
                                          strokeWidth: 3,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _WeekDots(habit: habit, color: color),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.check_circle_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .15)),
          const SizedBox(height: 12),
          Text(
            'Пока нет привычек',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
          ),
          const SizedBox(height: 4),
          Text(
            'Нажми + чтобы создать\nили выбери из шаблонов',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35)),
          ),
        ],
      ),
    );
  }

  Future<void> _showTemplates(BuildContext context, WidgetRef ref) async {
    final templates = [
      _HabitTemplate('Медитация 10 мин', AppColors.blue, Symbols.self_improvement),
      _HabitTemplate('Читать 30 мин', AppColors.amber, Symbols.menu_book),
      _HabitTemplate('Пить 2 л воды', const Color(0xFF38BDF8), Symbols.water_drop),
      _HabitTemplate('Прогулка 30 мин', AppColors.mint, Symbols.directions_walk),
      _HabitTemplate('Без соцсетей до обеда', AppColors.coral, Symbols.phone_disabled),
      _HabitTemplate('Утренняя зарядка', const Color(0xFFFF6B6B), Symbols.exercise),
      _HabitTemplate('Учить английский', const Color(0xFF9B8AFF), Symbols.translate),
      _HabitTemplate('Дневник благодарности', const Color(0xFFFFB347), Symbols.favorite),
    ];
    final existing = ref.read(appStateProvider).habits.map((h) => h.title).toSet();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Шаблоны привычек', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            for (final t in templates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: existing.contains(t.title)
                        ? null
                        : () {
                            ref.read(appStateProvider.notifier).addHabit(t.title, t.color.toARGB32());
                            Navigator.pop(context);
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: existing.contains(t.title)
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .03)
                            : Colors.transparent,
                        border: Border.all(
                          color: existing.contains(t.title)
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .06)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: existing.contains(t.title)
                                  ? AppColors.mint.withValues(alpha: .12)
                                  : t.color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              existing.contains(t.title) ? Symbols.check : t.icon,
                              size: 18,
                              color: existing.contains(t.title) ? AppColors.mint : t.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: existing.contains(t.title)
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .4)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateHabit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    Color selectedColor = AppColors.cyan;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colors = [
            AppColors.blue, AppColors.mint, AppColors.coral, AppColors.amber,
            const Color(0xFF9B8AFF), const Color(0xFF38BDF8), const Color(0xFFFF6B6B), const Color(0xFFFFB347),
          ];

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Новая привычка', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Название',
                    hintText: 'Например: Медитация 10 мин',
                    prefixIcon: const Icon(Symbols.check_circle_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Цвет', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((c) => GestureDetector(
                    onTap: () => setSheetState(() => selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == c ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (selectedColor == c)
                            BoxShadow(color: c.withValues(alpha: .4), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: selectedColor == c ? const Icon(Symbols.check, color: Colors.white, size: 18) : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final title = controller.text.trim();
                      if (title.isNotEmpty) {
                        ref.read(appStateProvider.notifier).addHabit(title, selectedColor.toARGB32());
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Создать', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _showEditHabit(BuildContext context, WidgetRef ref, Habit habit) async {
    final controller = TextEditingController(text: habit.title);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Редактировать', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(appStateProvider.notifier).deleteHabit(habit.id);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Symbols.delete_rounded, size: 18, color: AppColors.coral),
                    label: const Text('Удалить', style: TextStyle(color: AppColors.coral)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.coral.withValues(alpha: .3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      final title = controller.text.trim();
                      if (title.isNotEmpty) {
                        ref.read(appStateProvider.notifier).updateHabit(habit, title);
                      }
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

// ── Week dots (Mon–Sun) ──

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.habit, required this.color});

  final Habit habit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dayLabels = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];

    return Row(
      children: List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final completed = habit.completedDayKeys.contains(key);
        final isToday = key == '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final isFuture = day.isAfter(now);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Text(
                  dayLabels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isFuture
                        ? Colors.transparent
                        : completed
                            ? color
                            : color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !completed
                        ? Border.all(color: color.withValues(alpha: .5), width: 1.5)
                        : null,
                  ),
                  child: isFuture
                      ? null
                      : completed
                          ? const Icon(Symbols.check, color: Colors.white, size: 16)
                          : null,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _HabitTemplate {
  const _HabitTemplate(this.title, this.color, this.icon);

  final String title;
  final Color color;
  final IconData icon;
}
