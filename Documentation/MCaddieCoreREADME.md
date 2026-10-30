# MCaddieCore

纯 Swift 核心领域模块，不依赖任何平台 UI 框架。

## 设计原则

- ✅ 纯 Swift，无平台依赖
- ✅ 不依赖 SwiftUI、UIKit、WatchKit、CoreLocation、Speech、WatchConnectivity
- ✅ 完全可单元测试
- ✅ 区分 carry 和 total 距离
- ✅ 使用值类型（struct/enum）

## 包含的类型

### ✅ 已实现

#### 基础类型
- **`Distance`**: 距离值类型，支持 yards/meters 转换
- **`ClubType`**: 球杆类型枚举（driver, woods, irons, wedges, putter）
- **`ClubPerformance`**: 球杆性能数据（区分 carry 和 total）
- **`DistanceCalculator`**: 距离计算工具（Haversine 公式）

#### 位置和球位
- **`PositionObservation`**: 位置观测记录
  - GPS 坐标、精度、时间戳
  - 来源标记（gps, manual, mapSelection, courseDatabase）
  - 可靠性判断方法
  
- **`Lie`**: 球位分类
  - 发球台、球道、长草区、沙坑、果岭等
  - 难度系数（用于决策算法）

#### 核心击球记录
- **`Shot`**: 击球记录（最核心的模型）
  - 稳定的 Shot ID
  - 初始估计（口述的方向和距离）
  - 实际结果（走到球位后更新）
  - **严格区分 carry 和 total**
  - 确认状态跟踪
  - 支持丢球标记

#### 回合管理
- **`Hole`**: 球洞信息
  - 球洞号、标准杆、距离
  - 发球台和果岭位置
  - 难度等级

- **`Round`**: 回合记录
  - 回合 ID、开始/结束时间
  - 球场信息
  - 击球记录列表
  - 回合状态管理
  - 统计信息计算

- **`RoundStatistics`**: 回合统计
  - 平均距离、最长/最短击球
  - 球杆使用分布
  - 球位分布

### 🔄 待实现

未来将添加：
- **`ClubProfile`**: 球杆档案管理
- **`Recommendation`**: 球杆建议生成
- **`DecisionEngine`**: 决策引擎纯函数
- **`WindCondition`**: 风向风速
- **`ElevationChange`**: 高度差计算

## 运行测试

```bash
cd MCaddieCore
swift test
```

## 在 Xcode 中集成

**手动步骤（您需要在 Xcode 中执行）：**

1. 打开 `MCaddie.xcodeproj`
2. 选择 File → Add Package Dependencies → Add Local...
3. 选择 `MCaddieCore` 文件夹
4. 在 iOS App target 和 Watch App target 中添加 `MCaddieCore` 依赖
5. 构建验证

或者通过 Xcode UI：
- 选择 Project → MCaddie → Targets → MCaddie
- General → Frameworks, Libraries, and Embedded Content → + → Add Other → Add Package Dependency → Add Local
- 重复上述步骤用于 Watch App target

## 依赖图

```
MCaddie iOS App ──┐
                  ├──> MCaddieCore (纯 Swift)
MCaddie Watch App ┘
```

平台相关代码（定位、语音、UI）保持在 App target 中。
