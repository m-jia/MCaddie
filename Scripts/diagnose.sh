#!/bin/bash

# M-Caddie 项目诊断脚本
# 帮助找到重复文件和配置问题

echo "🔍 M-Caddie 项目诊断"
echo "===================="
echo ""

echo "1️⃣ 查找所有 Item.swift 文件："
echo "----------------------------"
find . -name "Item.swift" -not -path "*/DerivedData/*" -not -path "*/.git/*" -not -path "*/.*"
echo ""

echo "2️⃣ 查找所有 .swift 文件（非测试）："
echo "--------------------------------"
find . -name "*.swift" \
  -not -path "*/Tests/*" \
  -not -path "*/DerivedData/*" \
  -not -path "*/.git/*" \
  -not -path "*/.*" \
  -not -name "*Tests.swift"
echo ""

echo "3️⃣ 项目目录结构："
echo "------------------"
tree -L 3 -I 'DerivedData|.git|Build' . 2>/dev/null || \
  find . -maxdepth 3 -type d -not -path "*/.*" -not -path "*/DerivedData/*" | sort
echo ""

echo "4️⃣ 检查 MCaddieCore Package："
echo "----------------------------"
if [ -f "MCaddieCore/Package.swift" ]; then
  echo "✅ MCaddieCore/Package.swift 存在"
else
  echo "❌ MCaddieCore/Package.swift 未找到"
fi

if [ -f "MCaddieCore/Sources/MCaddieCore/Distance.swift" ]; then
  echo "✅ Distance.swift 存在"
else
  echo "❌ Distance.swift 未找到"
fi
echo ""

echo "5️⃣ 检查视图文件："
echo "------------------"
for file in iOSWelcomeView.swift WatchWelcomeView.swift; do
  if [ -f "$file" ]; then
    echo "✅ $file 存在"
  else
    echo "❌ $file 未找到"
  fi
done
echo ""

echo "6️⃣ 建议的文件结构："
echo "-------------------"
cat << 'EOF'
MCaddie/
├── MCaddie/                    # iOS App 源代码目录
│   ├── MCaddieApp.swift
│   ├── iOSWelcomeView.swift
│   ├── Item.swift              # ← Item.swift 应该在这里
│   └── ContentView.swift
├── MCaddie Watch App/          # Watch App 源代码目录
│   ├── MCaddie_Watch_AppApp.swift
│   └── WatchWelcomeView.swift
├── MCaddieTests/
│   └── MCaddieTests.swift
├── MCaddie Watch AppTests/
│   └── MCaddie_Watch_App_Watch_AppTests.swift
└── MCaddieCore/                # 独立 Package
    ├── Package.swift
    ├── Sources/
    └── Tests/
EOF
echo ""

echo "7️⃣ 推荐操作："
echo "-------------"
echo "1. 如果发现多个 Item.swift，只保留 MCaddie/Item.swift"
echo "2. 删除根目录的 Item.swift（如果存在）"
echo "3. 删除 Watch App 中的 Item.swift（如果存在）"
echo "4. 运行: rm -rf ~/Library/Developer/Xcode/DerivedData/MCaddie-*"
echo "5. 在 Xcode 中: ⇧⌘K (Clean) 然后 ⌘B (Build)"
echo ""

echo "✅ 诊断完成！"
