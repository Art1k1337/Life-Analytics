import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models/user_profile.dart';
import '../../core/repositories/app_repository.dart';
import '../../core/theme/app_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  Gender _gender = Gender.male;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _initIfNeeded(UserProfile? profile) {
    if (_initialized || profile == null) return;
    _initialized = true;
    _nameController.text = profile.name;
    _weightController.text = profile.weightKg.toStringAsFixed(1);
    _heightController.text = profile.heightCm.toString();
    _ageController.text = profile.age.toString();
    _gender = profile.gender;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profile = UserProfile(
      name: _nameController.text.trim(),
      weightKg: double.parse(_weightController.text.replaceAll(',', '.')),
      heightCm: int.parse(_heightController.text),
      age: int.parse(_ageController.text),
      gender: _gender,
    );
    await ref.read(appStateProvider.notifier).completeOnboarding(profile);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appStateProvider).profile;
    _initIfNeeded(profile);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? Colors.white.withValues(alpha: .05) : Colors.white.withValues(alpha: .9),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: .06) : Colors.black.withValues(alpha: .04),
                ),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Имя', prefixIcon: Icon(Symbols.person_outline)),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Вес, кг'),
                          validator: (v) {
                            final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                            if (n == null || n < 30 || n > 300) return '30-300';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Рост, см'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 100 || n > 250) return '100-250';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Возраст'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 10 || n > 120) return '10-120';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Пол'),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Gender>(
                              isExpanded: true,
                              value: _gender,
                              items: Gender.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _gender = value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
