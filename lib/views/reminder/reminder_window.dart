import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:window_manager/window_manager.dart';

import '../../models/timer_model.dart';
import '../../viewmodels/timer_view_model.dart';
import '../../shared/data/quote_data.dart';

class ReminderWindow extends ConsumerStatefulWidget {
  final TimerModel timerState;
  final VoidCallback onClose;
  final String? commandPath;
  final String? statePath;
  final int? seed;

  const ReminderWindow({
    super.key,
    required this.timerState,
    required this.onClose,
    this.commandPath,
    this.statePath,
    this.seed,
  });

  @override
  ConsumerState<ReminderWindow> createState() => _ReminderWindowState();
}

class _ReminderWindowState extends ConsumerState<ReminderWindow> {
  static const _continuePhrase = '健康不要了，继续工作';
  final TextEditingController _controller = TextEditingController();
  late Future<Map<String, String>> _quoteFuture;
  late int _quoteSeed;
  late TimerModel _timerState;
  Timer? _stateTimer;
  bool _showAllActions = true;
  int _selectedActionIndex = 1;
  bool _isClosing = false;
  bool _isWaitingForNextPhase = false;

  @override
  void initState() {
    super.initState();
    _timerState = widget.timerState;
    _quoteSeed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    _quoteFuture = _loadMaoxuanQuote(_quoteSeed);
    _startStateWatcher();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupReminderWindow());
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setupReminderWindow() async {
    if (_isClosing) return;

    final screenSize = await _getScreenSize();
    final targetSize = Size(screenSize.width * 0.8, screenSize.height * 0.8);

    try {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setMinimumSize(targetSize);
      await windowManager.setMaximumSize(targetSize);
      await windowManager.setSize(targetSize);
      await windowManager.center();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setBackgroundColor(const Color(0x00000000));
      await windowManager.setTitle('提醒时间到！');
    } catch (e) {
      debugPrint('设置提醒窗口失败: $e');
    }
  }

  Future<Size> _getScreenSize() async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      return display.size;
    } catch (_) {
      if (!mounted) {
        return const Size(1920, 1080);
      }
      return MediaQuery.sizeOf(context);
    }
  }

  Future<Map<String, String>> _loadMaoxuanQuote(int seed) async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/quotes/maoxuan/quotes.json');
      final items = jsonDecode(raw) as List<dynamic>;
      final item = items[seed % items.length] as Map<String, dynamic>;
      return {
        'text': item['text'] as String? ?? '',
        'author': item['author'] as String? ?? '毛泽东',
      };
    } catch (_) {
      final maoQuotes = QuoteData.workQuotes
          .where((item) => item['author'] == '毛泽东')
          .toList();
      if (maoQuotes.isEmpty) {
        return {'text': '下定决心，不怕牺牲，排除万难，去争取胜利。', 'author': '毛泽东'};
      }
      return maoQuotes[seed % maoQuotes.length];
    }
  }

  void _refreshQuote() {
    setState(() {
      _quoteSeed = DateTime.now().microsecondsSinceEpoch;
      _quoteFuture = _loadMaoxuanQuote(_quoteSeed);
    });
  }

  void _startStateWatcher() {
    final path = widget.statePath;
    if (path == null || path.isEmpty) return;

    _stateTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      try {
        final file = File(path);
        if (!await file.exists()) return;
        final payload =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        if (payload['close'] == true) {
          await _finishStandaloneReminder();
          return;
        }

        final nextState = _timerStateFromPayload(payload);

        if (!mounted) return;
        setState(() {
          _timerState = nextState;
          _isWaitingForNextPhase = false;
        });

        if (!nextState.isWorkPhase &&
            nextState.status == TimerStatus.completed) {
          await _finishStandaloneReminder();
        }
      } catch (_) {
        // The parent process rewrites this file every tick; retry next poll.
      }
    });
  }

  TimerModel _timerStateFromPayload(Map<String, dynamic> payload) {
    final statusName = payload['status'] as String? ?? 'completed';
    final status = TimerStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => TimerStatus.completed,
    );

    return TimerModel(
      status: status,
      elapsedSeconds: payload['elapsedSeconds'] as int? ?? 0,
      totalSeconds: payload['totalSeconds'] as int? ?? _timerState.totalSeconds,
      isWorkPhase: payload['isWorkPhase'] as bool? ?? _timerState.isWorkPhase,
      currentCycle: payload['currentCycle'] as int? ?? _timerState.currentCycle,
    );
  }

  Future<void> _writeAction(String action) async {
    if (widget.commandPath == null) return;
    try {
      await File(widget.commandPath!)
          .writeAsString(jsonEncode({'action': action}), flush: true);
    } catch (_) {}
  }

  Future<void> _finishStandaloneReminder() async {
    if (_isClosing) return;
    _isClosing = true;
    _stateTimer?.cancel();
    await _writeAction('closed');
    exit(0);
  }

  Future<void> _closeReminderWindow() async {
    if (_isClosing) return;
    _isClosing = true;
    await _writeAction('closed');

    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(const Size(360, 500));
      await windowManager.setMaximumSize(const Size(360, 500));
      await windowManager.setSize(const Size(360, 500));
      await windowManager.setTitle('桌面提醒助手');
    } catch (e) {
      debugPrint('恢复窗口失败: $e');
    }

    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final isWork = _timerState.isWorkPhase;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isWork ? const Color(0xFF6C5CE7) : const Color(0xFF00B894);
    final scale = (MediaQuery.of(context).size.shortestSide / 850)
        .clamp(0.72, 1.0)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: isDark ? const Color(0xFF101122) : const Color(0xFFF5F7FB),
        padding: EdgeInsets.fromLTRB(
          24 * scale,
          12 * scale,
          24 * scale,
          24 * scale,
        ),
        child: Column(
          children: [
            _dragHeader(scale, isDark, isWork),
            SizedBox(height: 10 * scale),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 14,
                    child: _exerciseGrid(scale, isDark),
                  ),
                  SizedBox(width: 22 * scale),
                  Expanded(
                    flex: 7,
                    child: _rightPanel(primary, scale, isDark, isWork),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHeader(double scale, bool isDark, bool isWork) {
    return SizedBox(
      height: 34 * scale,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18 * scale,
                    color: isWork
                        ? const Color(0xFF8E7CFF)
                        : const Color(0xFF00B894),
                  ),
                  SizedBox(width: 8 * scale),
                  Text(
                    isWork ? '工作提醒' : '休息提醒',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFB8BED0)
                          : const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _closeReminderWindow,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(Size(34 * scale, 34 * scale)),
            icon: Icon(
              Icons.close,
              size: 24 * scale,
              color: isDark ? const Color(0xFFC9CED8) : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseGrid(double scale, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: _cardDecoration(scale, isDark),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _exerciseToolbar(scale, isDark),
          SizedBox(height: 14 * scale),
          Expanded(
            child: _showAllActions
                ? _actionGrid(scale, isDark)
                : _singleActionView(scale, isDark),
          ),
        ],
      ),
    );
  }

  Widget _exerciseToolbar(double scale, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '放松动作',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF1F4FA) : const Color(0xFF1D2433),
            ),
          ),
        ),
        _viewModeButton('四图', _showAllActions, () {
          setState(() => _showAllActions = true);
        }, scale, isDark),
        SizedBox(width: 8 * scale),
        _viewModeButton('单图', !_showAllActions, () {
          setState(() => _showAllActions = false);
        }, scale, isDark),
      ],
    );
  }

  Widget _viewModeButton(
    String label,
    bool selected,
    VoidCallback onTap,
    double scale,
    bool isDark,
  ) {
    return SizedBox(
      height: 30 * scale,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12 * scale),
          backgroundColor: selected
              ? const Color(0xFF6C5CE7).withOpacity(isDark ? 0.26 : 0.12)
              : Colors.transparent,
          foregroundColor: selected
              ? const Color(0xFF8E7CFF)
              : (isDark ? const Color(0xFFB8BED0) : const Color(0xFF667085)),
          side: BorderSide(
            color: selected
                ? const Color(0xFF6C5CE7)
                : (isDark ? const Color(0xFF3C3F5F) : const Color(0xFFD8DEE9)),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8 * scale),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _actionGrid(double scale, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12 * scale;
        final tileSide = math
            .min(
              (constraints.maxWidth - gap) / 2,
              (constraints.maxHeight - gap) / 2,
            )
            .clamp(0.0, double.infinity)
            .toDouble();

        return Center(
          child: SizedBox(
            width: tileSide * 2 + gap,
            height: tileSide * 2 + gap,
            child: Column(
              children: [
                Row(
                  children: [
                    _actionGridTile(1, tileSide, scale, isDark),
                    SizedBox(width: gap),
                    _actionGridTile(2, tileSide, scale, isDark),
                  ],
                ),
                SizedBox(height: gap),
                Row(
                  children: [
                    _actionGridTile(3, tileSide, scale, isDark),
                    SizedBox(width: gap),
                    _actionGridTile(4, tileSide, scale, isDark),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionGridTile(
    int imageIndex,
    double tileSide,
    double scale,
    bool isDark,
  ) {
    return SizedBox.square(
      dimension: tileSide,
      child: _exerciseTile(
        imageIndex,
        scale,
        isDark,
        onTap: () {
          setState(() {
            _selectedActionIndex = imageIndex;
            _showAllActions = false;
          });
        },
      ),
    );
  }

  Widget _singleActionView(double scale, bool isDark) {
    return Row(
      children: [
        _actionNavButton(
            Icons.chevron_left, () => _switchAction(-1), scale, isDark),
        SizedBox(width: 12 * scale),
        Expanded(child: _exerciseTile(_selectedActionIndex, scale, isDark)),
        SizedBox(width: 12 * scale),
        _actionNavButton(
            Icons.chevron_right, () => _switchAction(1), scale, isDark),
      ],
    );
  }

  Widget _actionNavButton(
    IconData icon,
    VoidCallback onTap,
    double scale,
    bool isDark,
  ) {
    return SizedBox(
      width: 42 * scale,
      height: 54 * scale,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor:
              isDark ? const Color(0xFF181A31) : const Color(0xFFF2F4F7),
          foregroundColor:
              isDark ? const Color(0xFFB8BED0) : const Color(0xFF667085),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10 * scale),
          ),
        ),
        icon: Icon(icon, size: 24 * scale),
      ),
    );
  }

  void _switchAction(int delta) {
    setState(() {
      _selectedActionIndex = ((_selectedActionIndex - 1 + delta) % 4) + 1;
      if (_selectedActionIndex < 1) {
        _selectedActionIndex += 4;
      }
    });
  }

  Widget _exerciseTile(
    int imageIndex,
    double scale,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: GestureDetector(
            onTap: onTap,
            child: MouseRegion(
              cursor: onTap == null
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: SizedBox.square(
                dimension: side,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10 * scale),
                  child: Image.asset(
                    _actionImagePath(imageIndex, isDark),
                    fit: BoxFit.contain,
                    width: side,
                    height: side,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.self_improvement,
                          size: 52 * scale,
                          color: const Color(0xFF6C5CE7),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _actionImagePath(int imageIndex, bool isDark) {
    return isDark
        ? 'assets/images/actions/dark_actions_0$imageIndex.png'
        : 'assets/images/actions/lighti_actios_0$imageIndex.png';
  }

  Widget _rightPanel(Color primary, double scale, bool isDark, bool isWork) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FutureBuilder<Map<String, String>>(
            future: _quoteFuture,
            builder: (context, snapshot) {
              final quote = snapshot.data ??
                  const {'text': '下定决心，不怕牺牲，排除万难，去争取胜利。', 'author': '毛泽东'};
              return _quoteBox(quote, scale, isDark);
            },
          ),
        ),
        SizedBox(height: 20 * scale),
        _actionGroup(primary, scale, isDark, isWork),
      ],
    );
  }

  Widget _quoteBox(Map<String, String> quote, double scale, bool isDark) {
    return Container(
      padding: EdgeInsets.all(22 * scale),
      decoration: _cardDecoration(scale, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3 * scale,
                height: 24 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  '每日激励',
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF1F4FA)
                        : const Color(0xFF1D2433),
                  ),
                ),
              ),
              Text(
                '毛选摘录',
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF8B91A8)
                      : const Color(0xFF98A2B3),
                ),
              ),
              SizedBox(width: 8 * scale),
              Tooltip(
                message: '随机换一条',
                child: IconButton(
                  onPressed: _refreshQuote,
                  padding: EdgeInsets.zero,
                  constraints:
                      BoxConstraints.tight(Size(30 * scale, 30 * scale)),
                  style: IconButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFFB8BED0)
                        : const Color(0xFF667085),
                    hoverColor: const Color(0xFF00B894).withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                  ),
                  icon: Icon(Icons.refresh, size: 18 * scale),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF343653) : const Color(0xFFE4E7EC),
          ),
          SizedBox(height: 18 * scale),
          Expanded(
            child: Center(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '"${quote['text']}"',
                  style: TextStyle(
                    fontSize: 20 * scale,
                    height: 1.38,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF1F4FA)
                        : const Color(0xFF101828),
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${quote['author']}',
              style: TextStyle(
                fontSize: 20 * scale,
                color:
                    isDark ? const Color(0xFFB8BED0) : const Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(double scale, bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF20233D) : Colors.white,
      borderRadius: BorderRadius.circular(12 * scale),
      border: Border.all(
        color: isDark ? const Color(0xFF403B7A) : const Color(0xFFDDE3ED),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0xFF6C5CE7).withOpacity(0.14)
              : Colors.black.withOpacity(0.04),
          blurRadius: 16 * scale,
          offset: Offset(0, 6 * scale),
        ),
      ],
    );
  }

  Widget _actionGroup(Color primary, double scale, bool isDark, bool isWork) {
    final showBreakProgress = _isWaitingForNextPhase ||
        (!isWork && _timerState.status == TimerStatus.running);

    if (showBreakProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
              color:
                  isDark ? const Color(0xFF343653) : const Color(0xFFDDE3ED)),
          SizedBox(height: 14 * scale),
          _breakProgressPanel(primary, scale, isDark),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
            color: isDark ? const Color(0xFF343653) : const Color(0xFFDDE3ED)),
        SizedBox(height: 14 * scale),
        Text(
          isWork ? '如果必须继续工作，请输入：$_continuePhrase' : '休息结束后可以继续休息，或开始下一轮工作。',
          style: TextStyle(
            fontSize: 17 * scale,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF1F4FA) : const Color(0xFF1D2433),
          ),
        ),
        if (isWork) ...[
          SizedBox(height: 8 * scale),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '输入确认语后可以继续工作',
              filled: true,
              fillColor: isDark ? const Color(0xFF20233D) : Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 14 * scale,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * scale),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3C3F5F)
                        : const Color(0xFFD8DEE9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * scale),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3C3F5F)
                        : const Color(0xFFD8DEE9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * scale),
                borderSide: BorderSide(color: primary, width: 1.6),
              ),
            ),
            style: TextStyle(
              fontSize: 16 * scale,
              color: isDark ? const Color(0xFFF1F4FA) : const Color(0xFF1D2433),
            ),
          ),
        ],
        SizedBox(height: 12 * scale),
        Row(
          children: [
            Expanded(child: _secondaryAction(scale, isDark, isWork)),
            SizedBox(width: 14 * scale),
            Expanded(child: _primaryAction(scale, isWork)),
          ],
        ),
      ],
    );
  }

  Widget _breakProgressPanel(Color primary, double scale, bool isDark) {
    final total = _timerState.totalSeconds <= 0 ? 1 : _timerState.totalSeconds;
    final elapsed = _timerState.elapsedSeconds.clamp(0, total).toInt();
    final remaining = (total - elapsed).clamp(0, total).toInt();
    final progress = (elapsed / total).clamp(0.0, 1.0).toDouble();
    final label = _isWaitingForNextPhase
        ? '正在开始休息...'
        : '休息中 ${_formatDuration(remaining)}';

    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20233D) : Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(
          color: isDark ? const Color(0xFF3C3F5F) : const Color(0xFFD8DEE9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.self_improvement, color: primary, size: 18 * scale),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF1F4FA)
                        : const Color(0xFF1D2433),
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _isWaitingForNextPhase ? null : progress,
              minHeight: 8 * scale,
              backgroundColor: primary.withOpacity(0.14),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            _isWaitingForNextPhase ? '保持窗口打开，休息计时即将开始' : '休息结束后窗口会自动关闭',
            style: TextStyle(
              fontSize: 13 * scale,
              color: isDark ? const Color(0xFFB8BED0) : const Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final restSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${restSeconds.toString().padLeft(2, '0')}';
  }

  Widget _primaryAction(double scale, bool isWork) {
    return SizedBox(
      height: 50 * scale,
      child: ElevatedButton.icon(
        onPressed: () => _sendAction('start_next_phase'),
        icon: Icon(isWork ? Icons.self_improvement : Icons.play_arrow,
            size: 18 * scale),
        label: Text(isWork ? '开始休息' : '开始工作',
            style:
                TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isWork ? const Color(0xFF00B894) : const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10 * scale)),
        ),
      ),
    );
  }

  Widget _secondaryAction(double scale, bool isDark, bool isWork) {
    final valid = !isWork || _controller.text.trim() == _continuePhrase;

    return SizedBox(
      height: 50 * scale,
      child: OutlinedButton.icon(
        onPressed: valid ? () => _sendAction('continue_work') : null,
        icon:
            Icon(isWork ? Icons.work_outline : Icons.coffee, size: 18 * scale),
        label: Text(isWork ? '继续工作' : '继续休息',
            style:
                TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: isWork ? Colors.redAccent : const Color(0xFF00B894),
          disabledForegroundColor:
              isDark ? const Color(0xFF666B80) : const Color(0xFFB4BBC8),
          side: BorderSide(
            color: valid
                ? (isWork
                    ? Colors.redAccent.withOpacity(0.7)
                    : const Color(0xFF00B894))
                : (isDark ? const Color(0xFF3C3F5F) : const Color(0xFFD8DEE9)),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10 * scale)),
        ),
      ),
    );
  }

  Future<void> _sendAction(String action) async {
    if (widget.commandPath != null) {
      await _writeAction(action);
      if (action == 'start_next_phase') {
        if (!_timerState.isWorkPhase) {
          exit(0);
        }

        if (mounted) {
          setState(() => _isWaitingForNextPhase = true);
        }
        return;
      }
      exit(0);
    }

    final notifier = ref.read(timerStateProvider.notifier);
    if (action == 'start_next_phase') {
      final wasWorkPhase = _timerState.isWorkPhase;
      await notifier.switchToNextPhase();
      if (mounted) {
        setState(() {
          _timerState = ref.read(timerStateProvider);
          _isWaitingForNextPhase = false;
        });
      }
      if (!wasWorkPhase) {
        await _closeReminderWindow();
      }
      return;
    } else {
      await notifier.restartCurrentPhase();
    }
    await _closeReminderWindow();
  }
}
