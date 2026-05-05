import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedentary_reminder/models/timer_model.dart';
import 'package:sedentary_reminder/repositories/timer_repository.dart';

/// 本地计时器仓库实现
/// 使用 SharedPreferences 持久化计时器状态
class LocalTimerRepositoryImpl implements TimerRepository {
  static final LocalTimerRepositoryImpl _instance =
      LocalTimerRepositoryImpl._internal();
  factory LocalTimerRepositoryImpl() => _instance;
  LocalTimerRepositoryImpl._internal();

  static const String _timerStateKey = 'timer_state';

  @override
  Future<TimerModel> getTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString(_timerStateKey);

    if (stateJson == null) {
      return const TimerModel();
    }

    final Map<String, dynamic> stateMap = jsonDecode(stateJson);
    return TimerModel(
      status: TimerStatus.values[stateMap['status'] as int],
      elapsedSeconds: stateMap['elapsedSeconds'] as int? ?? 0,
      totalSeconds: stateMap['totalSeconds'] as int? ?? 1500,
      isWorkPhase: stateMap['isWorkPhase'] as bool? ?? true,
      currentCycle: stateMap['currentCycle'] as int? ?? 1,
      cyclesCompleted: stateMap['cyclesCompleted'] as int? ?? 0,
      breakCount: stateMap['breakCount'] as int? ?? 0,
      totalWorkMinutes: stateMap['totalWorkMinutes'] as int? ?? 0,
    );
  }

  @override
  Future<void> saveTimerState(TimerModel state) async {
    final prefs = await SharedPreferences.getInstance();
    final stateMap = {
      'status': state.status.index,
      'elapsedSeconds': state.elapsedSeconds,
      'totalSeconds': state.totalSeconds,
      'isWorkPhase': state.isWorkPhase,
      'currentCycle': state.currentCycle,
      'cyclesCompleted': state.cyclesCompleted,
      'breakCount': state.breakCount,
      'totalWorkMinutes': state.totalWorkMinutes,
    };
    await prefs.setString(_timerStateKey, jsonEncode(stateMap));
  }

  @override
  Future<void> resetTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerStateKey);
  }
}
