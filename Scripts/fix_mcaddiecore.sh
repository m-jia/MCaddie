#!/bin/bash

# MCaddieCore 结构一键修复脚本
# 自动创建正确的 Swift Package 结构

set -e  # 遇到错误立即退出

echo "🔧 MCaddieCore Package 结构修复"
echo "==============================="
echo ""

# 检查是否在项目根目录
if [ ! -f "MCaddieApp.swift" ] && [ ! -f "MCaddie/MCaddieApp.swift" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    echo "   (应该包含 MCaddieApp.swift 或 MCaddie/ 文件夹)"
    exit 1
fi

echo "1️⃣ 清理旧的错误文件..."
echo "------------------------"

# 安全删除扁平化的文件（如果存在）
[ -f "MCaddieCorePackage.swift" ] && rm -f "MCaddieCorePackage.swift" && echo "   ✅ 删除 MCaddieCorePackage.swift"
[ -f "MCaddieCoreSourcesMCaddieCoreDistance.swift" ] && rm -f "MCaddieCoreSourcesMCaddieCoreDistance.swift" && echo "   ✅ 删除扁平化的 Distance.swift"
[ -f "MCaddieCoreTestsMCaddieCoreTestsDistanceTests.swift" ] && rm -f "MCaddieCoreTestsMCaddieCoreTestsDistanceTests.swift" && echo "   ✅ 删除扁平化的 DistanceTests.swift"
[ -f "MCaddieCoreREADME.md" ] && rm -f "MCaddieCoreREADME.md" && echo "   ✅ 删除扁平化的 README.md"

# 如果 Package.swift 在根目录，也删除
if [ -f "Package.swift" ]; then
    echo "⚠️  发现根目录的 Package.swift"
    echo "   将移动到 MCaddieCore/ 目录"
    mv Package.swift Package.swift.backup
fi

echo ""
echo "2️⃣ 创建正确的目录结构..."
echo "--------------------------"

# 创建 MCaddieCore 目录结构
mkdir -p MCaddieCore/Sources/MCaddieCore
mkdir -p MCaddieCore/Tests/MCaddieCoreTests

echo "   ✅ MCaddieCore/"
echo "   ✅ MCaddieCore/Sources/MCaddieCore/"
echo "   ✅ MCaddieCore/Tests/MCaddieCoreTests/"
echo ""

echo "3️⃣ 创建 Package.swift..."
echo "------------------------"

cat > MCaddieCore/Package.swift << 'PACKAGE_EOF'
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
            dependencies: [],
            path: "Sources/MCaddieCore"
        ),
        .testTarget(
            name: "MCaddieCoreTests",
            dependencies: ["MCaddieCore"],
            path: "Tests/MCaddieCoreTests"
        ),
    ]
)
PACKAGE_EOF

echo "   ✅ Package.swift 已创建"
echo ""

echo "4️⃣ 创建源代码文件..."
echo "--------------------"

cat > MCaddieCore/Sources/MCaddieCore/Distance.swift << 'DISTANCE_EOF'
import Foundation

/// 距离单位：内部统一使用码(yards)
/// 根据 ARCHITECTURE.md 要求，必须区分 carry 和 total
public struct Distance: Equatable, Codable {
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
public enum ClubType: String, Codable, CaseIterable {
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
public struct ClubPerformance: Codable, Equatable {
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
    
    /// 计算两点之间的直线距离（简化版 Haversine）
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
DISTANCE_EOF

echo "   ✅ Distance.swift 已创建"
echo ""

echo "5️⃣ 创建测试文件..."
echo "------------------"

cat > MCaddieCore/Tests/MCaddieCoreTests/DistanceTests.swift << 'TESTS_EOF'
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
        let point1 = (latitude: 0.0, longitude: 0.0)
        let point2 = (latitude: 1.0, longitude: 0.0)
        
        let distance = DistanceCalculator.distance(from: point1, to: point2)
        
        // 1 度纬度约 111 km = 111000 m ≈ 121,391 yards
        #expect(distance.yards > 121000, "Distance should be approximately 121,391 yards")
        #expect(distance.yards < 122000, "Distance should be approximately 121,391 yards")
    }
}
TESTS_EOF

echo "   ✅ DistanceTests.swift 已创建"
echo ""

echo "6️⃣ 创建 README..."
echo "-----------------"

cat > MCaddieCore/README.md << 'README_EOF'
# MCaddieCore

纯 Swift 核心领域模块，不依赖任何平台 UI 框架。

## 设计原则

- ✅ 纯 Swift，无平台依赖
- ✅ 不依赖 SwiftUI、UIKit、WatchKit、CoreLocation、Speech
- ✅ 完全可单元测试
- ✅ 区分 carry 和 total 距离

## 运行测试

```bash
cd MCaddieCore
swift test
```

## 包含的类型

- `Distance`: 距离值类型（yards/meters）
- `ClubType`: 球杆类型枚举
- `ClubPerformance`: 球杆性能（区分 carry/total）
- `DistanceCalculator`: 距离计算工具
README_EOF

echo "   ✅ README.md 已创建"
echo ""

echo "7️⃣ 验证 Package 结构..."
echo "-----------------------"

if command -v tree &> /dev/null; then
    tree MCaddieCore -L 3
else
    find MCaddieCore -type f | sort
fi

echo ""
echo "8️⃣ 测试 Package 构建..."
echo "-----------------------"

cd MCaddieCore

if swift build 2>&1 | tee /tmp/mcaddie_build.log; then
    echo ""
    echo "   ✅ Package 构建成功！"
else
    echo ""
    echo "   ⚠️  构建失败。查看错误："
    tail -20 /tmp/mcaddie_build.log
    echo ""
    echo "   可能需要调整 Swift 版本或平台版本"
    echo "   请运行: ./check_environment.sh"
    cd ..
    exit 1
fi

echo ""
echo "9️⃣ 运行测试..."
echo "---------------"

if swift test 2>&1 | tee /tmp/mcaddie_test.log; then
    echo ""
    echo "   ✅ 所有测试通过！"
else
    echo ""
    echo "   ⚠️  测试失败。查看错误："
    tail -20 /tmp/mcaddie_test.log
    cd ..
    exit 1
fi

cd ..

echo ""
echo "🎉 MCaddieCore Package 修复完成！"
echo "================================"
echo ""
echo "✅ 完成的工作："
echo "   - 创建了正确的 Package 目录结构"
echo "   - Distance.swift (距离模型)"
echo "   - DistanceTests.swift (3 个测试)"
echo "   - Package 可以独立构建和测试"
echo ""
echo "📋 下一步操作："
echo "   1. 在 Xcode 中添加 MCaddieCore Package："
echo "      File → Add Package Dependencies → Add Local → 选择 MCaddieCore/"
echo ""
echo "   2. 将 MCaddieCore 添加到 iOS 和 Watch targets："
echo "      Target → General → Frameworks → + → MCaddieCore"
echo ""
echo "   3. 清理并重新构建："
echo "      rm -rf ~/Library/Developer/Xcode/DerivedData/MCaddie-*"
echo "      在 Xcode: ⇧⌘K 然后 ⌘B"
echo ""
echo "✅ 可以开始开发了！"
