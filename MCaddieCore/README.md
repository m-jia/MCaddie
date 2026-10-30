# MCaddieCore

纯 Swift 核心领域模块，不依赖任何平台 UI 框架。

## 设计原则

- ✅ 纯 Swift，无平台依赖
- ✅ 不依赖 SwiftUI、UIKit、WatchKit、CoreLocation、Speech、WatchConnectivity
- ✅ 完全可单元测试
- ✅ 区分 carry 和 total 距离
- ✅ 使用值类型（struct/enum）

## 测试

```bash
cd MCaddieCore
swift test
```

## 包含的类型

- `Distance`: 距离值类型（yards/meters）
- `ClubType`: 球杆类型枚举
- `ClubPerformance`: 球杆性能（区分 carry 和 total）
- `DistanceCalculator`: 距离计算工具
