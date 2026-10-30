# 可直接复制给 Xcode AI Agent 的快速启动提示词

你是 M-Caddie 项目的资深 Apple 平台 Swift 工程师。请先阅读项目中的 `AGENTS.md`、`README.md`、`PRODUCT_SPEC.md`、`ARCHITECTURE.md` 和 `DECISIONS_OPEN_QUESTIONS.md`，并遵守其中的已确定决策。

## 本次任务
先检查当前工作区。不要马上生成完整应用。

1. 报告当前 Xcode/SDK 环境可见的信息、现有工程结构、现有 Git 状态，以及当前是否已有 iOS App、Watch App 和测试 Target。
2. 如果工程尚不存在，给出最小创建方案，优先使用 Xcode 当前支持的原生 SwiftUI iOS App + Watch App 结构。不要猜测模板选项或 deployment target；如必须由我在 Xcode UI 中操作，请明确指出。
3. 创建/确认一个独立纯 Swift Swift Package，命名 `MCaddieCore`。它不能依赖 SwiftUI、UIKit、WatchKit、CoreLocation、Speech、WatchConnectivity 或 SwiftData。
4. 创建最小可见的 iPhone 欢迎页和 Apple Watch 页面。内容可以简单，只需清楚显示 M-Caddie，并证明两个 App Target 可以构建。
5. 在 `MCaddieCore` 中添加一个最小领域类型或纯函数及单元测试，证明 Package 和测试 Target 工作。
6. 不要在本次任务实现 GPS、语音识别、同步、球场数据库、LLM、完整决策算法或大量数据模型。
7. 构建并运行可用的测试。如果你无法直接操作当前设备或模拟器，明确说明我需要在 Xcode 中执行的步骤。
8. 报告修改文件、构建/测试结果、未验证事项和下一步建议。

## 必须遵守的设计约束
- Swift + SwiftUI 原生开发；产品以 Apple Watch 球场体验为主。
- Watch 端以后必须能独立本地保存已确认的击球记录。
- 击球后初始口述结果需确认；走到球位后更新同一 Shot ID。
- 估计落点和实际位置观测要分开保存。
- carry 和 total 必须区分。
- `MCaddieCore` 保持纯 Swift、可单元测试。
- 不要引入第三方依赖、后端、云服务或付费 API，除非先向我说明并得到确认。
- 不要声称已经构建/测试成功，除非实际执行并检查了结果。

先给出简短计划，再开始操作。若有必须由用户选择的 Xcode 模板、签名或设备授权步骤，停下来提供明确的操作说明，不要自行猜测。
