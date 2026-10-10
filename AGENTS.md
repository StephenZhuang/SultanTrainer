# SultanTrainer

《苏丹的游戏》(Sultan's Game) 存档修改器，Mac 原生 SwiftUI 桌面应用。

- **技术栈**: Swift 5.9+ / SwiftUI / macOS 13.0+
- **架构**: MVVM + Service 分层
- **核心功能**: 读取游戏纯 JSON 存档，提供快捷修改（金币、属性、胜利）和高级编辑（卡牌、计数器、仪式、全局数据）
- **构建**: xcodebuild CLI → ~/Applications/

## AI 协作规则索引

| 编号 | 文件 | 主题 | 触发方式 |
|------|------|------|----------|
| 00 | [00-overview.md](.qoder/rules/00-overview.md) | 项目概览 | always_on |
| 10 | [10-change-management.md](.qoder/rules/10-change-management.md) | 文档驱动变更管理 | always_on |
| 20 | [20-architecture.md](.qoder/rules/20-architecture.md) | 架构约束 | always_on |
| 30 | [30-coding-conventions.md](.qoder/rules/30-coding-conventions.md) | Swift 编码规范 | *.swift |
| 40 | [40-data-layer.md](.qoder/rules/40-data-layer.md) | 数据层规则 | *.swift |
| 41 | [41-ui-conventions.md](.qoder/rules/41-ui-conventions.md) | UI 规范 | *.swift |
| 50 | [50-build-and-distribution.md](.qoder/rules/50-build-and-distribution.md) | 构建与分发 | *.sh |
| 60 | [60-documentation.md](.qoder/rules/60-documentation.md) | 文档维护规范 | model_decision |
