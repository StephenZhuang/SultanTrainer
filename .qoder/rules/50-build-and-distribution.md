---
trigger: glob
globs: "*.sh"
---

# 构建与分发

不上架 App Store，采用本地分发方案。

## 构建命令

```bash
xcodebuild -project SultanTrainer.xcodeproj \
           -scheme SultanTrainer \
           -configuration Debug \
           -derivedDataPath ./build \
           build
```

## 安装流程

构建产物复制到 `~/Applications/`：

```bash
APP_PATH=$(find ./build/Build/Products/Debug -name "*.app" | head -1)
mkdir -p ~/Applications
rm -rf ~/Applications/SultanTrainer.app
cp -R "$APP_PATH" ~/Applications/SultanTrainer.app
```

## 签名

无需正式签名（本地使用），首次打开需在"系统设置 → 隐私与安全性"中允许。可选 ad-hoc 签名：

```bash
codesign --sign - ~/Applications/SultanTrainer.app
```

## 工作流

1. 首次：`./build.sh` → app 出现在 Launchpad
2. 代码修改后：重新 `./build.sh` → 覆盖旧版本
3. 通过 Spotlight 或 Launchpad 启动

## DMG 打包分发

给他人分发时打包成 DMG，采用 ad-hoc 签名（免费，对方首次打开需右键→打开放行 Gatekeeper）。

### 打包命令

```bash
./build-dmg.sh              # 构建当前架构 (arm64)
./build-dmg.sh --universal  # 构建通用架构 (arm64 + x86_64)
```

产物输出到 `./dist/SultanTrainer.dmg`。

### DMG 内容结构

```
SultanTrainer.dmg
├── SultanTrainer.app
└── Applications (快捷方式，拖拽安装)
```

### 签名说明

- 使用 `codesign --sign -` 做 ad-hoc 签名
- 无需 Apple Developer 账号
- 对方首次打开需在"系统设置 → 隐私与安全性"中点击"仍要打开"

### 分发须知

告知接收方：
> 首次打开如提示"无法验证开发者"，请右键点击 App → 选择"打开" → 再次确认"打开"

## AI 行为约束

- **构建/测试一律后台执行**：使用 `run_in_background: true` 运行 xcodebuild、xcodebuild test 等耗时命令，禁止占用用户屏幕
- 构建成功后简要报告结果即可，不要在前台跑测试

## build.sh 规范

- 使用 `set -e` 遇错即停
- 构建前清理旧的 derived data（可选）
- 构建后自动复制并输出安装路径
- 构建失败时输出明确错误信息
