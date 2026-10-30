import Foundation

/// 击球记录
/// 根据 ARCHITECTURE.md 的核心设计：
/// - Shot 有稳定的 ID
/// - 初始记录来自口述（估计的方向和距离）
/// - 走到球位后更新实际位置观测
/// - 必须区分 carry 和 total
/// - 估计落点和实际位置观测分开保存
public struct Shot: Codable, Equatable, Identifiable, Sendable, Hashable {
    /// 击球唯一标识符（稳定，不可变）
    public let id: UUID
    
    /// 击球时间戳
    public let timestamp: Date
    
    /// 使用的球杆
    public let club: ClubType
    
    /// 起始位置观测
    public let startPosition: PositionObservation
    
    /// 起始球位分类
    public let startLie: Lie
    
    /// 初始估计信息（来自口述）
    public let initialEstimate: InitialEstimate
    
    /// 实际结果（走到球位后更新）
    public var actualResult: ActualResult?
    
    /// 确认状态
    public var confirmationState: ConfirmationState
    
    /// 备注
    public var notes: String?
    
    // MARK: - 嵌套类型
    
    /// 初始估计（口述记录）
    public struct InitialEstimate: Codable, Equatable, Sendable, Hashable {
        /// 估计的 carry 距离
        public let estimatedCarry: Distance
        
        /// 估计的 total 距离
        public let estimatedTotal: Distance
        
        /// 估计的方向（度，0=正北，顺时针）
        public let estimatedDirection: Double?
        
        /// 估计的落点位置（可选，基于方向和距离计算）
        public let estimatedLandingPosition: PositionObservation?
        
        /// 口述记录的原始文本（可选）
        public let dictationText: String?
        
        public init(
            estimatedCarry: Distance,
            estimatedTotal: Distance,
            estimatedDirection: Double? = nil,
            estimatedLandingPosition: PositionObservation? = nil,
            dictationText: String? = nil
        ) {
            self.estimatedCarry = estimatedCarry
            self.estimatedTotal = estimatedTotal
            self.estimatedDirection = estimatedDirection
            self.estimatedLandingPosition = estimatedLandingPosition
            self.dictationText = dictationText
        }
    }
    
    /// 实际结果（走到球位后确认）
    public struct ActualResult: Codable, Equatable, Sendable, Hashable {
        /// 实际终点位置观测
        public let endPosition: PositionObservation
        
        /// 实际终点球位分类
        public let endLie: Lie
        
        /// 实际测量的 carry 距离（可选，通常来自起始和落点的 GPS）
        public let measuredCarry: Distance?
        
        /// 实际测量的 total 距离（来自起始和终点的 GPS）
        public let measuredTotal: Distance
        
        /// 是否达到预期（用户主观评价）
        public let performanceRating: PerformanceRating?
        
        public init(
            endPosition: PositionObservation,
            endLie: Lie,
            measuredCarry: Distance? = nil,
            measuredTotal: Distance,
            performanceRating: PerformanceRating? = nil
        ) {
            self.endPosition = endPosition
            self.endLie = endLie
            self.measuredCarry = measuredCarry
            self.measuredTotal = measuredTotal
            self.performanceRating = performanceRating
        }
    }
    
    /// 击球表现评级
    public enum PerformanceRating: String, Codable, Sendable, Hashable {
        /// 非常好（超出预期）
        case excellent
        
        /// 好（符合预期）
        case good
        
        /// 一般
        case average
        
        /// 不理想
        case poor
        
        /// 失误
        case mistake
    }
    
    /// 确认状态
    public enum ConfirmationState: String, Codable, Sendable, Hashable {
        /// 初始记录（仅口述估计）
        case initial
        
        /// 已走到球位，待确认
        case pendingConfirmation
        
        /// 已确认（有实际位置观测）
        case confirmed
        
        /// 丢球/无法找到
        case lost
    }
    
    // MARK: - 初始化
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        club: ClubType,
        startPosition: PositionObservation,
        startLie: Lie,
        initialEstimate: InitialEstimate,
        actualResult: ActualResult? = nil,
        confirmationState: ConfirmationState = .initial,
        notes: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.club = club
        self.startPosition = startPosition
        self.startLie = startLie
        self.initialEstimate = initialEstimate
        self.actualResult = actualResult
        self.confirmationState = confirmationState
        self.notes = notes
    }
    
    // MARK: - 便利方法
    
    /// 是否已完成（有实际结果）
    public var isCompleted: Bool {
        actualResult != nil && confirmationState == .confirmed
    }
    
    /// 获取最终的 total 距离（优先使用实际测量值）
    public var finalTotalDistance: Distance {
        actualResult?.measuredTotal ?? initialEstimate.estimatedTotal
    }
    
    /// 获取最终的 carry 距离（优先使用实际测量值）
    public var finalCarryDistance: Distance {
        actualResult?.measuredCarry ?? initialEstimate.estimatedCarry
    }
    
    /// 估计与实际的偏差（total 距离）
    public var totalDistanceDeviation: Distance? {
        guard let actualTotal = actualResult?.measuredTotal else { return nil }
        let deviation = actualTotal.yards - initialEstimate.estimatedTotal.yards
        return Distance(yards: abs(deviation))
    }
    
    /// 创建一个更新了实际结果的新 Shot
    public func withActualResult(_ result: ActualResult) -> Shot {
        Shot(
            id: self.id,
            timestamp: self.timestamp,
            club: self.club,
            startPosition: self.startPosition,
            startLie: self.startLie,
            initialEstimate: self.initialEstimate,
            actualResult: result,
            confirmationState: .confirmed,
            notes: self.notes
        )
    }
    
    /// 标记为丢球
    public func markAsLost() -> Shot {
        Shot(
            id: self.id,
            timestamp: self.timestamp,
            club: self.club,
            startPosition: self.startPosition,
            startLie: self.startLie,
            initialEstimate: self.initialEstimate,
            actualResult: self.actualResult,
            confirmationState: .lost,
            notes: self.notes
        )
    }
}
