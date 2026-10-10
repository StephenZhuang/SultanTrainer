---
trigger: always_on
---

# 项目概览

SultanTrainer 是《苏丹的游戏》(Sultan's Game) 的 Mac 原生存档修改器。

## 定位

为游戏提供可视化存档编辑能力，支持快捷一键修改和高级精细编辑两种模式。

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI（Mac 原生）
- **最低系统**: macOS 13.0+
- **数据解析**: Codable + 容错解码
- **架构**: MVVM + Service 分层
- **构建**: xcodebuild CLI，安装到 ~/Applications/

## 核心文件

- `docs/superpowers/specs/2026-10-10-sultan-trainer-design.md` — 设计文档（功能、架构、UI）
- `docs/save-data-structure.md` — 游戏存档数据结构逆向分析

## 关键路径

- **存档根目录**: `~/Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA/{SteamID}/`
- **游戏配置目录**: `~/Library/Application Support/Steam/steamapps/common/Sultan's Game/Sultan's Game.app/Contents/Resources/Data/StreamingAssets/config/`
- **备份目录**: `~/Library/Application Support/SultanTrainer/backups/`

## 项目阶段

当前为文档阶段，尚未编写源代码。所有开发须以 docs/ 中的文档为依据。
