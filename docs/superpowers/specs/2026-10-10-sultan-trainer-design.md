# SultanTrainer 设计文档

《苏丹的游戏》存档修改器，Mac原生SwiftUI应用。

## 一、需求概述

### 1.1 目标
为《苏丹的游戏》(Sultan's Game) 提供一个Mac桌面存档修改器，支持快捷修改和高级编辑两种模式。

### 1.2 存档信息
- **存档根目录**: `~/Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA/`
- **存档结构**: 根目录下按SteamID分子目录，如 `SAVEDATA/76561198107865511/`
- **存档格式**: 纯JSON，无加密
- **核心文件**:
  - `auto_save.json` - 当前局存档
  - `global.json` - 跨局持久化数据
- **自动加载策略**: 启动时自动扫描存档根目录，找到SteamID子目录中的 `auto_save.json`；若有多个SteamID则列出供选择（显示最后修改时间），只有一个则直接加载

### 1.3 游戏配置文件
- **关键配置文件**:
  - `config/cards.json` - 卡牌模板定义
  - `config/tag.json` - 标签/属性定义
  - `config/upgrade.json` - 升级定义
  - `config/quest.json` - 任务定义
  - `config/over.json` - 结局定义
  - `config/rite/*.json` - 仪式定义
- **定位策略（按优先级）**:
  1. 已知路径: `~/Library/Application Support/Steam/steamapps/common/Sultan's Game/Sultan's Game.app/Contents/Resources/Data/StreamingAssets/config/`
  2. 自动扫描: 用 `mdfind` (Spotlight) 搜索 `kMDItemFSName == 'cards.json'`
  3. 降级: 配置文件加载失败时，UI中卡牌/计数器只显示ID不显示名称

## 二、技术选型

### 2.1 技术栈
- **框架**: SwiftUI (Mac原生)
- **语言**: Swift 5.9+
- **最低系统**: macOS 13.0+
- **数据解析**: Codable + 容错处理

### 2.2 架构选择
**MVVM + Service 分层架构**:
- **Model**: 数据模型，Codable解析
- **ViewModel**: 持有Model引用，封装修改逻辑，通知UI更新
- **View**: 纯展示，通过ViewModel操作数据
- **Service**: 通用业务逻辑（存档读写、卡牌操作等）

选择理由:
1. SwiftUI天然适合MVVM，状态管理清晰
2. Service层复用通用逻辑
3. 易于测试和维护

### 2.3 数据流
```
App启动
    ↓
ConfigLoader 自动定位游戏config目录 → 加载模板字典
    ↓
SaveManager 自动扫描存档根目录 → 找到auto_save.json → 解析为 SaveData (内存)
    ↓
ViewModel 持有 SaveData 引用
    ↓
用户在UI中修改 → ViewModel调用Service方法 → 更新内存中的 SaveData
    ↓
用户点击"保存" → SaveManager.saveSave() → 自动备份 → 原子写入JSON
```

**关键原则**:
- 所有修改先操作内存中的Model
- 用户手动点击"保存"才写入文件
- 写入采用原子操作（先写临时文件再rename）
- 未保存时UI显示"已修改"指示

### 2.4 Codable容错策略
游戏更新可能新增字段，为避免解析失败：
```swift
// 所有Model实现容错解码
struct SaveData: Codable {
    var configId: Int
    var cards: [Card]
    // ... 必需字段
    
    // 可选字段用默认值
    var unknownFields: [String: Any]? = nil
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configId = try container.decode(Int.self, forKey: .configId)
        cards = try container.decode([Card].self, forKey: .cards)
        // 未知字段不报错，跳过即可
    }
}
```

## 三、功能设计

### 3.1 功能模块

| 模块 | 功能 | 目标文件 | 操作字段 |
|------|------|----------|----------|
| 快捷修改 | 金币+999 | auto_save.json | counter中金币计数器 或 卡牌2000090的count |
| 快捷修改 | 全属性满 | auto_save.json | 主角卡的tag字段 |
| 快捷修改 | 直接胜利 | auto_save.json | sudan_card_pool全部life=0 + success=true |
| 快捷修改 | 解锁所有结局 | global.json | overID数组添加所有结局ID |
| 卡牌管理 | 添加/替换/删除 | auto_save.json | cards数组 |
| 人物属性 | 修改9项属性、驯兽槽 | auto_save.json | 人物卡的tag字段、equip_slots字段 |
| 计数器 | 浏览/修改 | auto_save.json | counter字典（按作用域分组显示） |
| 仪式 | 编辑槽位 | auto_save.json | rites[].cards |
| 全局数据 | 升级点数/解锁 | global.json | totalPoint/upgrade/quest |

### 3.2 计数器作用域分组

| 前缀 | 作用域 | 显示名 |
|------|--------|--------|
| 7000xxx | 当前会话 | 局内状态 |
| 7100xxx | 持久统计 | 跨局数据 |
| 7200xxx | 成就计数 | 成就 |
| 7220xxx | 完成统计 | 完成记录 |
| 7230xxx | 解锁标记 | 解锁 |

### 3.3 卡牌类别

| 类别 | 说明 | 判断条件 |
|------|------|----------|
| 人物 | 主角卡、追随者等 | type == "char" |
| 装备 | 武器、服装、饰品、驯兽 | equips包含武器/服装/饰品/驯兽 |
| 书籍 | 书籍类卡牌 | tag包含"读物" |
| 苏丹卡 | 核心机制卡 | type == "sudan" |
| 其他 | 金币、资源等 | type == "item"且以上都不符合 |

### 3.4 存档管理
- **自动加载**: 启动时扫描 `~/Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA/`，自动找到并加载 `auto_save.json`
- **多存档处理**: 若有多个SteamID子目录，弹窗列出供选择（显示SteamID和最后修改时间）
- **无存档处理**: 若未找到存档，显示提示"未检测到存档"，引导用户检查游戏是否已运行过
- **自动备份**: 每次保存前自动备份原文件
- **备份位置**: `~/Library/Application Support/SultanTrainer/backups/`
- **备份命名**: `auto_save_YYYYMMDD_HHMMSS.json`
- **备份保留**: 最近10个，自动清理旧备份
- **原子写入**: 先写临时文件，成功后rename为目标文件

## 四、数据层设计

### 4.1 目录结构
```
SultanTrainer/
├── Models/                    # 数据模型
│   ├── SaveData.swift         # auto_save.json
│   ├── GlobalData.swift       # global.json
│   ├── Card.swift             # 卡牌实例
│   ├── Rite.swift             # 仪式
│   ├── CardTemplate.swift     # 卡牌模板 + 标签/升级/任务/结局模板（合并）
│   └── Enums.swift            # 枚举定义
├── Services/                  # 业务逻辑
│   ├── SaveManager.swift      # 存档读写、备份
│   ├── ConfigLoader.swift     # 游戏配置加载
│   ├── CardService.swift      # 卡牌操作
│   ├── QuickModifiers.swift   # 快捷修改
│   ├── SaveError.swift        # 存档错误类型
│   └── ConfigError.swift      # 配置错误类型
├── ViewModels/                # 视图模型
│   └── AppViewModel.swift     # 单一全局 ViewModel
├── Views/
│   ├── ContentView.swift              # 主窗口
│   ├── QuickModify/
│   │   └── QuickModifyView.swift
│   ├── Card/
│   │   ├── CardListView.swift
│   │   ├── CardDetailView.swift       # 卡牌详情弹窗
│   │   └── CardPickerView.swift       # 通用卡牌选择器
│   ├── Character/
│   │   └── CharacterAttributeView.swift
│   ├── Counter/
│   │   └── CounterEditorView.swift
│   ├── Rite/
│   │   └── RiteEditorView.swift
│   └── Global/
│       └── GlobalDataView.swift
└── SultanTrainerApp.swift
```

### 4.2 核心Model

```swift
// SaveData - auto_save.json
struct SaveData: Codable {
    var configId: Int
    var configVersion: Int
    var name: String
    var difficulty: Int
    var round: Int
    var min_round: Int
    var saveTime: String
    var card_uid_index: Int
    var rite_uid_index: Int
    var success: Bool
    var over_reason: Int
    var cards: [Card]
    var rites: [Rite]
    var sudan_card_pool: [Card]
    var counter: [String: Int]
    var event_status: [String: Bool]
    var timing_rounds: [String: TimingRound]
    var gen_cards: [String: Int]
    var gen_tags: [String: Int]
    var ithink_card: Card?
}

// Card - 卡牌实例
struct Card: Codable, Identifiable {
    var uid: Int
    var id: Int           // 模板ID
    var count: Int
    var life: Int
    var rareup: Int
    var tag: [String: Int]
    var equip_slots: [String]
    var equips: [Card]
    var bag: Int
    var bagpos: Int
    var custom_name: String
    var custom_text: String
}

// Rite - 仪式
struct Rite: Codable, Identifiable {
    var uid: Int
    var id: Int           // 仪式模板ID
    var cards: [Card?]    // 槽位数组，索引对应槽位（cards[0] = s1）
}

// TimingRound
struct TimingRound: Codable {
    var round: Int
    var status: Int
}

// GlobalData - global.json
struct GlobalData: Codable {
    var saveTime: String
    var finishTutorial: Bool
    var inGame: Bool
    var totalRound: Int
    var totalPoint: Int
    var usedPoint: Int
    var upgrade: [String: Int]        // 升级ID -> 等级
    var quest: [String: Int]          // 任务ID -> 状态(2=完成)
    var achievements: [String: Bool]
    var counter: [String: Int]
    var doneRite: [Int]
    var doneEvent: [Int]
    var overID: [Int]                 // 已解锁结局ID
    var gameStatistics: [String: GameStat]
    var mods: [String]
    var hasEnterSudanBox: Bool
    var hasEnterQuest: Bool
    var backToPrevRound: Int
    var roundRollback: Int
    var overRecord: [OverRecord]
    var showedGalleryCards: [Int]
    var showedPrompt: [String]
    
    struct GameStat: Codable {
        var startTimes: Int
        var overTimes: Int
    }
    
    struct OverRecord: Codable {
        var overID: Int
        var round: Int
        var name: String
    }
}

// CardTemplate - cards.json中的卡牌模板
struct CardTemplate: Codable {
    var id: Int
    var name: String
    var type: String        // "char" / "item" / "sudan"
    var title: String       // 细分类：书籍、武器、服装 等
    var text: String
    var tag: [String: Int]
    var equip_slots: [String]  // JSON字段名为 "equips"，值为中文（武器/服装/饰品）
}

// 枚举
enum CardCategory: String, CaseIterable {
    case character = "人物"
    case equipment = "装备"
    case book = "书籍"
    case sudan = "苏丹卡"
    case other = "其他"
}

enum AttributeType: String, CaseIterable {
    case physique = "physique"
    case charm = "charm"
    case wisdom = "wisdom"
    case conceal = "conceal"
    case battle = "battle"
    case social = "social"
    case survival = "survival"
    case magic = "magic"
    case knowledge = "knowledge"
}

enum CounterScope: String, CaseIterable {
    case session = "局内状态"      // 7000xxx
    case persistent = "跨局数据"   // 7100xxx
    case achievement = "成就"      // 7200xxx
    case completion = "完成记录"   // 7220xxx
    case unlock = "解锁"          // 7230xxx
}
```

### 4.3 ViewModel 结构

本项目采用单一全局 ViewModel（`AppViewModel`），所有视图共享同一实例：

```swift
class AppViewModel: ObservableObject {
    // 服务层
    let configLoader = ConfigLoader()
    private let saveManager = SaveManager()
    let cardService: CardService
    private let quickModifiers = QuickModifiers()
    
    // 数据
    @Published var saveData: SaveData?
    @Published var globalData: GlobalData?
    
    // 状态
    @Published var isLoading = true
    @Published var hasUnsavedChanges = false
    @Published var lastSaveMessage: String?
    @Published var errorMessage: String?
    
    // 导航
    @Published var selectedSidebarItem: SidebarItem?
}
```

**关键原则**:
- View 不直接操作 Model，通过 ViewModel 代理方法
- ViewModel 持有 SaveData 引用，修改操作更新内存中的 Model
- 用户手动点击"保存"才写入文件

### 4.4 数据加载流程
1. **启动时**: ConfigLoader按已知路径 → Spotlight扫描 定位游戏config目录 → 加载模板字典
2. **启动时**: SaveManager扫描存档根目录 → 找到SteamID子目录 → 加载 `auto_save.json` + `global.json`
3. **修改操作**: ViewModel调用Service → 更新内存中的Model
4. **保存**: SaveManager.saveSave() → 备份 → 原子写入JSON

## 五、UI设计

### 5.1 主窗口布局
```
┌─────────────────────────────────────────────────────────┐
│  SultanTrainer          [已修改 •]  [保存]              │
├──────────────┬──────────────────────────────────────────┤
│              │                                          │
│  快捷修改    │                                          │
│  卡牌管理    │          （右侧内容区）                   │
│  人物属性    │                                          │
│  计数器      │                                          │
│  仪式        │                                          │
│  全局数据    │                                          │
│              │                                          │
└──────────────┴──────────────────────────────────────────┘
```

**状态指示**:
- 存档加载中: 右侧显示加载动画
- 未找到存档: 右侧显示"未检测到存档，请先运行游戏"
- 已修改未保存: 标题栏显示"已修改 •"，保存按钮高亮
- 保存成功: 短暂显示"已保存"提示
- 刷新成功: 短暂显示"已刷新"提示

**工具栏按钮**:
- 保存: 将内存中的修改写入磁盘，无修改时禁用
- 刷新: 重新从磁盘读取存档数据（不重新加载游戏配置）。若有未保存修改，弹出确认对话框提示"当前未保存的修改将丢失，是否继续？"；若无未保存修改，直接刷新

### 5.2 侧边栏导航
```swift
enum SidebarItem: String, CaseIterable, Identifiable {
    case quickModify = "快捷修改"
    case cardManage = "卡牌管理"
    case characterAttribute = "人物属性"
    case counter = "计数器"
    case rite = "仪式"
    case globalData = "全局数据"
}
```

### 5.3 快捷修改页
```
┌─────────────────────────────────────────────────────┐
│  快捷修改                                           │
├─────────────────────────────────────────────────────┤
│  当前局 (auto_save.json)                            │
│  ┌─────────────────────────────────────────────┐   │
│  │ [金币+999]  [全属性满]  [直接胜利]           │   │
│  │ [回合数+1]  [清空苏丹卡]                    │   │
│  └─────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│  全局数据 (global.json)                             │
│  ┌─────────────────────────────────────────────┐   │
│  │ [升级点数+100]  [解锁所有结局]              │   │
│  │ [解锁所有升级]  [完成所有任务]              │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

**交互**: 点击按钮 → 弹出确认对话框 → 确认后执行修改 → 显示成功提示

### 5.4 卡牌管理页
```
┌─────────────────────────────────────────────────────┐
│  卡牌管理                                           │
├─────────────────────────────────────────────────────┤
│  [添加卡牌]  [替换卡牌]  [删除卡牌]                  │
├─────────────────────────────────────────────────────┤
│  筛选: [全部 ▼]  搜索: [____________]  排序: [UID ▼]│
├─────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────┐   │
│  │ ☐ │ UID │ 名称      │ 类别 │ 数量 │ 操作   │   │
│  ├───┼─────┼───────────┼──────┼──────┼────────┤   │
│  │ ☐ │ 29  │ 阿尔图    │ 人物 │ 1    │ [编辑] │   │
│  │ ☐ │ 45  │ 长剑      │ 装备 │ 1    │ [编辑] │   │
│  │ ☐ │ 160 │ 苏丹卡1   │ 苏丹 │ 1    │ [编辑] │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

**交互**:
- 删除: 选中卡牌 → 点击删除 → 确认对话框 → 删除
- 替换: 选中卡牌 → 点击替换 → CardPickerView → 确认 → 替换

### 5.5 卡牌详情弹窗

点击卡牌管理页的卡牌行或卡牌选择器的列表项时，弹出详情弹窗。

**两种模式**：

| 模式 | 触发场景 | 数据来源 | 显示内容差异 |
|------|----------|----------|--------------|
| 实例模式 | 卡牌管理页点击 | 存档卡牌实例 + 模板 | 显示实例特有数据（UID、数量、生命值、背包位置、自定义文本） |
| 模板模式 | 添加/替换选择器点击 | 仅模板数据 | 显示模板原始数据，无实例信息 |

```
┌─────────────────────────────────────────────────────┐
│  卡牌详情                                      [×]  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  名称: 阿尔图                                       │
│  类别: 人物 | 品级: ★★★                              │
│  模板ID: 2000001 | UID: 29                          │
│                                                     │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  描述:                                              │
│  游戏的主角，玩家扮演的角色。                          │
│                                                     │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  属性:                                              │
│  体魄: 3  魅力: 2  智慧: 4                          │
│  隐匿: 2  战斗: 2  社交: 2  生存: 2                  │
│                                                     │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  装备槽: 武器、服装、饰品                             │
│  已装备:                                            │
│    • 幸运护符 (饰品)                                 │
│    • 长剑 (武器)                                    │
│                                                     │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  数量: 1 | 生命: 0 | 背包位置: 15                    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**展示字段说明**：

| 区域 | 字段 | 来源 | 说明 |
|------|------|------|------|
| 基本信息 | 名称 | 实例custom_name > 模板name | 主角卡显示存档角色名；苏丹卡显示等级 |
| 基本信息 | 类别 | 模板type/title推导 | 人物/装备/书籍/苏丹卡/其他 |
| 基本信息 | 品级 | 模板rare | 星级显示（1-5星） |
| 基本信息 | 模板ID | 实例templateId / 模板id | — |
| 基本信息 | UID | 实例uid | 仅实例模式显示 |
| 描述 | text | 模板text | 卡牌描述文本 |
| 属性 | tag | 实例tag（优先）或模板tag | 英文key转中文显示名，仅显示can_visible=true的标签 |
| 装备信息 | 装备槽 | 模板equip_slots | 可装备的槽位类型 |
| 装备信息 | 已装备 | 实例equips | 嵌套卡牌实例，显示名称和类别 |
| 实例信息 | 数量 | 实例count | 堆叠数量 |
| 实例信息 | 生命 | 实例life | 苏丹卡显示剩余回合数 |
| 实例信息 | 背包位置 | 实例bag/bagpos | 仅实例模式显示 |

**交互**：
- 点击卡牌行/列表项 → 弹出详情弹窗
- 点击关闭按钮或弹窗外部 → 关闭弹窗
- 只读展示，无编辑功能

### 5.6 通用卡牌选择器 (CardPickerView)
```
┌─────────────────────────────────────┐
│  选择卡牌                      [×]  │
├─────────────────────────────────────┤
│  类别: [全部 ▼]                     │
│  搜索: [____________]               │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐ │
│  │ • 阿尔图 (2000001)            │ │
│  │   人物 | 体魄:2 魅力:2 ...    │ │
│  │ • 长剑 (2000045)              │ │
│  │   装备 | 攻击+5               │ │
│  └───────────────────────────────┘ │
├─────────────────────────────────────┤
│              [选择]  [取消]         │
└─────────────────────────────────────┘
```

### 5.7 人物属性页

**人物选择过滤条件**：`bagpos > 0`（只在背包中可见的人物卡）且分类为 `.character`。

```
┌─────────────────────────────────────────────────────┐
│  人物属性                                           │
├─────────────────────────────────────────────────────┤
│  选择人物: [阿尔图 ▼]                               │
├─────────────────────────────────────────────────────┤
│  体魄:  [__10__]  [-] [+]                          │
│  魅力:  [__10__]  [-] [+]                          │
│  智慧:  [__10__]  [-] [+]                          │
│  隐匿:  [__10__]  [-] [+]                          │
│  战斗:  [__10__]  [-] [+]                          │
│  社交:  [__10__]  [-] [+]                          │
│  生存:  [__10__]  [-] [+]                          │
├─────────────────────────────────────────────────────┤
│              [应用修改]                             │
└─────────────────────────────────────────────────────┘
```

### 5.8 计数器页
```
┌─────────────────────────────────────────────────────┐
│  计数器                                             │
├─────────────────────────────────────────────────────┤
│  作用域: [全部 ▼]  搜索: [____________]             │
├─────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────┐   │
│  │ ID       │ 名称        │ 当前值 │ 操作     │   │
│  ├─────────────────────────────────────────────┤   │
│  │ 7000195  │ 苏丹猜忌    │ 5      │ [编辑]   │   │
│  │ 7000567  │ 家被砸      │ 0      │ [编辑]   │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

**注意**: 计数器名称从配置文件加载，如无法获取则显示ID

## 六、核心服务设计

### 6.1 SaveManager

```swift
class SaveManager {
    static let saveRootDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA")
    
    var currentSavePath: URL?
    var currentGlobalPath: URL?
    let backupDir: URL
    let maxBackups = 10
    
    struct SaveInfo {
        let steamId: String
        let autoSavePath: URL
        let globalPath: URL
        let modifiedDate: Date
    }
    
    // 扫描存档目录，返回找到的存档列表
    func scanSaveDirectories() -> [SaveInfo]
    
    // 从指定路径加载存档
    func loadSave(from path: URL) throws -> SaveData
    func loadGlobal(from path: URL) throws -> GlobalData
    
    // 保存存档（自动备份 + 合并写入 + 原子操作）
    func saveSave(_ save: SaveData, to path: URL) throws
    func saveGlobal(_ global: GlobalData, to path: URL) throws
    
    // 备份文件
    func backupFile(at sourcePath: URL, to backupDir: URL) throws
}
```

**关键特性**:
- `scanSaveDirectories()` 遍历 SAVEDATA 下的 SteamID 子目录
- `loadSave/loadGlobal` 使用 Codable 解析，失败时抛出 `SaveError`
- `saveSave/saveGlobal` 自动备份 + 与原始 JSON 合并（保留未建模字段）+ 原子写入
- 备份保留最近 10 个，自动清理旧备份

### 6.2 ConfigLoader
```swift
class ConfigLoader {
    var configDirectory: URL?
    var cardTemplates: [Int: CardTemplate] = [:]
    var tagTemplates: [String: TagTemplate] = [:]
    var upgradeTemplates: [Int: UpgradeTemplate] = [:]
    var questTemplates: [Int: QuestTemplate] = [:]
    var overTemplates: [Int: OverTemplate] = [:]
    
    // 自动定位游戏config目录
    func locateConfigDirectory() -> URL? {
        // 1. 已知路径
        let knownPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Steam/steamapps/common/Sultan's Game/Sultan's Game.app/Contents/Resources/Data/StreamingAssets/config")
        if FileManager.default.fileExists(atPath: knownPath.path) {
            return knownPath
        }
        // 2. Spotlight扫描
        let task = Process()
        task.launchPath = "/usr/bin/mdfind"
        task.arguments = ["kMDItemFSName == 'cards.json'"]
        // ... 解析输出，提取目录
        return nil
    }
    
    func loadAllConfigs() throws
    func getCardName(id: Int) -> String  // 返回模板名或ID字符串
    func getCardDisplayName(card: Card, saveName: String?) -> String  // custom_name > saveName(主角卡) > 模板名
    func getCounterName(id: String) -> String
}
```

### 6.3 CardService
```swift
class CardService {
    var configLoader: ConfigLoader
    
    func getCards(from save: SaveData) -> [(card: Card, template: CardTemplate?)]
    func filterByCategory(_ cards: [Card], category: CardCategory) -> [Card]
    func addCard(to save: inout SaveData, templateId: Int, count: Int = 1)
    func replaceCard(in save: inout SaveData, cardUid: Int, newTemplateId: Int)
    func deleteCard(from save: inout SaveData, cardUid: Int) -> Bool  // 检查仪式引用
    func updateCharacterAttribute(in save: inout SaveData, characterUid: Int, attribute: AttributeType, value: Int)
    func categorize(template: CardTemplate) -> CardCategory
    
    // 删除前检查仪式引用
    func isCardInRite(save: SaveData, cardUid: Int) -> Bool
}
```

### 6.4 卡牌分类逻辑
```swift
func categorize(template: CardTemplate) -> CardCategory {
    if template.type == "sudan" { return .sudan }
    if template.type == "char" { return .character }
    if template.equip_slots.contains(where: { ["武器","服装","饰品","驯兽"].contains($0) }) {
        return .equipment
    }
    if template.tag.keys.contains("读物") { return .book }
    return .other
}
```

## 七、错误处理

| 场景 | 处理方式 |
|------|----------|
| 未找到存档目录 | 显示"未检测到存档，请先运行游戏" |
| 多个SteamID存档 | 弹窗列出供选择（显示SteamID和最后修改时间） |
| JSON解析失败 | 弹窗显示错误详情，建议检查文件完整性 |
| 写入失败（权限） | 弹窗提示，建议检查文件权限 |
| 备份失败 | 警告弹窗，让用户确认是否继续保存 |
| 卡牌UID冲突 | 自动递增UID，保证唯一性 |
| 删除被仪式引用的卡牌 | 警告弹窗，提示"该卡牌正在仪式中使用" |
| 属性值超出范围(0-999) | 输入框限制范围，超范围时显示警告 |
| 游戏正在运行 | 启动时检测游戏进程，显示警告 |
| 游戏config目录未找到 | 优雅降级，卡牌/计数器只显示ID不显示名称 |
| 快捷修改重复点击 | 操作后短暂禁用按钮 |

## 八、构建与日常使用

### 8.1 不上架App Store的本地分发方案

目标：构建一次后，app出现在Launchpad/Spotlight中，后续修改只需重新build即可。

**方案**: `xcodebuild` 命令行构建 + 复制到 `~/Applications/`

```bash
# build.sh - 一键构建并安装到本地Applications
#!/bin/bash
set -e

PROJECT="SultanTrainer.xcodeproj"
SCHEME="SultanTrainer"
BUILD_DIR="./build"

xcodebuild -project "$PROJECT" \
           -scheme "$SCHEME" \
           -configuration Debug \
           -derivedDataPath "$BUILD_DIR" \
           build

# 找到构建产物
APP_PATH=$(find "$BUILD_DIR/Build/Products/Debug" -name "*.app" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "构建失败：未找到.app文件"
    exit 1
fi

# 复制到本地Applications
mkdir -p ~/Applications
rm -rf ~/Applications/SultanTrainer.app
cp -R "$APP_PATH" ~/Applications/SultanTrainer.app

echo "已安装到 ~/Applications/SultanTrainer.app"
echo "可通过 Spotlight 或 Launchpad 启动"
```

**工作流**:
1. 首次：`./build.sh` → app出现在Launchpad
2. 代码修改后：重新运行 `./build.sh` → 覆盖旧版本
3. 直接 `open ~/Applications/SultanTrainer.app` 或 Spotlight 搜索启动

**注意**:
- 无需签名（本地使用），但首次打开需在"系统设置 → 隐私与安全性"中允许
- 或添加 ad-hoc 签名: `codesign --sign - ~/Applications/SultanTrainer.app`
- `~/Applications/` 中的app会自动出现在Launchpad中

## 九、注意事项

1. **UID唯一性**: 新增卡牌时，`uid` 必须大于等于 `card_uid_index`，并同步更新
2. **存档备份**: 修改前务必备份，JSON无校验和，错误数据可能导致游戏崩溃
3. **回合快照**: 修改 `auto_save.json` 后对应的回合快照可能不一致
4. **全局 vs 局内**: `global.json` 跨局生效，`auto_save.json` 仅当前局
5. **仪式一致性**: 修改仪式槽位中的卡牌UID时，该UID必须在 `cards[]` 数组中存在
6. **configVersion**: 修改存档时保持不变
7. **游戏运行检测**: 修改存档前建议关闭游戏，避免冲突
8. **JSON编码**: 使用 `.withoutEscapingSlashes` 避免中文被转义
