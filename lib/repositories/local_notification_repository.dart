import 'package:flutter/foundation.dart';
import 'package:sedentary_reminder/repositories/notification_repository.dart';

/// 本地通知仓库实现（Windows 平台简化版）
/// 由于 flutter_local_notifications Windows 支持不稳定，暂不发送系统通知
class LocalNotificationRepositoryImpl implements NotificationRepository {
  static final LocalNotificationRepositoryImpl _instance =
      LocalNotificationRepositoryImpl._internal();
  factory LocalNotificationRepositoryImpl() => _instance;
  LocalNotificationRepositoryImpl._internal();

  @override
  Future<void> showWorkCompleteNotification({
    required String title,
    required String body,
  }) async {
    // 暂不发送系统通知，仅打印日志
    debugPrint('通知: $title - $body');
  }

  @override
  Future<void> showBreakCompleteNotification({
    required String title,
    required String body,
  }) async {
    // 暂不发送系统通知，仅打印日志
    debugPrint('通知: $title - $body');
  }
}
