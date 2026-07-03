import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ai_insight.dart';
import '../models/day_entry.dart';
import '../models/habit.dart';
import '../models/life_goal.dart';
import '../models/user_profile.dart';
import '../models/elo_progress.dart';
import '../services/ai_engine.dart';
import '../services/analytics_service.dart';
import '../services/elo_service.dart';
import '../services/notification_service.dart';
import '../services/screen_time_service.dart';
import '../services/steps_service.dart';
import '../services/widget_service.dart';
import '../storage/database_service.dart';
import '../storage/hive_service.dart';
import '../storage/preferences_service.dart';
import '../scoring/day_scoring.dart';
import '../theme/app_colors.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) => throw UnimplementedError());

final eloServiceProvider = Provider<EloService>((ref) => throw UnimplementedError());

final appStateProvider = StateNotifierProvider<AppViewModel, AppState>((ref) {
  return AppViewModel(ref.watch(appRepositoryProvider))..load();
});

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel(ref.watch(appRepositoryProvider));
});

class AppRepository {
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferences = PreferencesService();
  final HiveService _hive = HiveService();
  final AnalyticsService analytics = AnalyticsService();
  late final AiEngine aiEngine = AiEngine(analytics);
  final EloService elo = EloService();
  final NotificationService notifications = NotificationService();
  final ScreenTimeService screenTime = ScreenTimeService();
  final StepsService steps = StepsService();

  int _currentSteps = 0;
  int _currentScreenMinutes = 0;
  Timer? _autoRefreshTimer;

  int get currentSteps => _currentSteps;
  int get currentScreenMinutes => _currentScreenMinutes;

  Future<void> initialize() async {
    await _preferences.initialize();
    await _hive.initialize();
    await elo.initialize();
    try {
      await notifications.initialize();
      await notifications.requestPermission();
      await notifications.scheduleAll();
    } catch (_) {}
    await _seedIfNeeded();
    await _requestSensorPermissions();
    await _refreshSensorData();
    _startAutoRefresh();
  }

  Future<void> _requestSensorPermissions() async {
    try {
      await screenTime.requestPermission();
    } catch (_) {}
    try {
      await steps.fetchTodaySteps();
    } catch (_) {}
  }

  Future<void> _refreshSensorData() async {
    try {
      _currentSteps = await steps.fetchTodaySteps().timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      _currentScreenMinutes = await screenTime.fetchTodayScreenMinutes().timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      await _refreshSensorData();
    });
  }

  Future<void> refreshSensors() async {
    await _refreshSensorData();
  }

  void dispose() {
    _autoRefreshTimer?.cancel();
    steps.dispose();
  }

  bool get onboardingComplete => _preferences.onboardingComplete;
  UserProfile? get userProfile => _preferences.userProfile;
  ThemeMode get themeMode => _preferences.themeMode;
  String get languageCode => _preferences.languageCode;

  Future<void> saveProfile(UserProfile profile) async {
    await _preferences.setUserProfile(profile);
    await _preferences.setOnboardingComplete(true);
  }

  Future<void> setThemeMode(ThemeMode mode) => _preferences.setThemeMode(mode);
  Future<void> setLanguageCode(String code) => _preferences.setLanguageCode(code);

  Future<List<DayEntry>> getEntries() async {
    final db = await _databaseService.database;
    final rows = await db.query('day_entries', orderBy: 'date DESC');
    return rows.map(DayEntry.fromMap).toList();
  }

  Future<DayEntry?> getEntryForDate(DateTime date) async {
    final db = await _databaseService.database;
    final key = DayEntry.keyFor(date);
    final rows = await db.query(
      'day_entries',
      where: 'date LIKE ?',
      whereArgs: ['$key%'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayEntry.fromMap(rows.first);
  }

  Future<void> saveEntry(DayEntry entry) async {
    final db = await _databaseService.database;
    final existing = await getEntryForDate(entry.date);
    final toSave = existing == null ? entry : entry.copyWith(id: existing.id);
    await db.insert('day_entries', toSave.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await _syncAutoGoals(toSave);
  }

  Future<void> syncGoalsFromToday() async {
    final today = await getEntryForDate(DateTime.now());
    final goals = await getGoals();
    for (final goal in goals.where((g) => g.autoTrack && g.metric != GoalMetric.custom)) {
      await saveGoal(goal.copyWith(current: today == null ? 0 : goal.valueFromEntry(today)));
    }
  }

  Future<List<Habit>> getHabits() async {
    final db = await _databaseService.database;
    final rows = await db.query('habits', orderBy: 'createdAt DESC');
    return rows.map(Habit.fromMap).toList();
  }

  Future<void> saveHabit(Habit habit) async {
    final db = await _databaseService.database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHabit(String id) async {
    final db = await _databaseService.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LifeGoal>> getGoals() async {
    final db = await _databaseService.database;
    final rows = await db.query('goals', orderBy: 'dueDate ASC');
    return rows.map(LifeGoal.fromMap).toList();
  }

  Future<void> _syncAutoGoals(DayEntry entry) async {
    final goals = await getGoals();
    for (final goal in goals.where((g) => g.autoTrack && g.metric != GoalMetric.custom)) {
      await saveGoal(goal.copyWith(current: goal.valueFromEntry(entry)));
    }
  }

  Future<void> saveGoal(LifeGoal goal) async {
    final db = await _databaseService.database;
    await db.insert('goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGoal(String id) async {
    final db = await _databaseService.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<AiAnalysis> refreshAnalysis() async {
    final analysis = aiEngine.analyze(
      entries: await getEntries(),
      habits: await getHabits(),
      goals: await getGoals(),
      profile: userProfile,
    );
    await _hive.analysisHistory.add(jsonEncode({
      'generatedAt': analysis.generatedAt.toIso8601String(),
      'summary': analysis.summary,
    }));
    return analysis;
  }

  List<String> analysisHistory() => _hive.analysisHistory.values.toList().reversed.toList();

  Future<void> _seedIfNeeded() async {
    final db = await _databaseService.database;
    final habitCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM habits')) ?? 0;
    if (habitCount > 0) return;
    final today = DateTime.now();
    await db.insert(
      'habits',
      Habit(title: 'Сон до 23:30', colorValue: AppColors.blue.toARGB32(), createdAt: today).toMap(),
    );
    await db.insert(
      'habits',
      Habit(title: '30 минут движения', colorValue: AppColors.mint.toARGB32(), createdAt: today).toMap(),
    );
  }
}

class AppState {
  const AppState({
    required this.loading,
    required this.entries,
    required this.habits,
    required this.goals,
    required this.analysis,
    required this.error,
    required this.onboardingComplete,
    required this.profile,
    required this.eloProgress,
  });

  final bool loading;
  final List<DayEntry> entries;
  final List<Habit> habits;
  final List<LifeGoal> goals;
  final AiAnalysis? analysis;
  final String? error;
  final bool onboardingComplete;
  final UserProfile? profile;
  final EloProgress eloProgress;

  DayEntry? get today {
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final entry in entries) {
      if (entry.dayKey == key) return entry;
    }
    return null;
  }

  bool get hasTodayEntry => today != null;
  int get currentIndex => today?.lifeIndex ?? 0;
  int get streak => calculateDayStreak(entries);

  AppState copyWith({
    bool? loading,
    List<DayEntry>? entries,
    List<Habit>? habits,
    List<LifeGoal>? goals,
    AiAnalysis? analysis,
    String? error,
    bool? onboardingComplete,
    UserProfile? profile,
    EloProgress? eloProgress,
  }) =>
      AppState(
        loading: loading ?? this.loading,
        entries: entries ?? this.entries,
        habits: habits ?? this.habits,
        goals: goals ?? this.goals,
        analysis: analysis ?? this.analysis,
        error: error,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        profile: profile ?? this.profile,
        eloProgress: eloProgress ?? this.eloProgress,
      );

  factory AppState.initial(AppRepository repository) => AppState(
        loading: true,
        entries: const [],
        habits: const [],
        goals: const [],
        analysis: null,
        error: null,
        onboardingComplete: repository.onboardingComplete,
        profile: repository.userProfile,
        eloProgress: EloProgress.initial(),
      );
}

class AppViewModel extends StateNotifier<AppState> {
  AppViewModel(this._repository) : super(AppState.initial(_repository));

  final AppRepository _repository;

  Future<void> load() async {
    try {
      await _repository.syncGoalsFromToday();
      final entries = await _repository.getEntries();
      final habits = await _repository.getHabits();
      final goals = await _repository.getGoals();
      final profile = _repository.userProfile;
      final analysis = _repository.aiEngine.analyze(entries: entries, habits: habits, goals: goals, profile: profile);
      state = state.copyWith(
        loading: false,
        entries: entries,
        habits: habits,
        goals: goals,
        analysis: analysis,
        onboardingComplete: _repository.onboardingComplete,
        profile: profile,
        eloProgress: _repository.elo.progress,
      );

      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DayEntry? todayEntry;
      for (final e in entries) {
        if (e.dayKey == todayKey) {
          todayEntry = e;
          break;
        }
      }
      await WidgetService.updateWidget(todayEntry);
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<EloHistoryEntry> recordEloDay(int index) async {
    final entry = await _repository.elo.recordDay(index);
    state = state.copyWith(eloProgress: _repository.elo.progress);
    return entry;
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    await _repository.saveProfile(profile);
    state = state.copyWith(onboardingComplete: true, profile: profile);
  }

  Future<void> saveEntry(DayEntry entry) async {
    await _repository.saveEntry(entry);
    try {
      await _repository.refreshAnalysis().timeout(const Duration(seconds: 10));
    } catch (_) {}
    await load();
    unawaited(WidgetService.updateWidget(entry));
  }

  Future<void> addHabit(String title, int colorValue) async {
    await _repository.saveHabit(Habit(title: title, colorValue: colorValue, createdAt: DateTime.now()));
    await load();
  }

  Future<void> toggleHabit(Habit habit, String dayKey) async {
    await _repository.saveHabit(habit.toggle(dayKey));
    await load();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    await load();
  }

  Future<void> updateHabit(Habit habit, String title) async {
    await _repository.saveHabit(habit.copyWith(title: title));
    await load();
  }

  Future<void> addGoal(String title, double target, String unit) async {
    await _repository.saveGoal(
      LifeGoal(
        title: title,
        target: target,
        current: 0,
        unit: unit,
        dueDate: DateTime.now().add(const Duration(days: 45)),
      ),
    );
    await load();
  }

  Future<void> addGoalTemplate(LifeGoal template) async {
    await _repository.saveGoal(template);
    await load();
  }

  Future<void> updateGoal(LifeGoal goal, double current) async {
    await _repository.saveGoal(goal.copyWith(current: current));
    await load();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
    await load();
  }

  Future<void> refreshAnalysis() async {
    final analysis = await _repository.refreshAnalysis();
    state = state.copyWith(analysis: analysis);
  }
}

class SettingsState {
  const SettingsState({required this.themeMode, required this.languageCode});

  final ThemeMode themeMode;
  final String languageCode;

  SettingsState copyWith({ThemeMode? themeMode, String? languageCode}) =>
      SettingsState(themeMode: themeMode ?? this.themeMode, languageCode: languageCode ?? this.languageCode);
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel(this._repository)
      : super(SettingsState(themeMode: _repository.themeMode, languageCode: _repository.languageCode));

  final AppRepository _repository;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLanguageCode(String code) async {
    await _repository.setLanguageCode(code);
    state = state.copyWith(languageCode: code);
  }
}
