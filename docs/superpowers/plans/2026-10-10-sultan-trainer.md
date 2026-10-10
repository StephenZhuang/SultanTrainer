# SultanTrainer 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个 Mac 原生 SwiftUI 存档修改器，支持快捷修改和高级编辑《苏丹的游戏》存档。

**Architecture:** MVVM + Service 分层。Model 层 Codable 解析游戏 JSON；Service 层处理存档读写、卡牌操作、快捷修改；ViewModel 持有数据并暴露给 View；View 层纯展示。启动时自动定位游戏配置和存档，用户修改内存中的数据后手动保存。

**Tech Stack:** SwiftUI, Swift 5.9+, macOS 13.0+, Codable, xcodebuild CLI

---

## 文件结构

```
SultanTrainer/SultanTrainer/SultanTrainer/
├── SultanTrainerApp.swift              # App入口，注入环境对象
├── ContentView.swift                   # NavigationSplitView主窗口
├── Models/
│   ├── Enums.swift                     # CardCategory, AttributeType, CounterScope, SidebarItem
│   ├── Card.swift                      # Card实例模型
│   ├── Rite.swift                      # Rite + CardReference + TimingRound
│   ├── SaveData.swift                  # auto_save.json模型
│   ├── GlobalData.swift                # global.json模型
│   └── CardTemplate.swift              # CardTemplate, TagTemplate, UpgradeTemplate, QuestTemplate, OverTemplate
├── Services/
│   ├── ConfigLoader.swift              # 定位游戏config目录，加载模板字典
│   ├── SaveManager.swift               # 存档扫描、加载、备份、原子写入
│   ├── CardService.swift               # 卡牌增删改查、分类、仪式引用检查
│   └── QuickModifiers.swift            # 快捷修改方法（金币+999、全属性满等）
├── ViewModels/
│   └── AppViewModel.swift              # 全局状态：存档数据、修改标记、保存逻辑
├── Views/
│   ├── QuickModify/
│   │   └── QuickModifyView.swift
│   ├── Card/
│   │   ├── CardListView.swift
│   │   └── CardPickerView.swift
│   ├── Character/
│   │   └── CharacterAttributeView.swift
│   ├── Counter/
│   │   └── CounterEditorView.swift
│   ├── Rite/
│   │   └── RiteEditorView.swift
│   ├── Global/
│   │   └── GlobalDataView.swift
│   └── Components/
│       └── SaveStatusView.swift
└── build.sh                            # 项目根目录

SultanTrainer/SultanTrainer/SultanTrainerTests/
├── CardServiceTests.swift
├── QuickModifiersTests.swift
├── SaveManagerTests.swift
└── ConfigLoaderTests.swift
```

---

## Task 1: 项目目录结构搭建

**Files:**
- Create directories under `SultanTrainer/SultanTrainer/SultanTrainer/`

- [ ] **Step 1: 创建目录结构**

```bash
cd SultanTrainer/SultanTrainer/SultanTrainer
mkdir -p Models Services ViewModels Views/QuickModify Views/Card Views/Character Views/Counter Views/Rite Views/Global Views/Components
```

- [ ] **Step 2: 验证目录创建成功**

Run: `find SultanTrainer/SultanTrainer/SultanTrainer -type d | sort`
Expected: 看到 Models, Services, ViewModels, Views/* 等目录

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/
git commit -m "chore: create project directory structure"
```

---

## Task 2: Enums 模型

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Models/Enums.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/EnumsTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/EnumsTests.swift
import XCTest
@testable import SultanTrainer

final class EnumsTests: XCTestCase {
    
    func testCardCategoryAllCases() {
        XCTAssertEqual(CardCategory.allCases.count, 5)
    }
    
    func testAttributeTypeAllCases() {
        XCTAssertEqual(AttributeType.allCases.count, 7)
    }
    
    func testAttributeTypeRawValues() {
        XCTAssertEqual(AttributeType.physique.rawValue, "physique")
        XCTAssertEqual(AttributeType.charm.rawValue, "charm")
        XCTAssertEqual(AttributeType.wisdom.rawValue, "wisdom")
        XCTAssertEqual(AttributeType.conceal.rawValue, "conceal")
        XCTAssertEqual(AttributeType.battle.rawValue, "battle")
        XCTAssertEqual(AttributeType.social.rawValue, "social")
        XCTAssertEqual(AttributeType.survival.rawValue, "survival")
    }
    
    func testCounterScopeFromId() {
        XCTAssertEqual(CounterScope(fromId: "7000195"), .session)
        XCTAssertEqual(CounterScope(fromId: "7100001"), .persistent)
        XCTAssertEqual(CounterScope(fromId: "7200131"), .achievement)
        XCTAssertEqual(CounterScope(fromId: "7220001"), .completion)
        XCTAssertEqual(CounterScope(fromId: "7230001"), .unlock)
        XCTAssertNil(CounterScope(fromId: "9999999"))
    }
    
    func testSidebarItemAllCases() {
        XCTAssertEqual(SidebarItem.allCases.count, 6)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/EnumsTests 2>&1 | tail -5`
Expected: 编译失败，类型未定义

- [ ] **Step 3: 实现 Enums**

```swift
// Models/Enums.swift
import Foundation

/// 卡牌类别
enum CardCategory: String, CaseIterable, Identifiable {
    case character = "人物"
    case equipment = "装备"
    case book = "书籍"
    case sudan = "苏丹卡"
    case other = "其他"
    
    var id: String { rawValue }
}

/// 人物属性类型
enum AttributeType: String, CaseIterable, Identifiable {
    case physique = "physique"
    case charm = "charm"
    case wisdom = "wisdom"
    case conceal = "conceal"
    case battle = "battle"
    case social = "social"
    case survival = "survival"
    
    var id: String { rawValue }
    
    /// 中文显示名
    var displayName: String {
        switch self {
        case .physique: return "体魄"
        case .charm: return "魅力"
        case .wisdom: return "智慧"
        case .conceal: return "隐匿"
        case .battle: return "战斗"
        case .social: return "社交"
        case .survival: return "生存"
        }
    }
}

/// 计数器作用域
enum CounterScope: String, CaseIterable, Identifiable {
    case session = "局内状态"
    case persistent = "跨局数据"
    case achievement = "成就"
    case completion = "完成记录"
    case unlock = "解锁"
    
    var id: String { rawValue }
    
    /// 根据计数器ID前缀判断作用域
    init?(fromId id: String) {
        guard let prefix = Int(String(id.prefix(4))) else { return nil }
        switch prefix {
        case 7000: self = .session
        case 7100: self = .persistent
        case 7200: self = .achievement
        case 7220: self = .completion
        case 7230: self = .unlock
        default: return nil
        }
    }
}

/// 侧边栏导航项
enum SidebarItem: String, CaseIterable, Identifiable {
    case quickModify = "快捷修改"
    case cardManage = "卡牌管理"
    case characterAttribute = "人物属性"
    case counter = "计数器"
    case rite = "仪式"
    case globalData = "全局数据"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .quickModify: return "bolt.fill"
        case .cardManage: return "rectangle.stack.fill"
        case .characterAttribute: return "person.fill"
        case .counter: return "number"
        case .rite: return "star.fill"
        case .globalData: return "globe"
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/EnumsTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Models/Enums.swift SultanTrainer/SultanTrainer/SultanTrainerTests/EnumsTests.swift
git commit -m "feat: add Enums model (CardCategory, AttributeType, CounterScope, SidebarItem)"
```

---

## Task 3: Card 模型

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Models/Card.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/CardModelTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/CardModelTests.swift
import XCTest
@testable import SultanTrainer

final class CardModelTests: XCTestCase {
    
    func testCardDecoding() throws {
        let json = """
        {
            "uid": 29,
            "id": 2000001,
            "count": 1,
            "life": 0,
            "rareup": 0,
            "tag": {"physique": 2, "charm": 2},
            "equip_slots": ["weapon", "cloth"],
            "equips": [],
            "bag": 0,
            "bagpos": 15,
            "custom_name": "",
            "custom_text": ""
        }
        """.data(using: .utf8)!
        
        let card = try JSONDecoder().decode(Card.self, from: json)
        XCTAssertEqual(card.uid, 29)
        XCTAssertEqual(card.id, 2000001)
        XCTAssertEqual(card.count, 1)
        XCTAssertEqual(card.life, 0)
        XCTAssertEqual(card.tag["physique"], 2)
        XCTAssertEqual(card.equip_slots, ["weapon", "cloth"])
    }
    
    func testCardDecodingWithUnknownFields() throws {
        let json = """
        {
            "uid": 1,
            "id": 2000001,
            "count": 1,
            "life": 0,
            "rareup": 0,
            "tag": {},
            "equip_slots": [],
            "equips": [],
            "bag": 0,
            "bagpos": 0,
            "custom_name": "",
            "custom_text": "",
            "future_field": "should_be_ignored"
        }
        """.data(using: .utf8)!
        
        let card = try JSONDecoder().decode(Card.self, from: json)
        XCTAssertEqual(card.uid, 1)
    }
    
    func testCardDecodingWithMissingOptionalFields() throws {
        let json = """
        {
            "uid": 1,
            "id": 2000001,
            "count": 1,
            "life": 0,
            "rareup": 0,
            "tag": {},
            "equip_slots": [],
            "equips": []
        }
        """.data(using: .utf8)!
        
        let card = try JSONDecoder().decode(Card.self, from: json)
        XCTAssertEqual(card.bag, 0)
        XCTAssertEqual(card.bagpos, 0)
        XCTAssertEqual(card.custom_name, "")
        XCTAssertEqual(card.custom_text, "")
    }
    
    func testCardIdentifiable() {
        let card = Card(uid: 42, id: 2000001)
        XCTAssertEqual(card.id, 2000001)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/CardModelTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 Card**

```swift
// Models/Card.swift
import Foundation

/// 卡牌实例，对应存档中 cards/sudan_card_pool/equips 数组的元素
struct Card: Codable, Identifiable, Hashable {
    var uid: Int
    var id: Int
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
    
    /// 便捷初始化，用于创建新卡牌实例
    init(uid: Int, id: Int, count: Int = 1, life: Int = 0, rareup: Int = 0,
         tag: [String: Int] = [:], equip_slots: [String] = [], equips: [Card] = [],
         bag: Int = 0, bagpos: Int = 0, custom_name: String = "", custom_text: String = "") {
        self.uid = uid
        self.id = id
        self.count = count
        self.life = life
        self.rareup = rareup
        self.tag = tag
        self.equip_slots = equip_slots
        self.equips = equips
        self.bag = bag
        self.bagpos = bagpos
        self.custom_name = custom_name
        self.custom_text = custom_text
    }
    
    // MARK: - Codable 容错解码
    
    private enum CodingKeys: String, CodingKey {
        case uid, id, count, life, rareup, tag, equip_slots, equips, bag, bagpos, custom_name, custom_text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        self.id = try container.decode(Int.self, forKey: .id)
        count = (try? container.decode(Int.self, forKey: .count)) ?? 1
        life = (try? container.decode(Int.self, forKey: .life)) ?? 0
        rareup = (try? container.decode(Int.self, forKey: .rareup)) ?? 0
        tag = (try? container.decode([String: Int].self, forKey: .tag)) ?? [:]
        equip_slots = (try? container.decode([String].self, forKey: .equip_slots)) ?? []
        equips = (try? container.decode([Card].self, forKey: .equips)) ?? []
        bag = (try? container.decode(Int.self, forKey: .bag)) ?? 0
        bagpos = (try? container.decode(Int.self, forKey: .bagpos)) ?? 0
        custom_name = (try? container.decode(String.self, forKey: .custom_name)) ?? ""
        custom_text = (try? container.decode(String.self, forKey: .custom_text)) ?? ""
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/CardModelTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Models/Card.swift SultanTrainer/SultanTrainer/SultanTrainerTests/CardModelTests.swift
git commit -m "feat: add Card model with fault-tolerant Codable"
```

---

## Task 4: Rite + TimingRound 模型

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Models/Rite.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/RiteModelTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/RiteModelTests.swift
import XCTest
@testable import SultanTrainer

final class RiteModelTests: XCTestCase {
    
    func testRiteDecoding() throws {
        let json = """
        {
            "uid": 5,
            "id": 5001001,
            "cards": {
                "s1": null,
                "s2": {"uid": 112},
                "s3": null,
                "s4": null,
                "s5": null,
                "s6": null,
                "s7": null
            }
        }
        """.data(using: .utf8)!
        
        let rite = try JSONDecoder().decode(Rite.self, from: json)
        XCTAssertEqual(rite.uid, 5)
        XCTAssertEqual(rite.id, 5001001)
        XCTAssertNil(rite.cards["s1"])
        XCTAssertEqual(rite.cards["s2"]?.uid, 112)
    }
    
    func testTimingRoundDecoding() throws {
        let json = """
        {"round": 5, "status": 1}
        """.data(using: .utf8)!
        
        let timing = try JSONDecoder().decode(TimingRound.self, from: json)
        XCTAssertEqual(timing.round, 5)
        XCTAssertEqual(timing.status, 1)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/RiteModelTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 Rite + TimingRound**

```swift
// Models/Rite.swift
import Foundation

/// 仪式实例
struct Rite: Codable, Identifiable, Hashable {
    var uid: Int
    var id: Int
    var cards: [String: CardReference?]
    
    /// 仪式槽位中的卡牌引用
    struct CardReference: Codable, Hashable {
        var uid: Int
    }
    
    // MARK: - Codable 容错解码
    
    private enum CodingKeys: String, CodingKey {
        case uid, id, cards
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        self.id = try container.decode(Int.self, forKey: .id)
        cards = (try? container.decode([String: CardReference?].self, forKey: .cards)) ?? [:]
    }
    
    init(uid: Int, id: Int, cards: [String: CardReference?] = [:]) {
        self.uid = uid
        self.id = id
        self.cards = cards
    }
}

/// 定时事件调度
struct TimingRound: Codable, Hashable {
    var round: Int
    var status: Int
    
    private enum CodingKeys: String, CodingKey {
        case round, status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.round = (try? container.decode(Int.self, forKey: .round)) ?? 0
        status = (try? container.decode(Int.self, forKey: .status)) ?? 0
    }
    
    init(round: Int, status: Int) {
        self.round = round
        self.status = status
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/RiteModelTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Models/Rite.swift SultanTrainer/SultanTrainer/SultanTrainerTests/RiteModelTests.swift
git commit -m "feat: add Rite and TimingRound models"
```

---

## Task 5: SaveData 模型

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Models/SaveData.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/SaveDataModelTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/SaveDataModelTests.swift
import XCTest
@testable import SultanTrainer

final class SaveDataModelTests: XCTestCase {
    
    func testSaveDataDecodingMinimal() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "哈兰德",
            "difficulty": 3,
            "round": 1,
            "min_round": 0,
            "saveTime": "2026-10-10T00:00:00Z",
            "card_uid_index": 261,
            "rite_uid_index": 7,
            "success": false,
            "over_reason": -2147483648,
            "cards": [],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null
        }
        """.data(using: .utf8)!
        
        let save = try JSONDecoder().decode(SaveData.self, from: json)
        XCTAssertEqual(save.configId, 1)
        XCTAssertEqual(save.name, "哈兰德")
        XCTAssertEqual(save.cards.count, 0)
        XCTAssertEqual(save.card_uid_index, 261)
    }
    
    func testSaveDataDecodingWithUnknownFields() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "Test",
            "difficulty": 1,
            "round": 1,
            "min_round": 0,
            "saveTime": "",
            "card_uid_index": 1,
            "rite_uid_index": 1,
            "success": false,
            "over_reason": 0,
            "cards": [],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null,
            "new_future_field": 123
        }
        """.data(using: .utf8)!
        
        let save = try JSONDecoder().decode(SaveData.self, from: json)
        XCTAssertEqual(save.configId, 1)
    }
    
    func testSaveDataRoundTrip() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "Test",
            "difficulty": 1,
            "round": 5,
            "min_round": 0,
            "saveTime": "2026-10-10",
            "card_uid_index": 10,
            "rite_uid_index": 2,
            "success": true,
            "over_reason": 0,
            "cards": [{"uid":1,"id":2000001,"count":1,"life":0,"rareup":0,"tag":{},"equip_slots":[],"equips":[],"bag":0,"bagpos":0,"custom_name":"","custom_name":""}],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {"7000195": 5},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null
        }
        """.data(using: .utf8)!
        
        let save = try JSONDecoder().decode(SaveData.self, from: json)
        let encoded = try JSONEncoder().encode(save)
        let decoded = try JSONDecoder().decode(SaveData.self, from: encoded)
        XCTAssertEqual(decoded.round, 5)
        XCTAssertEqual(decoded.success, true)
        XCTAssertEqual(decoded.counter["7000195"], 5)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/SaveDataModelTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 SaveData**

```swift
// Models/SaveData.swift
import Foundation

/// auto_save.json 数据模型
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
    
    // MARK: - Codable 容错解码
    
    private enum CodingKeys: String, CodingKey {
        case configId, configVersion, name, difficulty, round, min_round
        case saveTime, card_uid_index, rite_uid_index, success, over_reason
        case cards, rites, sudan_card_pool, counter, event_status
        case timing_rounds, gen_cards, gen_tags, ithink_card
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configId = try container.decode(Int.self, forKey: .configId)
        configVersion = (try? container.decode(Int.self, forKey: .configVersion)) ?? 0
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        difficulty = (try? container.decode(Int.self, forKey: .difficulty)) ?? 0
        round = (try? container.decode(Int.self, forKey: .round)) ?? 0
        min_round = (try? container.decode(Int.self, forKey: .min_round)) ?? 0
        saveTime = (try? container.decode(String.self, forKey: .saveTime)) ?? ""
        card_uid_index = (try? container.decode(Int.self, forKey: .card_uid_index)) ?? 0
        rite_uid_index = (try? container.decode(Int.self, forKey: .rite_uid_index)) ?? 0
        success = (try? container.decode(Bool.self, forKey: .success)) ?? false
        over_reason = (try? container.decode(Int.self, forKey: .over_reason)) ?? 0
        cards = (try? container.decode([Card].self, forKey: .cards)) ?? []
        rites = (try? container.decode([Rite].self, forKey: .rites)) ?? []
        sudan_card_pool = (try? container.decode([Card].self, forKey: .sudan_card_pool)) ?? []
        counter = (try? container.decode([String: Int].self, forKey: .counter)) ?? [:]
        event_status = (try? container.decode([String: Bool].self, forKey: .event_status)) ?? [:]
        timing_rounds = (try? container.decode([String: TimingRound].self, forKey: .timing_rounds)) ?? [:]
        gen_cards = (try? container.decode([String: Int].self, forKey: .gen_cards)) ?? [:]
        gen_tags = (try? container.decode([String: Int].self, forKey: .gen_tags)) ?? [:]
        ithink_card = try? container.decode(Card.self, forKey: .ithink_card)
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/SaveDataModelTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Models/SaveData.swift SultanTrainer/SultanTrainer/SultanTrainerTests/SaveDataModelTests.swift
git commit -m "feat: add SaveData model with fault-tolerant Codable"
```

---

## Task 6: GlobalData 模型

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Models/GlobalData.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/GlobalDataModelTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/GlobalDataModelTests.swift
import XCTest
@testable import SultanTrainer

final class GlobalDataModelTests: XCTestCase {
    
    func testGlobalDataDecodingMinimal() throws {
        let json = """
        {
            "saveTime": "2026-10-10",
            "finishTutorial": true,
            "inGame": true,
            "totalRound": 10,
            "totalPoint": 637,
            "usedPoint": 614,
            "upgrade": {},
            "quest": {},
            "achievements": {},
            "counter": {},
            "doneRite": [],
            "doneEvent": [],
            "overID": [],
            "gameStatistics": {},
            "mods": [],
            "hasEnterSudanBox": true,
            "hasEnterQuest": true,
            "backToPrevRound": 5,
            "roundRollback": 0,
            "overRecord": [],
            "showedGalleryCards": [],
            "showedPrompt": []
        }
        """.data(using: .utf8)!
        
        let global = try JSONDecoder().decode(GlobalData.self, from: json)
        XCTAssertEqual(global.totalPoint, 637)
        XCTAssertEqual(global.usedPoint, 614)
        XCTAssertEqual(global.overID.count, 0)
    }
    
    func testGlobalDataDecodingWithUnknownFields() throws {
        let json = """
        {
            "saveTime": "",
            "finishTutorial": true,
            "inGame": false,
            "totalRound": 0,
            "totalPoint": 0,
            "usedPoint": 0,
            "upgrade": {},
            "quest": {},
            "achievements": {},
            "counter": {},
            "doneRite": [],
            "doneEvent": [],
            "overID": [1, 2, 3],
            "gameStatistics": {},
            "mods": [],
            "hasEnterSudanBox": false,
            "hasEnterQuest": false,
            "backToPrevRound": 0,
            "roundRollback": 0,
            "overRecord": [],
            "showedGalleryCards": [],
            "showedPrompt": [],
            "future_field": true
        }
        """.data(using: .utf8)!
        
        let global = try JSONDecoder().decode(GlobalData.self, from: json)
        XCTAssertEqual(global.overID, [1, 2, 3])
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/GlobalDataModelTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 GlobalData**

```swift
// Models/GlobalData.swift
import Foundation

/// global.json 数据模型
struct GlobalData: Codable {
    var saveTime: String
    var finishTutorial: Bool
    var inGame: Bool
    var totalRound: Int
    var totalPoint: Int
    var usedPoint: Int
    var upgrade: [String: Int]
    var quest: [String: Int]
    var achievements: [String: Bool]
    var counter: [String: Int]
    var doneRite: [Int]
    var doneEvent: [Int]
    var overID: [Int]
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
        
        private enum CodingKeys: String, CodingKey {
            case startTimes, overTimes
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            startTimes = (try? container.decode(Int.self, forKey: .startTimes)) ?? 0
            overTimes = (try? container.decode(Int.self, forKey: .overTimes)) ?? 0
        }
        
        init(startTimes: Int = 0, overTimes: Int = 0) {
            self.startTimes = startTimes
            self.overTimes = overTimes
        }
    }
    
    struct OverRecord: Codable {
        var overID: Int
        var round: Int
        var name: String
        
        private enum CodingKeys: String, CodingKey {
            case overID, round, name
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            overID = (try? container.decode(Int.self, forKey: .overID)) ?? 0
            round = (try? container.decode(Int.self, forKey: .round)) ?? 0
            name = (try? container.decode(String.self, forKey: .name)) ?? ""
        }
        
        init(overID: Int, round: Int, name: String = "") {
            self.overID = overID
            self.round = round
            self.name = name
        }
    }
    
    // MARK: - Codable 容错解码
    
    private enum CodingKeys: String, CodingKey {
        case saveTime, finishTutorial, inGame, totalRound, totalPoint, usedPoint
        case upgrade, quest, achievements, counter, doneRite, doneEvent, overID
        case gameStatistics, mods, hasEnterSudanBox, hasEnterQuest, backToPrevRound
        case roundRollback, overRecord, showedGalleryCards, showedPrompt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        saveTime = (try? container.decode(String.self, forKey: .saveTime)) ?? ""
        finishTutorial = (try? container.decode(Bool.self, forKey: .finishTutorial)) ?? false
        inGame = (try? container.decode(Bool.self, forKey: .inGame)) ?? false
        totalRound = (try? container.decode(Int.self, forKey: .totalRound)) ?? 0
        totalPoint = (try? container.decode(Int.self, forKey: .totalPoint)) ?? 0
        usedPoint = (try? container.decode(Int.self, forKey: .usedPoint)) ?? 0
        upgrade = (try? container.decode([String: Int].self, forKey: .upgrade)) ?? [:]
        quest = (try? container.decode([String: Int].self, forKey: .quest)) ?? [:]
        achievements = (try? container.decode([String: Bool].self, forKey: .achievements)) ?? [:]
        counter = (try? container.decode([String: Int].self, forKey: .counter)) ?? [:]
        doneRite = (try? container.decode([Int].self, forKey: .doneRite)) ?? []
        doneEvent = (try? container.decode([Int].self, forKey: .doneEvent)) ?? []
        overID = (try? container.decode([Int].self, forKey: .overID)) ?? []
        gameStatistics = (try? container.decode([String: GameStat].self, forKey: .gameStatistics)) ?? [:]
        mods = (try? container.decode([String].self, forKey: .mods)) ?? []
        hasEnterSudanBox = (try? container.decode(Bool.self, forKey: .hasEnterSudanBox)) ?? false
        hasEnterQuest = (try? container.decode(Bool.self, forKey: .hasEnterQuest)) ?? false
        backToPrevRound = (try? container.decode(Int.self, forKey: .backToPrevRound)) ?? 0
        roundRollback = (try? container.decode(Int.self, forKey: .roundRollback)) ?? 0
        overRecord = (try? container.decode([OverRecord].self, forKey: .overRecord)) ?? []
        showedGalleryCards = (try? container.decode([Int].self, forKey: .showedGalleryCards)) ?? []
        showedPrompt = (try? container.decode([String].self, forKey: .showedPrompt)) ?? []
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/GlobalDataModelTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Models/GlobalData.swift SultanTrainer/SultanTrainer/SultanTrainerTests/GlobalDataModelTests.swift
git commit -m "feat: add GlobalData model with fault-tolerant Codable"
```

---

## Task 7: CardTemplate 模型

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Models/CardTemplate.swift`

- [ ] **Step 1: 实现 CardTemplate 及相关模板模型**

```swift
// Models/CardTemplate.swift
import Foundation

/// 卡牌模板，来自 config/cards.json
struct CardTemplate: Codable, Identifiable {
    var id: Int
    var name: String
    var text: String
    var tag: [String: Int]
    var equip_slots: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id, name, text, tag, equip_slots
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
        tag = (try? container.decode([String: Int].self, forKey: .tag)) ?? [:]
        equip_slots = (try? container.decode([String].self, forKey: .equip_slots)) ?? []
    }
    
    init(id: Int, name: String = "", text: String = "", tag: [String: Int] = [:], equip_slots: [String] = []) {
        self.id = id
        self.name = name
        self.text = text
        self.tag = tag
        self.equip_slots = equip_slots
    }
}

/// 标签模板，来自 config/tag.json
struct TagTemplate: Codable {
    var id: String
    var name: String
    var tag_rank: Int
    var can_visible: Bool
    var can_inherit: Bool
    var type: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, tag_rank, can_visible, can_inherit, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? ""
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        tag_rank = (try? container.decode(Int.self, forKey: .tag_rank)) ?? 0
        can_visible = (try? container.decode(Bool.self, forKey: .can_visible)) ?? false
        can_inherit = (try? container.decode(Bool.self, forKey: .can_inherit)) ?? false
        type = (try? container.decode(String.self, forKey: .type)) ?? ""
    }
}

/// 升级模板，来自 config/upgrade.json
struct UpgradeTemplate: Codable, Identifiable {
    var id: Int
    var name: String
    var text: String
    var cost: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, name, text, cost
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
        cost = (try? container.decode(Int.self, forKey: .cost)) ?? 0
    }
}

/// 任务模板，来自 config/quest.json
struct QuestTemplate: Codable, Identifiable {
    var id: Int
    var name: String
    var text: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
    }
}

/// 结局模板，来自 config/over.json
struct OverTemplate: Codable {
    var name: String
    var text: String
    
    private enum CodingKeys: String, CodingKey {
        case name, text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Models/CardTemplate.swift
git commit -m "feat: add CardTemplate, TagTemplate, UpgradeTemplate, QuestTemplate, OverTemplate models"
```

---

## Task 8: ConfigLoader 服务

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Services/ConfigLoader.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/ConfigLoaderTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/ConfigLoaderTests.swift
import XCTest
@testable import SultanTrainer

final class ConfigLoaderTests: XCTestCase {
    
    func testLocateConfigDirectoryKnownPath() {
        let loader = ConfigLoader()
        let knownPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Steam/steamapps/common/Sultan's Game/Sultan's Game.app/Contents/Resources/Data/StreamingAssets/config")
        
        if FileManager.default.fileExists(atPath: knownPath.path) {
            let result = loader.locateConfigDirectory()
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.path, knownPath.path)
        }
    }
    
    func testGetCardNameWithLoadedTemplate() {
        let loader = ConfigLoader()
        loader.cardTemplates[2000001] = CardTemplate(id: 2000001, name: "阿尔图")
        XCTAssertEqual(loader.getCardName(id: 2000001), "阿尔图")
    }
    
    func testGetCardNameFallbackToId() {
        let loader = ConfigLoader()
        XCTAssertEqual(loader.getCardName(id: 9999999), "9999999")
    }
    
    func testCategorizeCard() {
        let loader = ConfigLoader()
        
        let character = CardTemplate(id: 2000001, name: "阿尔图")
        XCTAssertEqual(loader.categorize(template: character), .character)
        
        let sudan = CardTemplate(id: 2010001, name: "苏丹卡1")
        XCTAssertEqual(loader.categorize(template: sudan), .sudan)
        
        let weapon = CardTemplate(id: 2000045, name: "长剑", equip_slots: ["weapon"])
        XCTAssertEqual(loader.categorize(template: weapon), .equipment)
        
        let book = CardTemplate(id: 2000100, name: "古书", tag: ["book": 1])
        XCTAssertEqual(loader.categorize(template: book), .book)
        
        let other = CardTemplate(id: 2000090, name: "金币")
        XCTAssertEqual(loader.categorize(template: other), .other)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/ConfigLoaderTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 ConfigLoader**

```swift
// Services/ConfigLoader.swift
import Foundation

/// 游戏配置加载器，负责定位config目录并加载模板数据
class ConfigLoader {
    var configDirectory: URL?
    var cardTemplates: [Int: CardTemplate] = [:]
    var tagTemplates: [String: TagTemplate] = [:]
    var upgradeTemplates: [Int: UpgradeTemplate] = [:]
    var questTemplates: [Int: QuestTemplate] = [:]
    var overTemplates: [Int: OverTemplate] = [:]
    
    /// 自动定位游戏config目录
    func locateConfigDirectory() -> URL? {
        // 1. 已知路径
        let knownPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Steam/steamapps/common/Sultan's Game/Sultan's Game.app/Contents/Resources/Data/StreamingAssets/config")
        if FileManager.default.fileExists(atPath: knownPath.path) {
            configDirectory = knownPath
            return knownPath
        }
        
        // 2. Spotlight扫描
        if let spotlightPath = spotlightSearch() {
            configDirectory = spotlightPath
            return spotlightPath
        }
        
        return nil
    }
    
    /// 加载所有配置文件
    func loadAllConfigs() throws {
        guard let configDir = configDirectory else {
            return // 降级模式：不加载配置，UI只显示ID
        }
        
        try loadCardsConfig(from: configDir)
        try loadTagConfig(from: configDir)
        try loadUpgradeConfig(from: configDir)
        try loadQuestConfig(from: configDir)
        try loadOverConfig(from: configDir)
    }
    
    /// 获取卡牌名称，找不到时返回ID字符串
    func getCardName(id: Int) -> String {
        return cardTemplates[id]?.name ?? "\(id)"
    }
    
    /// 获取计数器名称
    func getCounterName(id: String) -> String {
        return tagTemplates[id]?.name ?? id
    }
    
    /// 卡牌分类
    func categorize(template: CardTemplate) -> CardCategory {
        if template.id >= 2010001 && template.id <= 2010016 {
            return .sudan
        }
        if template.id >= 2000001 && template.id <= 2000010 {
            return .character
        }
        let equipmentSlots = ["weapon", "cloth", "accessory", "animal_handling"]
        if template.equip_slots.contains(where: { equipmentSlots.contains($0) }) {
            return .equipment
        }
        if template.tag.keys.contains("book") {
            return .book
        }
        return .other
    }
    
    // MARK: - Private
    
    private func spotlightSearch() -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemFSName == 'cards.json'"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            
            for line in output.components(separatedBy: "\n") where !line.isEmpty {
                let url = URL(fileURLWithPath: line)
                let configDir = url.deletingLastPathComponent()
                // 验证是否是有效的config目录（包含cards.json）
                let cardsPath = configDir.appendingPathComponent("cards.json")
                if FileManager.default.fileExists(atPath: cardsPath.path) {
                    return configDir
                }
            }
        } catch {
            // Spotlight搜索失败，降级处理
        }
        return nil
    }
    
    private func loadCardsConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("cards.json")
        let data = try Data(contentsOf: url)
        // cards.json 格式: {"id": {template}, ...} 或 [{template}, ...]
        if let dict = try? JSONDecoder().decode([String: CardTemplate].self, from: data) {
            for (_, template) in dict {
                cardTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([CardTemplate].self, from: data) {
            for template in array {
                cardTemplates[template.id] = template
            }
        }
    }
    
    private func loadTagConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("tag.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: TagTemplate].self, from: data) {
            for (_, template) in dict {
                tagTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([TagTemplate].self, from: data) {
            for template in array {
                tagTemplates[template.id] = template
            }
        }
    }
    
    private func loadUpgradeConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("upgrade.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: UpgradeTemplate].self, from: data) {
            for (_, template) in dict {
                upgradeTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([UpgradeTemplate].self, from: data) {
            for template in array {
                upgradeTemplates[template.id] = template
            }
        }
    }
    
    private func loadQuestConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("quest.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: QuestTemplate].self, from: data) {
            for (_, template) in dict {
                questTemplates[template.id] = template
            }
        } else if let array = try? JSONDecoder().decode([QuestTemplate].self, from: data) {
            for template in array {
                questTemplates[template.id] = template
            }
        }
    }
    
    private func loadOverConfig(from configDir: URL) throws {
        let url = configDir.appendingPathComponent("over.json")
        let data = try Data(contentsOf: url)
        if let dict = try? JSONDecoder().decode([String: OverTemplate].self, from: data) {
            for (key, template) in dict {
                if let id = Int(key) {
                    overTemplates[id] = template
                }
            }
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/ConfigLoaderTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Services/ConfigLoader.swift SultanTrainer/SultanTrainer/SultanTrainerTests/ConfigLoaderTests.swift
git commit -m "feat: add ConfigLoader service with auto-detection and graceful degradation"
```

---

## Task 9: SaveManager 服务

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Services/SaveManager.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/SaveManagerTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/SaveManagerTests.swift
import XCTest
@testable import SultanTrainer

final class SaveManagerTests: XCTestCase {
    
    var tempDir: URL!
    var saveManager: SaveManager!
    
    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        saveManager = SaveManager()
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }
    
    func testLoadSaveFromPath() throws {
        let json = """
        {
            "configId": 1,
            "configVersion": 0,
            "name": "Test",
            "difficulty": 1,
            "round": 3,
            "min_round": 0,
            "saveTime": "2026-10-10",
            "card_uid_index": 10,
            "rite_uid_index": 1,
            "success": false,
            "over_reason": 0,
            "cards": [],
            "rites": [],
            "sudan_card_pool": [],
            "counter": {},
            "event_status": {},
            "timing_rounds": {},
            "gen_cards": {},
            "gen_tags": {},
            "ithink_card": null
        }
        """
        let fileUrl = tempDir.appendingPathComponent("auto_save.json")
        try json.write(to: fileUrl, atomically: true, encoding: .utf8)
        
        let save = try saveManager.loadSave(from: fileUrl)
        XCTAssertEqual(save.round, 3)
        XCTAssertEqual(save.name, "Test")
    }
    
    func testAtomicWrite() throws {
        let save = createMinimalSaveData()
        let fileUrl = tempDir.appendingPathComponent("test_save.json")
        
        try saveManager.atomicWrite(save, to: fileUrl)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileUrl.path))
        let loaded = try saveManager.loadSave(from: fileUrl)
        XCTAssertEqual(loaded.name, save.name)
    }
    
    func testBackupCreation() throws {
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 1, "rite_uid_index": 1,
            "success": false, "over_reason": 0,
            "cards": [], "rites": [], "sudan_card_pool": [],
            "counter": {}, "event_status": {}, "timing_rounds": {},
            "gen_cards": {}, "gen_tags": {}, "ithink_card": null
        }
        """
        let fileUrl = tempDir.appendingPathComponent("auto_save.json")
        try json.write(to: fileUrl, atomically: true, encoding: .utf8)
        
        let backupDir = tempDir.appendingPathComponent("backups")
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        try saveManager.backupFile(at: fileUrl, to: backupDir)
        
        let backups = try FileManager.default.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(backups.count, 1)
        XCTAssertTrue(backups[0].lastPathComponent.hasPrefix("auto_save_"))
    }
    
    private func createMinimalSaveData() -> SaveData {
        return SaveData(from: {
            struct MinimalDecoder: Decoder {
                var codingPath: [CodingKey] = []
                var userInfo: [CodingUserInfoKey: Any] = [:]
                func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
                    fatalError("not used")
                }
                func unkeyedContainer() throws -> UnkeyedDecodingContainer { fatalError() }
                func singleValueContainer() throws -> SingleValueDecodingContainer { fatalError() }
            }
            return MinimalDecoder()
        }())
        // 使用更简单的方式：
    }
}
```

> 注意：上面的 `createMinimalSaveData` 辅助方法需要简化。实际实现中通过 JSON 字符串创建测试数据。

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/SaveManagerTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 SaveManager**

```swift
// Services/SaveManager.swift
import Foundation

/// 存档管理器，负责扫描、加载、备份和保存存档
class SaveManager {
    static let saveRootDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA")
    
    var currentSavePath: URL?
    var currentGlobalPath: URL?
    
    let backupDir: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/SultanTrainer/backups")
    
    let maxBackups = 10
    
    struct SaveInfo {
        let steamId: String
        let autoSavePath: URL
        let globalPath: URL
        let modifiedDate: Date
    }
    
    /// 扫描存档根目录，返回找到的存档列表
    func scanSaveDirectories() -> [SaveInfo] {
        var results: [SaveInfo] = []
        let fm = FileManager.default
        
        guard fm.fileExists(atPath: Self.saveRootDir.path) else { return results }
        
        guard let steamDirs = try? fm.contentsOfDirectory(
            at: Self.saveRootDir,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return results }
        
        for dir in steamDirs {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { continue }
            
            let autoSavePath = dir.appendingPathComponent("auto_save.json")
            let globalPath = dir.appendingPathComponent("global.json")
            
            guard fm.fileExists(atPath: autoSavePath.path) else { continue }
            
            let attrs = try? fm.attributesOfItem(atPath: autoSavePath.path)
            let modifiedDate = attrs?[.modificationDate] as? Date ?? Date.distantPast
            
            results.append(SaveInfo(
                steamId: dir.lastPathComponent,
                autoSavePath: autoSavePath,
                globalPath: globalPath,
                modifiedDate: modifiedDate
            ))
        }
        
        return results.sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    /// 从指定路径加载存档
    func loadSave(from path: URL) throws -> SaveData {
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try decoder.decode(SaveData.self, from: data)
    }
    
    /// 从指定路径加载全局数据
    func loadGlobal(from path: URL) throws -> GlobalData {
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try decoder.decode(GlobalData.self, from: data)
    }
    
    /// 保存存档（自动备份 + 原子写入）
    func saveSave(_ save: SaveData, to path: URL) throws {
        try backupFile(at: path, to: backupDir)
        try atomicWrite(save, to: path)
        currentSavePath = path
    }
    
    /// 保存全局数据（自动备份 + 原子写入）
    func saveGlobal(_ global: GlobalData, to path: URL) throws {
        try backupFile(at: path, to: backupDir)
        try atomicWrite(global, to: path)
        currentGlobalPath = path
    }
    
    /// 备份文件
    func backupFile(at sourcePath: URL, to backupDir: URL) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: backupDir.path) {
            try fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupName = "\(sourcePath.deletingPathExtension().lastPathComponent)_\(timestamp).json"
        let backupPath = backupDir.appendingPathComponent(backupName)
        
        try fm.copyItem(at: sourcePath, to: backupPath)
        
        try cleanupOldBackups(in: backupDir)
    }
    
    /// 原子写入：先写临时文件再rename
    func atomicWrite<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        
        let tempUrl = url.appendingPathExtension("tmp")
        try data.write(to: tempUrl, options: .atomic)
        
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
        try fm.moveItem(at: tempUrl, to: url)
    }
    
    // MARK: - Private
    
    private func cleanupOldBackups(in dir: URL) throws {
        let fm = FileManager.default
        let backups = try fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey]
        ).filter { $0.pathExtension == "json" }
        .sorted {
            let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return date1 > date2
        }
        
        if backups.count > maxBackups {
            for oldBackup in backups[maxBackups...] {
                try fm.removeItem(at: oldBackup)
            }
        }
    }
}
```

- [ ] **Step 4: 修正测试中的辅助方法并运行**

将 `createMinimalSaveData` 改为通过 JSON 解码创建：

```swift
private func createMinimalSaveData() -> SaveData {
    let json = """
    {
        "configId": 1, "configVersion": 0, "name": "Test",
        "difficulty": 1, "round": 1, "min_round": 0,
        "saveTime": "", "card_uid_index": 1, "rite_uid_index": 1,
        "success": false, "over_reason": 0,
        "cards": [], "rites": [], "sudan_card_pool": [],
        "counter": {}, "event_status": {}, "timing_rounds": {},
        "gen_cards": {}, "gen_tags": {}, "ithink_card": null
    }
    """.data(using: .utf8)!
    return try! JSONDecoder().decode(SaveData.self, from: json)
}
```

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/SaveManagerTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Services/SaveManager.swift SultanTrainer/SultanTrainer/SultanTrainerTests/SaveManagerTests.swift
git commit -m "feat: add SaveManager with auto-scan, backup, and atomic write"
```

---

## Task 10: CardService 服务

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Services/CardService.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/CardServiceTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/CardServiceTests.swift
import XCTest
@testable import SultanTrainer

final class CardServiceTests: XCTestCase {
    
    var cardService: CardService!
    var configLoader: ConfigLoader!
    
    override func setUp() {
        super.setUp()
        configLoader = ConfigLoader()
        configLoader.cardTemplates[2000001] = CardTemplate(id: 2000001, name: "阿尔图")
        configLoader.cardTemplates[2000045] = CardTemplate(id: 2000045, name: "长剑", equip_slots: ["weapon"])
        configLoader.cardTemplates[2010001] = CardTemplate(id: 2010001, name: "苏丹卡1")
        cardService = CardService(configLoader: configLoader)
    }
    
    func testAddCard() {
        var save = createMinimalSave()
        save.card_uid_index = 100
        
        cardService.addCard(to: &save, templateId: 2000001)
        
        XCTAssertEqual(save.cards.count, 1)
        XCTAssertEqual(save.cards[0].id, 2000001)
        XCTAssertEqual(save.cards[0].uid, 100)
        XCTAssertEqual(save.card_uid_index, 101)
    }
    
    func testDeleteCard() {
        var save = createMinimalSave()
        save.cards = [
            Card(uid: 1, id: 2000001),
            Card(uid: 2, id: 2000045)
        ]
        
        let deleted = cardService.deleteCard(from: &save, cardUid: 1)
        
        XCTAssertTrue(deleted)
        XCTAssertEqual(save.cards.count, 1)
        XCTAssertEqual(save.cards[0].uid, 2)
    }
    
    func testDeleteCardReferencedByRite() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, id: 2000001)]
        save.rites = [Rite(uid: 1, id: 5001001, cards: ["s1": Rite.CardReference(uid: 1)])]
        
        let deleted = cardService.deleteCard(from: &save, cardUid: 1)
        
        XCTAssertFalse(deleted)
        XCTAssertEqual(save.cards.count, 1)
    }
    
    func testReplaceCard() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, id: 2000001)]
        save.card_uid_index = 10
        
        cardService.replaceCard(in: &save, cardUid: 1, newTemplateId: 2000045)
        
        XCTAssertEqual(save.cards.count, 1)
        XCTAssertEqual(save.cards[0].id, 2000045)
        XCTAssertEqual(save.cards[0].uid, 10)
        XCTAssertEqual(save.card_uid_index, 11)
    }
    
    func testIsCardInRite() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, id: 2000001), Card(uid: 2, id: 2000045)]
        save.rites = [Rite(uid: 1, id: 5001001, cards: ["s1": Rite.CardReference(uid: 1)])]
        
        XCTAssertTrue(cardService.isCardInRite(save: save, cardUid: 1))
        XCTAssertFalse(cardService.isCardInRite(save: save, cardUid: 2))
    }
    
    func testUpdateCharacterAttribute() {
        var save = createMinimalSave()
        save.cards = [Card(uid: 1, id: 2000001, tag: ["physique": 2, "charm": 3])]
        
        cardService.updateCharacterAttribute(in: &save, characterUid: 1, attribute: .physique, value: 10)
        
        XCTAssertEqual(save.cards[0].tag["physique"], 10)
        XCTAssertEqual(save.cards[0].tag["charm"], 3)
    }
    
    private func createMinimalSave() -> SaveData {
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 1, "rite_uid_index": 1,
            "success": false, "over_reason": 0,
            "cards": [], "rites": [], "sudan_card_pool": [],
            "counter": {}, "event_status": {}, "timing_rounds": {},
            "gen_cards": {}, "gen_tags": {}, "ithink_card": null
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(SaveData.self, from: json)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/CardServiceTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 CardService**

```swift
// Services/CardService.swift
import Foundation

/// 卡牌操作服务
class CardService {
    let configLoader: ConfigLoader
    
    init(configLoader: ConfigLoader) {
        self.configLoader = configLoader
    }
    
    /// 添加卡牌到存档
    func addCard(to save: inout SaveData, templateId: Int, count: Int = 1) {
        var card = Card(uid: save.card_uid_index, id: templateId, count: count)
        
        // 从模板继承属性
        if let template = configLoader.cardTemplates[templateId] {
            card.tag = template.tag
            card.equip_slots = template.equip_slots
        }
        
        save.cards.append(card)
        save.card_uid_index += 1
    }
    
    /// 替换卡牌（删除旧的，添加新的）
    func replaceCard(in save: inout SaveData, cardUid: Int, newTemplateId: Int) {
        guard let index = save.cards.firstIndex(where: { $0.uid == cardUid }) else { return }
        save.cards.remove(at: index)
        addCard(to: &save, templateId: newTemplateId)
    }
    
    /// 删除卡牌，如果被仪式引用则返回false
    func deleteCard(from save: inout SaveData, cardUid: Int) -> Bool {
        if isCardInRite(save: save, cardUid: cardUid) {
            return false
        }
        save.cards.removeAll { $0.uid == cardUid }
        return true
    }
    
    /// 检查卡牌是否被仪式引用
    func isCardInRite(save: SaveData, cardUid: Int) -> Bool {
        for rite in save.rites {
            for (_, cardRef) in rite.cards {
                if let ref = cardRef, ref.uid == cardUid {
                    return true
                }
            }
        }
        return false
    }
    
    /// 修改人物属性
    func updateCharacterAttribute(in save: inout SaveData, characterUid: Int, attribute: AttributeType, value: Int) {
        guard let index = save.cards.firstIndex(where: { $0.uid == characterUid }) else { return }
        let clampedValue = max(0, min(999, value))
        save.cards[index].tag[attribute.rawValue] = clampedValue
    }
    
    /// 获取卡牌的分类
    func categorize(card: Card) -> CardCategory {
        if let template = configLoader.cardTemplates[card.id] {
            return configLoader.categorize(template: template)
        }
        // 无模板时按ID范围推断
        if card.id >= 2010001 && card.id <= 2010016 { return .sudan }
        if card.id >= 2000001 && card.id <= 2000010 { return .character }
        return .other
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/CardServiceTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Services/CardService.swift SultanTrainer/SultanTrainer/SultanTrainerTests/CardServiceTests.swift
git commit -m "feat: add CardService with add/replace/delete/attribute operations"
```

---

## Task 11: QuickModifiers 服务

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/Services/QuickModifiers.swift`
- Test: `SultanTrainer/SultanTrainer/SultanTrainerTests/QuickModifiersTests.swift`

- [ ] **Step 1: 写测试**

```swift
// SultanTrainerTests/QuickModifiersTests.swift
import XCTest
@testable import SultanTrainer

final class QuickModifiersTests: XCTestCase {
    
    var modifiers: QuickModifiers!
    
    override func setUp() {
        super.setUp()
        modifiers = QuickModifiers()
    }
    
    func testAddGold() {
        var save = createMinimalSave()
        save.counter = ["7000100": 50]
        
        modifiers.addGold(to: &save, amount: 999)
        
        XCTAssertEqual(save.counter["7000100"], 1049)
    }
    
    func testAddGoldNoExistingCounter() {
        var save = createMinimalSave()
        
        modifiers.addGold(to: &save, amount: 999)
        
        XCTAssertEqual(save.counter["7000100"], 999)
    }
    
    func testMaxAllAttributes() {
        var save = createMinimalSave()
        save.cards = [
            Card(uid: 1, id: 2000001, tag: ["physique": 2, "charm": 3, "wisdom": 1, "conceal": 1, "battle": 1, "social": 1, "survival": 1])
        ]
        
        modifiers.maxAllAttributes(in: &save, characterUid: 1)
        
        XCTAssertEqual(save.cards[0].tag["physique"], 999)
        XCTAssertEqual(save.cards[0].tag["charm"], 999)
        XCTAssertEqual(save.cards[0].tag["wisdom"], 999)
    }
    
    func testInstantVictory() {
        var save = createMinimalSave()
        save.sudan_card_pool = [
            Card(uid: 160, id: 2010001, life: 3),
            Card(uid: 161, id: 2010002, life: 5)
        ]
        save.success = false
        
        modifiers.instantVictory(in: &save)
        
        for card in save.sudan_card_pool {
            XCTAssertEqual(card.life, 0)
        }
        XCTAssertTrue(save.success)
    }
    
    func testUnlockAllEndings() {
        var global = createMinimalGlobal()
        global.overID = [0]
        
        let allEndingIds = [0, 1, 2, 3, 4, 5]
        modifiers.unlockAllEndings(in: &global, allEndingIds: allEndingIds)
        
        XCTAssertEqual(Set(global.overID), Set(allEndingIds))
    }
    
    func testAddUpgradePoints() {
        var global = createMinimalGlobal()
        global.totalPoint = 100
        
        modifiers.addUpgradePoints(to: &global, amount: 100)
        
        XCTAssertEqual(global.totalPoint, 200)
    }
    
    private func createMinimalSave() -> SaveData {
        let json = """
        {
            "configId": 1, "configVersion": 0, "name": "Test",
            "difficulty": 1, "round": 1, "min_round": 0,
            "saveTime": "", "card_uid_index": 1, "rite_uid_index": 1,
            "success": false, "over_reason": 0,
            "cards": [], "rites": [], "sudan_card_pool": [],
            "counter": {}, "event_status": {}, "timing_rounds": {},
            "gen_cards": {}, "gen_tags": {}, "ithink_card": null
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(SaveData.self, from: json)
    }
    
    private func createMinimalGlobal() -> GlobalData {
        let json = """
        {
            "saveTime": "", "finishTutorial": true, "inGame": true,
            "totalRound": 0, "totalPoint": 0, "usedPoint": 0,
            "upgrade": {}, "quest": {}, "achievements": {}, "counter": {},
            "doneRite": [], "doneEvent": [], "overID": [],
            "gameStatistics": {}, "mods": [],
            "hasEnterSudanBox": false, "hasEnterQuest": false,
            "backToPrevRound": 0, "roundRollback": 0,
            "overRecord": [], "showedGalleryCards": [], "showedPrompt": []
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(GlobalData.self, from: json)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/QuickModifiersTests 2>&1 | tail -5`
Expected: 编译失败

- [ ] **Step 3: 实现 QuickModifiers**

```swift
// Services/QuickModifiers.swift
import Foundation

/// 快捷修改器，封装常用的存档修改操作
class QuickModifiers {
    
    /// 金币+amount（修改counter中金币计数器）
    func addGold(to save: inout SaveData, amount: Int) {
        let goldKey = "7000100"
        let current = save.counter[goldKey] ?? 0
        save.counter[goldKey] = current + amount
    }
    
    /// 全属性满（修改主角卡的tag字段）
    func maxAllAttributes(in save: inout SaveData, characterUid: Int) {
        guard let index = save.cards.firstIndex(where: { $0.uid == characterUid }) else { return }
        for attr in AttributeType.allCases {
            save.cards[index].tag[attr.rawValue] = 999
        }
    }
    
    /// 直接胜利（苏丹卡全部life=0 + success=true）
    func instantVictory(in save: inout SaveData) {
        for i in save.sudan_card_pool.indices {
            save.sudan_card_pool[i].life = 0
        }
        save.success = true
    }
    
    /// 回合数+1
    func incrementRound(in save: inout SaveData) {
        save.round += 1
    }
    
    /// 清空苏丹卡池
    func clearSudanCards(in save: inout SaveData) {
        save.sudan_card_pool.removeAll()
    }
    
    /// 解锁所有结局
    func unlockAllEndings(in global: inout GlobalData, allEndingIds: [Int]) {
        let existingSet = Set(global.overID)
        let newIds = allEndingIds.filter { !existingSet.contains($0) }
        global.overID.append(contentsOf: newIds)
    }
    
    /// 升级点数+amount
    func addUpgradePoints(to global: inout GlobalData, amount: Int) {
        global.totalPoint += amount
    }
    
    /// 解锁所有升级
    func unlockAllUpgrades(in global: inout GlobalData, allUpgradeIds: [Int]) {
        for id in allUpgradeIds {
            global.upgrade["\(id)"] = 1
        }
    }
    
    /// 完成所有任务
    func completeAllQuests(in global: inout GlobalData, allQuestIds: [Int]) {
        for id in allQuestIds {
            global.quest["\(id)"] = 2
        }
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' -only-testing:SultanTrainerTests/QuickModifiersTests 2>&1 | tail -5`
Expected: Test Suite passed

- [ ] **Step 5: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Services/QuickModifiers.swift SultanTrainer/SultanTrainer/SultanTrainerTests/QuickModifiersTests.swift
git commit -m "feat: add QuickModifiers service for common save modifications"
```

---

## Task 12: AppViewModel

**Files:**
- Create: `SultanTrainer/SultanTrainer/SultanTrainer/ViewModels/AppViewModel.swift`

- [ ] **Step 1: 实现 AppViewModel**

```swift
// ViewModels/AppViewModel.swift
import Foundation
import SwiftUI

/// 全局视图模型，持有存档数据和修改状态
class AppViewModel: ObservableObject {
    // MARK: - 服务
    let configLoader = ConfigLoader()
    let saveManager = SaveManager()
    var cardService: CardService!
    let quickModifiers = QuickModifiers()
    
    // MARK: - 存档数据
    @Published var saveData: SaveData?
    @Published var globalData: GlobalData?
    
    // MARK: - 状态
    @Published var isLoading = true
    @Published var hasUnsavedChanges = false
    @Published var lastSaveMessage: String?
    @Published var errorMessage: String?
    @Published var showSavePicker = false
    @Published var availableSaves: [SaveManager.SaveInfo] = []
    
    // MARK: - 导航
    @Published var selectedSidebarItem: SidebarItem? = .quickModify
    
    init() {
        cardService = CardService(configLoader: configLoader)
    }
    
    /// 启动时自动加载
    func initialize() {
        isLoading = true
        
        // 加载游戏配置
        configLoader.locateConfigDirectory()
        try? configLoader.loadAllConfigs()
        
        // 扫描存档
        let saves = saveManager.scanSaveDirectories()
        availableSaves = saves
        
        if saves.isEmpty {
            isLoading = false
            errorMessage = "未检测到存档，请先运行游戏"
            return
        }
        
        if saves.count == 1 {
            loadSave(at: saves[0])
        } else {
            // 多个存档，让用户选择
            isLoading = false
            showSavePicker = true
        }
    }
    
    /// 加载指定存档
    func loadSave(at saveInfo: SaveManager.SaveInfo) {
        isLoading = true
        errorMessage = nil
        
        do {
            saveData = try saveManager.loadSave(from: saveInfo.autoSavePath)
            saveManager.currentSavePath = saveInfo.autoSavePath
            
            if FileManager.default.fileExists(atPath: saveInfo.globalPath.path) {
                globalData = try saveManager.loadGlobal(from: saveInfo.globalPath)
                saveManager.currentGlobalPath = saveInfo.globalPath
            }
            
            hasUnsavedChanges = false
        } catch {
            errorMessage = "存档加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 保存存档
    func save() {
        guard let save = saveData, let path = saveManager.currentSavePath else { return }
        
        do {
            try saveManager.saveSave(save, to: path)
            hasUnsavedChanges = false
            lastSaveMessage = "已保存"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if self.lastSaveMessage == "已保存" {
                    self.lastSaveMessage = nil
                }
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    /// 保存全局数据
    func saveGlobal() {
        guard let global = globalData, let path = saveManager.currentGlobalPath else { return }
        
        do {
            try saveManager.saveGlobal(global, to: path)
            lastSaveMessage = "已保存"
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    /// 标记数据已修改
    func markModified() {
        hasUnsavedChanges = true
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/ViewModels/AppViewModel.swift
git commit -m "feat: add AppViewModel with auto-load, save, and state management"
```

---

## Task 13: ContentView 主窗口

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/ContentView.swift`

- [ ] **Step 1: 实现 ContentView**

```swift
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $viewModel.selectedSidebarItem) { item in
                Label(item.rawValue, systemImage: item.iconName)
                    .tag(item)
            }
            .navigationTitle("SultanTrainer")
            .frame(minWidth: 180)
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    if viewModel.hasUnsavedChanges {
                        Text("已修改 ·")
                            .foregroundStyle(.orange)
                    }
                    if let msg = viewModel.lastSaveMessage {
                        Text(msg)
                            .foregroundStyle(.green)
                    }
                    Button("保存") {
                        viewModel.save()
                        viewModel.saveGlobal()
                    }
                    .disabled(!viewModel.hasUnsavedChanges)
                }
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        if viewModel.isLoading {
            ProgressView("加载中...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.saveData == nil && viewModel.errorMessage != nil {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text(viewModel.errorMessage ?? "")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch viewModel.selectedSidebarItem ?? .quickModify {
            case .quickModify:
                QuickModifyView()
            case .cardManage:
                CardListView()
            case .characterAttribute:
                CharacterAttributeView()
            case .counter:
                CounterEditorView()
            case .rite:
                RiteEditorView()
            case .globalData:
                GlobalDataView()
            }
        }
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: 编译失败（因为View文件还不存在，先创建占位文件）

需要先创建所有View的占位文件才能编译通过：

```swift
// Views/QuickModify/QuickModifyView.swift
import SwiftUI
struct QuickModifyView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("快捷修改") }
}

// Views/Card/CardListView.swift
import SwiftUI
struct CardListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("卡牌管理") }
}

// Views/Card/CardPickerView.swift
import SwiftUI
struct CardPickerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("卡牌选择器") }
}

// Views/Character/CharacterAttributeView.swift
import SwiftUI
struct CharacterAttributeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("人物属性") }
}

// Views/Counter/CounterEditorView.swift
import SwiftUI
struct CounterEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("计数器") }
}

// Views/Rite/RiteEditorView.swift
import SwiftUI
struct RiteEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("仪式") }
}

// Views/Global/GlobalDataView.swift
import SwiftUI
struct GlobalDataView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var body: some View { Text("全局数据") }
}
```

- [ ] **Step 3: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/ContentView.swift SultanTrainer/SultanTrainer/SultanTrainer/Views/
git commit -m "feat: add ContentView with NavigationSplitView and sidebar navigation"
```

---

## Task 14: QuickModifyView

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/Views/QuickModify/QuickModifyView.swift`

- [ ] **Step 1: 实现 QuickModifyView**

```swift
// Views/QuickModify/QuickModifyView.swift
import SwiftUI

struct QuickModifyView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showConfirmDialog = false
    @State private var pendingAction: (() -> Void)?
    @State private var confirmTitle = ""
    @State private var confirmMessage = ""
    @State private var lastActionTime: Date?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 当前局修改
                GroupBox("当前局 (auto_save.json)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        quickButton("金币+999") { addGold() }
                        quickButton("全属性满") { maxAttributes() }
                        quickButton("直接胜利") { instantVictory() }
                        quickButton("回合数+1") { incrementRound() }
                        quickButton("清空苏丹卡") { clearSudanCards() }
                    }
                    .padding(.vertical, 8)
                }
                
                // 全局数据修改
                GroupBox("全局数据 (global.json)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                        quickButton("升级点数+100") { addUpgradePoints() }
                        quickButton("解锁所有结局") { unlockAllEndings() }
                        quickButton("解锁所有升级") { unlockAllUpgrades() }
                        quickButton("完成所有任务") { completeAllQuests() }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
        .alert(confirmTitle, isPresented: $showConfirmDialog) {
            Button("取消", role: .cancel) {}
            Button("确认") {
                pendingAction?()
            }
        } message: {
            Text(confirmMessage)
        }
    }
    
    private func quickButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title) {
            confirmTitle = "确认修改"
            confirmMessage = "确定要执行「\(title)」吗？"
            pendingAction = action
            showConfirmDialog = true
        }
        .buttonStyle(.borderedProminent)
        .disabled(isButtonDisabled())
    }
    
    private func isButtonDisabled() -> Bool {
        guard let lastTime = lastActionTime else { return false }
        return Date().timeIntervalSince(lastTime) < 1.0
    }
    
    private func executeAction(_ action: () -> Void) {
        action()
        viewModel.markModified()
        lastActionTime = Date()
    }
    
    // MARK: - 当前局操作
    
    private func addGold() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.addGold(to: &save, amount: 999)
            viewModel.saveData = save
        }
    }
    
    private func maxAttributes() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            guard let character = save.cards.first(where: { $0.id >= 2000001 && $0.id <= 2000010 }) else { return }
            viewModel.quickModifiers.maxAllAttributes(in: &save, characterUid: character.uid)
            viewModel.saveData = save
        }
    }
    
    private func instantVictory() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.instantVictory(in: &save)
            viewModel.saveData = save
        }
    }
    
    private func incrementRound() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.incrementRound(in: &save)
            viewModel.saveData = save
        }
    }
    
    private func clearSudanCards() {
        executeAction {
            guard var save = viewModel.saveData else { return }
            viewModel.quickModifiers.clearSudanCards(in: &save)
            viewModel.saveData = save
        }
    }
    
    // MARK: - 全局数据操作
    
    private func addUpgradePoints() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            viewModel.quickModifiers.addUpgradePoints(to: &global, amount: 100)
            viewModel.globalData = global
        }
    }
    
    private func unlockAllEndings() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            let allIds = Array(viewModel.configLoader.overTemplates.keys)
            viewModel.quickModifiers.unlockAllEndings(in: &global, allEndingIds: allIds.isEmpty ? [0, 1, 2, 3, 4, 5] : allIds)
            viewModel.globalData = global
        }
    }
    
    private func unlockAllUpgrades() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            let allIds = Array(viewModel.configLoader.upgradeTemplates.keys)
            viewModel.quickModifiers.unlockAllUpgrades(in: &global, allUpgradeIds: allIds)
            viewModel.globalData = global
        }
    }
    
    private func completeAllQuests() {
        executeAction {
            guard var global = viewModel.globalData else { return }
            let allIds = Array(viewModel.configLoader.questTemplates.keys)
            viewModel.quickModifiers.completeAllQuests(in: &global, allQuestIds: allIds)
            viewModel.globalData = global
        }
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Views/QuickModify/QuickModifyView.swift
git commit -m "feat: add QuickModifyView with confirmation dialogs and cooldown"
```

---

## Task 15: CardListView + CardPickerView

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/Views/Card/CardListView.swift`
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/Views/Card/CardPickerView.swift`

- [ ] **Step 1: 实现 CardPickerView**

```swift
// Views/Card/CardPickerView.swift
import SwiftUI

struct CardPickerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: CardCategory? = nil
    @State private var searchText = ""
    @State private var selectedTemplateId: Int?
    
    var onSelect: ((Int) -> Void)?
    
    private var filteredTemplates: [CardTemplate] {
        var templates = Array(viewModel.configLoader.cardTemplates.values)
        
        if let category = selectedCategory {
            templates = templates.filter { viewModel.configLoader.categorize(template: $0) == category }
        }
        
        if !searchText.isEmpty {
            templates = templates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) || "\($0.id)".contains(searchText)
            }
        }
        
        return templates.sorted { $0.id < $1.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            HStack {
                Picker("类别", selection: $selectedCategory) {
                    Text("全部").tag(nil as CardCategory?)
                    ForEach(CardCategory.allCases) { category in
                        Text(category.rawValue).tag(category as CardCategory?)
                    }
                }
                .frame(width: 120)
                
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            
            Divider()
            
            // 卡牌列表
            List(filteredTemplates, selection: $selectedTemplateId) { template in
                HStack {
                    Text(template.name.isEmpty ? "\(template.id)" : template.name)
                        .font(.body)
                    Spacer()
                    Text("\(template.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.configLoader.categorize(template: template).rawValue)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .tag(template.id as Int?)
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("选择") {
                    if let id = selectedTemplateId {
                        onSelect?(id)
                        dismiss()
                    }
                }
                .disabled(selectedTemplateId == nil)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}
```

- [ ] **Step 2: 实现 CardListView**

```swift
// Views/Card/CardListView.swift
import SwiftUI

struct CardListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedCardUid: Int?
    @State private var filterCategory: CardCategory? = nil
    @State private var searchText = ""
    @State private var showPicker = false
    @State private var pickerMode: PickerMode = .add
    @State private var showDeleteConfirm = false
    @State private var showReplaceConfirm = false
    @State private var pendingReplaceTemplateId: Int?
    
    enum PickerMode {
        case add, replace
    }
    
    private var filteredCards: [Card] {
        guard let save = viewModel.saveData else { return [] }
        var cards = save.cards
        
        if let category = filterCategory {
            cards = cards.filter { viewModel.cardService.categorize(card: $0) == category }
        }
        
        if !searchText.isEmpty {
            cards = cards.filter {
                let name = viewModel.configLoader.getCardName(id: $0.id)
                return name.localizedCaseInsensitiveContains(searchText) || "\($0.id)".contains(searchText) || "\($0.uid)".contains(searchText)
            }
        }
        
        return cards.sorted { $0.uid < $1.uid }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 操作栏
            HStack {
                Button("添加卡牌") {
                    pickerMode = .add
                    showPicker = true
                }
                Button("替换卡牌") {
                    guard selectedCardUid != nil else { return }
                    pickerMode = .replace
                    showPicker = true
                }
                .disabled(selectedCardUid == nil)
                
                Button("删除卡牌") {
                    guard selectedCardUid != nil else { return }
                    showDeleteConfirm = true
                }
                .disabled(selectedCardUid == nil)
                
                Spacer()
            }
            .padding()
            
            // 筛选栏
            HStack {
                Picker("类别", selection: $filterCategory) {
                    Text("全部").tag(nil as CardCategory?)
                    ForEach(CardCategory.allCases) { category in
                        Text(category.rawValue).tag(category as CardCategory?)
                    }
                }
                .frame(width: 120)
                
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Text("共 \(filteredCards.count) 张")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            // 卡牌表格
            Table(filteredCards, selection: $selectedCardUid) {
                TableColumn("UID") { card in
                    Text("\(card.uid)")
                }
                .width(min: 50, ideal: 60)
                
                TableColumn("名称") { card in
                    Text(viewModel.configLoader.getCardName(id: card.id))
                }
                
                TableColumn("类别") { card in
                    Text(viewModel.cardService.categorize(card: card).rawValue)
                }
                .width(min: 50, ideal: 60)
                
                TableColumn("数量") { card in
                    Text("\(card.count)")
                }
                .width(min: 40, ideal: 50)
                
                TableColumn("生命") { card in
                    Text("\(card.life)")
                }
                .width(min: 40, ideal: 50)
            }
        }
        .sheet(isPresented: $showPicker) {
            CardPickerView { templateId in
                switch pickerMode {
                case .add:
                    addCard(templateId: templateId)
                case .replace:
                    pendingReplaceTemplateId = templateId
                    showReplaceConfirm = true
                }
            }
            .environmentObject(viewModel)
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteSelectedCard()
            }
        } message: {
            if let uid = selectedCardUid,
               let card = viewModel.saveData?.cards.first(where: { $0.uid == uid }) {
                let name = viewModel.configLoader.getCardName(id: card.id)
                Text("确定要删除「\(name)」(UID: \(uid)) 吗？")
            }
        }
        .alert("确认替换", isPresented: $showReplaceConfirm) {
            Button("取消", role: .cancel) { pendingReplaceTemplateId = nil }
            Button("替换") {
                if let uid = selectedCardUid, let templateId = pendingReplaceTemplateId {
                    replaceCard(uid: uid, templateId: templateId)
                }
                pendingReplaceTemplateId = nil
            }
        } message: {
            Text("确定要替换选中的卡牌吗？")
        }
    }
    
    private func addCard(templateId: Int) {
        guard var save = viewModel.saveData else { return }
        viewModel.cardService.addCard(to: &save, templateId: templateId)
        viewModel.saveData = save
        viewModel.markModified()
    }
    
    private func deleteSelectedCard() {
        guard var save = viewModel.saveData, let uid = selectedCardUid else { return }
        if viewModel.cardService.deleteCard(from: &save, cardUid: uid) {
            viewModel.saveData = save
            viewModel.markModified()
            selectedCardUid = nil
        } else {
            viewModel.errorMessage = "该卡牌正在仪式中使用，无法删除"
        }
    }
    
    private func replaceCard(uid: Int, templateId: Int) {
        guard var save = viewModel.saveData else { return }
        viewModel.cardService.replaceCard(in: &save, cardUid: uid, newTemplateId: templateId)
        viewModel.saveData = save
        viewModel.markModified()
    }
}
```

- [ ] **Step 3: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Views/Card/
git commit -m "feat: add CardListView with table and CardPickerView with category filter"
```

---

## Task 16: CharacterAttributeView

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/Views/Character/CharacterAttributeView.swift`

- [ ] **Step 1: 实现 CharacterAttributeView**

```swift
// Views/Character/CharacterAttributeView.swift
import SwiftUI

struct CharacterAttributeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedCharacterUid: Int?
    @State private var editingValues: [String: Int] = [:]
    
    private var characters: [Card] {
        viewModel.saveData?.cards.filter { $0.id >= 2000001 && $0.id <= 2000010 } ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 人物选择
            HStack {
                Text("选择人物:")
                Picker("人物", selection: $selectedCharacterUid) {
                    Text("请选择").tag(nil as Int?)
                    ForEach(characters) { card in
                        Text(viewModel.configLoader.getCardName(id: card.id))
                            .tag(card.uid as Int?)
                    }
                }
                .frame(width: 200)
            }
            
            if let uid = selectedCharacterUid,
               let character = viewModel.saveData?.cards.first(where: { $0.uid == uid }) {
                
                VStack(spacing: 12) {
                    ForEach(AttributeType.allCases) { attr in
                        HStack {
                            Text(attr.displayName)
                                .frame(width: 60, alignment: .leading)
                            
                            TextField("", value: attributeBinding(for: attr, character: character), format: .number)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: editingValues[attr.rawValue]) { _, newValue in
                                    if let val = newValue, val > 999 {
                                        editingValues[attr.rawValue] = 999
                                    }
                                }
                            
                            Stepper("", value: attributeBinding(for: attr, character: character), in: 0...999)
                                .labelsHidden()
                            
                            if let val = editingValues[attr.rawValue], val > 999 || val < 0 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .padding()
                
                Button("应用修改") {
                    applyAttributes(characterUid: uid)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            if selectedCharacterUid == nil, let first = characters.first {
                selectedCharacterUid = first.uid
                loadEditingValues(for: first)
            }
        }
        .onChange(of: selectedCharacterUid) { _, newUid in
            if let uid = newUid,
               let character = viewModel.saveData?.cards.first(where: { $0.uid == uid }) {
                loadEditingValues(for: character)
            }
        }
    }
    
    private func attributeBinding(for attr: AttributeType, character: Card) -> Binding<Int> {
        return Binding(
            get: { editingValues[attr.rawValue] ?? character.tag[attr.rawValue] ?? 0 },
            set: { editingValues[attr.rawValue] = $0 }
        )
    }
    
    private func loadEditingValues(for character: Card) {
        for attr in AttributeType.allCases {
            editingValues[attr.rawValue] = character.tag[attr.rawValue] ?? 0
        }
    }
    
    private func applyAttributes(characterUid: Int) {
        guard var save = viewModel.saveData else { return }
        for attr in AttributeType.allCases {
            if let value = editingValues[attr.rawValue] {
                viewModel.cardService.updateCharacterAttribute(
                    in: &save, characterUid: characterUid, attribute: attr, value: value
                )
            }
        }
        viewModel.saveData = save
        viewModel.markModified()
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Views/Character/CharacterAttributeView.swift
git commit -m "feat: add CharacterAttributeView with stepper input and range validation"
```

---

## Task 17: CounterEditorView

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/Views/Counter/CounterEditorView.swift`

- [ ] **Step 1: 实现 CounterEditorView**

```swift
// Views/Counter/CounterEditorView.swift
import SwiftUI

struct CounterEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var filterScope: CounterScope? = nil
    @State private var searchText = ""
    @State private var editingCounterId: String?
    @State private var editingValue: Int = 0
    
    private var filteredCounters: [(id: String, value: Int)] {
        guard let save = viewModel.saveData else { return [] }
        var counters = save.counter.map { (id: $0.key, value: $0.value) }
        
        if let scope = filterScope {
            counters = counters.filter { counter in
                CounterScope(fromId: counter.id) == scope
            }
        }
        
        if !searchText.isEmpty {
            counters = counters.filter {
                let name = viewModel.configLoader.getCounterName(id: $0.id)
                return $0.id.contains(searchText) || name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return counters.sorted { $0.id < $1.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            HStack {
                Picker("作用域", selection: $filterScope) {
                    Text("全部").tag(nil as CounterScope?)
                    ForEach(CounterScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope as CounterScope?)
                    }
                }
                .frame(width: 120)
                
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Text("共 \(filteredCounters.count) 项")
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // 计数器表格
            Table(filteredCounters, selection: $editingCounterId) {
                TableColumn("ID") { counter in
                    Text(counter.id)
                }
                
                TableColumn("名称") { counter in
                    Text(viewModel.configLoader.getCounterName(id: counter.id))
                }
                
                TableColumn("当前值") { counter in
                    Text("\(counter.value)")
                }
                .width(min: 60, ideal: 80)
                
                TableColumn("操作") { counter in
                    Button("编辑") {
                        editingCounterId = counter.id
                        editingValue = counter.value
                    }
                }
                .width(min: 50, ideal: 60)
            }
            
            // 编辑面板
            if let editId = editingCounterId {
                Divider()
                HStack {
                    Text("计数器 \(editId)")
                    TextField("值", value: $editingValue, format: .number)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                    Stepper("", value: $editingValue, in: 0...999999)
                        .labelsHidden()
                    Button("应用") {
                        applyCounterValue(id: editId, value: editingValue)
                        editingCounterId = nil
                    }
                    .buttonStyle(.borderedProminent)
                    Button("取消") {
                        editingCounterId = nil
                    }
                }
                .padding()
            }
        }
    }
    
    private func applyCounterValue(id: String, value: Int) {
        guard var save = viewModel.saveData else { return }
        save.counter[id] = value
        viewModel.saveData = save
        viewModel.markModified()
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Views/Counter/CounterEditorView.swift
git commit -m "feat: add CounterEditorView with scope filter and inline editing"
```

---

## Task 18: RiteEditorView

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/Views/Rite/RiteEditorView.swift`

- [ ] **Step 1: 实现 RiteEditorView**

```swift
// Views/Rite/RiteEditorView.swift
import SwiftUI

struct RiteEditorView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedRiteUid: Int?
    @State private var editingSlot: String?
    @State private var showCardPicker = false
    @State private var pendingSlotUid: Int?
    
    private var rites: [Rite] {
        viewModel.saveData?.rites ?? []
    }
    
    var body: some View {
        HSplitView {
            // 左侧：仪式列表
            VStack(alignment: .leading) {
                Text("仪式列表")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                List(rites, selection: $selectedRiteUid) { rite in
                    VStack(alignment: .leading) {
                        Text("仪式 \(rite.id)")
                            .font(.body)
                        Text("UID: \(rite.uid)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(rite.uid as Int?)
                }
            }
            .frame(minWidth: 200)
            
            // 右侧：槽位详情
            if let riteUid = selectedRiteUid,
               let rite = rites.first(where: { $0.uid == riteUid }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("仪式 \(rite.id) - 槽位")
                        .font(.headline)
                    
                    ForEach(sortedSlots(rite: rite), id: \.key) { slotKey, cardRef in
                        HStack {
                            Text(slotKey)
                                .frame(width: 30, alignment: .leading)
                                .font(.caption.monospaced())
                            
                            if let ref = cardRef {
                                if let card = viewModel.saveData?.cards.first(where: { $0.uid == ref.uid }) {
                                    Text("UID: \(ref.uid)")
                                    Text("(\(viewModel.configLoader.getCardName(id: card.id)))")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("UID: \(ref.uid) (卡牌不存在)")
                                        .foregroundStyle(.red)
                                }
                            } else {
                                Text("空")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("替换") {
                                editingSlot = slotKey
                                pendingSlotUid = cardRef?.uid
                                showCardPicker = true
                            }
                            
                            if cardRef != nil {
                                Button("清空") {
                                    clearSlot(riteUid: riteUid, slot: slotKey)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                VStack {
                    Text("选择一个仪式查看槽位")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showCardPicker) {
            CardPickerView { templateId in
                if let slot = editingSlot, let riteUid = selectedRiteUid {
                    assignCardToSlot(riteUid: riteUid, slot: slot, templateId: templateId)
                }
            }
            .environmentObject(viewModel)
        }
    }
    
    private func sortedSlots(rite: Rite) -> [(key: String, value: Rite.CardReference?)] {
        return rite.cards.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
    
    private func clearSlot(riteUid: Int, slot: String) {
        guard var save = viewModel.saveData,
              let riteIndex = save.rites.firstIndex(where: { $0.uid == riteUid }) else { return }
        save.rites[riteIndex].cards[slot] = nil
        viewModel.saveData = save
        viewModel.markModified()
    }
    
    private func assignCardToSlot(riteUid: Int, slot: String, templateId: Int) {
        guard var save = viewModel.saveData,
              let riteIndex = save.rites.firstIndex(where: { $0.uid == riteUid }) else { return }
        
        // 查找或创建对应模板的卡牌
        if let existingCard = save.cards.first(where: { $0.id == templateId }) {
            save.rites[riteIndex].cards[slot] = Rite.CardReference(uid: existingCard.uid)
        } else {
            // 添加新卡牌再引用
            viewModel.cardService.addCard(to: &save, templateId: templateId)
            if let newCard = save.cards.last {
                save.rites[riteIndex].cards[slot] = Rite.CardReference(uid: newCard.uid)
            }
        }
        
        viewModel.saveData = save
        viewModel.markModified()
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Views/Rite/RiteEditorView.swift
git commit -m "feat: add RiteEditorView with slot editing and card assignment"
```

---

## Task 19: GlobalDataView

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/Views/Global/GlobalDataView.swift`

- [ ] **Step 1: 实现 GlobalDataView**

```swift
// Views/Global/GlobalDataView.swift
import SwiftUI

struct GlobalDataView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            if let global = viewModel.globalData {
                VStack(alignment: .leading, spacing: 24) {
                    // 基本信息
                    GroupBox("基本信息") {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                            GridRow {
                                Text("总回合数:")
                                Text("\(global.totalRound)")
                            }
                            GridRow {
                                Text("总升级点数:")
                                editableIntField(
                                    value: Binding(
                                        get: { viewModel.globalData?.totalPoint ?? 0 },
                                        set: { viewModel.globalData?.totalPoint = $0 }
                                    )
                                )
                            }
                            GridRow {
                                Text("已使用点数:")
                                Text("\(global.usedPoint)")
                            }
                            GridRow {
                                Text("已完成局数:")
                                Text("\(global.doneRite.count)")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 已解锁结局
                    GroupBox("已解锁结局 (\(global.overID.count))") {
                        if global.overID.isEmpty {
                            Text("暂无").foregroundStyle(.secondary)
                        } else {
                            FlowLayout(spacing: 8) {
                                ForEach(global.overID.sorted(), id: \.self) { id in
                                    let name = viewModel.configLoader.overTemplates[id]?.name ?? "结局\(id)"
                                    Text(name)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // 升级列表
                    GroupBox("已获取升级 (\(global.upgrade.count))") {
                        if global.upgrade.isEmpty {
                            Text("暂无").foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], alignment: .leading, spacing: 4) {
                                ForEach(global.upgrade.sorted(by: { $0.key < $1.key }), id: \.key) { id, level in
                                    let name = viewModel.configLoader.upgradeTemplates[Int(id)]?.name ?? id
                                    Text("\(name) (Lv.\(level))")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // 任务列表
                    GroupBox("任务状态 (\(global.quest.count))") {
                        if global.quest.isEmpty {
                            Text("暂无").foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], alignment: .leading, spacing: 4) {
                                ForEach(global.quest.sorted(by: { $0.key < $1.key }), id: \.key) { id, status in
                                    let name = viewModel.configLoader.questTemplates[Int(id)]?.name ?? id
                                    HStack {
                                        Text(name)
                                            .font(.caption)
                                        Spacer()
                                        Text(status == 2 ? "已完成" : "进行中")
                                            .font(.caption2)
                                            .foregroundStyle(status == 2 ? .green : .secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
                .onChange(of: viewModel.globalData?.totalPoint) { _, _ in
                    viewModel.markModified()
                }
            } else {
                Text("全局数据未加载")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func editableIntField(value: Binding<Int>) -> some View {
        HStack {
            TextField("", value: value, format: .number)
                .frame(width: 100)
                .textFieldStyle(.roundedBorder)
            Stepper("", value: value, in: 0...999999)
                .labelsHidden()
        }
    }
}

/// 简单的流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        
        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
```

- [ ] **Step 2: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/Views/Global/GlobalDataView.swift
git commit -m "feat: add GlobalDataView with editable fields and flow layout"
```

---

## Task 20: SultanTrainerApp 入口 + build.sh

**Files:**
- Modify: `SultanTrainer/SultanTrainer/SultanTrainer/SultanTrainerApp.swift`
- Create: `SultanTrainer/build.sh`

- [ ] **Step 1: 修改 SultanTrainerApp.swift**

```swift
// SultanTrainerApp.swift
import SwiftUI

@main
struct SultanTrainerApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.initialize()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }
}
```

- [ ] **Step 2: 创建 build.sh**

```bash
#!/bin/bash
set -e

cd "$(dirname "$0")/SultanTrainer"

PROJECT="SultanTrainer.xcodeproj"
SCHEME="SultanTrainer"
BUILD_DIR="./build"

echo "开始构建..."

xcodebuild -project "$PROJECT" \
           -scheme "$SCHEME" \
           -configuration Debug \
           -derivedDataPath "$BUILD_DIR" \
           build

APP_PATH=$(find "$BUILD_DIR/Build/Products/Debug" -name "*.app" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "构建失败：未找到.app文件"
    exit 1
fi

mkdir -p ~/Applications
rm -rf ~/Applications/SultanTrainer.app
cp -R "$APP_PATH" ~/Applications/SultanTrainer.app

echo "构建成功！"
echo "已安装到 ~/Applications/SultanTrainer.app"
echo "可通过 Spotlight 或 Launchpad 启动"
```

- [ ] **Step 3: 设置 build.sh 可执行权限**

```bash
chmod +x SultanTrainer/build.sh
```

- [ ] **Step 4: 编译验证**

Run: `xcodebuild -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 运行 build.sh 验证完整构建流程**

```bash
cd SultanTrainer && ./build.sh
```

Expected: 构建成功，app 安装到 ~/Applications/

- [ ] **Step 6: 启动 app 验证基本功能**

```bash
open ~/Applications/SultanTrainer.app
```

验证：
- 窗口正常显示，侧边栏导航可用
- 自动加载存档（如果游戏存档存在）
- 快捷修改按钮可点击，弹出确认对话框
- 各页面正常切换

- [ ] **Step 7: Commit**

```bash
git add SultanTrainer/SultanTrainer/SultanTrainer/SultanTrainerApp.swift SultanTrainer/build.sh
git commit -m "feat: update App entry point and add build.sh for local distribution"
```

---

## Task 21: 集成测试 + 最终验证

- [ ] **Step 1: 运行所有单元测试**

```bash
xcodebuild test -project SultanTrainer/SultanTrainer/SultanTrainer.xcodeproj -scheme SultanTrainer -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: All tests pass

- [ ] **Step 2: 完整构建并安装**

```bash
cd SultanTrainer && ./build.sh
```

Expected: 构建成功

- [ ] **Step 3: 手动测试核心流程**

1. 启动 app → 自动加载存档
2. 快捷修改 → 金币+999 → 确认 → 保存 → 重新加载游戏验证
3. 卡牌管理 → 添加一张卡牌 → 保存
4. 人物属性 → 修改属性值 → 保存
5. 计数器 → 修改某个计数器 → 保存

- [ ] **Step 4: 最终 Commit**

```bash
git add -A
git commit -m "feat: SultanTrainer v1.0 - complete save trainer for Sultan's Game"
```
