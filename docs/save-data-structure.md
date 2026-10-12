# 《苏丹的游戏》存档数据结构分析报告

## 一、存档文件组织

存档目录：`~/Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA/{SteamID}/`

| 文件 | 用途 |
|------|------|
| `auto_save.json` | 当前局存档（核心） |
| `round_N.json` | 第N回合开始时的快照 |
| `round_N_end.json` | 第N回合结束时的快照 |
| `global.json` | 跨局持久化数据（升级、成就、统计） |
| `user_archive.json` | 用户档案设置 |
| `over_record_excerpt.json` | 结局记录摘要 |

所有文件均为**纯JSON，无加密**，可直接读写。

---

## 二、核心存档结构 (`auto_save.json`)

```json
{
  "configId": 1,
  "configVersion": 0,
  "name": "哈兰德",
  "difficulty": 3,
  "round": 1,
  "min_round": 0,
  "saveTime": "...",
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
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `configId` | int | 配置ID |
| `configVersion` | int | 配置版本 |
| `name` | string | 角色名 |
| `difficulty` | int | 难度等级 |
| `round` | int | 当前回合数 |
| `min_round` | int | 最小回合数 |
| `saveTime` | string | 保存时间（ISO 8601） |
| `card_uid_index` | int | 卡牌UID自增种子 |
| `rite_uid_index` | int | 仪式UID自增种子 |
| `success` | bool | 本局是否胜利 |
| `over_reason` | int | 结局ID（未结束=最小int） |
| `cards` | array | 卡牌实例数组 |
| `rites` | array | 激活的仪式数组 |
| `sudan_card_pool` | array | 苏丹卡池 |
| `counter` | object | 会话计数器 |
| `event_status` | object | 事件状态标记 |
| `timing_rounds` | object | 定时事件调度 |
| `gen_cards` | object | 卡牌生成计数 |
| `gen_tags` | object | 标签生成计数 |
| `ithink_card` | null/object | 当前思考中的卡 |

UI状态字段（`sudan_box_show`, `story_unshow`, `prestige_unshow`, `deadline_unshow`, `helpbtn_unshow`, `location_icon_show`, `change_desk_bg`, `after_round_auto_sort` 等）控制界面显示，修改器一般无需改动。

---

## 三、卡牌系统

### 3.1 模板ID vs 实例UID

- **模板ID (`id`)**：对应 `config/cards.json` 中的卡牌定义，如 `2000001` = 阿尔图（主角）
- **实例UID (`uid`)**：存档内唯一标识，由 `card_uid_index` 自增生成

### 3.2 卡牌实例结构

```json
{
  "uid": 29,
  "id": 2000001,
  "count": 1,
  "life": 0,
  "rareup": 0,
  "tag": {
    "physique": 2,
    "charm": 2,
    "wisdom": 4,
    "social": 2,
    "battle": 2,
    "conceal": 2,
    "survival": 2
  },
  "equip_slots": ["weapon", "cloth", "accessory"],
  "equips": [],
  "bag": 0,
  "bagpos": 15,
  "custom_name": "",
  "custom_text": ""
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `uid` | int | 实例唯一ID |
| `id` | int | 模板ID → cards.json |
| `count` | int | 堆叠数量 |
| `life` | int | 剩余生命（0=无限） |
| `rareup` | int | 稀有度提升等级 |
| `tag` | object | 该实例的属性值（覆盖/补充模板tag） |
| `equip_slots` | string[] | 可装备槽位类型 |
| `equips` | array | 已装备的物品（嵌套卡牌实例） |
| `bag` | int | 背包ID（0=主背包） |
| `bagpos` | int | 背包位置索引 |
| `custom_name` | string | 自定义名称 |
| `custom_text` | string | 自定义文本 |

### 3.3 卡牌模板结构 (`config/cards.json`)

每张卡牌模板的关键字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | int | 模板ID |
| `name` | string | 卡牌名称（中文） |
| `type` | string | 粗分类：`char`（角色）/ `item`（物品）/ `sudan`（苏丹卡） |
| `title` | string | 细分类：书籍、武器、服装、饰品、军队、大餐、食客、邪物、消耗品、路人、情报、敌人、苏丹卡、思潮、线索、地点、美德、宝石、倒计时、证据 等 |
| `text` | string | 卡牌描述文本 |
| `tag` | object | 标签字典（中文键→等级值），如 `{"体魄": 3, "魅力": 2, "读物": 1}` |
| `equips` | string[] | 可装备槽位（中文），如 `["武器", "服装", "饰品"]` |
| `rare` | int | 稀有度 |
| `is_only` | bool | 是否唯一 |

**注意**：模板中字段名为 `equips`（中文值），存档中对应字段名为 `equip_slots`（英文值）。两者映射关系：武器→weapon、服装→cloth、饰品→accessory、驯兽→animal_handling。

### 3.4 卡牌ID范围

| ID范围 | 类型 |
|--------|------|
| 2000xxx | 主要卡牌池（角色、物品、装备等，926张） |
| 2001xxx | 扩展卡牌（路人、大餐、书籍、特殊物品等，352张） |
| 2010001-2010016 | 苏丹卡（杀戮/纵欲/奢靡/征服各4级，共16张） |

卡牌分类应优先使用模板的 `type` 字段，而非依赖 ID 范围硬编码。

### 3.5 背包分布 (`bag` 字段)

| bag 值 | 含义 |
|--------|------|
| 0 | 主背包（玩家可见/可操作的卡牌） |
| 2 | 副区域（如追随者持有物等） |
| 3 | 副区域（如仪式关联物品等） |

卡牌管理界面应只显示 `bag == 0` 的卡牌。`sudan_card_pool` 是独立数组，不在 `cards` 数组内。

### 3.6 装备系统

卡牌可嵌套装备：`equips[]` 数组内存放子卡牌实例。装备槽位类型：

| 槽位代码 | 中文名 |
|----------|--------|
| `weapon` | 武器 |
| `cloth` | 服装 |
| `accessory` | 饰品 |
| `animal_handling` | 驯兽 |

---

## 四、标签/属性系统 (`tag.json`)

存档中使用**英文代码**，配置文件中使用**中文显示名**：

| 英文代码 | 中文名 | rank | 说明 |
|----------|--------|------|------|
| `physique` | 体魄 | 99 | 身体力量 |
| `charm` | 魅力 | 98 | 吸引力 |
| `wisdom` | 智慧 | 97 | 智力判断 |
| `conceal` | 隐匿 | 96 | 潜行暗杀 |
| `battle` | 战斗 | 95 | 战斗能力 |
| `social` | 社交 | 94 | 交际谈判 |
| `survival` | 生存 | — | 野外生存 |

其他标签类型：`男性/女性`、`贵族`、`主角`、`追随者`、`奢靡`、`武器`、`服装`、`饰品` 等。

`tag.json` 中每个标签的关键控制字段：

| 字段 | 说明 |
|------|------|
| `can_visible` | 是否在UI中可见 |
| `can_inherit` | 是否可继承到下局 |
| `can_nagative_and_zero` | 是否可为负值或零 |
| `can_add` | 是否可叠加 |
| `tag_rank` | 排序优先级 |
| `type` | 类型（`buff`等） |

---

## 五、计数器系统 (`counter`)

计数器是游戏状态的核心驱动机制，ID前缀决定作用域：

| 前缀 | 作用域 | 示例 |
|------|--------|------|
| `7000xxx` | 当前会话（局内状态） | `7000001`=装修次数, `7000158`=大敌干扰, `7000195`=苏丹猜忌, `7000567`=家被砸, `7000617`=领地被践踏, `7000730`=某游戏内计数 |
| `7100xxx` | 持久统计（跨局保留） | `7100001`=总游玩次数(160), `7100008`=某持久计数(5) |
| `7200xxx` | 成就计数 | `7200131`=金币收益次数(280), `7200133`=某成就(183) |
| `7210xxx` | 跨局累计 | `7210001`=总游玩次数 |
| `7220xxx` | 完成统计 | `7220001`=完成局数(6), `7220002`=胜利次数(3) |
| `7230xxx` | 解锁标记 | `7230001`=某解锁(1=已解锁) |

### 计数器操作语法（在仪式配置中使用）

| 语法 | 含义 |
|------|------|
| `"counter+7000730": 1` | 加1 |
| `"counter-7000617": 1` | 减1 |
| `"counter=7000007": 0` | 设为0 |
| `"counter.7000617=": 7` | 条件判断（等于7时触发） |
| `"counter.7000617<": 3` | 条件判断（小于3时触发） |
| `"counter.7000617>=": 10` | 条件判断（大于等于10时触发） |

---

## 六、仪式系统 (`rites`)

### 6.1 存档中的仪式结构

```json
{
  "uid": 5,
  "id": 5001001,
  "cards": [
    null,
    {"uid": 29, "id": 2000001, "count": 1, "life": 0, ...},
    null,
    null,
    null,
    null,
    null
  ]
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `uid` | int | 仪式实例唯一ID |
| `id` | int | 仪式模板ID → config/rite/{id}.json |
| `cards` | array | 各槽位中放置的卡牌实例，数组长度等于槽位数，空槽为 `null`，非空槽为完整的 Card 对象 |

**注意**：`cards` 是**数组**而非字典，索引对应槽位（`cards[0]` = s1, `cards[1]` = s2, ...）。

### 6.2 仪式配置文件结构

每个仪式JSON文件（`config/rite/{id}.json`）包含：

| 字段 | 说明 |
|------|------|
| `id` | 仪式ID |
| `name` | 仪式名称 |
| `text` | 仪式描述文本 |
| `mapping_id` | 映射ID |
| `round_number` | 每回合执行次数 |
| `auto_begin` | 是否自动开始 |
| `auto_result` | 是否自动结算 |
| `location` | 地点 |
| `cards_slot` | 槽位定义（名称、接受条件） |
| `tag_tips` | 标签提示 |
| `open_conditions` | 开启条件 |
| `settlement_prior[]` | 优先判定的结算条件（如领地被毁） |
| `settlement[]` | 常规结算逻辑 |
| `settlement_extre[]` | 额外条件分支 |
| `random_text` / `random_text_up` | 随机文本 |

### 6.3 结算条件DSL

| 语法 | 含义 |
|------|------|
| `"r1:智慧+社交>=": [3, 5]` | 骰子检定：智慧+社交之和，阈值3（成功）/5（大成功） |
| `"s1.is": 2000008` | 槽位1的卡牌模板ID是2000008 |
| `"s3.is": 2000178` | 槽位3的卡牌模板ID是2000178 |
| `"f:反对-支持>=": 0` | 公式计算：反对值-支持值 >= 0 |
| `"counter.7000085<": 1` | 计数器条件 |
| `"!s1": 1` | 槽位1为空 |
| `"!s2": 1` | 槽位2为空 |

### 6.4 结算结果操作

| 语法 | 含义 |
|------|------|
| `"金币": 5` | 增加5金币 |
| `"counter+7000001": 1` | 计数器+1 |
| `"clean.s3": 1` | 清除槽位3 |
| `"card": 2000179` | 添加卡牌（模板ID） |
| `"s4+回收": 1` | 回收槽位4的卡牌 |
| `"rite": 5000001` | 触发另一个仪式 |
| `"global_counter+7200131": 1` | 全局计数器+1 |
| `"global_counter=7200123": 1` | 设置全局计数器 |
| `"choose": {"pop.xxx": "文本"}` | 弹出对话选项 |

### 6.5 当前存档中的激活仪式

| 仪式ID | 名称 | 槽位数 | 说明 |
|--------|------|--------|------|
| 5001001 | 权力的游戏 | 7 (s1-s7) | 宫廷仪式，最复杂 |
| 5001501 | — | — | — |
| 5000001 | 治理家业 | 4 (s1-s4) | 收入来源，智慧+社交检定 |
| 5002006 | — | — | — |
| 5000109 | — | — | — |

---

## 七、苏丹卡池 (`sudan_card_pool`)

苏丹卡是游戏核心机制，当前存档有44张卡实例（模板2010001-2010016）。

```json
{
  "uid": 160,
  "id": 2010001,
  "count": 1,
  "life": 3,
  "rareup": 0,
  "tag": {},
  "equip_slots": [],
  "equips": [],
  "bag": 0,
  "bagpos": 0,
  "custom_name": "",
  "custom_text": ""
}
```

- `life` 字段表示剩余回合数，每回合递减
- **全部苏丹卡life归零 = 游戏胜利**（结局ID 0）
- 苏丹卡模板ID范围：2010001 - 2010016

---

## 八、全局持久化 (`global.json`)

```json
{
  "saveTime": "...",
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
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `totalRound` | int | 总游玩回合数 |
| `totalPoint` | int | 总升级点数 |
| `usedPoint` | int | 已使用点数 |
| `upgrade` | object | 已购升级 `{升级ID: 等级}` |
| `quest` | object | 任务状态 `{任务ID: 状态}` (2=已完成) |
| `counter` | object | 持久计数器 |
| `doneRite` | array | 已完成仪式ID列表 |
| `doneEvent` | array | 已完成事件ID列表 |
| `overID` | array | 已触发结局ID列表 |
| `gameStatistics` | object | 游戏统计 `{难度: {startTimes, overTimes}}` |
| `showedGalleryCards` | array | 已展示的图鉴卡 |
| `showedPrompt` | array | 已展示的提示 |

---

## 九、事件与定时系统

### 9.1 `event_status` — 事件开关

```json
{"5310100": true, "5300066": false, ...}
```

key为事件ID（对应config中的event定义），value为是否已触发/完成。

### 9.2 `timing_rounds` — 定时调度

```json
{"5310100_01": {"round": 5, "status": 1}, ...}
```

控制事件在指定回合触发，当前存档约200+条目。

---

## 十、结局系统 (`over.json`)

结局定义在 `config/over.json` 中：

```json
{
  "0": {
    "name": "结局标题",
    "text": "本轮苏丹卡已全部消解，游戏结束。",
    "text_extra": [{"condition": {}, "result_text": ""}],
    "bg": "over_cg/over_cg_1",
    "icon": "over_icon/over_icon_1",
    "title": "over_icon/over_title"
  }
}
```

已知结局ID：

| ID | 名称 | 触发条件 |
|----|------|----------|
| 0 | （苏丹卡消完） | 所有苏丹卡life归零 |
| 1 | 伴君如伴虎 | 触怒苏丹 |
| 2 | 永恒之梦 | 被梅姬杀死 |
| 3 | 不自量力 | 决斗失败 |
| 4 | 因果报应 | 被刺杀 |
| 5 | 欢愉的极致 | 死于朱娜 |

---

## 十一、升级系统 (`upgrade.json`)

升级定义在 `config/upgrade.json` 中：

```json
{
  "id": 3300042,
  "name": "神之侧身像",
  "text": "...",
  "cost": 40,
  "condition": {},
  "icon": "...",
  "link_card": "...",
  "effect": {
    "counter+7000730": 1,
    "g.card": [2000019, "追随者+1"]
  },
  "incompatible": []
}
```

效果类型：
- `counter+{ID}` — 增加计数器
- `g.card` — 添加卡牌
- 其他counter操作

---

## 十二、任务系统 (`quest.json`)

任务定义在 `config/quest.json` 中：

```json
{
  "id": 3300001,
  "name": "坠落的初端",
  "text": "讲述了一名臣子终结了1场苏丹的游戏的故事。",
  "favour_text": "以生命为代价，又或以灵魂为代价。",
  "upgrade_point": 1,
  "pre": 0,
  "target": [
    {
      "text": "完成1局苏丹的游戏",
      "show_counter": "",
      "condition": {
        "global_counter.7220001>=": 1
      }
    }
  ],
  "icon": "cards/2000001"
}
```

---

## 十三、存档修改器关键修改点

| 修改目标 | 操作方式 |
|----------|----------|
| **金币** | 修改 `counter` 中对应计数器，或修改卡牌列表中2000090(金币)的`count` |
| **属性值** | 修改主角卡(2000001)的 `tag` 字段中各属性数值 |
| **卡牌数量** | 修改对应卡牌实例的 `count`，或删除/新增实例 |
| **苏丹卡消解** | 将 `sudan_card_pool` 中卡牌的 `life` 设为0 |
| **直接胜利** | 清空 `sudan_card_pool` 或全部life设0 + 设 `success:true` |
| **回合数** | 修改 `round` 字段 |
| **升级点数** | 修改 `global.json` 的 `totalPoint` / `usedPoint` |
| **解锁升级** | 在 `global.json` 的 `upgrade` 中添加升级ID |
| **完成任务** | 在 `global.json` 的 `quest` 中设任务ID值为2 |
| **解锁结局** | 在 `global.json` 的 `overID` 数组中添加结局ID |
| **仪式槽位** | 修改 `rites[].cards` 中各槽位的卡牌UID |
| **计数器** | 直接修改 `counter` 中任意key的数值 |
| **事件进度** | 修改 `event_status` 或 `timing_rounds` |

---

## 十四、注意事项

1. **UID唯一性**：新增卡牌实例时，`uid` 必须大于等于 `card_uid_index`，并同步更新 `card_uid_index`
2. **存档备份**：修改前务必备份，JSON无校验和，但错误数据可能导致游戏崩溃
3. **回合快照**：`round_N.json` 是回合快照，修改 `auto_save.json` 后对应的回合快照可能不一致
4. **全局 vs 局内**：`global.json` 跨局生效，`auto_save.json` 仅当前局。修改全局数据会影响所有新局
5. **仪式一致性**：修改仪式槽位中的卡牌UID时，该UID必须在 `cards[]` 数组中存在
6. **configVersion**：当前为 `20260306160333`，修改存档时建议保持不变
7. **存档时机**：游戏在回合结束/关键节点自动保存，修改后需确保游戏重新加载存档

---

## 十五、配置文件目录结构

```
config/
├── cards.json          # 卡牌模板定义（~954KB）
├── tag.json            # 标签/属性定义（~222KB）
├── variable.json       # 系统配置（语言、分辨率等）
├── quest.json          # 任务/成就定义（~110KB）
├── over.json           # 结局定义（~299KB）
├── upgrade.json        # 升级定义（~28KB）
└── rite/               # 仪式配置目录
    ├── 5000001.json    # 治理家业
    ├── 5001001.json    # 权力的游戏
    ├── 5001501.json
    ├── 5002006.json
    └── ...
```
