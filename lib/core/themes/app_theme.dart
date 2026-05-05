import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 桌面应用推荐字体栈 - 微软雅黑，中文字体渲染优秀
  static const String _fontFamily = 'MicrosoftYaHei';

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF6C5CE7),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.grey[50],
        dividerColor: Colors.grey[300],
        fontFamily: _fontFamily,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF6C5CE7)),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFA29BFE),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey[800],
        fontFamily: _fontFamily,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFA29BFE)),
      );
}
