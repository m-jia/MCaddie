import Foundation

/// 回合记录
/// 根据 ARCHITECTURE.md：Round 包含一次完整打球的所有信息
public struct Round: Codable, Equatable, Identifiable, Sendable, Hashable {
    /// 回合唯一标识符
    public let id: UUID
    
    /// 开始时间
    public let startTime: Date
    
    /// 结束时间（可选，进行中时为 nil）
    public var endTime: Date?
    
    /// 球场信息（洞数和 Tee 台可在回合中修改）
    public var course: CourseInfo
    
    /// 击球记录列表
    public var shots: [Shot]
    
    /// 每洞记分（按洞号，未开始的洞不在列表中）
    public var holeScores: [HoleScore]
    
    /// 回合状态
    public var status: RoundStatus
    
    /// 备注
    public var notes: String?
    
    // MARK: - 嵌套类型
    
    /// 球场信息
    public struct CourseInfo: Codable, Equatable, Sendable, Hashable {
        /// 球场名称
        public let name: String
        
        /// 球场位置（城市/地区）
        public let location: String?
        
        /// 总洞数（通常 9 或 18）
        public let numberOfHoles: Int
        
        /// 球洞详细信息（可选）
        public let holes: [Hole]?
        
        /// 球场在外部球场数据库中的 ID（用于重新加载 Tee 台）
        public let externalCourseID: String?
        
        /// 所选 Tee 台名称
        public let teeName: String?
        
        /// 所选 Tee 台性别（"male" / "female"）
        public let teeGender: String?
        
        /// 球场总标准杆
        public var totalPar: Int {
            holes?.reduce(0) { $0 + $1.par } ?? 72
        }
        
        public init(
            name: String,
            location: String? = nil,
            numberOfHoles: Int = 18,
            holes: [Hole]? = nil,
            externalCourseID: String? = nil,
            teeName: String? = nil,
            teeGender: String? = nil
        ) {
            self.name = name
            self.location = location
            self.numberOfHoles = numberOfHoles
            self.holes = holes
            self.externalCourseID = externalCourseID
            self.teeName = teeName
            self.teeGender = teeGender
        }
    }
    
    /// 回合状态
    public enum RoundStatus: String, Codable, Sendable, Hashable {
        /// 进行中
        case inProgress
        
        /// 已完成
        case completed
        
        /// 已放弃
        case abandoned
        
        /// 暂停
        case paused
    }
    
    // MARK: - 初始化
    
    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        course: CourseInfo,
        shots: [Shot] = [],
        holeScores: [HoleScore] = [],
        status: RoundStatus = .inProgress,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.course = course
        self.shots = shots
        self.holeScores = holeScores
        self.status = status
        self.notes = notes
    }
    
    // MARK: - 便利方法
    
    /// 回合时长（秒）
    public var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 是否进行中
    public var isInProgress: Bool {
        status == .inProgress
    }
    
    /// 是否已完成
    public var isCompleted: Bool {
        status == .completed
    }
    
    /// 总击球数
    public var totalShots: Int {
        shots.count
    }
    
    /// 已确认的击球数
    public var confirmedShots: Int {
        shots.filter { $0.isCompleted }.count
    }
    
    /// 按球洞分组的击球记录（简化版，基于时间排序）
    /// 注意：完整实现需要将 Shot 关联到具体的 Hole
    public var shotsByHole: [[Shot]] {
        // 简化版：每 Shot 数量 / 18 分组
        // 实际实现应该在 Shot 中添加 holeNumber 字段
        let holesCount = course.numberOfHoles
        let shotsPerHole = max(1, shots.count / holesCount)
        return stride(from: 0, to: shots.count, by: shotsPerHole).map {
            Array(shots[$0..<min($0 + shotsPerHole, shots.count)])
        }
    }
    
    /// 添加击球记录
    public mutating func addShot(_ shot: Shot) {
        shots.append(shot)
    }
    
    /// 更新击球记录
    public mutating func updateShot(_ shot: Shot) {
        if let index = shots.firstIndex(where: { $0.id == shot.id }) {
            shots[index] = shot
        }
    }
    
    /// 删除击球记录
    public mutating func removeShot(id: UUID) {
        shots.removeAll { $0.id == id }
    }
    
    /// 指定洞的标准杆（无球洞数据时默认 4）
    public func par(forHole number: Int) -> Int {
        course.holes?.first { $0.number == number }?.par ?? 4
    }
    
    /// 获取指定洞的记分；尚未记录时返回空白记分
    public func holeScore(forHole number: Int) -> HoleScore {
        holeScores.first { $0.holeNumber == number }
            ?? HoleScore(holeNumber: number, par: par(forHole: number))
    }
    
    /// 下一个尚未记分的洞号；全部记完时为 nil
    public var nextHoleToScore: Int? {
        guard course.numberOfHoles > 0 else { return nil }
        return (1...course.numberOfHoles).first { !holeScore(forHole: $0).isScored }
    }
    
    /// 写入或替换某洞记分
    public mutating func setHoleScore(_ score: HoleScore) {
        if let index = holeScores.firstIndex(where: { $0.holeNumber == score.holeNumber }) {
            holeScores[index] = score
        } else {
            holeScores.append(score)
            holeScores.sort { $0.holeNumber < $1.holeNumber }
        }
    }
    
    /// 已记分洞的总杆数
    public var totalStrokes: Int {
        holeScores.compactMap(\.strokes).reduce(0, +)
    }
    
    /// 已记分洞的标准杆合计
    public var scoredPar: Int {
        holeScores.filter(\.isScored).reduce(0) { $0 + $1.par }
    }
    
    /// 修改洞数或 Tee 台
    /// - 超出新洞数的记分会被删除
    /// - 已记分洞的标准杆更新为新球洞数据中的值
    /// - 已完成的回合如果出现未记分的洞，恢复为进行中
    public mutating func reconfigure(
        numberOfHoles: Int,
        holes: [Hole]?,
        teeName: String?,
        teeGender: String?,
        externalCourseID: String?
    ) {
        course = CourseInfo(
            name: course.name,
            location: course.location,
            numberOfHoles: numberOfHoles,
            holes: holes,
            externalCourseID: externalCourseID,
            teeName: teeName,
            teeGender: teeGender
        )
        
        holeScores = holeScores
            .filter { $0.holeNumber <= numberOfHoles }
            .map { score in
                var updated = score
                updated.par = par(forHole: score.holeNumber)
                return updated
            }
        
        if status == .completed && nextHoleToScore != nil {
            status = .inProgress
            endTime = nil
        }
    }
    
    /// 已记分洞相对标准杆的成绩（如 +3）
    public var scoreToPar: Int {
        holeScores.reduce(0) { sum, score in
            guard let strokes = score.strokes else { return sum }
            return sum + strokes - score.par
        }
    }
    
    /// 完成回合
    public mutating func complete() {
        self.endTime = Date()
        self.status = .completed
    }
    
    /// 放弃回合
    public mutating func abandon() {
        self.endTime = Date()
        self.status = .abandoned
    }
    
    /// 计算回合统计信息
    public var statistics: RoundStatistics {
        RoundStatistics(round: self)
    }
}

// MARK: - 回合统计

/// 回合统计信息
public struct RoundStatistics: Codable, Equatable, Sendable {
    /// 总击球数
    public let totalShots: Int
    
    /// 已确认击球数
    public let confirmedShots: Int
    
    /// 平均击球距离
    public let averageDistance: Distance
    
    /// 最长击球
    public let longestShot: Distance?
    
    /// 最短击球
    public let shortestShot: Distance?
    
    /// 各球杆使用次数
    public let clubUsage: [ClubType: Int]
    
    /// 不同球位的击球分布
    public let lieDistribution: [Lie: Int]
    
    public init(round: Round) {
        self.totalShots = round.totalShots
        self.confirmedShots = round.confirmedShots
        
        let completedShots = round.shots.filter { $0.isCompleted }
        let distances = completedShots.map { $0.finalTotalDistance.yards }
        
        if !distances.isEmpty {
            self.averageDistance = Distance(yards: distances.reduce(0, +) / Double(distances.count))
            self.longestShot = Distance(yards: distances.max() ?? 0)
            self.shortestShot = Distance(yards: distances.min() ?? 0)
        } else {
            self.averageDistance = Distance(yards: 0)
            self.longestShot = nil
            self.shortestShot = nil
        }
        
        // 统计球杆使用
        var clubCount: [ClubType: Int] = [:]
        for shot in round.shots {
            clubCount[shot.club, default: 0] += 1
        }
        self.clubUsage = clubCount
        
        // 统计球位分布
        var lieCount: [Lie: Int] = [:]
        for shot in round.shots {
            lieCount[shot.startLie, default: 0] += 1
        }
        self.lieDistribution = lieCount
    }
}
