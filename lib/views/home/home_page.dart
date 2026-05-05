import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../models/timer_model.dart';
import '../../viewmodels/timer_view_model.dart';
import '../../viewmodels/settings_view_model.dart';

class _StepperInputController {
  final TextEditingController controller = TextEditingController();
  int currentValue;

  _StepperInputController(this.currentValue) {
    controller.text = currentValue.toString();
  }

  void updateValue(int newValue) {
    currentValue = newValue;
    controller.text = newValue.toString();
  }

  void dispose() {
    controller.dispose();
  }
}

class _CustomStepper extends StatefulWidget {
  final String title;
  final int value;
  final String range;
  final ValueChanged<int> onChanged;
  final _StepperInputController inputController;

  const _CustomStepper({
    required this.title,
    required this.value,
    required this.range,
    required this.onChanged,
    required this.inputController,
  });

  @override
  State<_CustomStepper> createState() => _CustomStepperState();
}

class _CustomStepperState extends State<_CustomStepper> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = widget.inputController.controller;
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = _textController.text;
      final parsed = int.tryParse(text);
      if (parsed != null &&
          parsed >= 1 &&
          parsed <= (widget.title.contains('工作') ? 120 : 60)) {
        widget.inputController.updateValue(parsed);
        widget.onChanged(parsed);
      } else {
        _textController.text = widget.inputController.currentValue.toString();
      }
    }
  }

  void _increment() {
    final newValue = widget.value + 1;
    widget.inputController.updateValue(newValue);
    widget.onChanged(newValue);
  }

  void _decrement() {
    final newValue = widget.value - 1;
    widget.inputController.updateValue(newValue);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1D2333),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A5A)
                          : const Color(0xFFE1E5EE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: IconButton(
                        onPressed: _decrement,
                        icon: Icon(Icons.remove,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF9E9E9E)
                                : const Color(0xFF6B7280)),
                        splashRadius: 16,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF1D2333),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (text) {
                          final parsed = int.tryParse(text);
                          if (parsed != null && parsed >= 1) {
                            widget.inputController.updateValue(parsed);
                            widget.onChanged(parsed);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: IconButton(
                        onPressed: _increment,
                        icon: const Icon(Icons.add,
                            size: 16, color: Color(0xFF6C5CE7)),
                        splashRadius: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.range,
              style: TextStyle(
                fontSize: 10,
                color:
                    isDark ? const Color(0xFF9E9E9E) : const Color(0xFF8B93A3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isFloatingMode = false;
  bool _isAlwaysOnTop = false;
  bool _reminderLaunched = false;
  Timer? _reminderCommandTimer;
  String? _reminderThemePath;
  String? _reminderStatePath;
  String? _lastReminderThemeMode;
  String? _selectedQuickMode;
  bool _isHandlingReminderCommand = false;
  bool _isRequestingReminderClose = false;
  Timer? _breakEndCountdownTimer;
  int _breakEndCountdown = 15;
  bool _isAutoStartingWork = false;

  Future<void> _toggleAlwaysOnTop() async {
    setState(() => _isAlwaysOnTop = !_isAlwaysOnTop);
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
  }

  Color _bg(BuildContext c) {
    final b = Theme.of(c).brightness;
    return b == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF0F4F8);
  }

  Color _surf(BuildContext c) {
    final b = Theme.of(c).brightness;
    return b == Brightness.dark ? const Color(0xFF16213E) : Colors.white;
  }

  Color _txt(BuildContext c) {
    final b = Theme.of(c).brightness;
    return b == Brightness.dark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF2D3436);
  }

  Color _sub(BuildContext c) {
    final b = Theme.of(c).brightness;
    return b == Brightness.dark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF636E72);
  }

  Color _border(BuildContext c) {
    final b = Theme.of(c).brightness;
    return b == Brightness.dark
        ? const Color(0xFF2A2A4A)
        : const Color(0xFFE8EEF5);
  }

  @override
  void dispose() {
    _reminderCommandTimer?.cancel();
    _breakEndCountdownTimer?.cancel();
    _clearActiveReminderFiles();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerStateProvider);
    ref.listen<String>(
      settingsProvider.select((settings) => settings.themeMode),
      (previous, next) => _syncReminderTheme(next),
    );
    ref.listen<TimerModel>(
      timerStateProvider,
      (previous, next) => _syncReminderTimerState(next),
    );

    if (!_reminderLaunched &&
        timerState.status == TimerStatus.completed &&
        timerState.isWorkPhase) {
      _reminderLaunched = true;
      Future.microtask(() => _launchReminderProcess(timerState));
    }
    if (timerState.status != TimerStatus.completed || !timerState.isWorkPhase) {
      _reminderLaunched = false;
    }

    if (_isFloatingMode) {
      return GestureDetector(
        onTap: () => _toggleFloatingMode(),
        child: _buildFloatingBall(timerState),
      );
    }

    final isBreakEnd =
        timerState.status == TimerStatus.completed && !timerState.isWorkPhase;
    if (isBreakEnd) {
      _ensureBreakEndCountdown();
    } else {
      _stopBreakEndCountdown();
    }

    return Scaffold(
      backgroundColor: _bg(context),
      body: Column(
        children: [
          _buildTitleBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isBreakEnd) {
                  return _buildBreakEndConfirmationCard(
                      timerState, constraints);
                }
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 0),
                          _buildStatusTag(timerState),
                          const SizedBox(height: 20),
                          _buildTimerRing(timerState),
                          const SizedBox(height: 20),
                          _buildControls(timerState),
                          const SizedBox(height: 20),
                          const Divider(height: 1, indent: 42, endIndent: 42),
                          const SizedBox(height: 12),
                          _buildModesSection(timerState),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('------ 专注工作，按时休息 ------',
                style: TextStyle(fontSize: 12, color: _sub(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEndConfirmationCard(
      TimerModel timerState, BoxConstraints constraints) {
    const primary = Color(0xFF00B894);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: (isDark ? Colors.black : const Color(0xFFEFF4F8))
                .withOpacity(isDark ? 0.35 : 0.58),
          ),
        ),
        Padding(
          padding: _smallDialogInset(context),
          child: LayoutBuilder(
            builder: (context, dialogConstraints) {
              final dialogWidth = _smallDialogWidth(dialogConstraints.maxWidth);
              return Center(
                child: SizedBox(
                  width: dialogWidth,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: dialogConstraints.maxHeight),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF202043) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 30)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.coffee,
                                      color: primary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text('休息结束',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? const Color(0xFFE0E0E0)
                                                : const Color(0xFF1D2333)))),
                                Text('第 ${timerState.currentCycle} 轮',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF9E9E9E)
                                            : const Color(0xFF8B93A3))),
                              ],
                            ),
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(28)),
                                    child: const Icon(Icons.coffee,
                                        color: primary, size: 28),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                      '准备开始第 ${timerState.currentCycle + 1} 轮工作',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? const Color(0xFF9E9E9E)
                                              : const Color(0xFF6B7280))),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${_breakEndCountdown}s 后自动开始工作',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                            decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF2A2A4A)
                                          : const Color(0xFFE8EEF5))),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: OutlinedButton(
                                      onPressed: _continueBreakFromBreakEnd,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF3A3A5A)
                                                : const Color(0xFFE1E5EE)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: Text('继续休息',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? const Color(0xFFE0E0E0)
                                                  : const Color(0xFF2D3436))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: ElevatedButton(
                                      onPressed: _startWorkFromBreakEnd,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text('开始工作',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _ensureBreakEndCountdown() {
    if (_breakEndCountdownTimer != null || _isAutoStartingWork) return;

    _breakEndCountdown = 15;
    _breakEndCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_breakEndCountdown <= 1) {
        timer.cancel();
        _breakEndCountdownTimer = null;
        setState(() => _breakEndCountdown = 0);
        await _startWorkFromBreakEnd();
        return;
      }

      setState(() => _breakEndCountdown--);
    });
  }

  void _stopBreakEndCountdown() {
    _breakEndCountdownTimer?.cancel();
    _breakEndCountdownTimer = null;
    _breakEndCountdown = 15;
    _isAutoStartingWork = false;
  }

  Future<void> _continueBreakFromBreakEnd() async {
    _stopBreakEndCountdown();
    await ref.read(timerStateProvider.notifier).restartCurrentPhase();
  }

  Future<void> _startWorkFromBreakEnd() async {
    if (_isAutoStartingWork) return;
    _isAutoStartingWork = true;
    _breakEndCountdownTimer?.cancel();
    _breakEndCountdownTimer = null;
    await ref.read(timerStateProvider.notifier).startWorkPhase();
    if (mounted) {
      setState(() => _isAutoStartingWork = false);
    } else {
      _isAutoStartingWork = false;
    }
  }

  EdgeInsets _smallDialogInset(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return EdgeInsets.symmetric(
      horizontal: size.width * 0.12,
      vertical: size.height * 0.1,
    );
  }

  double _smallDialogWidth(double availableWidth) {
    return availableWidth.clamp(280.0, 340.0).toDouble();
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF202043)
              : const Color(0xFFFFFFFF),
          border:
              Border(bottom: BorderSide(color: _border(context), width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.04,
              ),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: Color(0xFF6C5CE7), shape: BoxShape.circle),
              child: const Icon(Icons.timer, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 8),
            Text('久坐提醒 v1.1.0',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _txt(context))),
            const Spacer(),
            _barBtn(_isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
                _toggleAlwaysOnTop),
            const SizedBox(width: 2),
            _barBtn(Icons.picture_in_picture_alt_outlined,
                () => _toggleFloatingMode()),
            const SizedBox(width: 2),
            _barBtn(
                Icons.settings_outlined,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsPageSimple()))),
            const SizedBox(width: 2),
            _barBtn(Icons.close, () => windowManager.close(), isClose: true),
          ],
        ),
      ),
    );
  }

  Widget _barBtn(IconData icon, VoidCallback onTap, {bool isClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: isClose ? Colors.red.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(5)),
        alignment: Alignment.center,
        child:
            Icon(icon, size: 15, color: isClose ? Colors.red : _sub(context)),
      ),
    );
  }

  Widget _buildStatusTag(TimerModel timerState) {
    final isWork = timerState.isWorkPhase;
    final pc = isWork ? const Color(0xFF6C5CE7) : const Color(0xFF00B894);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: pc.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: pc.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: pc, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(isWork ? '工作中' : '休息中',
              style: TextStyle(
                  color: pc, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(width: 8),
      Text('第 ${timerState.currentCycle} 轮',
          style: TextStyle(fontSize: 12, color: _sub(context))),
    ]);
  }

  Widget _buildTimerRing(TimerModel timerState) {
    final isWork = timerState.isWorkPhase;
    final pc = isWork ? const Color(0xFF6C5CE7) : const Color(0xFF00B894);
    const ringSize = 158.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleFloatingMode(),
        child: SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(alignment: Alignment.center, children: [
            Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(
                      color: pc.withOpacity(0.1),
                      blurRadius: 16,
                      spreadRadius: 1)
                ])),
            SizedBox(
                width: ringSize,
                height: ringSize,
                child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 7,
                    backgroundColor: pc.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.transparent))),
            SizedBox(
                width: ringSize,
                height: ringSize,
                child: CircularProgressIndicator(
                    value: timerState.progress,
                    strokeWidth: 7,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(pc),
                    strokeCap: StrokeCap.round)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: ringSize * 0.78,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                      app_date.DateUtils.formatDuration(
                          timerState.remainingSeconds),
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Microsoft YaHei',
                          color: _txt(context))),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: pc.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(
                      isWork ? Icons.work_outline : Icons.coffee_outlined,
                      color: pc,
                      size: 13)),
              const SizedBox(height: 3),
              Text(isWork ? '专注工作' : '放松休息',
                  style: TextStyle(fontSize: 11, color: _sub(context))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildControls(TimerModel timerState) {
    final isWork = timerState.isWorkPhase;
    final pc = isWork ? const Color(0xFF6C5CE7) : const Color(0xFF00B894);
    final isRunning = timerState.status == TimerStatus.running;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _actionBtn(Icons.replay, '重置',
          () => ref.read(timerStateProvider.notifier).resetTimer(), pc),
      const SizedBox(width: 10),
      _mainBtn(
          isRunning ? Icons.pause : Icons.play_arrow, isRunning ? '暂停' : '开始',
          () {
        final n = ref.read(timerStateProvider.notifier);
        isRunning ? n.pauseTimer() : n.startTimer();
      }, pc),
      const SizedBox(width: 10),
      _actionBtn(Icons.skip_next, '跳过', () => _handleSkipTimer(timerState), pc),
    ]);
  }

  Future<void> _handleSkipTimer(TimerModel timerState) async {
    final notifier = ref.read(timerStateProvider.notifier);
    if (_reminderStatePath != null) {
      _isRequestingReminderClose = true;
      await notifier.startWorkPhase(advanceCycle: timerState.isWorkPhase);
      await _requestActiveReminderClose();
      return;
    }

    if (timerState.status == TimerStatus.completed && timerState.isWorkPhase) {
      await notifier.startWorkPhase(advanceCycle: true);
      return;
    }

    await notifier.skipTimer();
  }

  Widget _mainBtn(
      IconData icon, String label, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: 90,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: 62,
      height: 30,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _surf(context),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 3),
        ),
      ),
    );
  }

  Widget _buildCustomButton(TimerModel timerState) {
    final pc = timerState.isWorkPhase
        ? const Color(0xFF6C5CE7)
        : const Color(0xFF00B894);
    final settings = ref.watch(settingsProvider);
    final customLabel =
        '${settings.workDuration ~/ 60}+${settings.breakDuration ~/ 60}';
    final currentLabel = _selectedQuickMode ?? customLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        height: 42,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showCustomTimerDialog,
          icon: Icon(Icons.calendar_today_outlined, size: 14, color: pc),
          label: Text('自定义: $currentLabel',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: pc)),
          style: OutlinedButton.styleFrom(
            backgroundColor: _surf(context),
            side: BorderSide(color: _border(context), width: 1.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildModesSection(TimerModel timerState) {
    final isWork = timerState.isWorkPhase;
    final pc = isWork ? const Color(0xFF6C5CE7) : const Color(0xFF00B894);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: _surf(context),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _border(context))),
          child: Row(children: [
            _modeBtn('25+5', 25, 5, timerState, pc),
            _modeBtn('45+10', 45, 10, timerState, pc),
            _modeBtn('60+15', 60, 15, timerState, pc)
          ]),
        ),
        const SizedBox(height: 8),
        _buildCustomButton(timerState),
      ]),
    );
  }

  Future<void> _showCustomTimerDialog() async {
    final settings = ref.read(settingsProvider);
    var workMinutes = (settings.workDuration ~/ 60).clamp(1, 120).toInt();
    var breakMinutes = (settings.breakDuration ~/ 60).clamp(1, 60).toInt();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        final workInputController = _StepperInputController(workMinutes);
        final breakInputController = _StepperInputController(breakMinutes);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: _smallDialogInset(context),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dialogWidth = _smallDialogWidth(constraints.maxWidth);
                  return SizedBox(
                    width: dialogWidth,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxHeight: constraints.maxHeight),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF202043)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 30)
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF6C5CE7)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.alarm,
                                        color: Color(0xFF6C5CE7), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text('自定义番茄钟',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFFE0E0E0)
                                                  : const Color(0xFF1D2333)))),
                                  IconButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      icon: Icon(Icons.close,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF9E9E9E)
                                              : const Color(0xFF6B7280),
                                          size: 18)),
                                ],
                              ),
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 8, 18, 12),
                                child: Column(
                                  children: [
                                    _customStepper(
                                        '工作时长（分钟）',
                                        workMinutes,
                                        '范围 1-120',
                                        (v) => setDialogState(() {
                                              workMinutes = v.clamp(1, 120);
                                              workInputController
                                                  .updateValue(workMinutes);
                                            }),
                                        workInputController),
                                    const SizedBox(height: 12),
                                    _customStepper(
                                        '休息时长（分钟）',
                                        breakMinutes,
                                        '范围 1-60',
                                        (v) => setDialogState(() {
                                              breakMinutes = v.clamp(1, 60);
                                              breakInputController
                                                  .updateValue(breakMinutes);
                                            }),
                                        breakInputController),
                                    const SizedBox(height: 12),
                                    Text('设置完成后将应用到下一轮番茄钟。',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF9E9E9E)
                                                    : const Color(0xFF8B93A3))),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 14),
                              decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF2A2A4A)
                                            : const Color(0xFFE8EEF5))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF3A3A5A)
                                                  : const Color(0xFFE1E5EE)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: Text('取消',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFFE0E0E0)
                                                    : const Color(0xFF2D3436))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final settingsNotifier = ref
                                              .read(settingsProvider.notifier);
                                          await settingsNotifier
                                              .updateWorkDuration(
                                                  workMinutes * 60);
                                          await settingsNotifier
                                              .updateBreakDuration(
                                                  breakMinutes * 60);
                                          await ref
                                              .read(timerStateProvider.notifier)
                                              .resetTimer();
                                          setState(
                                              () => _selectedQuickMode = null);
                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6C5CE7),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: const Text('确定',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _customStepper(String title, int value, String range,
      ValueChanged<int> onChanged, _StepperInputController inputController) {
    return _CustomStepper(
      title: title,
      value: value,
      range: range,
      onChanged: onChanged,
      inputController: inputController,
    );
  }

  Widget _modeBtn(
      String label, int work, int rest, TimerModel timerState, Color pc) {
    final selected = _selectedQuickMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _selectedQuickMode = label);
          final settingsNotifier = ref.read(settingsProvider.notifier);
          final notifier = ref.read(timerStateProvider.notifier);
          await settingsNotifier.updateWorkDuration(work * 60);
          await settingsNotifier.updateBreakDuration(rest * 60);
          await notifier.updateWorkDuration(work * 60);
          await notifier.updateBreakDuration(rest * 60);
          await notifier.resetTimer(totalSeconds: work * 60);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
              color: selected ? pc.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: selected ? Border.all(color: pc.withOpacity(0.2)) : null),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? pc : _sub(context))),
        ),
      ),
    );
  }

  Future<void> _launchReminderProcess(TimerModel ts) async {
    if (_reminderStatePath != null) {
      await _syncReminderTimerState(ts);
      return;
    }

    try {
      _reminderCommandTimer?.cancel();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final jsonPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}desktop_reminder_reminder_$stamp.json';
      final commandPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}desktop_reminder_command_$stamp.json';
      final themePath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}desktop_reminder_theme_$stamp.json';
      final statePath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}desktop_reminder_state_$stamp.json';
      final themeMode = ref.read(settingsProvider).themeMode;
      final data = {
        'isWork': ts.isWorkPhase,
        'cycle': ts.currentCycle,
        'seed': DateTime.now().millisecondsSinceEpoch,
        'commandPath': commandPath,
        'themePath': themePath,
        'statePath': statePath,
        'themeMode': themeMode,
      };
      await File(jsonPath).writeAsString(jsonEncode(data), flush: true);
      await _writeReminderTheme(themeMode, themePath);
      await _writeReminderTimerState(ts, statePath);

      final exe = Platform.resolvedExecutable;
      await Process.start(exe, ['--reminder=$jsonPath'],
          mode: ProcessStartMode.detached);
      _reminderThemePath = themePath;
      _reminderStatePath = statePath;
      _lastReminderThemeMode = themeMode;
      _watchReminderCommand(commandPath);
    } catch (e) {
      await _clearActiveReminderFiles();
      _reminderLaunched = false;
      debugPrint('启动提醒进程失败: $e');
    }
  }

  void _watchReminderCommand(String commandPath) {
    final file = File(commandPath);
    _reminderCommandTimer =
        Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (_isHandlingReminderCommand) return;
      if (!await file.exists()) return;

      _isHandlingReminderCommand = true;
      try {
        final payload =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        await file.delete();
        final action = payload['action'] as String?;
        if (action == null) return;

        final notifier = ref.read(timerStateProvider.notifier);
        switch (action) {
          case 'start_next_phase':
            final wasWorkPhase = ref.read(timerStateProvider).isWorkPhase;
            await notifier.switchToNextPhase();
            final nextState = ref.read(timerStateProvider);
            if (wasWorkPhase) {
              await _syncReminderTimerState(nextState);
            } else {
              timer.cancel();
              _reminderCommandTimer = null;
              await _clearActiveReminderFiles();
            }
            break;
          case 'continue_work':
            await notifier.restartCurrentPhase();
            timer.cancel();
            _reminderCommandTimer = null;
            await _clearActiveReminderFiles();
            break;
          case 'closed':
            timer.cancel();
            _reminderCommandTimer = null;
            await _clearActiveReminderFiles();
            break;
          default:
            debugPrint('未知提醒窗口动作: $action');
        }
      } catch (e) {
        debugPrint('读取提醒窗口命令失败: $e');
      } finally {
        _isHandlingReminderCommand = false;
      }
    });
  }

  Future<void> _syncReminderTimerState(TimerModel timerState) async {
    final path = _reminderStatePath;
    if (path == null || _isRequestingReminderClose) return;
    await _writeReminderTimerState(timerState, path);
  }

  Future<void> _requestActiveReminderClose() async {
    final path = _reminderStatePath;
    if (path == null) return;

    try {
      _isRequestingReminderClose = true;
      await File(path).writeAsString(jsonEncode({'close': true}), flush: true);
    } catch (e) {
      _isRequestingReminderClose = false;
      debugPrint('Failed to request reminder window close: $e');
    }
  }

  Future<void> _writeReminderTimerState(
      TimerModel timerState, String path) async {
    try {
      await File(path).writeAsString(
        jsonEncode({
          'status': timerState.status.name,
          'elapsedSeconds': timerState.elapsedSeconds,
          'totalSeconds': timerState.totalSeconds,
          'isWorkPhase': timerState.isWorkPhase,
          'currentCycle': timerState.currentCycle,
        }),
        flush: true,
      );
    } catch (e) {
      debugPrint('Failed to write reminder window state: $e');
    }
  }

  void _syncReminderTheme(String themeMode) {
    final path = _reminderThemePath;
    if (path == null || _lastReminderThemeMode == themeMode) return;

    _lastReminderThemeMode = themeMode;
    Future.microtask(() => _writeReminderTheme(themeMode, path));
  }

  Future<void> _writeReminderTheme(String themeMode, String path) async {
    try {
      await File(path)
          .writeAsString(jsonEncode({'themeMode': themeMode}), flush: true);
    } catch (e) {
      debugPrint('鍚屾鎻愰啋绐楀彛涓婚澶辫触: $e');
    }
  }

  Future<void> _clearActiveReminderFiles() async {
    final themePath = _reminderThemePath;
    final statePath = _reminderStatePath;
    _reminderThemePath = null;
    _reminderStatePath = null;
    _lastReminderThemeMode = null;
    _isRequestingReminderClose = false;

    for (final path in [themePath, statePath]) {
      if (path == null) continue;
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best effort cleanup for temp files owned by the reminder process.
      }
    }
  }

  Future<void> _toggleFloatingMode() async {
    final entering = !_isFloatingMode;
    final notifier = ref.read(timerStateProvider.notifier);
    final wasRunning =
        ref.read(timerStateProvider).status == TimerStatus.running;
    if (wasRunning) await notifier.pauseTimer();
    if (entering) {
      setState(() => _isFloatingMode = true);
      await Future.delayed(const Duration(milliseconds: 50));
      final pos = await windowManager.getPosition();
      await windowManager.setPreventClose(true);
      await windowManager.setAsFrameless();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setBackgroundColor(const Color(0x00000000));
      await windowManager.setMinimumSize(const Size(150, 150));
      await windowManager.setMaximumSize(const Size(150, 150));
      await windowManager.setSize(const Size(150, 150));
      await windowManager.setPosition(pos);
    } else {
      await windowManager.setPreventClose(false);
      await windowManager.setMinimumSize(const Size(360, 500));
      await windowManager.setMaximumSize(const Size(360, 500));
      await windowManager.setSize(const Size(360, 500));
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
      await windowManager.setBackgroundColor(const Color(0xFFFFFFFF));
      await Future.delayed(const Duration(milliseconds: 100));
      final pos = await windowManager.getPosition();
      await windowManager.setPosition(pos);
      setState(() => _isFloatingMode = false);
    }
    if (wasRunning) notifier.startTimer();
  }

  Widget _buildFloatingBall(TimerModel timerState) {
    final isWork = timerState.isWorkPhase;
    final pc = isWork ? const Color(0xFF6C5CE7) : const Color(0xFF00B894);
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        width: 220,
        height: 220,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF202043)
                    : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: pc.withOpacity(0.18),
                      blurRadius: 8,
                      spreadRadius: 1),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 4)
                ],
              ),
            ),
            SizedBox(
              width: 134,
              height: 134,
              child: CircularProgressIndicator(
                value: timerState.progress,
                strokeWidth: 5,
                backgroundColor: pc.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(pc),
                strokeCap: StrokeCap.butt,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                    app_date.DateUtils.formatDuration(
                        timerState.remainingSeconds),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _txt(context),
                        decoration: TextDecoration.none)),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ballBtn(
                        timerState.status == TimerStatus.running
                            ? Icons.pause
                            : Icons.play_arrow, () {
                      final n = ref.read(timerStateProvider.notifier);
                      timerState.status == TimerStatus.running
                          ? n.pauseTimer()
                          : n.startTimer();
                    }, pc),
                    const SizedBox(width: 6),
                    _ballBtn(Icons.skip_next,
                        () => _handleSkipTimer(timerState), pc),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ballBtn(IconData icon, VoidCallback onTap, Color pc) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration:
            BoxDecoration(color: pc.withOpacity(0.1), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: pc),
      ),
    );
  }
}

class SettingsPageSimple extends ConsumerStatefulWidget {
  const SettingsPageSimple({super.key});

  @override
  ConsumerState<SettingsPageSimple> createState() => _SettingsPageSimpleState();
}

class _SettingsPageSimpleState extends ConsumerState<SettingsPageSimple> {
  Color _settingsBg() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1A1A2E)
      : const Color(0xFFF0F4F8);

  Color _settingsSurface() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF202043)
      : Colors.white;

  Color _settingsText() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE0E0E0)
      : const Color(0xFF2D3436);

  Color _settingsSubText() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFA9A9C8)
      : const Color(0xFF636E72);

  Color _settingsBorder() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2A2A4A)
      : const Color(0xFFE8EEF5);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: _settingsBg(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: _settingsBg(),
                border: Border(bottom: BorderSide(color: _settingsBorder()))),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back,
                          size: 16, color: Color(0xFF6C5CE7)))),
              const SizedBox(width: 10),
              Text('设置',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _settingsText())),
              const Spacer(),
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.red))),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(14), children: [
              _setCard(Icons.palette_outlined, const Color(0xFF6C5CE7), '主题模式',
                  child: Row(children: [
                    _themeChip('浅色', 'light', s.themeMode),
                    const SizedBox(width: 6),
                    _themeChip('深色', 'dark', s.themeMode),
                    const SizedBox(width: 6),
                    _themeChip('跟随系统', 'system', s.themeMode)
                  ])),
              const SizedBox(height: 10),
              _setCard(
                  Icons.notifications_outlined, const Color(0xFF00B894), '桌面通知',
                  trailing: Switch(
                      value: s.showNotification,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .updateShowNotification(v),
                      activeColor: const Color(0xFF00B894))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.verified_outlined,
                    size: 12, color: const Color(0xFF6C5CE7).withOpacity(0.4)),
                const SizedBox(width: 4),
                Text('设置将自动保存到本地',
                    style: TextStyle(
                        fontSize: 11,
                        color: _settingsSubText().withOpacity(0.7)))
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _setCard(IconData icon, Color ic, String title,
      {Widget? trailing, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _settingsSurface(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _settingsBorder())),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: ic.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: ic)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _settingsText()))),
          if (trailing != null) trailing
        ]),
        if (child != null) ...[const SizedBox(height: 10), child],
      ]),
    );
  }

  Widget _themeChip(String label, String value, String current) {
    final sel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(settingsProvider.notifier).updateThemeMode(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
              color: sel
                  ? const Color(0xFF6C5CE7)
                  : _settingsBorder().withOpacity(0.55),
              borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? Colors.white : _settingsSubText())),
        ),
      ),
    );
  }
}
