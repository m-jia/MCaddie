# M-Caddie — 项目入口

## 项目定位
M-Caddie 是一个以 Apple Watch 为球场使用主界面的个人 AI 高尔夫球童应用。第一阶段优先完成可在真实球场使用的本地优先 MVP；未来再评估是否扩展为商业产品。

## 目标设备与技术路线
- iPhone：iPhone 14 Pro Max
- Apple Watch：Apple Watch SE 3（通过 iPhone 配对）
- 主要语言：Swift
- UI：SwiftUI
- Apple 平台原生开发：Xcode
- 核心决策模块：独立、纯 Swift 的 `MCaddieCore` Swift Package
- 本地持久化：初步倾向 SwiftData；实施前须核实 watchOS 支持、数据迁移和离线可靠性。若跨平台/迁移需求使其不合适，应先提出理由再改选 SQLite 等方案。
- 初期不依赖后端，也不要求 iPhone 在球场期间持续连接。

## 核心原则
1. **Watch-first、local-first**：击球记录和下一杆流程不能依赖 iPhone、网络或云端可用。
2. **同一杆持续更新**：击球后的初始口述记录与走到球位后的实际位置/球位信息属于同一条 Shot，不得误建第二条 Shot。
3. **记录估计与事实**：初始落点/方向是用户估计；后续 GPS 位置和球位描述是后续观测。保留时间戳、来源和 GPS 精度。
4. **核心逻辑独立**：`MCaddieCore` 不依赖 SwiftUI、Core Location、Speech、WatchConnectivity 或任何 UI 框架。
5. **数值决策可解释、可测试**：球杆/目标建议的核心数值逻辑不能只交给 LLM。未来可以让 LLM 解释建议，但不能作为唯一的数值决策器。
6. **渐进式交付**：先创建最小 iPhone 与 Watch 目标并通过构建，再增加 GPS、语音、持久化和决策逻辑。
7. **不臆造外部 API**：不得假设 18Birdies 等第三方有可用 API；未来以独立导入适配器处理 CSV/手动导入等来源。

## 建议阅读顺序
1. `AGENTS.md` — AI 编程工作规则
2. `PRODUCT_SPEC.md` — 产品范围与用户流程
3. `ARCHITECTURE.md` — 模块边界和数据流
4. `DATA_MODEL.md` — 初始领域模型
5. `ROADMAP.md` — 交付阶段
6. `TEST_PLAN.md` — 验收与测试
7. `DECISIONS_OPEN_QUESTIONS.md` — 已定决策与待确认事项
8. `QUICK_START_PROMPT.md` — 可复制给 Xcode AI Agent 的启动提示词

## 目前的边界
这些文件是开发交接材料，不代表应用代码已经实现。对尚未决定的技术细节，AI 必须标记为待确认或提出方案，不得悄悄当作既定要求。
