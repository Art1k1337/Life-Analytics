import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class PreferencesService {
  late final SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get onboardingComplete => _prefs.getBool('onboardingComplete') ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool('onboardingComplete', value);

  UserProfile? get userProfile {
    final raw = _prefs.getString('userProfile');
    if (raw == null) return null;
    return UserProfile.fromMap(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> setUserProfile(UserProfile profile) =>
      _prefs.setString('userProfile', jsonEncode(profile.toMap()));

  ThemeMode get themeMode {
    final value = _prefs.getString('themeMode') ?? ThemeMode.system.name;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString('themeMode', mode.name);

  String get languageCode => _prefs.getString('languageCode') ?? 'ru';

  Future<void> setLanguageCode(String code) => _prefs.setString('languageCode', code);
}
