#!/bin/bash

# 将新模型文件添加到 MCaddieCore Package 的正确位置

echo "🔧 正在将 Shot 模型文件移动到正确位置..."
echo ""

# 检查 MCaddieCore 目录是否存在
if [ ! -d "MCaddieCore" ]; then
    echo "❌ 错误：MCaddieCore 目录不存在！"
    echo "请先运行 recreate_mcaddiecore.sh 创建 Package"
    exit 1
fi

# 确保目录结构存在
mkdir -p MCaddieCore/Sources/MCaddieCore
mkdir -p MCaddieCore/Tests/MCaddieCoreTests

echo "📁 目录结构确认完成"
echo ""

# 复制文件到正确位置
echo "📄 正在复制模型文件..."

# 检查并复制 Lie.swift（可能有多种命名）
COPIED=0
for file in "MCaddieCoreSourcesMCaddieCoreL ie.swift" "MCaddieCoreSourcesMCaddieCoreL.swift" "MCaddieCoreSourcesMCaddieCoreL*.swift"; do
    if [ -f "$file" ] && [ $COPIED -eq 0 ]; then
        cp "$file" MCaddieCore/Sources/MCaddieCore/Lie.swift
        echo "✅ Lie.swift (from $file)"
        COPIED=1
        break
    fi
done
if [ $COPIED -eq 0 ]; then
    echo "⚠️  Lie.swift 未找到"
fi

# 检查并复制 PositionObservation.swift
if [ -f "MCaddieCoreSourcesMCaddieCorePositionObservation.swift" ]; then
    cp MCaddieCoreSourcesMCaddieCorePositionObservation.swift MCaddieCore/Sources/MCaddieCore/PositionObservation.swift
    echo "✅ PositionObservation.swift"
else
    echo "⚠️  MCaddieCoreSourcesMCaddieCorePositionObservation.swift 未找到"
fi

# 检查并复制 Shot.swift
if [ -f "MCaddieCoreSourcesMCaddieCoreShot.swift" ]; then
    cp MCaddieCoreSourcesMCaddieCoreShot.swift MCaddieCore/Sources/MCaddieCore/Shot.swift
    echo "✅ Shot.swift"
else
    echo "⚠️  MCaddieCoreSourcesMCaddieCoreShot.swift 未找到"
fi

# 检查并复制 Hole.swift
if [ -f "MCaddieCoreSourcesMCaddieCoreHole.swift" ]; then
    cp MCaddieCoreSourcesMCaddieCoreHole.swift MCaddieCore/Sources/MCaddieCore/Hole.swift
    echo "✅ Hole.swift"
else
    echo "⚠️  MCaddieCoreSourcesMCaddieCoreHole.swift 未找到"
fi

# 检查并复制 Round.swift
if [ -f "MCaddieCoreSourcesMCaddieCoreRound.swift" ]; then
    cp MCaddieCoreSourcesMCaddieCoreRound.swift MCaddieCore/Sources/MCaddieCore/Round.swift
    echo "✅ Round.swift"
else
    echo "⚠️  MCaddieCoreSourcesMCaddieCoreRound.swift 未找到"
fi

# 检查并复制 ShotTests.swift（从更新后的版本）
if [ -f "ShotTests.swift" ]; then
    # 确保有 import Foundation
    if ! grep -q "import Foundation" ShotTests.swift; then
        echo "⚠️  ShotTests.swift 缺少 import Foundation，正在修复..."
        sed -i.bak '1s/^/import Foundation\n/' ShotTests.swift
    fi
    cp ShotTests.swift MCaddieCore/Tests/MCaddieCoreTests/ShotTests.swift
    echo "✅ ShotTests.swift (已修复 import)"
elif [ -f "MCaddieCoreTestsMCaddieCoreTestsShotTests.swift" ]; then
    # 确保有 import Foundation
    if ! grep -q "import Foundation" MCaddieCoreTestsMCaddieCoreTestsShotTests.swift; then
        echo "⚠️  ShotTests.swift 缺少 import Foundation，正在修复..."
        sed -i.bak '1a\
import Foundation' MCaddieCoreTestsMCaddieCoreTestsShotTests.swift
    fi
    cp MCaddieCoreTestsMCaddieCoreTestsShotTests.swift MCaddieCore/Tests/MCaddieCoreTests/ShotTests.swift
    echo "✅ ShotTests.swift (已修复 import)"
else
    echo "⚠️  ShotTests.swift 未找到"
fi

echo ""
echo "📋 文件结构："
echo "=============="
tree MCaddieCore -L 3 -I 'DerivedData|.git' 2>/dev/null || find MCaddieCore -type f -name "*.swift" | sort

echo ""
echo "🧪 运行测试..."
cd MCaddieCore
swift test

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ 所有文件已正确添加并测试通过！"
    echo ""
    echo "📋 下一步："
    echo "1. 在 Xcode 中重新构建项目 (⇧⌘K 然后 ⌘B)"
    echo "2. 验证 iOS 和 Watch App 构建成功"
else
    echo ""
    echo "❌ 测试失败，请检查错误信息"
fi
