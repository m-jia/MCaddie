# 新文件目录组织指南

## 📁 推荐的目录结构

根据项目的当前组织方式，这是新文件应该放置的位置：

```
/repo/
│
├── 📄 项目文档（根目录）
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── DATA_MODEL.md
│   ├── SWIFTDATA_GUIDE.md                    # ✅ 已创建
│   ├── SWIFTDATA_QUICK_REFERENCE.md          # ✅ 已创建
│   ├── SWIFTDATA_IMPLEMENTATION_REPORT.md    # ✅ 已创建
│   └── PROJECT_STATUS.md                      # ✅ 已更新
│
├── 🍎 iOS App (MCaddie target)
│   │
│   ├── App/
│   │   └── MCaddieApp.swift                   # ✅ 已更新
│   │
│   ├── Views/
│   │   ├── iOSWelcomeView.swift              # ✅ 已存在
│   │   ├── RoundListView.swift               # 🆕 新建
│   │   ├── RecordShotView.swift              # 🆕 新建
│   │   └── ContentView.swift                  # ⚠️ 可选保留
│   │
│   ├── Persistence/
│   │   ├── PersistenceModels.swift           # 🆕 新建
│   │   └── DataManager.swift                 # 🆕 新建
│   │
│   ├── Models/
│   │   └── Item.swift                         # ⚠️ 待移除（已被新模型替代）
│   │
│   └── Tests/
│       ├── MCaddieTests.swift                 # ✅ 已存在
│       └── PersistenceTests.swift            # 🆕 新建
│
├── ⌚ Watch App (MCaddie Watch App target)
│   │
│   ├── App/
│   │   └── MCaddie_Watch_AppApp.swift        # ✅ 已存在
│   │
│   ├── Views/
│   │   ├── WatchWelcomeView.swift            # ✅ 已存在
│   │   └── RecordShotView.swift              # 🔄 共享（或创建 Watch 专用版本）
│   │
│   ├── Persistence/
│   │   ├── PersistenceModels.swift           # 🔄 共享（链接到 iOS）
│   │   └── DataManager.swift                 # 🔄 共享（链接到 iOS）
│   │
│   └── Tests/
│       └── MCaddie_Watch_App_Watch_AppTests.swift  # ✅ 已存在
│
└── 📦 MCaddieCore/ (独立 Swift Package)
    ├── Package.swift
    ├── README.md
    │
    ├── Sources/MCaddieCore/
    │   ├── Models/
    │   │   ├── Distance.swift                # ✅ 已存在
    │   │   ├── Shot.swift                    # ✅ 已存在
    │   │   ├── Round.swift                   # ✅ 已存在
    │   │   ├── Hole.swift                    # ✅ 已存在
    │   │   ├── Lie.swift                     # ✅ 已存在
    │   │   └── PositionObservation.swift     # ✅ 已存在
    │   │
    │   └── ... (未来的决策引擎等)
    │
    └── Tests/MCaddieCoreTests/
        └── DistanceTests.swift               # ✅ 已存在
```

---

## 🎯 文件归属规则

### iOS App Target 专属
放在 iOS App 目录下，**只**添加到 iOS target：

- ✅ `PersistenceModels.swift` → iOS App/Persistence/
- ✅ `DataManager.swift` → iOS App/Persistence/
- ✅ `RoundListView.swift` → iOS App/Views/
- ✅ `RecordShotView.swift` → iOS App/Views/（或共享）
- ✅ `PersistenceTests.swift` → iOS App/Tests/

### Watch App Target（两种策略）

**策略 1：共享文件（推荐）**
- 在 Xcode 中，将 iOS 的文件也添加到 Watch target
- 优点：代码复用，减少维护
- 缺点：Watch 包体积稍大

**策略 2：独立文件**
- 为 Watch 创建简化版本的视图
- 优点：Watch 专用优化
- 缺点：代码重复

推荐对以下文件使用**共享策略**：
- `PersistenceModels.swift` - 数据模型应该一致
- `DataManager.swift` - 数据访问逻辑应该一致

推荐对以下文件使用**独立策略**：
- `RecordShotView.swift` - Watch 界面应该简化

### MCaddieCore Package
**纯领域模型**，不放持久化代码：
- ✅ Distance.swift（已存在）
- ✅ Shot.swift（已存在）
- ✅ Round.swift（已存在）
- ✅ Lie.swift（已存在）
- ✅ PositionObservation.swift（已存在）
- ✅ Hole.swift（已存在）

**不要放**：
- ❌ PersistenceModels.swift（依赖 SwiftData）
- ❌ DataManager.swift（依赖 SwiftData）
- ❌ 任何视图文件（依赖 SwiftUI）

---

## 📋 在 Xcode 中的操作步骤

### 方案 A：建议的扁平结构（如果项目当前没有子文件夹）

如果您的 Xcode 项目当前所有文件都在根目录，可以这样组织：

```
MCaddie/
├── MCaddieApp.swift
├── iOSWelcomeView.swift
├── PersistenceModels.swift        # 🆕 添加这里
├── DataManager.swift              # 🆕 添加这里
├── RoundListView.swift            # 🆕 添加这里
├── RecordShotView.swift           # 🆕 添加这里
├── Item.swift
└── ContentView.swift

MCaddieTests/
├── MCaddieTests.swift
└── PersistenceTests.swift         # 🆕 添加这里

MCaddie Watch App/
├── MCaddie_Watch_AppApp.swift
├── WatchWelcomeView.swift
└── (可选) WatchRecordShotView.swift
```

### 方案 B：推荐的分组结构（使用 Xcode Groups）

在 Xcode 中创建虚拟文件夹（Groups）来组织：

1. **在 Xcode Project Navigator 中右键点击 "MCaddie" 文件夹**
2. **选择 "New Group"**
3. **创建以下 Groups**：
   - App
   - Views
   - Persistence
   - Models

4. **将文件拖到对应 Group**

---

## 🛠️ Xcode 实际操作指南

### 步骤 1: 添加 Persistence 文件到 iOS Target

1. 在 Xcode 的 Project Navigator 中，右键点击 `MCaddie` 组
2. 选择 **New Group** 并命名为 `Persistence`
3. 在 Finder 中找到 `/repo/PersistenceModels.swift`
4. 拖拽到 Xcode 的 `Persistence` 组中
5. 在弹出的对话框中：
   - ✅ 勾选 "Copy items if needed"
   - ✅ 勾选 "MCaddie" target
   - ⚠️ 暂时不勾选 "MCaddie Watch App" target
   - ❌ 不勾选测试 targets

6. 重复步骤 3-5，添加 `DataManager.swift`

### 步骤 2: 添加 Views 文件到 iOS Target

1. 在 `MCaddie` 组中创建 `Views` 组（如果还没有）
2. 将 `RoundListView.swift` 拖入
3. 将 `RecordShotView.swift` 拖入
4. Target 设置同上（只勾选 MCaddie）

### 步骤 3: 添加测试文件

1. 找到 `MCaddieTests` 组
2. 将 `PersistenceTests.swift` 拖入
3. 在对话框中：
   - ✅ 勾选 "MCaddieTests" target
   - ❌ 不勾选其他 targets

### 步骤 4: （可选）为 Watch 添加共享文件

如果要让 Watch App 也能使用持久化：

1. 在 Project Navigator 中选中 `PersistenceModels.swift`
2. 在右侧 **File Inspector** 中找到 **Target Membership**
3. ✅ 勾选 "MCaddie Watch App"
4. 对 `DataManager.swift` 重复步骤 2-3

### 步骤 5: 验证 Target 配置

1. 在 Xcode 中选择 **MCaddie** scheme
2. 按 **⌘ + B** 构建
3. 确保没有编译错误
4. 选择 **MCaddieTests** scheme
5. 按 **⌘ + U** 运行测试
6. 确保 17 个测试全部通过

---

## ⚙️ Target Membership 参考表

| 文件名 | iOS Target | Watch Target | Tests Target |
|--------|-----------|--------------|--------------|
| `PersistenceModels.swift` | ✅ 必需 | ✅ 推荐 | ❌ |
| `DataManager.swift` | ✅ 必需 | ✅ 推荐 | ❌ |
| `RoundListView.swift` | ✅ 必需 | ❌ | ❌ |
| `RecordShotView.swift` | ✅ 必需 | ⚠️ 可选* | ❌ |
| `PersistenceTests.swift` | ❌ | ❌ | ✅ 必需 |
| `SWIFTDATA_*.md` | ❌ | ❌ | ❌ |

*RecordShotView 可以共享给 Watch，但建议创建 Watch 专用简化版本

---

## 🔍 文件物理位置 vs Xcode Groups

### 重要区分：

**Xcode Groups（虚拟文件夹）**：
- 只存在于 Xcode 项目中
- 不影响磁盘上的实际位置
- 用于组织和查找
- **推荐使用**

**Finder 文件夹（实际目录）**：
- 磁盘上的真实目录结构
- 如果要创建实际文件夹，需要在 Finder 中操作
- 在 Xcode 添加文件时选择 "Create groups" 创建虚拟文件夹
- 在 Xcode 添加文件时选择 "Create folder references" 创建实际文件夹引用

**建议**：使用 Xcode Groups 即可，除非有特殊需要。

---

## 📝 推荐的最终结构

### Xcode Project Navigator 中应该看到：

```
📁 MCaddie
  📁 App
    - MCaddieApp.swift
  📁 Views
    - iOSWelcomeView.swift
    - RoundListView.swift
    - RecordShotView.swift
    - ContentView.swift
  📁 Persistence
    - PersistenceModels.swift
    - DataManager.swift
  📁 Models
    - Item.swift (可以删除)

📁 MCaddieTests
  - MCaddieTests.swift
  - PersistenceTests.swift

📁 MCaddie Watch App
  📁 App
    - MCaddie_Watch_AppApp.swift
  📁 Views
    - WatchWelcomeView.swift
    - (可选) WatchRecordShotView.swift
  📁 Persistence (如果共享)
    - PersistenceModels.swift (引用)
    - DataManager.swift (引用)

📁 MCaddie Watch App Tests
  - MCaddie_Watch_App_Watch_AppTests.swift

📁 MCaddieCore (Package)
  📁 Sources/MCaddieCore
    - Distance.swift
    - Shot.swift
    - Round.swift
    - Hole.swift
    - Lie.swift
    - PositionObservation.swift
  📁 Tests/MCaddieCoreTests
    - DistanceTests.swift

📁 Documentation (可选，用于 Markdown 文件)
  - SWIFTDATA_GUIDE.md
  - SWIFTDATA_QUICK_REFERENCE.md
  - SWIFTDATA_IMPLEMENTATION_REPORT.md
  - ... 其他文档
```

---

## ✅ 检查清单

完成添加后，验证以下内容：

- [ ] `PersistenceModels.swift` 在 iOS target 的 **Compile Sources** 中
- [ ] `DataManager.swift` 在 iOS target 的 **Compile Sources** 中
- [ ] `RoundListView.swift` 在 iOS target 的 **Compile Sources** 中
- [ ] `RecordShotView.swift` 在 iOS target 的 **Compile Sources** 中
- [ ] `PersistenceTests.swift` 在 **MCaddieTests** target 的 **Compile Sources** 中
- [ ] iOS App scheme 编译成功（⌘ + B）
- [ ] Tests 运行成功（⌘ + U）
- [ ] 没有 "Duplicate symbols" 错误
- [ ] 没有 "File not found" 错误

---

## 💡 常见问题

### Q: 文件应该放在磁盘的哪里？
A: 当前所有文件都在 `/repo/` 根目录。在 Xcode 中添加时，可以：
- 选择 "Copy items if needed" 让 Xcode 复制到项目目录
- 或者直接引用 `/repo/` 中的文件

### Q: Groups 和实际文件夹有什么区别？
A: Groups 是 Xcode 的虚拟组织方式，不影响磁盘结构。推荐使用 Groups。

### Q: Watch App 必须和 iOS 共享持久化代码吗？
A: 不是必须，但推荐共享 `PersistenceModels.swift` 和 `DataManager.swift` 以确保数据一致性。

### Q: 文档文件需要添加到 target 吗？
A: 不需要。Markdown 文档只是参考资料，不参与编译。

### Q: Item.swift 怎么办？
A: 这是 Xcode 模板生成的占位文件，已被新的持久化模型替代，可以删除。

---

## 🚀 下一步

完成文件组织后：

1. ✅ 更新 `iOSWelcomeView.swift` 添加导航到 `RoundListView`
2. ✅ 测试完整的用户流程
3. 🔄 集成真实的 GPS 位置服务
4. 🔄 创建 Watch 专用界面

---

需要帮助吗？如果遇到任何问题（如编译错误、target 配置等），请告诉我具体的错误信息！
