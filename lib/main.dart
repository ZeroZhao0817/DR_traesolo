import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/themes/app_theme.dart';
import 'models/timer_model.dart';
import 'views/reminder/reminder_window.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  String? reminderArg;
  for (final arg in args) {
    if (arg.startsWith('--reminder=')) {
      reminderArg = arg;
      break;
    }
  }

  if (reminderArg != null) {
    final jsonPath = reminderArg.replaceFirst('--reminder=', '');
    await _runReminderStandalone(jsonPath);
  } else {
    await _runMainApp();
  }
}

Future<void> _runMainApp() async {
  const windowOptions = WindowOptions(
    size: Size(360, 500),
    minimumSize: Size(360, 500),
    maximumSize: Size(360, 500),
    center: true,
    windowButtonVisibility: false,
    title: '久坐提醒 v1.1.0',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: App()));
}

Future<void> _runReminderStandalone(String jsonPath) async {
  Map<String, dynamic> data;
  try {
    data = jsonDecode(await File(jsonPath).readAsString());
  } catch (_) {
    exit(0);
  }

  final screen = await _getScreenSize();
  final w = screen.width * 0.8;
  final h = screen.height * 0.8;

  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setSize(Size(w, h));
  await windowManager.setMinimumSize(Size(w, h));
  await windowManager.setMaximumSize(Size(w, h));
  await windowManager.center();
  await windowManager.setAlwaysOnTop(true);
  await windowManager.setBackgroundColor(const Color(0x00000000));
  await windowManager.setTitle('⏰ 提醒时间到！');

  runApp(ProviderScope(child: _ReminderStandaloneApp(data: data)));
}

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class _ReminderStandaloneApp extends StatefulWidget {
  final Map<String, dynamic> data;

  const _ReminderStandaloneApp({required this.data});

  @override
  State<_ReminderStandaloneApp> createState() => _ReminderStandaloneAppState();
}

class _ReminderStandaloneAppState extends State<_ReminderStandaloneApp> {
  Timer? _themeTimer;
  late ThemeMode _themeMode;
  String? _lastThemeModeValue;

  String? get _themePath => widget.data['themePath'] as String?;

  @override
  void initState() {
    super.initState();
    _lastThemeModeValue = widget.data['themeMode'] as String?;
    _themeMode = _themeModeFromString(_lastThemeModeValue);
    _startThemeWatcher();
  }

  @override
  void dispose() {
    _themeTimer?.cancel();
    super.dispose();
  }

  void _startThemeWatcher() {
    final path = _themePath;
    if (path == null || path.isEmpty) return;

    _themeTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      try {
        final file = File(path);
        if (!await file.exists()) return;
        final payload =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final themeModeValue = payload['themeMode'] as String?;
        if (themeModeValue == null || themeModeValue == _lastThemeModeValue) {
          return;
        }

        if (!mounted) return;
        setState(() {
          _lastThemeModeValue = themeModeValue;
          _themeMode = _themeModeFromString(themeModeValue);
        });
      } catch (_) {
        // The parent may be writing the file at the same time; retry next tick.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: ReminderWindow(
        timerState: TimerModel(
          status: TimerStatus.completed,
          isWorkPhase: widget.data['isWork'] as bool? ?? true,
          currentCycle: widget.data['cycle'] as int? ?? 1,
        ),
        onClose: () => exit(0),
        commandPath: widget.data['commandPath'] as String?,
        statePath: widget.data['statePath'] as String?,
        seed: widget.data['seed'] as int?,
      ),
    );
  }
}

Future<Size> _getScreenSize() async {
  try {
    final display = await screenRetriever.getPrimaryDisplay();
    return display.size;
  } catch (_) {
    return const Size(1920, 1080);
  }
}
