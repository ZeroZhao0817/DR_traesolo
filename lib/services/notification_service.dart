import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedentary_reminder/repositories/notification_repository.dart';
import 'package:sedentary_reminder/repositories/repository_providers.dart';

/// 通知服务 Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationService(repository: repository);
});

/// 通知服务
class NotificationService {
  final NotificationRepository _repository;

  NotificationService({required NotificationRepository repository})
      : _repository = repository;

  /// 显示工作结束提醒
  Future<void> showWorkComplete({
    required int cycleNumber,
    required bool isLongBreak,
  }) async {
    final title = isLongBreak ? '🎉 长休息时间到！' : '⏰ 工作时间到！';
    final body = isLongBreak
        ? '恭喜完成第 $cycleNumber 轮！休息一下吧～'
        : '第 $cycleNumber 轮工作完成，该休息啦！';

    await _repository.showWorkCompleteNotification(
      title: title,
      body: body,
    );
  }

  /// 显示休息结束提醒
  Future<void> showBreakComplete({
    required int cycleNumber,
  }) async {
    await _repository.showBreakCompleteNotification(
      title: '☕ 休息结束！',
      body: '准备开始第 $cycleNumber 轮工作吧！',
    );
  }
}
