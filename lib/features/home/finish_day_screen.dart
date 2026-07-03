import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/day_entry.dart';
import '../../core/models/elo_progress.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';

class FinishDayScreen extends ConsumerStatefulWidget {
  const FinishDayScreen({super.key});

  @override
  ConsumerState<FinishDayScreen> createState() => _FinishDayScreenState();
}

class _FinishDayScreenState extends ConsumerState<FinishDayScreen> {
  double _sleepHours = 7;
  double _mood = 7;
  double _workStudyMinutes = 240;
  double _entertainmentMinutes = 60;
  double _sportMinutes = 30;
  int _steps = 0;
  int _screenMinutes = 0;
  bool _loadingAuto = true;
  bool _screenPermission = false;
  bool _saving = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final state = ref.read(appStateProvider);
    final existing = state.today;
    if (existing != null) {
      _sleepHours = existing.sleepHours;
      _mood = existing.mood.toDouble();
      _workStudyMinutes = existing.workStudyMinutes.toDouble();
      _entertainmentMinutes = existing.gameMinutes.toDouble();
      _sportMinutes = existing.sportMinutes.toDouble();
      _steps = existing.steps;
      _screenMinutes = existing.screenMinutes;
      _noteController.text = existing.note;
    } else {
      final repo = ref.read(appRepositoryProvider);
      _steps = repo.currentSteps;
      _screenMinutes = repo.currentScreenMinutes;
      _screenPermission = await repo.screenTime.hasPermission;
    }
    if (mounted) setState(() => _loadingAuto = false);
  }

  Future<void> _refreshAutoData() async {
    setState(() => _loadingAuto = true);
    final repo = ref.read(appRepositoryProvider);
    await repo.refreshSensors();
    _steps = repo.currentSteps;
    _screenMinutes = repo.currentScreenMinutes;
    _screenPermission = await repo.screenTime.hasPermission;
    if (mounted) setState(() => _loadingAuto = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = ref.read(appStateProvider).profile;
    final existing = ref.read(appStateProvider).today;
    final work = _workStudyMinutes.round();
    final entertainment = _entertainmentMinutes.round();
    final sport = _sportMinutes.round();

    final entry = (existing ??
            DayEntry(
              date: DateTime.now(),
              sleepHours: _sleepHours,
              waterLiters: 2,
              calories: 2200,
              weightKg: profile?.weightKg ?? 0,
              steps: _steps,
              sportMinutes: sport,
              studyMinutes: work ~/ 2,
              workMinutes: work - work ~/ 2,
              gameMinutes: entertainment,
              screenMinutes: _screenMinutes,
              mood: _mood.round(),
              stress: 5,
              energy: _mood.round(),
              note: _noteController.text.trim(),
            ))
        .copyWith(
      sleepHours: _sleepHours,
      mood: _mood.round(),
      energy: _mood.round(),
      workMinutes: work - work ~/ 2,
      studyMinutes: work ~/ 2,
      gameMinutes: entertainment,
      screenMinutes: _screenMinutes,
      sportMinutes: sport,
      steps: _steps,
      note: _noteController.text.trim(),
      weightKg: profile?.weightKg ?? existing?.weightKg ?? 0,
    );

    await ref.read(appStateProvider.notifier).saveEntry(entry);
    final lifeIndex = entry.lifeIndex;
    final eloEntry = await ref.read(appStateProvider.notifier).recordEloDay(lifeIndex);
    if (mounted) {
      Navigator.of(context).pop();
      _showEloSummary(context, lifeIndex, eloEntry);
    }
  }

  void _showEloSummary(BuildContext context, int index, EloHistoryEntry eloEntry) {
    final progress = ref.read(appStateProvider).eloProgress;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              progress.isCalibrating ? 'Калибровка' : 'День завершён!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Индекс дня: $index',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.blue),
              ),
            ),
            if (progress.isCalibrating) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.calibrationDay / 7,
                  minHeight: 8,
                  color: AppColors.amber,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: .06),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'День ${progress.calibrationDay}/7 · Осталось ${progress.daysLeft}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'ELO: ${eloEntry.deltaElo >= 0 ? '+' : ''}${eloEntry.deltaElo}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: eloEntry.deltaElo >= 0 ? AppColors.mint : AppColors.coral,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Текущий: ${eloEntry.eloAfter}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${progress.currentLevel.title} · Уровень ${eloLevels.indexOf(progress.currentLevel) + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.violet),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отлично'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Закончить день')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildSliderCard(
            context,
            icon: Symbols.bedtime_rounded,
            color: AppColors.violet,
            title: 'Сон',
            value: '${_sleepHours.toStringAsFixed(1)} ч',
            slider: Slider(
              value: _sleepHours,
              min: 0,
              max: 14,
              divisions: 28,
              activeColor: AppColors.violet,
              onChanged: (v) => setState(() => _sleepHours = v),
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildSliderCard(
            context,
            icon: Symbols.mood,
            color: AppColors.amber,
            title: 'Настроение',
            value: '${_mood.round()}/10',
            slider: Slider(
              value: _mood,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: AppColors.amber,
              onChanged: (v) => setState(() => _mood = v),
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildSliderCard(
            context,
            icon: Symbols.work,
            color: AppColors.cyan,
            title: 'Работа / учёба',
            value: '${_workStudyMinutes.round()} мин',
            slider: Slider(
              value: _workStudyMinutes,
              min: 0,
              max: 720,
              divisions: 48,
              activeColor: AppColors.cyan,
              onChanged: (v) => setState(() => _workStudyMinutes = v),
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildSliderCard(
            context,
            icon: Symbols.fitness_center,
            color: AppColors.mint,
            title: 'Спорт',
            value: '${_sportMinutes.round()} мин',
            slider: Slider(
              value: _sportMinutes,
              min: 0,
              max: 180,
              divisions: 36,
              activeColor: AppColors.mint,
              onChanged: (v) => setState(() => _sportMinutes = v),
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildSliderCard(
            context,
            icon: Symbols.sports_esports,
            color: AppColors.pink,
            title: 'Развлечения',
            value: '${_entertainmentMinutes.round()} мин',
            slider: Slider(
              value: _entertainmentMinutes,
              min: 0,
              max: 480,
              divisions: 32,
              activeColor: AppColors.pink,
              onChanged: (v) => setState(() => _entertainmentMinutes = v),
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildNoteCard(context, isDark),
          const SizedBox(height: 12),
          _buildAutoDataCard(context, isDark),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.violet],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: .3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saving ? null : _save,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Symbols.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Сохранить день', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required Widget slider,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
            ],
          ),
          slider,
        ],
      ),
    );
  }

  Widget _buildAutoDataCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Symbols.directions_walk, color: AppColors.mint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _loadingAuto
                    ? Text('Загрузка...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)))
                    : Text('Шаги: $_steps', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Symbols.smartphone, color: AppColors.coral, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _loadingAuto
                    ? Text('Загрузка...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)))
                    : Text('Экран: $_screenMinutes мин', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (!_loadingAuto && !_screenPermission) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await ref.read(appRepositoryProvider).screenTime.requestPermission();
                await _refreshAutoData();
              },
              child: const Text('Разрешить доступ к экранному времени'),
            ),
          ],
          if (!_loadingAuto)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Обновить',
                onPressed: _refreshAutoData,
                icon: Icon(Symbols.refresh, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .4)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Symbols.edit_note, color: AppColors.violet, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Заметка', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Как прошёл день? Что запомнить?',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .35)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: .04) : Colors.black.withValues(alpha: .03),
            ),
          ),
        ],
      ),
    );
  }
}
