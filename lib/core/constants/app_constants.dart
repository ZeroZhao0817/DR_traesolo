class AppConstants {
  AppConstants._();

  // App info
  static const String appName = '久坐提醒 v1.1.0';
  static const String appVersion = '1.1.0';

  // Timer constants
  static const int defaultWorkDuration = 25 * 60; // 25 minutes in seconds
  static const int defaultBreakDuration = 5 * 60; // 5 minutes in seconds
  static const int longBreakDuration = 15 * 60; // 15 minutes in seconds
  static const int cyclesForLongBreak = 4;
  static const int minDuration = 1 * 60; // 1 minute
  static const int maxDuration = 120 * 60; // 2 hours

  // Notification constants
  static const int preReminderSeconds = 60; // 1 minute before
  static const int level2DelaySeconds = 60; // 1 minute delay to level 2
  static const int level3DelaySeconds = 60; // 1 minute delay to level 3
  static const int catAnimationDuration = 30; // 30 seconds

  // Storage keys
  static const String prefsKey = 'desktop_reminder_prefs';
  static const String quotesKey = 'quotes_data';
  static const String statisticsKey = 'statistics_data';

  // Database
  static const String dbName = 'desktop_reminder.db';

  // Quote categories
  static const List<String> quoteCategories = [
    'maoxuan',
    'philosophy',
    'workplace',
    'tech',
  ];

  // Quote category display names
  static const Map<String, String> categoryNames = {
    'maoxuan': '毛选',
    'philosophy': '哲学/人生',
    'workplace': '职场/管理',
    'tech': '科技/创新',
  };

  // Background images
  static const List<String> backgroundImages = [
    'assets/images/backgrounds/bg_nature.jpg',
    'assets/images/backgrounds/bg_sunset.jpg',
    'assets/images/backgrounds/bg_mountains.jpg',
    'assets/images/backgrounds/bg_ocean.jpg',
    'assets/images/backgrounds/bg_forest.jpg',
  ];

  // Alert sounds
  static const List<String> alertSounds = [
    'assets/audio/alert_default.mp3',
    'assets/audio/alert_gentle.mp3',
    'assets/audio/alert_urgent.mp3',
  ];
}
