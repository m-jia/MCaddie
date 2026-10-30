# 修复 Testing 框架错误

## 问题

编译时出现错误：
```
error: Unable to resolve module dependency: 'Testing'
error: No such module 'Testing'
```

## 原因

项目使用了 Swift Testing 框架（`import Testing`），这是 Xcode 16+ 和 Swift 6.0+ 才支持的新特性。如果您的 Xcode 版本较低，会出现这个错误。

## 解决方案

### 方案 1：使用 XCTest（推荐，已实施）

我已经创建了使用传统 XCTest 框架的测试文件：

**`PersistenceTests_XCTest.swift`** - 兼容所有 Xcode 版本

#### 操作步骤：

1. **删除旧的测试文件**
   - 在 Xcode Project Navigator 中找到 `PersistenceTests.swift`
   - 右键点击 → Move to Trash

2. **添加新的测试文件**
   - 将 `PersistenceTests_XCTest.swift` 添加到项目
   - 重命名为 `PersistenceTests.swift`
   - 确保勾选 **MCaddieTests** target

3. **验证**
   ```
   ⌘ + B  # 构建项目（应该成功）
   ⌘ + U  # 运行测试（应该通过）
   ```

### 方案 2：升级 Xcode（如果需要使用 Swift Testing）

如果您想使用新的 Swift Testing 框架：

1. 升级到 Xcode 16 或更高版本
2. 保留原始的 `PersistenceTests.swift`
3. 确保项目的 Swift Language Version 设置为 6.0+

## 主要区别

### Swift Testing (新框架)
```swift
import Testing

@Suite("测试套件")
struct MyTests {
    @Test("测试名称")
    func testSomething() {
        #expect(value == expected)
    }
}
```

### XCTest (传统框架)
```swift
import XCTest

class MyTests: XCTestCase {
    func testSomething() {
        XCTAssertEqual(value, expected)
    }
}
```

## 测试对照表

| Swift Testing | XCTest |
|--------------|---------|
| `#expect(a == b)` | `XCTAssertEqual(a, b)` |
| `#expect(value != nil)` | `XCTAssertNotNil(value)` |
| `#expect(value == nil)` | `XCTAssertNil(value)` |
| `#expect(condition)` | `XCTAssertTrue(condition)` |
| `try #require(optional)` | `try XCTUnwrap(optional)` |
| `@Test("name")` | `func testName()` |
| `@Suite("name")` | `class NameTests: XCTestCase` |

## 当前状态

✅ **已创建 XCTest 版本的测试文件**
- 文件名: `PersistenceTests_XCTest.swift`
- 包含 17 个测试用例
- 完全兼容 Xcode 13+

✅ **测试覆盖**
- DataManager 基础测试 (2)
- Round 持久化测试 (6)
- Shot 持久化测试 (5)
- 统计和查询测试 (2)
- 数据完整性测试 (2)

## 其他可能需要检查的文件

如果项目中还有其他文件使用了 `import Testing`，也需要进行类似的转换：

```bash
# 在项目目录中搜索
grep -r "import Testing" .
```

常见的文件：
- `MCaddieTests.swift`
- `MCaddie_Watch_App_Watch_AppTests.swift`
- `DistanceTests.swift`（在 MCaddieCore package 中）

如果发现这些文件也有问题，请告诉我，我会帮您一起转换。

## 验证清单

- [ ] 删除旧的 `PersistenceTests.swift`
- [ ] 添加 `PersistenceTests_XCTest.swift` 到项目
- [ ] 重命名为 `PersistenceTests.swift`
- [ ] 确保在 **MCaddieTests** target 中
- [ ] 构建成功（⌘ + B）
- [ ] 测试通过（⌘ + U）

---

**需要帮助吗？**

如果还有其他编译错误，请告诉我具体的错误信息！
