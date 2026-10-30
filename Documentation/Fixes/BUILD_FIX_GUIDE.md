# 🚨 构建错误修复指南

## 报告的错误

```
❌ 错误 1: Cannot find 'Date' in scope
❌ 错误 2: watchOS minimum deployment target of watchOS 27.0
```

---

## 修复步骤

### 🔧 修复 1: Date 找不到的问题

#### 原因分析
`Item.swift` 文件可能被错误地包含在 Watch App target 中，导致编译错误。

#### 解决方案

**步骤 1:** 检查 Item.swift 的 Target Membership

1. 在 Xcode 左侧项目导航器中找到 `Item.swift`
2. 单击选中该文件
3. 按 `⌥⌘1` 打开右侧的 File Inspector
4. 查看 "Target Membership" 部分
5. **应该只勾选：**
   - ✅ `MCaddie` (iOS App)
   - ❌ `MCaddie Watch App` (取消勾选)
   - ❌ `MCaddieTests` (取消勾选，除非需要)

**步骤 2:** 如果问题仍存在

检查是否有重复的 Item.swift 文件：

```bash
# 在终端中运行
find . -name "Item.swift"
```

如果有多个，删除 Watch App 目录下的版本，只保留 iOS App 的版本。

---

### 🔧 修复 2: watchOS Deployment Target 错误

#### 原因分析
Watch App target 的 deployment target 被错误设置为 27.0（这个版本不存在）。

#### 解决方案

**步骤 1:** 修正 Watch App Deployment Target

1. 在 Xcode 项目导航器中选择最上层的 **MCaddie** 项目
2. 在中间的编辑器中选择 **TARGETS** 列表中的 **MCaddie Watch App Watch App**
3. 进入 **General** 标签页
4. 找到 **Minimum Deployments** 部分
5. 将 **watchOS** 下拉菜单改为：
   - **推荐：watchOS 10.0** （支持 SwiftData 和最新特性）
   - 或者：**watchOS 9.0** （更广泛兼容性）

**步骤 2:** 检查 iOS App Deployment Target

同样方法，检查 iOS App target：
- **推荐：iOS 17.0** （支持 SwiftData）

**步骤 3:** 清理构建缓存

```
Product → Clean Build Folder (⇧⌘K)
然后重新构建 (⌘B)
```

---

## ✅ 验证修复

完成上述步骤后：

1. **清理构建：** `⇧⌘K`
2. **重新构建：** `⌘B`
3. **检查错误是否消失**

### 预期结果

- ✅ iOS App 应该能成功构建
- ✅ Watch App 应该能成功构建
- ✅ 不再有 "Date not found" 错误
- ✅ 不再有 "watchOS 27.0" 错误

---

## 🔍 如果问题仍然存在

### 额外检查清单

**检查 1: 确认 SDK 版本**
- Xcode → Preferences → Locations
- 确认 Command Line Tools 已设置

**检查 2: 确认项目配置**
```
项目设置 → Build Settings → 搜索 "deployment"
确认所有 target 的 deployment target 合理：
- iOS: 17.0 或更低
- watchOS: 10.0 或更低
```

**检查 3: MCaddieCore Package 配置**

如果 MCaddieCore Package.swift 中的平台版本过高：

```swift
// MCaddieCore/Package.swift
platforms: [
    .iOS(.v17),      // 如果太高，改为 .v16 或 .v15
    .watchOS(.v10)   // 如果太高，改为 .v9
]
```

---

## 📸 请提供以下截图（如果问题仍存在）

1. Xcode 完整的错误信息截图
2. iOS App target → General → Minimum Deployments 截图
3. Watch App target → General → Minimum Deployments 截图
4. Item.swift 的 Target Membership 截图

---

## 🎯 下一步

修复后，请运行：

```bash
# 测试 MCaddieCore
cd MCaddieCore
swift test

# 在 Xcode 中
⌘B (构建所有 targets)
⌘U (运行所有测试)
```

如果一切正常，我们可以继续添加 Shot/Round 领域模型！
