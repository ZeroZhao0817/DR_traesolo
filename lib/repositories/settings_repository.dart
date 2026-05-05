import 'package:sedentary_reminder/models/settings_model.dart';

/// 设置仓库接口
/// 定义应用设置的相关操作
abstract class SettingsRepository {
  /// 获取当前设置
  Future<SettingsModel> getSettings();

  /// 保存设置
  Future<void> saveSettings(SettingsModel settings);

  /// 更新单个设置项
  Future<void> updateSetting(String key, dynamic value);
}
