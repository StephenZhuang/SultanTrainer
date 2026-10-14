# SultanTrainer

《苏丹的游戏》(Sultan's Game) Mac 原生存档修改器。

## 功能

- **快捷修改** — 金币+999、全属性满、直接胜利、解锁所有结局等一键操作
- **卡牌管理** — 添加/替换/删除卡牌，编辑数量和生命值，按类别筛选和搜索
- **人物属性** — 修改9项属性（体魄/魅力/智慧/隐匿/战斗/社交/生存/魔力/学识），管理驯兽槽，医治受伤
- **计数器编辑** — 浏览和修改游戏计数器（金币、金骰子等），按作用域分组
- **仪式编辑** — 查看和编辑仪式槽位，显示仪式名称、描述和剩余回合数
- **全局数据** — 修改升级点数、解锁升级/任务/结局等跨局数据

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI (macOS 原生)
- **最低系统**: macOS 13.0+
- **架构**: MVVM + Service 分层

## 构建

```bash
# 构建并安装到 ~/Applications/
./build.sh

# 打包 DMG（当前架构）
./build-dmg.sh

# 打包 DMG（通用架构 arm64 + x86_64）
./build-dmg.sh --universal
```

构建完成后可通过 Spotlight 或 Launchpad 启动。首次打开如提示"无法验证开发者"，右键点击 App → 选择"打开" → 再次确认"打开"。

## 使用

1. 确保已运行过《苏丹的游戏》（需要存在存档文件）
2. 启动 SultanTrainer，自动扫描并加载存档
3. 在左侧选择功能模块，进行修改
4. 点击工具栏"保存"按钮写入存档（修改前先自动备份）

### 存档位置

```
~/Library/Application Support/com.DoubleCross.SultansGame/SAVEDATA/{SteamID}/
```

- `auto_save.json` — 当前局存档
- `global.json` — 跨局持久化数据

### 备份

每次保存前自动备份到 `~/Library/Application Support/SultanTrainer/backups/`，保留最近 10 个备份。

## 项目结构

```
SultanTrainer/
├── Models/          # 数据模型 (Codable)
├── Services/        # 业务逻辑（存档读写、卡牌操作、配置加载）
├── ViewModels/      # 视图模型
├── Views/
│   ├── QuickModify/     # 快捷修改
│   ├── Card/            # 卡牌管理
│   ├── Character/       # 人物属性
│   ├── Counter/         # 计数器
│   ├── Rite/            # 仪式
│   ├── Global/          # 全局数据
│   └── Components/      # 通用组件
└── SultanTrainerApp.swift
```

## License

MIT
