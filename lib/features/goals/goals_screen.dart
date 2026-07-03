import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/life_goal.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final goals = state.goals;
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
                'Цели',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showCreateGoal(context, ref),
                icon: const Icon(Symbols.add_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStreakCard(context, state, isDark),
                const SizedBox(height: 16),
                if (goals.isEmpty)
                  _buildEmptyCard(context, isDark)
                else
                  ...goals.map((goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalTile(goal: goal, isDark: isDark),
                      )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, AppState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1B0E), const Color(0xFF1A1D26)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFFFBF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.coral.withValues(alpha: .15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.local_fire_department, color: AppColors.coral, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Стрик: ${state.streak} ${_dayLabel(state.streak)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Подряд дней с заполненным дневником',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        children: [
          Icon(Symbols.flag_rounded, size: 40, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .2)),
          const SizedBox(height: 12),
          Text('Пока нет целей', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
          const SizedBox(height: 4),
          Text('Нажми + чтобы создать цель', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4))),
        ],
      ),
    );
  }

  String _dayLabel(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'дня';
    return 'дней';
  }

  void _showCreateGoal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CreateGoalSheet(ref: ref),
    );
  }
}

// ── Goal Tile ──

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal, required this.isDark});

  final LifeGoal goal;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(goal.id),
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
            title: const Text('Удалить цель?'),
            content: Text('"${goal.title}" будет удалена безвозвратно.'),
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
        ref.read(appStateProvider.notifier).deleteGoal(goal.id);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditGoal(context, ref),
          borderRadius: BorderRadius.circular(16),
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
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: goal.achieved ? AppColors.mint.withValues(alpha: .15) : AppColors.blue.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        goal.achieved ? Symbols.check_circle : _iconForMetric(goal.metric),
                        size: 18,
                        color: goal.achieved ? AppColors.mint : AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        goal.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          decoration: goal.achieved ? TextDecoration.lineThrough : null,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: goal.achieved ? .4 : .9),
                        ),
                      ),
                    ),
                    if (goal.achieved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.mint)),
                      ),
                    if (!goal.achieved)
                      Icon(Symbols.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .25)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 7,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .05),
                    color: goal.achieved ? AppColors.mint : AppColors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${(goal.progress * 100).round()}% · ${goal.current.toStringAsFixed(0)} / ${goal.target.toStringAsFixed(0)} ${goal.unit}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
                    ),
                    const Spacer(),
                    Text(DateFormat('dd.MM').format(goal.dueDate), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4))),
                    if (goal.autoTrack) ...[
                      const SizedBox(width: 6),
                      Icon(Symbols.sync, size: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditGoal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _EditGoalSheet(goal: goal, ref: ref),
    );
  }

  IconData _iconForMetric(GoalMetric metric) {
    return switch (metric) {
      GoalMetric.steps => Symbols.directions_walk,
      GoalMetric.studyMinutes => Symbols.school,
      GoalMetric.workStudyMinutes => Symbols.work,
      GoalMetric.sportMinutes => Symbols.fitness_center,
      GoalMetric.sleepHours => Symbols.bedtime,
      GoalMetric.mood => Symbols.sentiment_satisfied,
      GoalMetric.lifeIndex => Symbols.auto_awesome,
      GoalMetric.productivity => Symbols.trending_up,
      GoalMetric.custom => Symbols.flag,
    };
  }
}

// ── Create Goal Sheet (templates + custom) ──

class _CreateGoalSheet extends StatefulWidget {
  const _CreateGoalSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  GoalMetric _metric = GoalMetric.custom;
  bool _autoTrack = false;
  int _days = 30;
  bool _showCustom = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final dueDate = DateTime.now().add(Duration(days: _days));
    final templates = LifeGoal.templates(dueDate);
    final existing = widget.ref.read(appStateProvider).goals.map((g) => g.title).toSet();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_showCustom ? 'Новая цель' : 'Добавить цель', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              _showCustom ? 'Создай свою цель' : 'Выбери шаблон или создай свою',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (!_showCustom) ...[
              for (final template in templates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: existing.contains(template.title)
                          ? null
                          : () {
                              widget.ref.read(appStateProvider.notifier).addGoalTemplate(template);
                              Navigator.pop(context);
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: existing.contains(template.title)
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .03)
                              : Colors.transparent,
                          border: Border.all(
                            color: existing.contains(template.title)
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
                                color: existing.contains(template.title)
                                    ? AppColors.mint.withValues(alpha: .12)
                                    : AppColors.blue.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                existing.contains(template.title) ? Symbols.check : _iconForMetric(template.metric),
                                size: 18,
                                color: existing.contains(template.title) ? AppColors.mint : AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: existing.contains(template.title)
                                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .4)
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    '${template.target.toStringAsFixed(0)} ${template.unit}',
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showCustom = true),
                  icon: const Icon(Symbols.add_rounded, size: 18),
                  label: const Text('Создать свою цель'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например: Бегать каждое утро',
                  prefixIcon: const Icon(Symbols.flag_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Цель',
                        hintText: '100',
                        prefixIcon: const Icon(Symbols.track_changes, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Ед.',
                        hintText: 'шт',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Метрика', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(label: 'Своя', icon: Symbols.flag, selected: _metric == GoalMetric.custom, onTap: () => setState(() { _metric = GoalMetric.custom; _autoTrack = false; })),
                  _MetricChip(label: 'Шаги', icon: Symbols.directions_walk, selected: _metric == GoalMetric.steps, onTap: () => _selectMetric(GoalMetric.steps, 'шагов')),
                  _MetricChip(label: 'Спорт', icon: Symbols.fitness_center, selected: _metric == GoalMetric.sportMinutes, onTap: () => _selectMetric(GoalMetric.sportMinutes, 'мин')),
                  _MetricChip(label: 'Учёба', icon: Symbols.school, selected: _metric == GoalMetric.studyMinutes, onTap: () => _selectMetric(GoalMetric.studyMinutes, 'мин')),
                  _MetricChip(label: 'Сон', icon: Symbols.bedtime, selected: _metric == GoalMetric.sleepHours, onTap: () => _selectMetric(GoalMetric.sleepHours, 'ч')),
                  _MetricChip(label: 'Настроение', icon: Symbols.sentiment_satisfied, selected: _metric == GoalMetric.mood, onTap: () => _selectMetric(GoalMetric.mood, '/10')),
                ],
              ),
              const SizedBox(height: 14),
              Text('Срок', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [7, 14, 30, 60, 90].map((d) => ChoiceChip(
                  label: Text('$d дн'),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _days = d),
                  selectedColor: AppColors.blue.withValues(alpha: .15),
                  labelStyle: TextStyle(fontWeight: _days == d ? FontWeight.w700 : FontWeight.w500, color: _days == d ? AppColors.blue : null),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _canCreate() ? _create : null,
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Создать цель', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectMetric(GoalMetric metric, String unit) {
    setState(() {
      _metric = metric;
      _autoTrack = true;
      _unitCtrl.text = unit;
    });
  }

  bool _canCreate() => _titleCtrl.text.trim().isNotEmpty && _targetCtrl.text.trim().isNotEmpty;

  void _create() {
    final target = double.tryParse(_targetCtrl.text.trim());
    if (target == null || target <= 0) return;

    final goal = LifeGoal(
      title: _titleCtrl.text.trim(),
      target: target,
      current: 0,
      unit: _unitCtrl.text.trim().isNotEmpty ? _unitCtrl.text.trim() : 'шт',
      dueDate: DateTime.now().add(Duration(days: _days)),
      metric: _metric,
      autoTrack: _autoTrack,
    );

    widget.ref.read(appStateProvider.notifier).addGoalTemplate(goal);
    Navigator.pop(context);
  }

  IconData _iconForMetric(GoalMetric metric) {
    return switch (metric) {
      GoalMetric.steps => Symbols.directions_walk,
      GoalMetric.studyMinutes => Symbols.school,
      GoalMetric.workStudyMinutes => Symbols.work,
      GoalMetric.sportMinutes => Symbols.fitness_center,
      GoalMetric.sleepHours => Symbols.bedtime,
      GoalMetric.mood => Symbols.sentiment_satisfied,
      GoalMetric.lifeIndex => Symbols.auto_awesome,
      GoalMetric.productivity => Symbols.trending_up,
      GoalMetric.custom => Symbols.flag,
    };
  }
}

// ── Edit Goal Sheet ──

class _EditGoalSheet extends StatefulWidget {
  const _EditGoalSheet({required this.goal, required this.ref});

  final LifeGoal goal;
  final WidgetRef ref;

  @override
  State<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<_EditGoalSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.goal.title);
    _targetCtrl = TextEditingController(text: widget.goal.target.toStringAsFixed(0));
    _currentCtrl = TextEditingController(text: widget.goal.current.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Редактировать', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              widget.goal.autoTrack ? 'Автотрекинг · ${widget.goal.metric.label}' : 'Ручная цель',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Название',
                prefixIcon: const Icon(Symbols.edit_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Цель', suffixText: widget.goal.unit, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _currentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Текущий', suffixText: widget.goal.unit, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.ref.read(appStateProvider.notifier).deleteGoal(widget.goal.id);
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
                    onPressed: _save,
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
  }

  void _save() {
    final target = double.tryParse(_targetCtrl.text.trim());
    final current = double.tryParse(_currentCtrl.text.trim());
    if (target == null || target <= 0) return;

    final updated = LifeGoal(
      id: widget.goal.id,
      title: _titleCtrl.text.trim(),
      target: target,
      current: current ?? widget.goal.current,
      unit: widget.goal.unit,
      dueDate: widget.goal.dueDate,
      metric: widget.goal.metric,
      autoTrack: widget.goal.autoTrack,
    );

    widget.ref.read(appStateProvider.notifier).addGoalTemplate(updated);
    Navigator.pop(context);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? AppColors.blue.withValues(alpha: .12) : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.blue.withValues(alpha: .4) : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.blue : Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.blue : Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
            ],
          ),
        ),
      ),
    );
  }
}
