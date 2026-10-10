---
trigger: glob
globs: "*.swift"
---

# Swift 编码规范

## 命名

- **标识符一律使用英文**：变量、函数、类名、枚举等全部英文命名
- **文档注释使用中文**：`///` 注释用中文描述业务含义
- **遵循 Swift API Design Guidelines**：
  - 类型名用 `UpperCamelCase`（如 `SaveData`、`CardService`）
  - 函数和变量用 `lowerCamelCase`（如 `loadSave`、`cardTemplates`）
  - 枚举 case 用 `lowerCamelCase`（如 `.character`、`.equipment`）

## 代码风格

- 使用 `struct` 优先，仅在需要引用语义时使用 `class`
- Model 层全部使用 `struct` + `Codable`
- Service 和 ViewModel 使用 `class`（需要引用共享状态）
- 使用 `@Observable` 或 `ObservableObject` 管理 ViewModel 状态（视 macOS 13 兼容性决定）
- 避免强制解包 `!`，使用 `guard` 或 `if let` 安全解包
- 魔法数字用常量或枚举替代（如卡牌 ID 范围、计数器前缀）

## 禁止项

- 禁止提交调试代码（`print` 调试输出、硬编码测试路径等）
- 禁止提交密钥、令牌等敏感信息
- 禁止在 View 中直接读写文件，必须通过 Service 层
- 禁止在 Model 中包含业务逻辑

## 错误处理

- 使用 `throws` + `do-catch`，不吞掉错误
- Service 层抛出语义明确的错误类型（如 `SaveError.fileNotFound`、`SaveError.parseFailed`）
- View 层捕获错误后以弹窗/提示展示给用户

## 编辑后验证

修改 Swift 文件后，必须执行编译验证：

```bash
xcodebuild -project SultanTrainer.xcodeproj -scheme SultanTrainer -configuration Debug build
```
