import 'package:sedentary_reminder/models/timer_model.dart';

/// 计时器仓库接口
/// 定义计时器相关的数据操作
abstract class TimerRepository {
  /// 获取当前计时器状态
  Future<TimerModel> getTimerState();

  /// 保存计时器状态
  Future<void> saveTimerState(TimerModel state);

  /// 重置计时器
  Future<void> resetTimer();
}
