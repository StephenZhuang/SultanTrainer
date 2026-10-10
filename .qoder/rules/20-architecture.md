---
trigger: always_on
---

# 架构约束

采用 MVVM + Service 分层架构，各层职责严格分离。

## 分层定义

| 层 | 目录 | 职责 | 允许依赖 |
|---|------|------|----------|
| Model | Models/ | 数据模型，Codable 解析 | 无（最底层） |
| Service | Services/ | 通用业务逻辑（存档读写、卡牌操作、配置加载） | Model |
| ViewModel | ViewModels/ | 持有 Model 引用，封装修改逻辑，通知 UI 更新 | Model, Service |
| View | Views/ | 纯展示，通过 ViewModel 操作数据 | ViewModel |

## 关键原则

1. **View 不直接操作 Model**：所有数据修改通过 ViewModel → Service 链路
2. **Service 不依赖 UI**：Service 层可独立测试，不引用任何 SwiftUI 类型
3. **ViewModel 持有 SaveData 引用**：修改操作更新内存中的 Model，用户手动点击"保存"才写入文件
4. **单向数据流**：用户操作 → ViewModel → Service → 更新 Model → 通知 View

## 数据流

```
App 启动
  → ConfigLoader 定位游戏 config 目录 → 加载模板字典
  → SaveManager 扫描存档根目录 → 加载 auto_save.json + global.json
  → ViewModel 持有 SaveData
  → 用户修改 → ViewModel 调用 Service → 更新内存 Model
  → 用户点击"保存" → SaveManager 备份 → 原子写入 JSON
```

## 目录结构

```
SultanTrainer/
├── Models/          # 数据模型 (Codable)
├── Services/        # 业务逻辑
├── ViewModels/      # 视图模型
├── Views/
│   ├── QuickModify/     # 快捷修改
│   ├── Card/            # 卡牌管理
│   ├── Character/       # 人物属性
│   ├── Counter/         # 计数器
│   ├── Rite/            # 仪式
│   ├── Global/          # 全局数据
│   └── Components/      # 通用组件（如 CardPickerView）
└── SultanTrainerApp.swift
```
