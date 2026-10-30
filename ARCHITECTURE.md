# M-Caddie — 技术架构

## 1. 总体结构

```text
MCaddie iOS App (SwiftUI)                 MCaddie Watch App (SwiftUI)
  - 设置/球杆资料                          - 回合内主界面
  - 球场/球洞管理                          - 语音与确认流程
  - 地图/回合历史                          - 当前球位与下一杆建议
  - 导入/导出                              - 本地优先保存
             |                                      |
             +------------ MCaddieCore ------------+
                       纯 Swift 领域模块
       Models / Rules / Candidate Selection / Risk / Tests

iOS/watchOS platform adapters:
- Location provider (Core Location)
- Speech capture / speech recognition / speech output
- Persistence adapter
- WatchConnectivity sync adapter
```

上图是逻辑边界，不是要求把所有模块都放在一个 Xcode Target 中。具体 target/package 配置应以当前 Xcode 和 deployment target 支持为准。

## 2. 模块责任
### `MCaddieCore`（独立纯 Swift Package）
包含：
- 领域模型：Round、Hole、Shot、ClubProfile、Lie、PositionObservation、Recommendation。
- 工作流相关的领域状态/事件类型（不调用设备 API）。
- 距离计算、球杆候选筛选、风险评分、建议生成的纯函数。
- 解析结果的规范化值类型（语音转写本身可在平台层完成）。
- 领域错误与测试。
不得导入 SwiftUI、UIKit、WatchKit、CoreLocation、Speech、WatchConnectivity、SwiftData。

### Watch 应用层
负责：
- SwiftUI 回合内界面；
- 位置服务适配；
- 语音捕获、系统语音识别/合成能力适配；
- 本地持久化；
- `ShotWorkflowController` 状态协调；
- 调用 `MCaddieCore`；
- 将本地变更排入待同步队列。

### iPhone 应用层
负责：
- 设置、球杆档案、球场/球洞数据管理；
- 回合历史和回顾；
- 地图/球场可视化（后续）；
- 本地数据浏览与导出；
- 作为同步对端，但不是 Watch 记录的必需依赖。

### 同步层
使用 WatchConnectivity 或经验证的 Apple 平台方案。同步要支持延迟、重复投递、重试、冲突处理和离线排队。不得把“iPhone 已收到”作为 Watch 本地保存成功的条件。

## 3. `ShotWorkflowController`
这是应用层协调器，不属于纯决策引擎。可采用显式状态机，例如：

- `awaitingShotReport`
- `capturingReport`
- `parsingReport`
- `awaitingConfirmation`
- `needsClarification`
- `savingShot`
- `shotSaved`
- `awaitingBallPosition`
- `updatingBallPosition`
- `readyForNextShot`
- `failedRecoverably`

实现时可以调整名称，但要保留清晰、可测试的状态转移和错误恢复。不要用大量独立 Bool 让状态互相冲突。

### 建议流程
1. 用户报告刚打出的球；
2. 平台层捕获语音并返回转写文本；
3. 解析器生成候选字段及置信度；
4. 如果关键字段不确定，要求澄清；否则播报简短摘要；
5. 用户口头确认或点按；
6. 创建 Shot ID 并在 Watch 本地持久化；
7. 等用户走到球位；
8. 获取当前位置与精度，解析球位描述；
9. 将新的 PositionObservation / LieObservation 追加到同一 Shot；
10. 调用 `MCaddieCore` 生成下一杆建议；
11. 有机会时异步同步到 iPhone。

如果第一版的自然语言解析还未实现，允许用结构化表单/按钮先完成端到端数据流程，不能因此把数据模型和工作流写死在某个语音服务里。

## 4. 数据模型原则
- 每个已确认击球都有稳定、唯一的 `ShotID`。
- Shot 记录原始转写、解析字段、用户确认时间、创建时间等信息。
- 估计落点和后续 GPS 观测是不同概念。
- 位置观测记录经纬度、水平精度、采集时间、来源（如 watch GPS）和可选的用户修正。
- 球位分类和球位描述也保留来源/时间；用户后续修正不应抹去事件历史。
- `carryYards` 和 `totalYards` 分开存储，单位转换集中处理。
- 避免在领域模型中依赖 CLLocation 等平台类型；使用纯 Swift 的经纬度/精度值类型。
- 对持久化模型的变更考虑 schema migration；初期也应避免把临时 UI 状态持久化成领域事实。

详细建议见 `DATA_MODEL.md`。

## 5. 本地存储与同步
- 目前初步倾向 SwiftData，但必须先确认所选 iOS/watchOS deployment target 的可用性与限制。Watch 本地持久化可靠性是关键验证项。
- 若 SwiftData 不适合 watchOS 目标或迁移/同步需求，先比较 SQLite/Core Data 等方案并给出明确取舍，不要默默切换。
- Watch 本地保存成功后，即使同步失败，也要显示“已保存在手表”而不是“记录失败”。
- 每个可同步实体有稳定 ID、更新时间或版本信息；采用幂等 upsert，避免重复插入。
- 同步冲突规则应显式化。初期可采用事件追加 + 明确的字段修正策略，不要简单以最后写入覆盖所有历史。
- 不能假定 WatchConnectivity 每次立即发送、设备始终连接或后台任务无限运行。

## 6. 定位与后台限制
- Watch GPS 获取的是设备位置，不是球本身的位置。球可能在手表用户数米之外；UI 应显示精度/定位质量，并允许修正。
- 保存位置观测时记录水平精度与时间戳；对低精度/陈旧位置给出提示。
- 不要承诺持续后台定位。按当前 watchOS 能力验证前台、屏幕关闭、应用切换和回合期间的实际行为。
- 可以研究 workout session 等维持回合活动的方案，但不能把它视为不受限制的后台执行许可。
- 需要评估耗电、权限说明、GPS 失效和用户取消路径。

## 7. 语音能力
- 使用 Apple 原生能力作为第一候选，但必须针对当前 watchOS / iOS SDK 验证语音识别、语音合成、语言支持、网络/离线行为和权限。
- 户外风噪和短句误识别必须纳入实测。
- 将“语音捕获/识别”与“字段解析/领域逻辑”分离，方便以后替换实现。
- 对低置信度字段进行澄清；确认流程必须可手动完成。
- 如果系统语音识别依赖网络或在 Watch 上受限，先做一个可用的降级方案，不要让整个击球记录流程阻塞。

## 8. 决策引擎设计
输入可能包括：
- 当前球位和位置观测；
- 到目标/果岭的距离（可信数据存在时）；
- 球杆距离分布（carry/total 分开）；
- 球杆使用限制、方向偏差等个人表现数据；
- 球场几何与障碍（若有可信数据）；
- 用户风险偏好（尚待确定）。

输出建议至少包含：
- 候选球杆；
- 目标区域/目标策略；
- 预计距离或距离范围（数据足够时）；
- 风险与不确定性；
- 简短的理由；
- 输入数据缺失时的警告。

第一版可以从透明的规则引擎开始。不要在缺少球场几何/球杆数据时编造数值。LLM 若未来参与，只用于语言解释、解析辅助或用户明确同意的功能，数值建议必须保留可测试的核心规则和来源依据。

## 9. 工程与测试
- 将 `MCaddieCore` 的单元测试与 iOS/Watch UI 分开。
- 在真实 Watch 上验证定位、语音、屏幕交互、耗电和无手机连接场景。
- 设备测试前确认 Apple 开发者签名/Personal Team 状态；不要把签名配置写入共享文档。
- 第一个可交付物必须是能构建的最小骨架，而不是尚无法运行的大量代码。
