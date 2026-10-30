# Hashable 协议修复

## 问题

编译错误：`Type 'Round' does not conform to protocol 'Hashable'`

## 原因

虽然在 `Round` 上添加了 `Hashable` 协议，但 `Round` 包含的所有类型也必须遵循 `Hashable`：
- `Round` 包含 `CourseInfo`
- `CourseInfo` 包含 `[Hole]?`
- `Round` 包含 `[Shot]`
- `Shot` 包含嵌套类型（`InitialEstimate`, `ActualResult` 等）

## 修复的文件

### 1. Round.swift
```swift
public struct Round: Codable, Equatable, Identifiable, Sendable, Hashable {
    // ...
    
    public struct CourseInfo: Codable, Equatable, Sendable, Hashable {
        // ✅ 添加 Hashable
    
    public enum RoundStatus: String, Codable, Sendable, Hashable {
        // ✅ 添加 Hashable
}
```

### 2. Hole.swift
```swift
public struct Hole: Codable, Equatable, Identifiable, Sendable, Hashable {
    // ✅ 添加 Hashable
}
```

### 3. Shot.swift
```swift
public struct Shot: Codable, Equatable, Identifiable, Sendable, Hashable {
    // ✅ 添加 Hashable
    
    public struct InitialEstimate: Codable, Equatable, Sendable, Hashable {
        // ✅ 添加 Hashable
    
    public struct ActualResult: Codable, Equatable, Sendable, Hashable {
        // ✅ 添加 Hashable
    
    public enum PerformanceRating: String, Codable, Sendable, Hashable {
        // ✅ 添加 Hashable
    
    public enum ConfirmationState: String, Codable, Sendable, Hashable {
        // ✅ 添加 Hashable
}
```

## 已修复的类型

✅ Round
✅ Round.CourseInfo
✅ Round.RoundStatus
✅ Hole
✅ Shot
✅ Shot.InitialEstimate
✅ Shot.ActualResult
✅ Shot.PerformanceRating
✅ Shot.ConfirmationState

## 为什么需要 Hashable？

在 `NewRoundView.swift` 中使用了 `NavigationPath`：

```swift
@State private var navigationPath = NavigationPath()

// 需要将 Round 添加到路径中
navigationPath.append(round)  // ← 这里需要 Round 是 Hashable

// 配置导航目标
.navigationDestination(for: Round.self) { round in
    RoundDetailView(round: round)
}
```

`NavigationPath` 要求所有添加的类型都必须遵循 `Hashable` 协议。

## 验证

现在编译应该成功：

```
⌘ + B
```

所有类型都已正确遵循 `Hashable` 协议。

## 说明

这些修改不会影响现有功能，因为：
- `Hashable` 是 `Equatable` 的子协议
- 所有这些类型已经是 `Equatable`
- Swift 会自动合成 `Hashable` 的实现（因为所有属性都是 `Hashable` 的）

---

**修复完成！** 现在应该可以正常编译了。
