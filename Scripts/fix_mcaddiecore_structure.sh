#!/bin/bash

echo "🔧 正在修复 MCaddieCore Package 结构..."
echo ""

# 创建正确的目录结构
echo "📁 创建目录结构..."
mkdir -p MCaddieCore/Sources/MCaddieCore
mkdir -p MCaddieCore/Tests/MCaddieCoreTests

# 核心模型文件列表
CORE_FILES=(
    "Distance.swift"
    "Shot.swift"
    "Round.swift"
    "Hole.swift"
    "Lie.swift"
    "PositionObservation.swift"
)

# 移动核心模型文件
echo ""
echo "📦 移动核心模型文件..."
for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        if [ ! -f "MCaddieCore/Sources/MCaddieCore/$file" ]; then
            cp "$file" "MCaddieCore/Sources/MCaddieCore/"
            echo "  ✅ 复制 $file 到 MCaddieCore/Sources/MCaddieCore/"
        else
            echo "  ⏭️  $file 已存在，跳过"
        fi
    else
        echo "  ⚠️  找不到 $file"
    fi
done

# 处理 Package.swift
echo ""
echo "📄 处理 Package.swift..."
if [ -f "Package.swift" ]; then
    if [ ! -f "MCaddieCore/Package.swift" ]; then
        cp "Package.swift" "MCaddieCore/"
        echo "  ✅ 复制 Package.swift 到 MCaddieCore/"
    else
        echo "  ⏭️  MCaddieCore/Package.swift 已存在，跳过"
    fi
else
    echo "  ⚠️  找不到 Package.swift"
fi

# 创建 README（如果不存在）
if [ ! -f "MCaddieCore/README.md" ]; then
    echo ""
    echo "📝 创建 README.md..."
    cat > MCaddieCore/README.md << 'EOF'
# MCaddieCore

纯 Swift 领域模型 Package，不依赖任何平台框架。

## 包含的模型

- `Distance` - 距离表示（支持码/米转换）
- `Shot` - 击球记录
- `Round` - 回合记录  
- `Hole` - 球洞信息
- `Lie` - 球位分类
- `PositionObservation` - GPS 位置观测

## 架构原则

- 纯 Swift 值类型
- 无平台依赖（SwiftUI、UIKit、CoreLocation 等）
- 可独立测试
- 可跨平台复用

## 使用

```swift
import MCaddieCore

// 创建距离
let distance = Distance(yards: 150)
let meters = distance.meters  // 自动转换

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
```

## 平台支持

- iOS 17.0+
- watchOS 10.0+
EOF
    echo "  ✅ 创建 MCaddieCore/README.md"
fi

# 显示结果
echo ""
echo "📊 MCaddieCore 结构："
echo ""
tree -L 3 MCaddieCore/ 2>/dev/null || find MCaddieCore -type f | sort

echo ""
echo "🎉 MCaddieCore Package 结构修复完成！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "下一步：在 Xcode 中添加 Package"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 打开 Xcode"
echo "2. File → Add Package Dependencies..."
echo "3. 点击 Add Local..."
echo "4. 选择 'MCaddieCore' 文件夹"
echo "5. 在弹出的对话框中勾选："
echo "   ✅ MCaddie (iOS App)"
echo "   ✅ MCaddie Watch App"
echo "   ✅ MCaddieTests"
echo "6. 点击 Add Package"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
