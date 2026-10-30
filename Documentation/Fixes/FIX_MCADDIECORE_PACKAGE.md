# MCaddieCore Package 配置检查和修复指南

## 🔍 问题诊断

您遇到的所有 "Cannot find 'Distance'" 错误表明：
**MCaddieCore package 没有正确添加到 Xcode 项目中**

## 📁 正确的文件结构

MCaddieCore package 需要这样的结构：

```
MCaddieCore/
├── Package.swift                    # ✅ 存在
├── README.md
├── Sources/
│   └── MCaddieCore/
│       ├── Distance.swift          # 需要在这里
│       ├── Shot.swift              # 需要在这里
│       ├── Round.swift             # 需要在这里
│       ├── Hole.swift              # 需要在这里
│       ├── Lie.swift               # 需要在这里
│       └── PositionObservation.swift  # 需要在这里
└── Tests/
    └── MCaddieCoreTests/
        └── DistanceTests.swift
```

## ⚠️ 当前问题

根据项目状态，这些文件可能在 `/repo/` 根目录，而不是在正确的 `MCaddieCore/Sources/MCaddieCore/` 路径下。

## ✅ 解决方案

### 方法 1：在 Finder 中手动组织文件

1. **打开 Finder**，找到项目文件夹

2. **检查是否有 MCaddieCore 文件夹**
   - 如果没有，创建这个结构：
   ```
   mkdir -p MCaddieCore/Sources/MCaddieCore
   mkdir -p MCaddieCore/Tests/MCaddieCoreTests
   ```

3. **移动文件到正确位置**：
   ```bash
   # 移动核心模型文件
   mv Distance.swift MCaddieCore/Sources/MCaddieCore/
   mv Shot.swift MCaddieCore/Sources/MCaddieCore/
   mv Round.swift MCaddieCore/Sources/MCaddieCore/
   mv Hole.swift MCaddieCore/Sources/MCaddieCore/
   mv Lie.swift MCaddieCore/Sources/MCaddieCore/
   mv PositionObservation.swift MCaddieCore/Sources/MCaddieCore/
   
   # 移动 Package.swift（如果不在 MCaddieCore/ 中）
   mv Package.swift MCaddieCore/
   ```

4. **在 Xcode 中添加 package**：
   - File → Add Package Dependencies...
   - Add Local...
   - 选择 `MCaddieCore` 文件夹
   - 选择 targets: MCaddie, MCaddie Watch App, MCaddieTests

### 方法 2：使用脚本自动修复

创建一个脚本文件 `fix_mcaddiecore_structure.sh`：

```bash
#!/bin/bash

# 创建正确的目录结构
mkdir -p MCaddieCore/Sources/MCaddieCore
mkdir -p MCaddieCore/Tests/MCaddieCoreTests

# 移动核心模型文件
for file in Distance.swift Shot.swift Round.swift Hole.swift Lie.swift PositionObservation.swift; do
    if [ -f "$file" ]; then
        mv "$file" MCaddieCore/Sources/MCaddieCore/
        echo "✅ 移动 $file"
    fi
done

# 移动 Package.swift
if [ -f "Package.swift" ] && [ ! -f "MCaddieCore/Package.swift" ]; then
    mv Package.swift MCaddieCore/
    echo "✅ 移动 Package.swift"
fi

# 创建 README
if [ ! -f "MCaddieCore/README.md" ]; then
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

## 使用

```swift
import MCaddieCore

let distance = Distance(yards: 150)
```
EOF
    echo "✅ 创建 README.md"
fi

echo ""
echo "🎉 MCaddieCore 结构修复完成！"
echo ""
echo "下一步：在 Xcode 中添加 package"
echo "1. 打开 Xcode"
echo "2. File → Add Package Dependencies..."
echo "3. Add Local... → 选择 MCaddieCore 文件夹"
echo "4. 选择 targets: MCaddie, MCaddie Watch App, MCaddieTests"
```

运行脚本：
```bash
chmod +x fix_mcaddiecore_structure.sh
./fix_mcaddiecore_structure.sh
```

### 方法 3：在 Xcode 中检查现有 Package

如果 MCaddieCore 文件夹已经存在：

1. **在 Xcode Project Navigator 中**：
   - 查找 📦 **MCaddieCore**
   - 如果看不到，可能需要重新添加

2. **验证 package 产品**：
   - 点击项目根节点
   - 选择 **MCaddie** target
   - 进入 **Build Phases** 标签页
   - 展开 **Link Binary With Libraries**
   - 应该看到 **MCaddieCore**

3. **如果没有**：
   - 点击 **+** 按钮
   - 在列表中找到并添加 **MCaddieCore**

## 🧪 验证修复

修复后，测试是否工作：

1. **在任何 Swift 文件中导入**：
   ```swift
   import MCaddieCore
   
   let distance = Distance(yards: 150)
   ```

2. **编译项目**：
   ```
   ⌘ + B
   ```

3. **应该没有 "Cannot find 'Distance'" 错误**

## 📝 快速检查清单

- [ ] MCaddieCore 文件夹存在
- [ ] MCaddieCore/Package.swift 存在
- [ ] MCaddieCore/Sources/MCaddieCore/ 包含所有 .swift 文件
- [ ] 在 Xcode 中看到 📦 MCaddieCore
- [ ] MCaddie target 链接了 MCaddieCore
- [ ] MCaddie Watch App target 链接了 MCaddieCore
- [ ] MCaddieTests target 链接了 MCaddieCore
- [ ] 编译成功

## ❓ 还是不工作？

如果仍然有问题，请提供：

1. 运行这个命令的输出：
   ```bash
   ls -la MCaddieCore/Sources/MCaddieCore/
   ```

2. Xcode 中是否能看到 📦 MCaddieCore？

3. 具体的错误信息（截图更好）

---

**下一步**：请告诉我当前的文件结构，我可以帮您确定正确的修复方法。
