import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/ai_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/home/finish_day_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/onboarding_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/weekly_report/weekly_report_screen.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final hasProfile = ref.watch(appStateProvider.select((state) => state.profile != null));
  return GoRouter(
    initialLocation: hasProfile ? '/' : '/onboarding',
    redirect: (context, state) {
      if (!hasProfile && state.matchedLocation != '/onboarding') return '/onboarding';
      if (hasProfile && state.matchedLocation == '/onboarding') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/finish-day', builder: (context, state) => const FinishDayScreen()),
      GoRoute(path: '/weekly-report', builder: (context, state) => const WeeklyReportScreen()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/habits', builder: (context, state) => const HabitsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/ai', builder: (context, state) => const AiScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen())]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text(state.error.toString()))),
  );
});
