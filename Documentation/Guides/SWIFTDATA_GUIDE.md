# SwiftData 持久化实现指南

## 📋 概述

本文档说明了 M-Caddie 项目的 SwiftData 持久化层设计和使用方法。

## 🏗️ 架构设计

### 分层架构

```
┌─────────────────────────────────────────┐
│        UI 层 (SwiftUI Views)            │
│  RoundListView, RecordShotView, etc.    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      数据管理层 (DataManager)            │
│  统一的数据访问接口和业务逻辑            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   持久化模型层 (SwiftData Models)        │
│  RoundModel, ShotModel                   │
│  提供与领域模型的双向转换                │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   领域模型层 (MCaddieCore)               │
│  Round, Shot, Distance, etc.             │
│  纯 Swift 值类型，无持久化依赖            │
└─────────────────────────────────────────┘
```

### 设计原则

1. **领域模型独立性**
   - MCaddieCore 中的领域模型保持纯 Swift
   - 不引入 SwiftData、SwiftUI 等框架依赖
   - 便于单元测试和跨平台复用

2. **适配器模式**
   - 持久化模型（RoundModel、ShotModel）是适配器
   - 提供 `init(from:)` 和 `toDomain()` 方法进行转换
   - 处理枚举的 rawValue 存储和复杂类型的 JSON 编码

3. **统一的数据访问**
   - DataManager 封装所有 SwiftData 操作
   - 提供类型安全的 API
   - 集中处理错误和异常

## 📁 文件结构

### 新增文件

```
/repo/
├── PersistenceModels.swift     # SwiftData 持久化模型
│   ├── RoundModel              # 回合持久化模型
│   ├── ShotModel               # 击球持久化模型
│   └── 转换扩展和错误类型
│
├── DataManager.swift           # 数据管理服务
│   ├── DataManager class       # 主要的数据访问接口
│   ├── CRUD 操作方法
│   └── 环境值扩展
│
├── RoundListView.swift         # 回合列表 UI
│   ├── RoundListView           # 主列表视图
│   ├── RoundRowView            # 回合行视图
│   ├── RoundDetailView         # 回合详情
│   ├── ShotRowView             # 击球行视图
│   └── NewRoundView            # 新建回合
│
└── RecordShotView.swift        # 击球记录 UI
    ├── RecordShotView          # 记录新击球
    └── UpdateShotResultView    # 更新击球结果
```

### 已更新文件

- `MCaddieApp.swift` - 使用新的 SwiftData schema

## 🔧 使用指南

### 1. 初始化数据管理器

在 App 入口初始化：

```swift
@main
struct MCaddieApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RoundModel.self,
            ShotModel.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var dataManager: DataManager {
        DataManager(modelContainer: sharedModelContainer)
    }
    
    var body: some Scene {
        WindowGroup {
            iOSWelcomeView()
                .dataManager(dataManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
```

### 2. 在视图中使用

通过环境值访问：

```swift
struct MyView: View {
    @Environment(\.dataManager) private var dataManager
    
    var body: some View {
        // 使用 dataManager
    }
}
```

### 3. 保存新回合

```swift
func createRound() {
    guard let manager = dataManager else { return }
    
    let courseInfo = Round.CourseInfo(
        name: "春城湖畔高尔夫球场",
        location: "昆明",
        numberOfHoles: 18
    )
    
    let round = Round(
        course: courseInfo,
        status: .inProgress
    )
    
    do {
        try manager.saveRound(round)
    } catch {
        print("保存失败: \(error)")
    }
}
```

### 4. 记录击球

```swift
func recordShot(in round: Round, position: PositionObservation) {
    guard let manager = dataManager else { return }
    
    let estimate = Shot.InitialEstimate(
        estimatedCarry: Distance(yards: 150),
        estimatedTotal: Distance(yards: 160),
        dictationText: "7号铁，向右偏"
    )
    
    let shot = Shot(
        club: .iron7,
        startPosition: position,
        startLie: .fairway,
        initialEstimate: estimate
    )
    
    do {
        try manager.saveShot(shot, toRoundID: round.id)
    } catch {
        print("保存失败: \(error)")
    }
}
```

### 5. 更新击球结果

```swift
func updateShotResult(shot: Shot, endPosition: PositionObservation) {
    guard let manager = dataManager else { return }
    
    let measuredDistance = shot.startPosition.distance(to: endPosition)
    
    let actualResult = Shot.ActualResult(
        endPosition: endPosition,
        endLie: .green,
        measuredTotal: measuredDistance,
        performanceRating: .good
    )
    
    let updatedShot = shot.withActualResult(actualResult)
    
    do {
        try manager.updateShot(updatedShot)
    } catch {
        print("更新失败: \(error)")
    }
}
```

### 6. 查询数据

```swift
// 获取所有回合
let allRounds = try manager.fetchAllRounds()

// 获取进行中的回合
let activeRounds = try manager.fetchActiveRounds()

// 获取特定回合
if let round = try manager.fetchRound(id: roundID) {
    // 处理回合
}

// 获取回合的击球记录
let shots = try manager.fetchShots(forRoundID: roundID)

// 获取最近的回合
let recentRounds = try manager.fetchRecentRounds(limit: 5)
```

## 🎯 核心概念

### 领域模型 → 持久化模型

```swift
// 创建领域模型
let round = Round(course: courseInfo, status: .inProgress)

// 转换为持久化模型
let roundModel = try RoundModel(from: round)

// 保存到 SwiftData
modelContext.insert(roundModel)
try modelContext.save()
```

### 持久化模型 → 领域模型

```swift
// 从 SwiftData 获取
let roundModel = try modelContext.fetch(descriptor).first

// 转换为领域模型
let round = try roundModel.toDomain(with: shots)

// 在业务逻辑中使用
processRound(round)
```

### 数据转换策略

1. **简单值类型** - 直接存储（Int, Double, String, Date）
2. **枚举** - 存储 rawValue，转换时重建
3. **复杂结构** - JSON 编码存储为 Data，使用 `@Attribute(.externalStorage)`
4. **关系** - 使用 SwiftData 的 `@Relationship`

## ⚠️ 重要注意事项

### 1. 同步更新领域模型和持久化模型

当修改领域模型时，必须同步更新：
- 持久化模型的属性
- `init(from:)` 转换逻辑
- `toDomain()` 转换逻辑

### 2. 枚举值验证

所有从 rawValue 重建的枚举都要处理 nil 情况：

```swift
guard let status = Round.RoundStatus(rawValue: statusRawValue) else {
    throw PersistenceError.invalidEnumValue("RoundStatus", statusRawValue)
}
```

### 3. 处理可选值

在转换过程中正确处理可选值：

```swift
var actualResult: Shot.ActualResult? = nil
if let endPositionData = endPositionData,
   let endLieRaw = endLieRawValue,
   let totalYards = measuredTotalYards {
    // 构建 actualResult
}
```

### 4. 性能考虑

- 使用 `@Attribute(.externalStorage)` 存储大型数据（JSON）
- 避免在循环中频繁保存，使用批量操作
- 使用 `fetchLimit` 限制查询结果

### 5. 同步和冲突

当前实现是单设备本地存储。未来添加 Watch-iPhone 同步时需要：
- 添加 `createdAt` 和 `updatedAt` 时间戳（已预留）
- 实现冲突解决策略
- 使用 UUID 作为稳定标识符（已实现）

## 🧪 测试

### 单元测试示例

```swift
import Testing
@testable import MCaddie

@Suite("DataManager Tests")
struct DataManagerTests {
    
    @Test("保存和读取回合")
    func saveAndFetchRound() async throws {
        let manager = try DataManager.preview()
        
        let courseInfo = Round.CourseInfo(
            name: "测试球场",
            numberOfHoles: 18
        )
        
        let round = Round(course: courseInfo)
        
        try manager.saveRound(round)
        
        let fetchedRound = try manager.fetchRound(id: round.id)
        #expect(fetchedRound != nil)
        #expect(fetchedRound?.course.name == "测试球场")
    }
    
    @Test("保存击球到回合")
    func saveShotToRound() async throws {
        let manager = try DataManager.preview()
        
        // 创建并保存回合
        let round = Round(
            course: Round.CourseInfo(name: "测试", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        // 创建击球
        let position = PositionObservation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160)
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: position,
            startLie: .fairway,
            initialEstimate: estimate
        )
        
        try manager.saveShot(shot, toRoundID: round.id)
        
        // 验证
        let shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 1)
        #expect(shots.first?.club == .iron7)
    }
}
```

## 📚 下一步

### 待集成功能

1. **位置服务集成**
   - 替换 RecordShotView 中的模拟位置
   - 集成 CoreLocation
   - 处理权限请求

2. **Watch 同步**
   - 实现 WatchConnectivity
   - 离线队列机制
   - 冲突解决

3. **数据迁移**
   - SwiftData schema 版本管理
   - 迁移策略

4. **性能优化**
   - 分页加载
   - 后台保存
   - 缓存策略

## 🔍 故障排除

### 常见错误

1. **"数据管理器未初始化"**
   - 确保在 App 入口正确设置 `.dataManager()`
   - 检查环境值传递链

2. **枚举值转换失败**
   - 检查 rawValue 是否匹配
   - 确认数据迁移后枚举定义未改变

3. **JSON 编码失败**
   - 确保所有嵌套类型遵循 Codable
   - 检查循环引用

4. **性能问题**
   - 使用 Instruments 分析
   - 检查是否有 N+1 查询
   - 优化 FetchDescriptor

## 📞 需要帮助？

如果遇到问题：
1. 检查本指南的相关章节
2. 查看 `ARCHITECTURE.md` 了解整体设计
3. 参考 `DATA_MODEL.md` 了解领域模型
4. 查看示例视图的实现

---

**文档版本**: 1.0  
**最后更新**: 2026-10-24  
**作者**: M-Caddie 开发团队
