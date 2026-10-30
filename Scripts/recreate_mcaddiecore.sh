#!/bin/bash

# 重新创建 MCaddieCore Package 脚本

echo "🗑️  第一步：清理旧的 MCaddieCore"
echo "================================"

# 删除旧的 MCaddieCore 文件夹
if [ -d "MCaddieCore" ]; then
    echo "删除旧的 MCaddieCore 目录..."
    rm -rf MCaddieCore
    echo "✅ 已删除"
else
    echo "⚠️  MCaddieCore 目录不存在（可能已删除）"
fi

echo ""
echo "🆕 第二步：创建新的 MCaddieCore Package"
echo "======================================"

# 创建目录结构
mkdir -p MCaddieCore/Sources/MCaddieCore
mkdir -p MCaddieCore/Tests/MCaddieCoreTests

echo "✅ 目录结构创建完成"
echo ""

echo "📄 创建 Package.swift..."
cat > MCaddieCore/Package.swift << 'EOF'
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MCaddieCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "MCaddieCore",
            targets: ["MCaddieCore"]),
    ],
    targets: [
        .target(
            name: "MCaddieCore",
            dependencies: []
        ),
        .testTarget(
            name: "MCaddieCoreTests",
            dependencies: ["MCaddieCore"]
        ),
    ]
)
EOF

echo "✅ Package.swift 创建完成"
echo ""

echo "📄 创建 Distance.swift..."
cat > MCaddieCore/Sources/MCaddieCore/Distance.swift << 'EOF'
import Foundation

/// 距离单位：内部统一使用码(yards)
/// 根据 ARCHITECTURE.md 要求，必须区分 carry 和 total
public struct Distance: Equatable, Codable, Sendable {
    public let yards: Double
    
    public init(yards: Double) {
        self.yards = yards
    }
    
    public init(meters: Double) {
        self.yards = meters * 1.09361
    }
    
    public var meters: Double {
        yards / 1.09361
    }
}

/// 球杆类型
public enum ClubType: String, Codable, CaseIterable, Sendable {
    case driver
    case wood3
    case wood5
    case hybrid
    case iron3
    case iron4
    case iron5
    case iron6
    case iron7
    case iron8
    case iron9
    case pitchingWedge
    case gapWedge
    case sandWedge
    case lobWedge
    case putter
}

/// 球杆距离性能（区分 carry 和 total）
public struct ClubPerformance: Codable, Equatable, Sendable {
    public let clubType: ClubType
    public let averageCarry: Distance
    public let averageTotal: Distance
    public let swingSpeedMPH: Double?
    
    public init(
        clubType: ClubType,
        averageCarry: Distance,
        averageTotal: Distance,
        swingSpeedMPH: Double? = nil
    ) {
        self.clubType = clubType
        self.averageCarry = averageCarry
        self.averageTotal = averageTotal
        self.swingSpeedMPH = swingSpeedMPH
    }
}

/// 简单的距离计算工具
public struct DistanceCalculator {
    
    public init() {}
    
    /// 计算两点之间的直线距离（使用 Haversine 公式）
    public static func distance(
        from: (latitude: Double, longitude: Double),
        to: (latitude: Double, longitude: Double)
    ) -> Distance {
        let lat1Rad = from.latitude * .pi / 180
        let lat2Rad = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        let earthRadiusMeters = 6371000.0
        let meters = earthRadiusMeters * c
        
        return Distance(meters: meters)
    }
}
EOF

echo "✅ Distance.swift 创建完成"
echo ""

echo "📄 创建 DistanceTests.swift..."
cat > MCaddieCore/Tests/MCaddieCoreTests/DistanceTests.swift << 'EOF'
import Testing
@testable import MCaddieCore

@Suite("Distance Tests")
struct DistanceTests {
    
    @Test("Distance conversion between yards and meters")
    func distanceConversion() {
        let distance = Distance(yards: 100)
        #expect(abs(distance.meters - 91.44) < 0.01, "100 yards should be approximately 91.44 meters")
        
        let distanceFromMeters = Distance(meters: 91.44)
        #expect(abs(distanceFromMeters.yards - 100) < 0.01, "91.44 meters should be approximately 100 yards")
    }
    
    @Test("ClubPerformance stores carry and total separately")
    func clubPerformanceCarryAndTotal() {
        let driver = ClubPerformance(
            clubType: .driver,
            averageCarry: Distance(yards: 180),
            averageTotal: Distance(yards: 200),
            swingSpeedMPH: 77.5
        )
        
        #expect(driver.averageCarry.yards == 180)
        #expect(driver.averageTotal.yards == 200)
        #expect(driver.swingSpeedMPH == 77.5)
    }
    
    @Test("Distance calculator computes approximate distance")
    func distanceCalculation() {
        // 测试两个已知距离的点（约 111 km 的纬度差）
        let point1 = (latitude: 0.0, longitude: 0.0)
        let point2 = (latitude: 1.0, longitude: 0.0)
        
        let distance = DistanceCalculator.distance(from: point1, to: point2)
        
        // 1 度纬度约 111 km = 111000 m ≈ 121,391 yards
        #expect(distance.yards > 121000, "Distance should be approximately 121,391 yards")
        #expect(distance.yards < 122000, "Distance should be approximately 121,391 yards")
    }
}
EOF

echo "✅ DistanceTests.swift 创建完成"
echo ""

echo "📄 创建 README.md..."
cat > MCaddieCore/README.md << 'EOF'
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
EOF

echo "✅ README.md 创建完成"
echo ""

echo "🧪 第三步：测试 Package"
echo "======================"

cd MCaddieCore
echo "运行 swift test..."
swift test

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ Package 创建成功并测试通过！"
    echo ""
    echo "📋 下一步操作（在 Xcode 中）："
    echo "================================"
    echo "1. 在 Xcode 中：File → Add Package Dependencies → Add Local..."
    echo "2. 选择 MCaddieCore 文件夹"
    echo "3. 在 iOS target 和 Watch target 中添加 MCaddieCore"
    echo "4. ⌘B 构建项目"
else
    echo ""
    echo "❌ 测试失败，请检查错误信息"
fi

cd ..
