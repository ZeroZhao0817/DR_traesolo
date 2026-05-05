import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedentary_reminder/repositories/local_notification_repository.dart';
import 'package:sedentary_reminder/repositories/local_settings_repository.dart';
import 'package:sedentary_reminder/repositories/local_timer_repository.dart';
import 'package:sedentary_reminder/repositories/notification_repository.dart';
import 'package:sedentary_reminder/repositories/settings_repository.dart';
import 'package:sedentary_reminder/repositories/timer_repository.dart';

final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  return LocalTimerRepositoryImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepositoryImpl();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return LocalNotificationRepositoryImpl();
});
