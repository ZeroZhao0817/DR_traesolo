import 'package:sedentary_reminder/core/constants/app_constants.dart';

/// 应用设置实体（MVP 精简版）
class SettingsModel {
  final int workDuration;
  final int breakDuration;
  final bool showNotification;
  final String themeMode;

  const SettingsModel({
    this.workDuration = AppConstants.defaultWorkDuration,
    this.breakDuration = AppConstants.defaultBreakDuration,
    this.showNotification = true,
    this.themeMode = 'system',
  });

  SettingsModel copyWith({
    int? workDuration,
    int? breakDuration,
    bool? showNotification,
    String? themeMode,
  }) {
    return SettingsModel(
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      showNotification: showNotification ?? this.showNotification,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workDuration': workDuration,
      'breakDuration': breakDuration,
      'showNotification': showNotification ? 1 : 0,
      'themeMode': themeMode,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      workDuration:
          map['workDuration'] as int? ?? AppConstants.defaultWorkDuration,
      breakDuration:
          map['breakDuration'] as int? ?? AppConstants.defaultBreakDuration,
      showNotification: (map['showNotification'] ?? 1) == 1,
      themeMode: map['themeMode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      SettingsModel.fromMap(json);

  @override
  String toString() =>
      'SettingsModel(theme: $themeMode, work: ${workDuration / 60}min)';
}
