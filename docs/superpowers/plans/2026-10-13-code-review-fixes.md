# Code Review 修复方案

**日期**: 2026-10-13
**触发**: 全项目 Code Review
**状态**: 待实施

## 总览

| 严重度 | 数量 | 关键项 |
|--------|------|--------|
| Critical | 15 | 数据丢失风险、MVVM 分层违反、文档严重漂移、假阳性测试 |
| Warning | 57 | 静默吞错、硬编码、性能、测试覆盖缺口 |
| Suggestion | 26 | 代码组织、命名、日志 |

## 实施批次

按优先级分 5 个批次，每批可独立提交。

---

## 批次 1：存档安全（P0，立即修复）

### 1.1 原子写入改造

**问题**: C-01 — `SaveManager.swift:112-146` 原子写入实现有数据丢失窗口

**现状**: 先 `.atomic` 写临时文件 → `removeItem(目标)` → `moveItem(临时, 目标)`。如果在 `removeItem` 之后、`moveItem` 之前进程崩溃，目标文件已删除而临时文件尚未就位，存档永久丢失。

**方案**: 用 `FileManager.replaceItemAt(withBackupItemName:)` 替换当前的 remove+move 两步操作。

**影响文件**: `Services/SaveManager.swift`

### 1.2 备份命名加亚秒精度

**问题**: C-02 — `SaveManager.swift:96-101` 备份命名精度仅到秒，同秒连续保存会因文件已存在而崩溃

**方案**: DateFormatter 格式从 `yyyyMMdd_HHmmss` 改为 `yyyyMMdd_HHmmss_SSS`（加 3 位毫秒）。同时在 `copyItem` 失败时做 fallback：若目标已存在则先 removeItem 再 copy。

**影响文件**: `Services/SaveManager.swift`

### 1.3 存档 UI 状态字段保留验证

**问题**: C-03 — `SaveData.swift:4-57` 存档 UI 状态字段（`sudan_box_show` 等）完全未建模，round-trip 会丢失

**方案**: 采用"合并写入透传"策略（已在 `mergeWrite` 中实现）。需验证 `mergeWrite` 的合并逻辑覆盖了所有顶层未建模字段。

**验证方式**: 写单元测试，构造含未建模字段的 JSON → 解码为 SaveData → 编码 → 合并 → 验证未建模字段保留。

**影响文件**: `Services/SaveManager.swift`（可能无需改代码，只需补测试）

### 1.4 over_reason 默认值修正

**问题**: C-04 — `SaveData.swift:47` `over_reason` 默认值 `0` 与胜利结局 ID 冲突

**方案**: 默认值从 `0` 改为 `Int.min`，与游戏行为一致（未结束时值为 `Int.min`）。

**影响文件**: `Models/SaveData.swift`

---

## 批次 2：数据模型补全（P1）

### 2.1 CardTemplate 补字段

**问题**: C-05 — `CardTemplate.swift` 缺 `is_only` 字段，无法验证唯一卡约束

**方案**: 新增字段：
- `var is_only: Bool`（需 decodeBool 处理 int→bool）
- `var resource: String?`（卡牌图片资源）

**影响文件**: `Models/CardTemplate.swift`

### 2.2 TagTemplate 补字段

**问题**: C-06 — `CardTemplate.swift` (TagTemplate) 缺 `can_nagative_and_zero` 字段

**方案**: 新增字段：
- `var can_nagiative_and_zero: Bool`（int→bool）
- `var text: String?`
- `var tips: String?`
- `var fail_tag: String?`
- `var tag_vanishing: Int?`
- `var attributes: [String: Int]?`

**影响文件**: `Models/CardTemplate.swift`

### 2.3 replaceCard 逻辑修复

**问题**: C-07 — `CardService.swift:39-43` `replaceCard` 丢失原卡背包位置，不更新仪式引用

**方案**:
1. `replaceCard` 保留原卡的 `bag`/`bagpos`
2. 检查仪式引用，若原卡被引用则更新仪式中的引用
3. `addCard` 返回新卡 UID（`Int`），供调用方使用
4. `replaceCard` 返回新卡 UID（`Int?`）

**影响文件**: `Services/CardService.swift`

### 2.4 CounterScope 补 7210 前缀

**问题**: `Enums.swift:64-85` `CounterScope` 缺 `7210` 前缀（跨局累计）

**方案**: 新增 `case 7210: self = .crossSession`

**影响文件**: `Models/Enums.swift`

---

## 批次 3：MVVM 分层修复（P0/P1）

### 3.1 ViewModel 封装代理方法

**问题**: C-08/C-09 — View 直接修改 Model，绕过 Service/ViewModel

**方案**: 在 `AppViewModel` 中新增代理方法：

```
// 计数器
func setCounter(id: String, value: Int)
func setGoldCardCount(value: Int)

// 人物属性
func updateCharacterAttribute(templateId: Int, attr: String, value: Int)
func setEquipSlot(templateId: Int, slot: String, add: Bool)

// 仪式
func assignCardToRiteSlot(riteIndex: Int, slotIndex: Int, templateId: Int)
func clearRiteSlot(riteIndex: Int, slotIndex: Int)

// 全局数据
func updateTotalPoint(_ value: Int)

// 卡牌
func addCard(templateId: Int)
func deleteCard(uid: Int) -> Bool
func replaceCard(uid: Int, newTemplateId: Int) -> Int?
```

**影响文件**: `ViewModels/AppViewModel.swift`

### 3.2 View 层改造

**问题**: 所有 View 中的 `viewModel.xxxService.method()` 直接调用 Service

**方案**: 所有 View 中的 Service 调用改为 `viewModel.method()`，所有直接修改 `save.xxx` 的代码移入 ViewModel 方法。

**影响文件**:
- `Views/Counter/CounterEditorView.swift`
- `Views/Global/GlobalDataView.swift`
- `Views/QuickModify/QuickModifyView.swift`
- `Views/Card/CardListView.swift`
- `Views/Character/CharacterAttributeView.swift`
- `Views/Rite/RiteEditorView.swift`

### 3.3 AppViewModel 清理

**问题**: `AppViewModel` import SwiftUI、Service 属性暴露、`cardService` 隐式解包

**方案**:
- 移除 `import SwiftUI`，改 `import Combine`
- Service 属性改为 `private`，只通过代理方法暴露
- `cardService` 去掉 `!`，改为 `let`

**影响文件**: `ViewModels/AppViewModel.swift`

### 3.4 多存档选择 UI 实现

**问题**: C-10 — `AppViewModel.swift:55-57` 多存档选择 UI 未实现

**方案**: 新增 `SavePickerView.swift`，当 `showSavePicker == true` 时弹出 sheet，列出所有扫描到的存档目录（显示 SteamID + 最后修改时间），用户选择后调用 `viewModel.loadSave(path:)`。

**影响文件**:
- 新增 `Views/SavePickerView.swift`
- 修改 `Views/ContentView.swift`（添加 `.sheet` 绑定）

---

## 批次 4：错误处理与健壮性（P1/P2）

### 4.1 自定义错误类型

**问题**: C-03 Service 层 — 缺自定义错误类型，违反编码规范

**方案**: 新增 `SaveError` 和 `ConfigError`：

```swift
enum SaveError: LocalizedError {
    case fileNotFound(URL)
    case parseFailed(URL, underlying: Error)
    case writeFailed(URL, underlying: Error)
    case backupFailed(URL, underlying: Error)
    case noSaveLoaded
}

enum ConfigError: LocalizedError {
    case configDirectoryNotFound
    case loadFailed(String, underlying: Error)
}
```

**影响文件**:
- 新增 `Services/SaveError.swift`
- 新增 `Services/ConfigError.swift`
- 修改 `Services/SaveManager.swift`
- 修改 `Services/ConfigLoader.swift`

### 4.2 静默吞错改为日志记录

**问题**: 多处 `try?` 降级静默吞掉错误

**方案**: 引入 `os.Logger`，所有 `try?` 降级处加 `logger.error(...)` 记录。关键路径（`originalData` 读取失败、配置解码失败）改为抛出错误。

**影响文件**: `Services/SaveManager.swift`, `Services/ConfigLoader.swift`

### 4.3 防抖机制修复

**问题**: `QuickModifyView.swift:56-62` 防抖机制无效，按钮点击后可能永久禁用

**方案**: 用 `Task` + `Task.sleep` 替代无效的状态等待：

```swift
private func triggerCooldown() {
    lastActionTime = Date()
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(1))
        lastActionTime = nil
    }
}
```

**影响文件**: `Views/QuickModify/QuickModifyView.swift`

### 4.4 金币 key 验证

**问题**: C-15 — `QuickModifiers.swift:8` 金币计数器 key `"7000100"` 未经验证

**方案**: 从实际存档中确认金币对应的计数器 key。若确认为 `7000100`，在文档中记录；若不是，修正代码。同时统一金币卡牌 templateId（`2000029` vs `2000090`），以实际存档为准。

**影响文件**: 待定（可能涉及 `QuickModifiers.swift`、`CounterEditorView.swift`、文档）

### 4.5 save() guard 失败反馈

**问题**: `AppViewModel.swift:84` `save()` guard 失败无用户反馈

**方案**: guard 失败时设置 `errorMessage`，给用户明确提示。

**影响文件**: `ViewModels/AppViewModel.swift`

---

## 批次 5：文档同步与测试补全（P1-P3）

### 5.1 设计文档修正

**问题**: C-11/C-12 — 设计文档与代码严重不一致

**修正项**:

| 位置 | 修正内容 |
|------|----------|
| 233-239 | Rite.cards 改为 `[Card?]`（数组），删除 `CardReference` 描述 |
| 305-315 | AttributeType rawValue 改为英文（`"physique"` 等） |
| 143-155 | 目录结构更新：模板文件合并说明、View 文件合并说明 |
| 160-163 | ViewModel 改为单一 `AppViewModel` |
| 566-577 | SaveManager API 更新为当前实现 |

**影响文件**: `docs/superpowers/specs/2026-10-10-sultan-trainer-design.md`

### 5.2 数据结构文档修正

**问题**: 文档与代码不一致

**修正项**:
- 确认 `configVersion` 值描述（文档 vs 代码默认值差异的原因）
- 确认金币卡牌 ID（`2000029` vs `2000090`）

**影响文件**: `docs/save-data-structure.md`

### 5.3 规则文件更新

**问题**: 规则与实际不一致

**修正项**:
- `30-coding-conventions.md`: 明确 `ObservableObject`（删除 `@Observable` 模糊描述）
- 自定义错误类型规则：标记为"待实施"或补充实施计划

**影响文件**: `.qoder/rules/30-coding-conventions.md`

### 5.4 删除空壳测试

**问题**: C-13/C-14 — 空壳测试永远通过

**方案**:
- 删除 `SultanTrainerTests.swift`（纯模板残留）
- 删除 `SultanTrainerUITests.swift` 中的 `testExample()` 和 `testLaunchPerformance()`（或保留 performance 但添加说明）

**影响文件**:
- 删除 `SultanTrainerTests/SultanTrainerTests.swift`
- 修改 `SultanTrainerUITests/SultanTrainerUITests.swift`

### 5.5 补充测试

| 测试文件 | 补充内容 |
|----------|----------|
| `CardTemplateTests.swift`（新建） | TagTemplate.decodeBool、CardTemplate 解码、CodingKeys 映射 |
| `AppViewModelTests.swift`（新建） | initialize/loadSave/save 状态转换、errorMessage 设置 |
| `QuickModifiersTests.swift` | `incrementRound` / `clearSudanCards` / `unlockAllUpgrades` / `completeAllQuests` / `addGold` 负数 |
| `CardServiceTests.swift` | `setEquipSlot` / `categorize(card:)` / `replaceCard` 无效 UID / `updateCharacterAttribute` 边界值（0, 999, 1000, -1） |
| `ConfigLoaderTests.swift` | `stripJSONComments` / `getCardDisplayName` / `getSudanCardLevel` / `convertTagKeys` |
| `SaveManagerTests.swift` | `mergeWrite` 保留未建模字段 / `cleanupOldBackups` / `loadGlobal` |
| `SaveDataModelTests.swift` | `over_reason` 缺失时默认值为 `Int.min` |

### 5.6 硬编码常量化

**方案**: 新建 `Models/GameConstants.swift`，集中管理硬编码常量：

```swift
enum GameConstants {
    static let goldCardTemplateId = 2000029  // 待验证
    static let protagonistCardTemplateId = 2000001
    static let avatarCardTemplateId = 2000861
    static let sudanCardIdRange = 2010001...2010016
    static let attributeMaxValue = 999
    static let attributeMinValue = 0
    static let counterMaxValue = 999999
    static let messageClearDelay: TimeInterval = 2
    static let actionCooldown: TimeInterval = 1
}
```

**影响文件**:
- 新增 `Models/GameConstants.swift`
- 修改引用硬编码的所有文件

### 5.7 代码组织优化（Suggestion）

- `FlowLayout` 移至 `Views/Components/FlowLayout.swift`
- `CardCategory` 从 `Models/Enums.swift` 移至 `ViewModels/` 或 `Views/Components/`
- `ConfigLoader` 的 5 个 `loadXxxConfig` 抽泛型方法
- `ConfigLoader.categorize(template:)` 移至 `CardService`
- `CardListView` 去重改用 `(bag: Int, bagpos: Int)` 元组做 Set key
- `CardDetailView` 的 `.cornerRadius` 改为 `.clipShape(.rect(cornerRadius:))`
- `filteredCards` 加缓存（`@State` 或 `.task(id:)`）
- `zhTagToEn` / `enTagToZh` 改为 `lazy var` 缓存
- `ContentView` 去除双重状态源，只保留 ViewModel 中的 `selectedSidebarItem`

---

## 实施顺序

```
批次 1（存档安全）  ──→  批次 2（模型补全）  ──→  批次 4（错误处理）
         │                                              │
         └──────────────→  批次 3（MVVM 修复）  ←────────┘
                                  │
                                  └──────────→  批次 5（文档+测试）
```

批次 1 和 2 可并行，批次 3 依赖 1/2 完成（代理方法需要正确的 Service 签名），批次 5 在所有代码稳定后统一处理。

---

## 待确认项

1. **金币计数器 key**: 需从实际存档确认是 `7000100` 还是其他值
2. **金币卡牌 templateId**: 需确认是 `2000029` 还是 `2000090`
3. **`cards.json` 语法错误**: 实际 `cards.json` 第 2370 行附近存在 JSON 解析错误，需确认是游戏原始文件问题还是解析方式问题
