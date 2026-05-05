import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedentary_reminder/models/timer_model.dart';
import 'package:sedentary_reminder/repositories/timer_repository.dart';
import 'package:sedentary_reminder/repositories/settings_repository.dart';
import 'package:sedentary_reminder/repositories/repository_providers.dart';
import 'package:sedentary_reminder/services/notification_service.dart';

/// 计时器状态 Provider
final timerStateProvider =
    StateNotifierProvider<TimerViewModel, TimerModel>((ref) {
  final timerRepository = ref.watch(timerRepositoryProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return TimerViewModel(
    timerRepository: timerRepository,
    settingsRepository: settingsRepository,
    notificationService: notificationService,
  );
});

/// 计时器状态管理器（MVP 精简版）
class TimerViewModel extends StateNotifier<TimerModel> {
  Timer? _timer;
  final TimerRepository _timerRepository;
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;

  TimerViewModel({
    required TimerRepository timerRepository,
    required SettingsRepository settingsRepository,
    required NotificationService notificationService,
  })  : _timerRepository = timerRepository,
        _settingsRepository = settingsRepository,
        _notificationService = notificationService,
        super(const TimerModel()) {
    _loadInitialSettings();
  }

  /// 加载初始设置
  Future<void> _loadInitialSettings() async {
    final settings = await _settingsRepository.getSettings();
    state = state.copyWith(
      totalSeconds: settings.workDuration,
      isWorkPhase: true,
    );
  }

  /// 开始计时
  Future<void> startTimer() async {
    if (state.status == TimerStatus.running ||
        state.status == TimerStatus.completed) {
      return;
    }

    state = state.copyWith(status: TimerStatus.running);
    await _timerRepository.saveTimerState(state);
    _startCountdown();
  }

  /// 暂停计时
  Future<void> pauseTimer() async {
    if (state.status != TimerStatus.running) return;

    state = state.copyWith(status: TimerStatus.paused);
    _timer?.cancel();
    _timer = null;
    await _timerRepository.saveTimerState(state);
  }

  /// 恢复计时
  Future<void> resumeTimer() async {
    if (state.status != TimerStatus.paused) return;

    state = state.copyWith(status: TimerStatus.running);
    await _timerRepository.saveTimerState(state);
    _startCountdown();
  }

  /// 重置计时
  Future<void> resetTimer({int? totalSeconds}) async {
    _timer?.cancel();
    _timer = null;

    final settings = await _settingsRepository.getSettings();
    state = TimerModel(
      status: TimerStatus.idle,
      elapsedSeconds: 0,
      totalSeconds: totalSeconds ??
          (state.isWorkPhase ? settings.workDuration : settings.breakDuration),
      isWorkPhase: state.isWorkPhase,
    );
    await _timerRepository.resetTimer();
  }

  /// 重启当前阶段（休息完成后续休息，或工作完成后继续工作）
  Future<void> restartCurrentPhase() async {
    _timer?.cancel();
    _timer = null;

    final settings = await _settingsRepository.getSettings();
    state = TimerModel(
      status: TimerStatus.running,
      elapsedSeconds: 0,
      totalSeconds:
          state.isWorkPhase ? settings.workDuration : settings.breakDuration,
      currentCycle: state.currentCycle,
      isWorkPhase: state.isWorkPhase,
    );
    await _timerRepository.saveTimerState(state);
    _startCountdown();
  }

  /// 跳过当前阶段
  Future<void> startWorkPhase({bool advanceCycle = false}) async {
    _timer?.cancel();
    _timer = null;

    final settings = await _settingsRepository.getSettings();
    state = TimerModel(
      status: TimerStatus.running,
      elapsedSeconds: 0,
      totalSeconds: settings.workDuration,
      currentCycle: advanceCycle ? state.currentCycle + 1 : state.currentCycle,
      isWorkPhase: true,
    );
    await _timerRepository.saveTimerState(state);
    _startCountdown();
  }

  Future<void> skipTimer() async {
    _timer?.cancel();
    _timer = null;

    final wasWorkPhase = state.isWorkPhase;
    final newCycle = wasWorkPhase ? state.currentCycle + 1 : state.currentCycle;
    final isNewWorkPhase = !wasWorkPhase;

    state = TimerModel(
      status: TimerStatus.idle,
      elapsedSeconds: 0,
      totalSeconds: isNewWorkPhase
          ? (await _settingsRepository.getSettings()).workDuration
          : (await _settingsRepository.getSettings()).breakDuration,
      currentCycle: newCycle,
      isWorkPhase: isNewWorkPhase,
    );
    await _timerRepository.saveTimerState(state);
  }

  /// 启动倒计时
  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.elapsedSeconds >= state.totalSeconds) {
        _onTimerComplete();
        timer.cancel();
        _timer = null;
        return;
      }

      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      _timerRepository.saveTimerState(state);
    });
  }

  /// 计时器完成处理 - 只发送通知，不自动切换阶段
  Future<void> _onTimerComplete() async {
    state = state.copyWith(status: TimerStatus.completed);
    await _timerRepository.saveTimerState(state);

    // 发送 Windows 通知
    final settings = await _settingsRepository.getSettings();
    if (settings.showNotification) {
      if (state.isWorkPhase) {
        await _notificationService.showWorkComplete(
          cycleNumber: state.currentCycle,
          isLongBreak: false,
        );
      } else {
        await _notificationService.showBreakComplete(
          cycleNumber: state.currentCycle + 1,
        );
      }
    }
    // 注意：不自动切换阶段，等待用户通过弹窗确认
  }

  /// 切换到下一阶段（由 UI 调用，在弹窗确认后）
  Future<void> switchToNextPhase() async {
    final settings = await _settingsRepository.getSettings();

    if (state.isWorkPhase) {
      // 工作完成，切换到休息
      state = state.copyWith(
        isWorkPhase: false,
        totalSeconds: settings.breakDuration,
        currentCycle: state.currentCycle + 1,
        elapsedSeconds: 0,
        status: TimerStatus.running, // 自动开始倒计时
      );
    } else {
      // 休息完成，切换到工作
      state = state.copyWith(
        isWorkPhase: true,
        totalSeconds: settings.workDuration,
        elapsedSeconds: 0,
        status: TimerStatus.running, // 自动开始倒计时
      );
    }
    await _timerRepository.saveTimerState(state);
    _startCountdown(); // 启动倒计时
  }

  /// 更新工作时长
  Future<void> updateWorkDuration(int duration) async {
    await _settingsRepository.updateSetting('workDuration', duration);
    if (state.isWorkPhase && state.status == TimerStatus.idle) {
      state = state.copyWith(totalSeconds: duration);
      await _timerRepository.saveTimerState(state);
    }
  }

  /// 更新休息时长
  Future<void> updateBreakDuration(int duration) async {
    await _settingsRepository.updateSetting('breakDuration', duration);
    if (!state.isWorkPhase && state.status == TimerStatus.idle) {
      state = state.copyWith(totalSeconds: duration);
      await _timerRepository.saveTimerState(state);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
