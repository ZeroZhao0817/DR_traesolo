# 久坐提醒 v1.1.0

一款轻量级桌面番茄钟提醒工具，帮助长时间电脑工作者定时休息。

## 功能特性

- 番茄钟计时（工作/休息）
- 强制休息机制（输入确认语才能继续工作）
- 放松动作引导
- 每日激励名言（毛选、哲学、科技、职场等分类）
- 浅色/深色主题切换
- 悬浮球模式
- 窗口置顶功能

## 技术栈

- Flutter (Windows 桌面开发)
- flutter_riverpod (状态管理)
- window_manager (窗口管理)
- screen_retriever (屏幕尺寸获取)
- shared_preferences (本地存储)

## 快速开始

1. 安装 Flutter SDK
2. 克隆项目
3. 运行 `flutter pub get`
4. 运行 `flutter run -d windows`

## 项目结构

```
lib/
├── core/          # 核心功能（常量、主题、工具）
├── models/        # 数据模型
├── repositories/  # 数据仓库
├── services/      # 服务层
├── shared/        # 共享数据
├── viewmodels/    # 视图模型
└── views/         # 视图页面
```

## 使用说明

1. 选择番茄钟模式（25+5 / 45+10 / 60+15）
2. 点击"开始"开始工作
3. 工作结束后会弹出提醒窗口
4. 选择"开始休息"或输入确认语继续工作
