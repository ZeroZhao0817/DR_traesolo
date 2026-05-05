import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/themes/app_theme.dart';
import 'viewmodels/settings_view_model.dart';
import 'views/home/home_page.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // 根据设置选择主题模式
    ThemeMode getThemeMode() {
      switch (settings.themeMode) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    }

    return MaterialApp(
      title: '桌面提醒助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: getThemeMode(), // 使用 themeMode 控制主题切换
      home: const HomePage(),
    );
  }
}
