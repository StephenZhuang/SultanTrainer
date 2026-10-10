---
trigger: glob
globs: "*.swift"
---

# 数据层规则

数据层负责游戏存档和配置文件的读写，是修改器的核心。

## 存档操作

### 原子写入

所有文件写入必须采用原子操作：先写临时文件，成功后 rename 为目标文件。禁止直接覆盖原文件。

### 自动备份

每次保存前自动备份原文件到 `~/Library/Application Support/SultanTrainer/backups/`，命名格式 `auto_save_YYYYMMDD_HHMMSS.json`，保留最近 10 个。

### UID 唯一性

新增卡牌实例时，`uid` 必须 >= `card_uid_index`，并同步更新 `card_uid_index`。新增仪式同理，使用 `rite_uid_index`。

### 容错解码

游戏更新可能新增字段，所有 Model 的 Codable 实现必须容错：
- 未知字段跳过，不报错
- 可选字段使用默认值
- 必需字段缺失时抛出明确错误

## 配置文件加载

ConfigLoader 按以下优先级定位游戏 config 目录：
1. 已知路径：`~/Library/Application Support/Steam/steamapps/common/Sultan's Game/...`
2. Spotlight 扫描：`mdfind kMDItemFSName == 'cards.json'`
3. 降级：加载失败时 UI 中只显示 ID 不显示名称

## 存档加载

SaveManager 启动时自动扫描存档根目录：
- 单个 SteamID 子目录 → 直接加载
- 多个 SteamID → 弹窗列出供选择（显示最后修改时间）
- 无存档 → 提示"未检测到存档"

## 数据一致性约束

- 修改仪式槽位中的卡牌 UID 时，该 UID 必须在 `cards[]` 中存在
- 删除卡牌前检查是否被仪式引用，若引用则警告用户
- `configVersion` 修改存档时保持不变
- `global.json` 与 `auto_save.json` 分开加载、分开保存，不混写

## JSON 编码

- 使用 `.prettyPrinted` 保持可读性
- 使用 `.withoutEscapingSlashes` 避免中文被转义
