# 🔧 快速修复：ShotTests.swift 缺少 import Foundation

## 问题
```
error: cannot find 'Date' in scope
/Users/mjia/WorkSpace/MCaddie/MCaddie/MCaddieCore/Tests/MCaddieCoreTests/ShotTests.swift:269:24
```

## ✅ 已修复

我已经在项目根目录的 `ShotTests.swift` 中添加了 `import Foundation`。

---

## 🚀 立即解决

### 方案 1: 重新运行脚本（推荐）⚡

脚本已更新，会自动修复 import 问题：

```bash
cd /Users/mjia/WorkSpace/MCaddie/MCaddie
chmod +x add_shot_models.sh
./add_shot_models.sh
```

---

### 方案 2: 手动修复（最快）🔥

#### 在终端运行：

```bash
cd /Users/mjia/WorkSpace/MCaddie/MCaddie

# 如果 ShotTests.swift 已经在正确位置
cd MCaddieCore/Tests/MCaddieCoreTests

# 编辑文件，在第一行添加 import Foundation
# 使用 sed 命令：
sed -i.bak '1s/^/import Foundation\n/' ShotTests.swift

# 或者手动编辑：
# vim ShotTests.swift
# 或
# nano ShotTests.swift
# 在第一行添加: import Foundation
```

#### 正确的文件开头应该是：

```swift
import Foundation
import Testing
@testable import MCaddieCore

@Suite("Shot Tests")
struct ShotTests {
    // ...
}
```

---

### 方案 3: 完整的手动复制（如果脚本不工作）

```bash
cd /Users/mjia/WorkSpace/MCaddie/MCaddie

# 1. 确保目录存在
mkdir -p MCaddieCore/Sources/MCaddieCore
mkdir -p MCaddieCore/Tests/MCaddieCoreTests

# 2. 复制源文件（如果还没有）
cp "MCaddieCoreSourcesMCaddieCoreL ie.swift" "MCaddieCore/Sources/MCaddieCore/Lie.swift" 2>/dev/null
cp "MCaddieCoreSourcesMCaddieCorePositionObservation.swift" "MCaddieCore/Sources/MCaddieCore/PositionObservation.swift" 2>/dev/null
cp "MCaddieCoreSourcesMCaddieCoreShot.swift" "MCaddieCore/Sources/MCaddieCore/Shot.swift" 2>/dev/null
cp "MCaddieCoreSourcesMCaddieCoreHole.swift" "MCaddieCore/Sources/MCaddieCore/Hole.swift" 2>/dev/null
cp "MCaddieCoreSourcesMCaddieCoreRound.swift" "MCaddieCore/Sources/MCaddieCore/Round.swift" 2>/dev/null

# 3. 复制测试文件（使用已修复的版本）
cp "ShotTests.swift" "MCaddieCore/Tests/MCaddieCoreTests/ShotTests.swift"

# 4. 如果 ShotTests.swift 已经在 MCaddieCore 中但缺少 import
# 手动编辑它
code MCaddieCore/Tests/MCaddieCoreTests/ShotTests.swift
# 或
nano MCaddieCore/Tests/MCaddieCoreTests/ShotTests.swift

# 在文件开头添加:
# import Foundation
```

---

## ✅ 验证修复

```bash
cd /Users/mjia/WorkSpace/MCaddie/MCaddie/MCaddieCore

# 查看文件开头
head -5 Tests/MCaddieCoreTests/ShotTests.swift
```

**应该看到：**
```swift
import Foundation
import Testing
@testable import MCaddieCore
```

**然后运行测试：**
```bash
swift test
```

**预期结果：**
```
Test Suite 'All tests' passed
Executed 21 tests, with 0 failures
```

---

## 🎯 推荐操作顺序

```bash
# 1. 进入项目目录
cd /Users/mjia/WorkSpace/MCaddie/MCaddie

# 2. 运行更新后的脚本
chmod +x add_shot_models.sh
./add_shot_models.sh

# 3. 如果测试通过，在 Xcode 中
# ⇧⌘K (Clean Build Folder)
# ⌘B (Build)
```

---

## 📞 如果仍有问题

请提供：

1. **当前的 ShotTests.swift 内容（前 10 行）：**
   ```bash
   head -10 MCaddieCore/Tests/MCaddieCoreTests/ShotTests.swift
   ```

2. **完整的测试输出：**
   ```bash
   cd MCaddieCore
   swift test 2>&1 | tee test_output.txt
   ```

3. **文件位置确认：**
   ```bash
   find . -name "ShotTests.swift" -not -path "*/DerivedData/*"
   ```

---

## 💡 根本原因

Swift Testing 框架需要 `Date` 类型，它来自 `Foundation` 框架。

**必须在测试文件开头添加：**
```swift
import Foundation  // ← 必须有这行！
import Testing
@testable import MCaddieCore
```

所有测试文件都需要这三个 import。

---

**现在请重新运行脚本或手动添加 import，然后告诉我结果！** 🚀
