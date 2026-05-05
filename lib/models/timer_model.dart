import 'package:sedentary_reminder/core/constants/app_constants.dart';

/// 计时器状态实体
/// 用于跟踪番茄钟的当前状态
class TimerModel {
  final TimerStatus status;
  final int elapsedSeconds;
  final int totalSeconds;
  final bool isWorkPhase;
  final int currentCycle;
  final int cyclesCompleted;
  final int breakCount;
  final int totalWorkMinutes;

  const TimerModel({
    this.status = TimerStatus.idle,
    this.elapsedSeconds = 0,
    this.totalSeconds = AppConstants.defaultWorkDuration,
    this.isWorkPhase = true,
    this.currentCycle = 1,
    this.cyclesCompleted = 0,
    this.breakCount = 0,
    this.totalWorkMinutes = 0,
  });

  int get remainingSeconds => totalSeconds - elapsedSeconds;
  double get progress => totalSeconds > 0 ? elapsedSeconds / totalSeconds : 0.0;

  TimerModel copyWith({
    TimerStatus? status,
    int? elapsedSeconds,
    int? totalSeconds,
    bool? isWorkPhase,
    int? currentCycle,
    int? cyclesCompleted,
    int? breakCount,
    int? totalWorkMinutes,
  }) {
    return TimerModel(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isWorkPhase: isWorkPhase ?? this.isWorkPhase,
      currentCycle: currentCycle ?? this.currentCycle,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      breakCount: breakCount ?? this.breakCount,
      totalWorkMinutes: totalWorkMinutes ?? this.totalWorkMinutes,
    );
  }

  @override
  String toString() =>
      'TimerModel(status: $status, elapsed: $elapsedSeconds, remaining: $remainingSeconds)';
}

/// 计时器状态枚举
enum TimerStatus {
  idle,
  running,
  paused,
  completed,
}
