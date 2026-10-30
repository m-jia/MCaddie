# SwiftData 快速参考

> 快速查询常用的 SwiftData 操作

## 🚀 快速开始

### 在视图中使用 DataManager

```swift
struct MyView: View {
    @Environment(\.dataManager) private var dataManager
    
    var body: some View {
        // 你的视图代码
    }
}
```

## 📝 常用操作

### 创建新回合

```swift
let courseInfo = Round.CourseInfo(
    name: "球场名称",
    location: "位置（可选）",
    numberOfHoles: 18
)

let round = Round(
    course: courseInfo,
    status: .inProgress
)

try dataManager?.saveRound(round)
```

### 记录击球

```swift
// 1. 获取当前位置
let position = PositionObservation(
    latitude: 纬度,
    longitude: 经度,
    horizontalAccuracy: GPS精度,
    source: .gps
)

// 2. 创建初始估计
let estimate = Shot.InitialEstimate(
    estimatedCarry: Distance(yards: 150),
    estimatedTotal: Distance(yards: 160),
    dictationText: "口述记录（可选）"
)

// 3. 创建击球记录
let shot = Shot(
    club: .iron7,
    startPosition: position,
    startLie: .fairway,
    initialEstimate: estimate
)

// 4. 保存到回合
try dataManager?.saveShot(shot, toRoundID: round.id)
```

### 更新击球结果

```swift
// 1. 获取终点位置
let endPosition = PositionObservation(...)

// 2. 计算实际距离
let measuredDistance = shot.startPosition.distance(to: endPosition)

// 3. 创建实际结果
let actualResult = Shot.ActualResult(
    endPosition: endPosition,
    endLie: .green,
    measuredTotal: measuredDistance,
    performanceRating: .good
)

// 4. 更新击球
let updatedShot = shot.withActualResult(actualResult)
try dataManager?.updateShot(updatedShot)
```

### 查询数据

```swift
// 获取所有回合
let allRounds = try dataManager?.fetchAllRounds()

// 获取进行中的回合
let activeRounds = try dataManager?.fetchActiveRounds()

// 获取特定回合
let round = try dataManager?.fetchRound(id: roundID)

// 获取回合的击球记录
let shots = try dataManager?.fetchShots(forRoundID: roundID)

// 获取最近 5 个回合
let recent = try dataManager?.fetchRecentRounds(limit: 5)
```

### 删除数据

```swift
// 删除回合（会级联删除所有击球）
try dataManager?.deleteRound(id: roundID)

// 删除击球
try dataManager?.deleteShot(id: shotID)
```

## 🎯 球杆类型

```swift
ClubType.driver          // 1号木
ClubType.wood3           // 3号木
ClubType.wood5           // 5号木
ClubType.hybrid          // 混合杆
ClubType.iron3           // 3号铁
ClubType.iron4           // 4号铁
ClubType.iron5           // 5号铁
ClubType.iron6           // 6号铁
ClubType.iron7           // 7号铁
ClubType.iron8           // 8号铁
ClubType.iron9           // 9号铁
ClubType.pitchingWedge   // P杆
ClubType.gapWedge        // G杆
ClubType.sandWedge       // S杆
ClubType.lobWedge        // L杆
ClubType.putter          // 推杆
```

## 🌿 球位类型

```swift
Lie.tee          // 发球台
Lie.fairway      // 球道
Lie.firstCut     // 浅草区
Lie.roughDeep    // 深草区
Lie.bunker       // 沙坑
Lie.green        // 果岭
Lie.waterHazard  // 水障碍
Lie.trees        // 树林
Lie.other        // 其他
```

## 📏 距离单位

```swift
// 创建距离
let distance1 = Distance(yards: 150)    // 从码创建
let distance2 = Distance(meters: 137)   // 从米创建

// 获取值
let yards = distance1.yards             // 获取码数
let meters = distance1.meters           // 获取米数
```

## 🎭 回合状态

```swift
Round.RoundStatus.inProgress  // 进行中
Round.RoundStatus.completed   // 已完成
Round.RoundStatus.abandoned   // 已放弃
Round.RoundStatus.paused      // 已暂停
```

## ⭐ 击球表现评级

```swift
Shot.PerformanceRating.excellent  // 非常好
Shot.PerformanceRating.good       // 好
Shot.PerformanceRating.average    // 一般
Shot.PerformanceRating.poor       // 不理想
Shot.PerformanceRating.mistake    // 失误
```

## 📍 位置来源

```swift
PositionObservation.PositionSource.gps            // GPS定位
PositionObservation.PositionSource.manual         // 手动标记
PositionObservation.PositionSource.mapSelection   // 地图选择
PositionObservation.PositionSource.courseDatabase // 球场数据库
```

## 🔍 击球状态

```swift
Shot.ConfirmationState.initial             // 初始记录
Shot.ConfirmationState.pendingConfirmation // 待确认
Shot.ConfirmationState.confirmed           // 已确认
Shot.ConfirmationState.lost                // 丢球
```

## 💡 实用方法

### Round 便利方法

```swift
round.isInProgress       // 是否进行中
round.isCompleted        // 是否已完成
round.totalShots         // 总击球数
round.confirmedShots     // 已确认的击球数
round.duration           // 回合时长（秒）
round.statistics         // 统计信息
```

### Shot 便利方法

```swift
shot.isCompleted                // 是否已完成
shot.finalTotalDistance         // 最终 total 距离
shot.finalCarryDistance         // 最终 carry 距离
shot.totalDistanceDeviation     // 估计与实际的偏差
```

### PositionObservation 便利方法

```swift
position.distance(to: otherPosition)  // 计算到另一个位置的距离
position.isReliable                   // 是否可靠（< 10米）
position.isHighPrecision              // 是否高精度（< 5米）
```

## ⚠️ 错误处理

```swift
do {
    try dataManager?.saveRound(round)
} catch DataManagerError.roundNotFound(let id) {
    print("找不到回合: \(id)")
} catch DataManagerError.shotNotFound(let id) {
    print("找不到击球: \(id)")
} catch {
    print("发生错误: \(error.localizedDescription)")
}
```

## 🧪 测试

```swift
// 创建测试用 DataManager（内存存储）
let testManager = try DataManager.preview()

// 清除所有数据（测试用）
try testManager.clearAllData()
```

## 📚 更多信息

- 详细文档: `SWIFTDATA_GUIDE.md`
- 实施报告: `SWIFTDATA_IMPLEMENTATION_REPORT.md`
- 架构设计: `ARCHITECTURE.md`
- 数据模型: `DATA_MODEL.md`

---

**提示**: 所有涉及 GPS 的操作目前使用模拟数据。集成真实位置服务后需要替换 `RecordShotView.swift` 中的 TODO 标记处。
