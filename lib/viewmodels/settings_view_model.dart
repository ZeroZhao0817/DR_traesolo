import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedentary_reminder/models/settings_model.dart';
import 'package:sedentary_reminder/repositories/settings_repository.dart';
import 'package:sedentary_reminder/repositories/repository_providers.dart';

/// 设置状态 Provider
final settingsProvider =
    StateNotifierProvider<SettingsViewModel, SettingsModel>((ref) {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return SettingsViewModel(settingsRepository: settingsRepository);
});

/// 设置状态管理器（MVP 精简版）
class SettingsViewModel extends StateNotifier<SettingsModel> {
  final SettingsRepository _repository;

  SettingsViewModel({required SettingsRepository settingsRepository})
      : _repository = settingsRepository,
        super(const SettingsModel()) {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final settings = await _repository.getSettings();
    state = settings;
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    await _repository.saveSettings(state);
  }

  /// 更新工作时长
  Future<void> updateWorkDuration(int duration) async {
    state = state.copyWith(workDuration: duration);
    await _saveSettings();
  }

  /// 更新休息时长
  Future<void> updateBreakDuration(int duration) async {
    state = state.copyWith(breakDuration: duration);
    await _saveSettings();
  }

  /// 更新主题
  Future<void> updateTheme(String themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  /// 更新主题（别名）
  Future<void> updateThemeMode(String themeMode) async {
    await updateTheme(themeMode);
  }

  /// 更新通知开关
  Future<void> updateShowNotification(bool showNotification) async {
    state = state.copyWith(showNotification: showNotification);
    await _saveSettings();
  }
}
