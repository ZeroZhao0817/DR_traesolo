import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedentary_reminder/models/settings_model.dart';
import 'package:sedentary_reminder/repositories/settings_repository.dart';

/// 本地设置仓库实现（MVP 精简版）
class LocalSettingsRepositoryImpl implements SettingsRepository {
  static final LocalSettingsRepositoryImpl _instance =
      LocalSettingsRepositoryImpl._internal();
  factory LocalSettingsRepositoryImpl() => _instance;
  LocalSettingsRepositoryImpl._internal();

  static const String _settingsKey = 'app_settings';

  @override
  Future<SettingsModel> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson == null) {
      return const SettingsModel();
    }

    return SettingsModel.fromJson(jsonDecode(settingsJson));
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<void> updateSetting(String key, dynamic value) async {
    final settings = await getSettings();
    final updatedSettings = switch (key) {
      'workDuration' => settings.copyWith(workDuration: value as int),
      'breakDuration' => settings.copyWith(breakDuration: value as int),
      'themeMode' => settings.copyWith(themeMode: value as String),
      'showNotification' => settings.copyWith(showNotification: value as bool),
      _ => settings,
    };
    await saveSettings(updatedSettings);
  }
}
