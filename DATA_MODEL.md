# M-Caddie — 初始领域数据模型

这是一个用于启动实现的领域模型草案，不是最终数据库 schema。先以纯 Swift 类型表达领域含义，再由平台层映射到所选持久化方案。若要改动核心字段，应说明原因并更新测试。

## 1. 核心实体

### Round
建议字段：
- `id: UUID`
- `startedAt: Date`
- `endedAt: Date?`
- `courseID: CourseID?`
- `currentHoleNumber: Int?`
- `status: RoundStatus`
- `createdOnDevice` / 同步元数据（若实际需要）

### Course / Hole（分阶段）
Course：
- `id`
- `name`
- `location` 或可选坐标
- `dataSource` / `licenseNotes`（如果使用外部球场数据）
- `holes`
Hole：
- `number`
- `par: Int?`
- `tee/green` 相关几何数据（只有可信数据源可用时）
- `greenFront/Center/Back` 等距离应按实时位置计算或记录数据来源，不要凭空预设。

球场数据提供方、许可和缓存格式尚未决定。

### ClubProfile
- `id`
- `name`（例如 Driver、3-wood、7-iron）
- `carryYards: DistanceEstimate?`
- `totalYards: DistanceEstimate?`
- `leftRightBias` 或表现统计（可后续添加）
- `notes`
- `updatedAt`

`DistanceEstimate` 可包含：
- `value`
- `unit`（内部建议统一规范单位；界面显示可换算）
- `confidence` / `sampleCount`（后续有数据时）
- `source`（用户输入、测量、历史估计等）

不要把用户提供的 Driver/3-wood total 距离当成 carry。

### Shot
- `id: UUID`（创建后稳定不变）
- `roundID: UUID`
- `holeNumber: Int?`
- `shotNumberOnHole: Int?`
- `clubID: UUID?`
- `reportedText: String?`（原始口述转写）
- `estimatedDirection: ShotDirection?`
- `estimatedLanding: EstimatedLanding?`
- `estimatedDistance: DistanceEstimate?`
- `confirmedAt: Date?`
- `createdAt: Date`
- `updatedAt: Date`
- `observations: [ShotObservation]` 或以独立事件实体存储
- `status: ShotStatus`

不要将所有字段都假设为用户一次说完整。允许部分字段为空。

### ShotObservation（追加式观察/事件）
可用 enum 或独立实体实现：
- `estimatedLandingReported`
- `positionObserved`
- `lieReported`
- `fieldCorrected`
- `shotEdited`
- `syncStateChanged`（是否作为领域事件存储待决定）

每个 observation 至少要能表示：
- 稳定 ID
- 关联的 `shotID`
- 时间戳
- 来源（语音、GPS、用户手动修改、导入等）
- 对应的结构化内容

如果直接使用关联模型不方便，可使用独立表/记录，但必须保留估计与后续观测的区别。

### PositionObservation
纯 Swift 值类型，不依赖 CoreLocation：
- `latitude: Double`
- `longitude: Double`
- `horizontalAccuracyMeters: Double?`
- `capturedAt: Date`
- `source: PositionSource`（如 watchGPS、phoneGPS、manualCorrection、imported）
- `isUserCorrected: Bool`
- 可选备注

需校验经纬度范围及无效/负精度值。

### LieObservation
- `lie: LieType?`（fairway、rough、deepRough、bunker、penaltyArea、trees、green、tee、unknown 等，分类可调整）
- `description: String?`（如“右侧长草，球陷得比较深”）
- `capturedAt`
- `source`
- `confidence`（仅当解析器能给出有意义的置信度时）
- 可选用户确认/修正标记

### Recommendation
- `id`
- `createdAt`
- `roundID` / `shotID` 或当前球位引用
- `candidateClubIDs`
- `targetDescription`
- `rationale`
- `riskLevel`
- `confidence` 或 `dataQuality`
- `inputSnapshot` / 数据版本（若为复现建议所必需）

建议应能说明基于哪些输入生成；避免保存无法追溯的黑盒文本。

## 2. 枚举草案
- `RoundStatus`: `inProgress`, `completed`, `abandoned`
- `ShotStatus`: `draft`, `confirmed`, `awaitingBallPosition`, `positionUpdated`, `completed`, `needsCorrection`
- `ShotDirection`: `left`, `slightLeft`, `straight`, `slightRight`, `right`, `unknown`
- `LieType`: `tee`, `fairway`, `firstCut`, `rough`, `deepRough`, `bunker`, `penaltyArea`, `trees`, `green`, `unknown`
- `PositionSource`: `watchGPS`, `phoneGPS`, `manualCorrection`, `imported`
- `ObservationSource`: `voice`, `manual`, `gps`, `imported`, `system`

这些枚举是初始建议，可在实现时按实际使用场景调整并加测试。

## 3. 同一杆更新规则
- 创建并确认一杆时生成唯一 `Shot.id`。
- 后续球位更新必须引用该 ID。
- 若用户取消或重新录入，不要自动生成重复的已确认 Shot。
- 估计落点和 GPS 观测并存；不要用 GPS 直接覆盖估计落点。
- 后续修正追加新观察或有明确历史的更正，不抹去原始用户报告。
- 重复同步同一实体必须幂等，不能插入重复 Shot。

## 4. 单位和距离
- 所有内部距离都必须有明确单位或使用命名明确的类型。
- UI 默认可以展示码（yards），但内部单位策略需要在实现前统一，并写测试覆盖换算。
- `carry` 与 `total` 是不同指标；绝不可只使用一个 `distance` 字段混淆两者。
- 位置间直线距离不能未经说明就当成沿球道的策略距离。

## 5. 示例流程（概念性）
1. 口述：“7 号铁，向右偏，大约 130 码。”
2. 解析后用户确认，保存 `Shot(id: A)`，记录原始文本、方向和估计距离。
3. 到球位口述：“右侧长草，球陷得比较深。”
4. 新建位置观察与球位观察，二者关联 `shotID: A`。
5. 下一杆建议关联当前球位/观察数据。整个过程只存在一条对应本杆的 Shot。
