/// 通知仓库接口
/// 定义通知相关的数据操作
abstract class NotificationRepository {
  /// 显示工作结束提醒
  Future<void> showWorkCompleteNotification({
    required String title,
    required String body,
  });

  /// 显示休息结束提醒
  Future<void> showBreakCompleteNotification({
    required String title,
    required String body,
  });
}
