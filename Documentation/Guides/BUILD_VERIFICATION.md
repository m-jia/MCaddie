# M-Caddie 项目构建与验证指南

本文档说明如何构建和测试当前的最小骨架。

## ✅ 已完成的工作

### 1. iOS App Target
- ✅ `MCaddieApp.swift` - 应用入口
- ✅ `iOSWelcomeView.swift` - 欢迎页面
- ✅ `Item.swift` - SwiftData 占位模型
- ✅ `MCaddieTests.swift` - 基本测试

### 2. Watch App Target
- ✅ `MCaddie_Watch_AppApp.swift` - Watch 应用入口
- ✅ `WatchWelcomeView.swift` - Watch 欢迎页面
- ✅ `MCaddie_Watch_App_Watch_AppTests.swift` - 基本测试

### 3. MCaddieCore Package
- ✅ 独立 Swift Package (MCaddieCore/)
- ✅ `Distance.swift` - 距离模型（区分 carry/total）
- ✅ `DistanceTests.swift` - 单元测试
- ✅ 纯 Swift，无平台依赖

---

## 🚨 您需要在 Xcode 中完成的步骤

### 步骤 1: 添加 MCaddieCore 本地 Package

1. 在 Xcode 中打开项目
2. 选择 File → Add Package Dependencies...
3. 点击 "Add Local..." 按钮
4. 导航到 `MCaddieCore` 文件夹并选择
5. 点击 "Add Package"

### 步骤 2: 将 MCaddieCore 添加到 App Targets

**iOS App:**
1. 选择项目导航器中的 Project
2. 选择 "MCaddie" iOS target
3. 进入 "General" 标签
4. 在 "Frameworks, Libraries, and Embedded Content" 中点击 +
5. 选择 "MCaddieCore" 并添加

**Watch App:**
1. 选择 "MCaddie Watch App" target
2. 重复上述步骤添加 "MCaddieCore"

### 步骤 3: 验证文件所属 Target

请确认以下文件属于正确的 target：

**iOS Target (MCaddie):**
- ✅ MCaddieApp.swift
- ✅ iOSWelcomeView.swift
- ✅ Item.swift
- ⚠️ ContentView.swift（可删除或保留作为参考）

**Watch Target (MCaddie Watch App Watch App):**
- ✅ MCaddie_Watch_AppApp.swift
- ✅ WatchWelcomeView.swift

**测试 Targets:**
- MCaddieTests.swift → MCaddieTests target
- MCaddie_Watch_App_Watch_AppTests.swift → Watch tests target

### 步骤 4: 构建项目

1. 选择 iOS 模拟器（例如 iPhone 14 Pro Max）
2. 按 Cmd+B 构建
3. 如果成功，按 Cmd+R 运行
4. 应该看到绿色高尔夫图标和 "M-Caddie" 欢迎页

5. 切换到 Watch 模拟器方案
6. 按 Cmd+B 构建
7. 如果成功，按 Cmd+R 运行
8. 应该看到 Watch 欢迎页面

### 步骤 5: 运行测试

**MCaddieCore 单元测试:**
```bash
cd MCaddieCore
swift test
```

或者在 Xcode 中：
1. 选择 MCaddieCore scheme
2. 按 Cmd+U 运行测试

**iOS App 测试:**
1. 选择 MCaddie scheme
2. 按 Cmd+U 运行测试

**Watch App 测试:**
1. 选择 Watch scheme
2. 按 Cmd+U 运行测试

---

## 📋 验证清单

运行后请检查以下内容：

- [ ] iOS App 可以构建并运行
- [ ] iOS 欢迎页显示 "M-Caddie" 和三个按钮
- [ ] Watch App 可以构建并运行
- [ ] Watch 欢迎页显示简化版界面
- [ ] MCaddieCore 单元测试通过（3 个测试）
- [ ] iOS 和 Watch tests 可以运行

---

## 🔍 已知问题和限制

### 当前实现的限制：
1. ❌ **未实现功能**: GPS、语音、持久化、同步
2. ❌ **未实现数据模型**: Round, Shot, Hole 等
3. ❌ **未实现决策引擎**: 球杆建议、风险评估
4. ⚠️ **占位符**: 按钮点击后只显示占位文本

### 待确认的环境信息：
- ⚠️ **Xcode 版本**: 请报告您当前的 Xcode 版本
- ⚠️ **iOS SDK**: 请确认当前 SDK 版本
- ⚠️ **Deployment Target**: iOS 和 watchOS 的最低版本
- ⚠️ **Swift 版本**: Package 假设 Swift 6.0+
- ⚠️ **平台版本**: Package 假设 iOS 17+ / watchOS 10+

**如果这些假设不匹配，请告知，我将调整配置。**

---

## 🎯 测试报告模板

请在完成上述步骤后报告以下信息：

```
### 环境信息
- Xcode 版本: 
- iOS SDK 版本: 
- watchOS SDK 版本: 
- iOS Deployment Target: 
- watchOS Deployment Target: 

### 构建结果
- [ ] MCaddieCore Package 添加成功
- [ ] iOS App 构建: ✅成功 / ❌失败（错误信息：）
- [ ] Watch App 构建: ✅成功 / ❌失败（错误信息：）
- [ ] iOS App 运行: ✅成功 / ❌失败（错误信息：）
- [ ] Watch App 运行: ✅成功 / ❌失败（错误信息：）

### 测试结果
- [ ] MCaddieCore 测试: ✅通过 / ❌失败（失败信息：）
- [ ] iOS App 测试: ✅通过 / ❌失败（失败信息：）
- [ ] Watch App 测试: ✅通过 / ❌失败（失败信息：）

### UI 验证
- [ ] iOS 欢迎页显示正确
- [ ] Watch 欢迎页显示正确
- [ ] 按钮导航工作（即使是占位内容）

### 遇到的问题
（请详细描述任何构建错误、警告或异常行为）
```

---

## 📝 下一步建议

构建验证成功后，推荐按以下顺序继续：

### 优先级 1: 领域模型完善
1. 在 MCaddieCore 中添加 `Shot`, `Round`, `Hole` 等核心模型
2. 添加对应的单元测试
3. 保持纯 Swift，不引入平台依赖

### 优先级 2: 最小持久化
4. 确认 SwiftData 在 iOS 17+ / watchOS 10+ 的可用性
5. 在 Watch App 中实现最小的本地保存
6. 测试离线保存是否可靠

### 优先级 3: 第一条端到端流程
7. 实现简化的"开始回合"流程
8. 实现手动输入一条击球记录（暂不实现语音）
9. 在 Watch 本地保存
10. 在 iPhone 查看

### 不要在第一个迭代做的事：
- ❌ 完整的语音识别
- ❌ GPS 定位集成
- ❌ WatchConnectivity 同步
- ❌ 复杂的决策引擎
- ❌ LLM 集成

---

## 🆘 故障排除

### 如果 MCaddieCore Package 无法添加：
- 确认 `Package.swift` 在 `MCaddieCore/` 目录下
- 确认 Swift tools version 兼容（可能需要调整为 5.9）

### 如果构建失败提示 SwiftData 不可用：
- 检查 Deployment Target 是否足够新
- iOS 17.0+ 和 watchOS 10.0+ 支持 SwiftData

### 如果 Watch App 无法构建：
- 确认 Watch App target 有正确的 WatchKit App 配置
- 检查 Bundle Identifier 配置

如有任何错误，请提供完整的错误信息！
