import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/repositories/app_repository.dart';
import '../../core/services/export_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _fillDay = true;
  bool _sleep = true;
  bool _water = false;
  bool _loaded = false;

  void _loadNotifState() {
    if (_loaded) return;
    _loaded = true;
    final repo = ref.read(appRepositoryProvider);
    _fillDay = repo.notifications.fillDayEnabled;
    _sleep = repo.notifications.sleepEnabled;
    _water = repo.notifications.waterEnabled;
  }

  @override
  Widget build(BuildContext context) {
    _loadNotifState();
    final settings = ref.watch(settingsViewModelProvider);
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
                'Настройки',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle(context, 'Внешний вид'),
                const SizedBox(height: 10),
                _buildThemeCard(context, ref, settings, isDark),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Язык'),
                const SizedBox(height: 10),
                _buildLanguageCard(context, ref, settings, isDark),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Уведомления'),
                const SizedBox(height: 10),
                _buildNotificationsCard(context, ref, isDark),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Виджет'),
                const SizedBox(height: 10),
                _buildWidgetCard(context, isDark),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Данные'),
                const SizedBox(height: 10),
                _buildDataCard(context, ref, isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, SettingsState settings, bool isDark) {
    return Container(
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
        children: [
          _ThemeOption(
            icon: Symbols.contrast,
            label: 'Системная',
            isSelected: settings.themeMode == ThemeMode.system,
            onTap: () => ref.read(settingsViewModelProvider.notifier).setThemeMode(ThemeMode.system),
            isDark: isDark,
          ),
          Divider(height: 1, indent: 52, color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .06)),
          _ThemeOption(
            icon: Symbols.light_mode,
            label: 'Светлая',
            isSelected: settings.themeMode == ThemeMode.light,
            onTap: () => ref.read(settingsViewModelProvider.notifier).setThemeMode(ThemeMode.light),
            isDark: isDark,
          ),
          Divider(height: 1, indent: 52, color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .06)),
          _ThemeOption(
            icon: Symbols.dark_mode,
            label: 'Тёмная',
            isSelected: settings.themeMode == ThemeMode.dark,
            onTap: () => ref.read(settingsViewModelProvider.notifier).setThemeMode(ThemeMode.dark),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, WidgetRef ref, SettingsState settings, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5B8DEF).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Symbols.language, size: 18, color: Color(0xFF5B8DEF)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Русский', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Язык приложения', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(BuildContext context, WidgetRef ref, bool isDark) {
    final repo = ref.read(appRepositoryProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        children: [
          _NotificationToggle(
            icon: Symbols.edit_calendar,
            label: 'Заполнить день',
            subtitle: 'Каждый день в 21:00',
            value: _fillDay,
            color: const Color(0xFF5B8DEF),
            onChanged: (v) async {
              setState(() => _fillDay = v);
              await repo.notifications.setFillDay(v);
            },
            isDark: isDark,
          ),
          Divider(height: 1, indent: 52, color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .06)),
          _NotificationToggle(
            icon: Symbols.bedtime,
            label: 'Пора спать',
            subtitle: 'Каждый день в 23:00',
            value: _sleep,
            color: const Color(0xFF9B8AFF),
            onChanged: (v) async {
              setState(() => _sleep = v);
              await repo.notifications.setSleep(v);
            },
            isDark: isDark,
          ),
          Divider(height: 1, indent: 52, color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .06)),
          _NotificationToggle(
            icon: Symbols.water_drop,
            label: 'Пей воду',
            subtitle: 'Каждые 2 часа с 9:00 до 19:00',
            value: _water,
            color: const Color(0xFF38BDF8),
            onChanged: (v) async {
              setState(() => _water = v);
              await repo.notifications.setWater(v);
            },
            isDark: isDark,
          ),

        ],
      ),
    );
  }

  Widget _buildWidgetCard(BuildContext context, bool isDark) {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8DEF).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.widgets, size: 18, color: Color(0xFF5B8DEF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Виджет на рабочий стол', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      'Показывает индекс дня, сон, настроение и шаги',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await HomeWidget.registerInteractivityCallback(_backgroundCallback);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Долгое нажатие на рабочем столе → Виджеты → Life Analytics')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Symbols.add, size: 18),
              label: const Text('Добавить виджет'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {}

  Widget _buildDataCard(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04)),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final entries = ref.read(appStateProvider).entries;
                if (entries.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет данных для экспорта')));
                  return;
                }
                try {
                  await ExportService.shareCsv(entries);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: _DataRow(
                icon: Symbols.table_chart,
                label: 'Экспорт CSV',
                subtitle: 'Таблица для Excel / Google Sheets',
                isDark: isDark,
              ),
            ),
          ),
          Divider(height: 24, color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .06)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final entries = ref.read(appStateProvider).entries;
                if (entries.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет данных для экспорта')));
                  return;
                }
                try {
                  await ExportService.shareJson(entries);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: _DataRow(
                icon: Symbols.data_object,
                label: 'Экспорт JSON',
                subtitle: 'Для разработчиков и бэкапов',
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label, required this.isSelected, required this.onTap, required this.isDark});

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: isSelected ? 1 : .7),
                  ),
                ),
              ),
              if (isSelected)
                Icon(Symbols.check_circle, size: 20, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.icon, required this.label, required this.subtitle, required this.isDark});

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45)),
              ),
            ],
          ),
        ),
        Icon(Symbols.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .3)),
      ],
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}
