#!/bin/bash

# 环境信息收集脚本
# 帮助诊断 Xcode 和 Swift 版本问题

echo "🔍 M-Caddie 环境诊断"
echo "===================="
echo ""

echo "1️⃣ Xcode 版本："
echo "---------------"
xcodebuild -version
echo ""

echo "2️⃣ Swift 版本："
echo "---------------"
swift --version
echo ""

echo "3️⃣ 可用的 SDK："
echo "---------------"
xcodebuild -showsdks | grep -E "iOS|watchOS"
echo ""

echo "4️⃣ 当前项目信息："
echo "-----------------"
if [ -f "*.xcodeproj/project.pbxproj" ]; then
  echo "✅ 找到 .xcodeproj"
  ls -d *.xcodeproj
else
  echo "❌ 未找到 .xcodeproj"
fi
echo ""

echo "5️⃣ MCaddieCore Package 状态："
echo "----------------------------"
if [ -f "MCaddieCore/Package.swift" ]; then
  echo "✅ MCaddieCore/Package.swift 存在"
  echo ""
  echo "Package.swift 内容："
  cat MCaddieCore/Package.swift | head -20
else
  echo "❌ MCaddieCore/Package.swift 未找到"
fi
echo ""

echo "6️⃣ 项目文件结构："
echo "-----------------"
ls -la | grep -v "^\."
echo ""

echo "7️⃣ Swift 文件位置："
echo "------------------"
find . -name "*.swift" -type f \
  -not -path "*/DerivedData/*" \
  -not -path "*/.git/*" \
  -not -path "*/.*" | head -20
echo ""

echo "✅ 诊断完成！请将上述信息提供给 AI。"
