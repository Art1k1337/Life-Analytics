import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/repositories/app_repository.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = AppRepository();
  await repository.initialize();
  runApp(
    ProviderScope(
      overrides: [
        appRepositoryProvider.overrideWithValue(repository),
        eloServiceProvider.overrideWithValue(repository.elo),
      ],
      child: const LifeAnalyticsApp(),
    ),
  );
}

class LifeAnalyticsApp extends ConsumerWidget {
  const LifeAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsViewModelProvider).themeMode;
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Life Analytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
