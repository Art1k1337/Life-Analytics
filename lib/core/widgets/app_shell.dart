import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(icon: Icon(Symbols.home), selectedIcon: Icon(Symbols.home, fill: 1), label: 'Главная'),
          NavigationDestination(icon: Icon(Symbols.monitoring), selectedIcon: Icon(Symbols.monitoring, fill: 1), label: 'Аналитика'),
          NavigationDestination(icon: Icon(Symbols.checklist), selectedIcon: Icon(Symbols.checklist, fill: 1), label: 'Привычки'),
          NavigationDestination(icon: Icon(Symbols.flag), selectedIcon: Icon(Symbols.flag, fill: 1), label: 'Цели'),
          NavigationDestination(icon: Icon(Symbols.calendar_month), selectedIcon: Icon(Symbols.calendar_month, fill: 1), label: 'Календарь'),
          NavigationDestination(icon: Icon(Symbols.auto_awesome), selectedIcon: Icon(Symbols.auto_awesome, fill: 1), label: 'AI'),
          NavigationDestination(icon: Icon(Symbols.person), selectedIcon: Icon(Symbols.person, fill: 1), label: 'Профиль'),
          NavigationDestination(icon: Icon(Icons.settings), selectedIcon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
