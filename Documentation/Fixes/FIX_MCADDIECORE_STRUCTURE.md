# 🚨 MCaddieCore Package 结构修复指南

## ❌ 问题根源

MCaddieCore Package 的文件结构不正确。应该按照标准 Swift Package 结构组织。

---

## ✅ 正确的 MCaddieCore 目录结构

```
MCaddieCore/                          ← Package 根目录
├── Package.swift                     ← Package 定义文件
├── README.md
├── Sources/                          ← 源代码目录
│   └── MCaddieCore/                  ← 模块目录
│       └── Distance.swift            ← 源文件
└── Tests/                            ← 测试目录
    └── MCaddieCoreTests/             ← 测试模块目录
        └── DistanceTests.swift       ← 测试文件
```

---

## 🔧 手动修复步骤

### 方案 A: 在 Finder 中手动创建正确结构

1. **在项目根目录创建 MCaddieCore 文件夹：**
   ```bash
   mkdir -p MCaddieCore/Sources/MCaddieCore
   mkdir -p MCaddieCore/Tests/MCaddieCoreTests
   ```

2. **移动现有文件到正确位置：**
   
   如果文件在根目录：
   ```bash
   # 移动 Package.swift
   mv Package.swift MCaddieCore/
   
   # 移动源代码文件（如果名字被扁平化）
   mv MCaddieCoreSourcesMCaddieCoreDistance.swift MCaddieCore/Sources/MCaddieCore/Distance.swift
   
   # 移动测试文件
   mv MCaddieCoreTestsMCaddieCoreTestsDistanceTests.swift MCaddieCore/Tests/MCaddieCoreTests/DistanceTests.swift
   
   # 移动 README（如果存在）
   mv MCaddieCoreREADME.md MCaddieCore/README.md
   ```

3. **验证结构：**
   ```bash
   tree MCaddieCore -L 3
   ```

---

### 方案 B: 删除旧文件，重新创建完整 Package

如果文件结构太混乱，最简单的方法是重新创建：

#### 步骤 1: 清理旧的错误文件

在 Xcode 或 Finder 中删除：
- `Package.swift`（根目录的）
- `MCaddieCoreSourcesMCaddieCoreDistance.swift`
- `MCaddieCoreTestsMCaddieCoreTestsDistanceTests.swift`
- `MCaddieCoreREADME.md`
- 任何其他 `MCaddieCore*` 开头的扁平化文件

#### 步骤 2: 在终端创建正确结构

```bash
cd /path/to/MCaddie项目根目录

# 创建 Package 目录结构
mkdir -p MCaddieCore/Sources/MCaddieCore
mkdir -p MCaddieCore/Tests/MCaddieCoreTests

# 创建 Package.swift
cat > MCaddieCore/Package.swift << 'EOF'
// swift-tools-version: 5.9

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
EOF

# 创建 Distance.swift
cat > MCaddieCore/Sources/MCaddieCore/Distance.swift << 'EOF'
import Foundation

/// 距离单位：内部统一使用码(yards)
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
    case iron3, iron4, iron5, iron6, iron7, iron8, iron9
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

# 创建 DistanceTests.swift
cat > MCaddieCore/Tests/MCaddieCoreTests/DistanceTests.swift << 'EOF'
import Testing
@testable import MCaddieCore

@Suite("Distance Tests")
struct DistanceTests {
    
    @Test("Distance conversion between yards and meters")
    func distanceConversion() {
        let distance = Distance(yards: 100)
        #expect(abs(distance.meters - 91.44) < 0.01)
        
        let distanceFromMeters = Distance(meters: 91.44)
        #expect(abs(distanceFromMeters.yards - 100) < 0.01)
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
        
        #expect(distance.yards > 121000)
        #expect(distance.yards < 122000)
    }
}
EOF

# 创建 README
cat > MCaddieCore/README.md << 'EOF'
# MCaddieCore

纯 Swift 核心领域模块。

## 特性
- ✅ 无平台依赖
- ✅ 完全可单元测试
- ✅ 区分 carry 和 total 距离

## 测试
```bash
swift test
```
EOF

echo "✅ MCaddieCore 结构创建完成！"
```

#### 步骤 3: 验证 Package 可以构建

```bash
cd MCaddieCore
swift build
swift test
```

**应该看到：**
```
Build complete!
Test Suite 'All tests' passed
```

---

### 方案 C: 我为您生成完整的一键修复脚本

```bash
# 保存为 fix_mcaddiecore.sh
chmod +x fix_mcaddiecore.sh
./fix_mcaddiecore.sh
```

---

## 🎯 修复后的验证步骤

### 1. 验证 Package 结构

```bash
tree MCaddieCore
```

**应该看到：**
```
MCaddieCore
├── Package.swift
├── README.md
├── Sources
│   └── MCaddieCore
│       └── Distance.swift
└── Tests
    └── MCaddieCoreTests
        └── DistanceTests.swift
```

### 2. 测试 Package 独立构建

```bash
cd MCaddieCore
swift build
swift test
```

### 3. 在 Xcode 中添加 Package

**现在才能正确添加！**

1. File → Add Package Dependencies...
2. Add Local...
3. 选择 `MCaddieCore` **文件夹**
4. Add Package

### 4. 链接到 Targets

- iOS target: General → Frameworks → + → MCaddieCore
- Watch target: 同上

### 5. 清理并重新构建

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/MCaddie-*
```

在 Xcode:
```
⇧⌘K (Clean)
⌘B (Build)
```

---

## 📋 故障排除

### 如果 Swift 版本不匹配

修改 `Package.swift` 第一行：

```swift
// 如果您的 Xcode 较旧
// swift-tools-version: 5.8  // 或 5.7
```

### 如果平台版本太高

修改 `Package.swift` 中的 platforms：

```swift
platforms: [
    .iOS(.v16),      // 降低到 16
    .watchOS(.v9)    // 降低到 9
]
```

---

## 🆘 需要帮助？

请提供：

1. **环境信息：**
   ```bash
   ./check_environment.sh
   ```

2. **当前文件结构：**
   ```bash
   find . -name "*.swift" -o -name "Package.swift" | head -20
   ```

3. **完整的错误信息**（截图或文本）

---

我建议您选择 **方案 B**（重新创建），因为它最干净可靠。

请告诉我您选择哪个方案，或者需要我生成自动化脚本！
