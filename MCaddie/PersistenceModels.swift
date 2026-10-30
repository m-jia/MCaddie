import Foundation
import SwiftData
import MCaddieCore

/// SwiftData 持久化模型
/// 这些模型是领域模型的持久化适配器，用于在 iOS 和 Watch App 中保存数据
/// 
/// 设计原则：
/// - 领域模型（MCaddieCore）保持纯 Swift，不依赖 SwiftData
/// - 持久化模型在 App 层，提供与领域模型的双向转换
/// - 使用 @Model 宏使其成为 SwiftData 实体

// MARK: - Round 持久化模型

@Model
final class RoundModel {
    /// 回合唯一标识符
    @Attribute(.unique) var id: UUID
    
    /// 开始时间
    var startTime: Date
    
    /// 结束时间（可选，进行中时为 nil）
    var endTime: Date?
    
    /// 球场名称
    var courseName: String
    
    /// 球场位置
    var courseLocation: String?
    
    /// 总洞数
    var numberOfHoles: Int
    
    /// 回合状态（使用 rawValue 存储枚举）
    var statusRawValue: String
    
    /// 备注
    var notes: String?
    
    /// 球洞信息（编码为 JSON）
    @Attribute(.externalStorage) var holesData: Data?
    
    /// 每洞记分（编码为 JSON；可选以兼容旧数据）
    var holeScoresData: Data?
    
    /// 外部球场数据库 ID
    var courseExternalID: String?
    
    /// 所选 Tee 台名称
    var teeName: String?
    
    /// 所选 Tee 台性别
    var teeGender: String?
    
    /// 击球记录关系
    @Relationship(deleteRule: .cascade, inverse: \ShotModel.round)
    var shots: [ShotModel] = []
    
    /// 创建时间（用于同步）
    var createdAt: Date
    
    /// 最后更新时间（用于同步）
    var updatedAt: Date
    
    init(
        id: UUID,
        startTime: Date,
        endTime: Date? = nil,
        courseName: String,
        courseLocation: String? = nil,
        numberOfHoles: Int,
        statusRawValue: String,
        notes: String? = nil,
        holesData: Data? = nil,
        holeScoresData: Data? = nil,
        courseExternalID: String? = nil,
        teeName: String? = nil,
        teeGender: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.courseName = courseName
        self.courseLocation = courseLocation
        self.numberOfHoles = numberOfHoles
        self.statusRawValue = statusRawValue
        self.notes = notes
        self.holesData = holesData
        self.holeScoresData = holeScoresData
        self.courseExternalID = courseExternalID
        self.teeName = teeName
        self.teeGender = teeGender
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Shot 持久化模型

@Model
final class ShotModel {
    /// 击球唯一标识符
    @Attribute(.unique) var id: UUID
    
    /// 击球时间戳
    var timestamp: Date
    
    /// 使用的球杆（rawValue）
    var clubRawValue: String
    
    /// 确认状态（rawValue）
    var confirmationStateRawValue: String
    
    /// 备注
    var notes: String?
    
    // MARK: - 起始位置和球位
    
    /// 起始位置观测（JSON 编码）
    @Attribute(.externalStorage) var startPositionData: Data
    
    /// 起始球位（rawValue）
    var startLieRawValue: String
    
    // MARK: - 初始估计
    
    /// 估计 carry 距离（码）
    var estimatedCarryYards: Double
    
    /// 估计 total 距离（码）
    var estimatedTotalYards: Double
    
    /// 估计方向（度）
    var estimatedDirection: Double?
    
    /// 估计落点位置（JSON 编码）
    @Attribute(.externalStorage) var estimatedLandingPositionData: Data?
    
    /// 口述文本
    var dictationText: String?
    
    // MARK: - 实际结果
    
    /// 终点位置观测（JSON 编码）
    @Attribute(.externalStorage) var endPositionData: Data?
    
    /// 终点球位（rawValue）
    var endLieRawValue: String?
    
    /// 实际测量 carry 距离（码）
    var measuredCarryYards: Double?
    
    /// 实际测量 total 距离（码）
    var measuredTotalYards: Double?
    
    /// 表现评级（rawValue）
    var performanceRatingRawValue: String?
    
    // MARK: - 关系
    
    /// 所属回合
    var round: RoundModel?
    
    /// 创建时间（用于同步）
    var createdAt: Date
    
    /// 最后更新时间（用于同步）
    var updatedAt: Date
    
    init(
        id: UUID,
        timestamp: Date,
        clubRawValue: String,
        confirmationStateRawValue: String,
        notes: String? = nil,
        startPositionData: Data,
        startLieRawValue: String,
        estimatedCarryYards: Double,
        estimatedTotalYards: Double,
        estimatedDirection: Double? = nil,
        estimatedLandingPositionData: Data? = nil,
        dictationText: String? = nil,
        endPositionData: Data? = nil,
        endLieRawValue: String? = nil,
        measuredCarryYards: Double? = nil,
        measuredTotalYards: Double? = nil,
        performanceRatingRawValue: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.clubRawValue = clubRawValue
        self.confirmationStateRawValue = confirmationStateRawValue
        self.notes = notes
        self.startPositionData = startPositionData
        self.startLieRawValue = startLieRawValue
        self.estimatedCarryYards = estimatedCarryYards
        self.estimatedTotalYards = estimatedTotalYards
        self.estimatedDirection = estimatedDirection
        self.estimatedLandingPositionData = estimatedLandingPositionData
        self.dictationText = dictationText
        self.endPositionData = endPositionData
        self.endLieRawValue = endLieRawValue
        self.measuredCarryYards = measuredCarryYards
        self.measuredTotalYards = measuredTotalYards
        self.performanceRatingRawValue = performanceRatingRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 转换扩展

extension RoundModel {
    /// 从领域模型创建持久化模型
    convenience init(from domain: Round) throws {
        // 编码球洞信息
        var holesData: Data? = nil
        if let holes = domain.course.holes {
            holesData = try JSONEncoder().encode(holes)
        }
        
        self.init(
            id: domain.id,
            startTime: domain.startTime,
            endTime: domain.endTime,
            courseName: domain.course.name,
            courseLocation: domain.course.location,
            numberOfHoles: domain.course.numberOfHoles,
            statusRawValue: domain.status.rawValue,
            notes: domain.notes,
            holesData: holesData,
            holeScoresData: domain.holeScores.isEmpty ? nil : try JSONEncoder().encode(domain.holeScores),
            courseExternalID: domain.course.externalCourseID,
            teeName: domain.course.teeName,
            teeGender: domain.course.teeGender,
            createdAt: domain.startTime,
            updatedAt: Date()
        )
    }
    
    /// 转换为领域模型
    func toDomain(with shots: [Shot] = []) throws -> Round {
        // 解码球洞信息
        var holes: [Hole]? = nil
        if let holesData = holesData {
            holes = try JSONDecoder().decode([Hole].self, from: holesData)
        }
        
        var holeScores: [HoleScore] = []
        if let holeScoresData = holeScoresData {
            holeScores = try JSONDecoder().decode([HoleScore].self, from: holeScoresData)
        }
        
        let courseInfo = Round.CourseInfo(
            name: courseName,
            location: courseLocation,
            numberOfHoles: numberOfHoles,
            holes: holes,
            externalCourseID: courseExternalID,
            teeName: teeName,
            teeGender: teeGender
        )
        
        guard let status = Round.RoundStatus(rawValue: statusRawValue) else {
            throw PersistenceError.invalidEnumValue("RoundStatus", statusRawValue)
        }
        
        return Round(
            id: id,
            startTime: startTime,
            endTime: endTime,
            course: courseInfo,
            shots: shots,
            holeScores: holeScores,
            status: status,
            notes: notes
        )
    }
}

extension ShotModel {
    /// 从领域模型创建持久化模型
    convenience init(from domain: Shot) throws {
        // 编码位置观测
        let startPositionData = try JSONEncoder().encode(domain.startPosition)
        
        var estimatedLandingData: Data? = nil
        if let estimatedLanding = domain.initialEstimate.estimatedLandingPosition {
            estimatedLandingData = try JSONEncoder().encode(estimatedLanding)
        }
        
        var endPositionData: Data? = nil
        var endLieRawValue: String? = nil
        var measuredCarryYards: Double? = nil
        var measuredTotalYards: Double? = nil
        var performanceRatingRawValue: String? = nil
        
        if let actualResult = domain.actualResult {
            endPositionData = try JSONEncoder().encode(actualResult.endPosition)
            endLieRawValue = actualResult.endLie.rawValue
            measuredCarryYards = actualResult.measuredCarry?.yards
            measuredTotalYards = actualResult.measuredTotal.yards
            performanceRatingRawValue = actualResult.performanceRating?.rawValue
        }
        
        self.init(
            id: domain.id,
            timestamp: domain.timestamp,
            clubRawValue: domain.club.rawValue,
            confirmationStateRawValue: domain.confirmationState.rawValue,
            notes: domain.notes,
            startPositionData: startPositionData,
            startLieRawValue: domain.startLie.rawValue,
            estimatedCarryYards: domain.initialEstimate.estimatedCarry.yards,
            estimatedTotalYards: domain.initialEstimate.estimatedTotal.yards,
            estimatedDirection: domain.initialEstimate.estimatedDirection,
            estimatedLandingPositionData: estimatedLandingData,
            dictationText: domain.initialEstimate.dictationText,
            endPositionData: endPositionData,
            endLieRawValue: endLieRawValue,
            measuredCarryYards: measuredCarryYards,
            measuredTotalYards: measuredTotalYards,
            performanceRatingRawValue: performanceRatingRawValue,
            createdAt: domain.timestamp,
            updatedAt: Date()
        )
    }
    
    /// 转换为领域模型
    func toDomain() throws -> Shot {
        // 解码位置观测
        let startPosition = try JSONDecoder().decode(PositionObservation.self, from: startPositionData)
        
        var estimatedLandingPosition: PositionObservation? = nil
        if let data = estimatedLandingPositionData {
            estimatedLandingPosition = try JSONDecoder().decode(PositionObservation.self, from: data)
        }
        
        guard let club = ClubType(rawValue: clubRawValue) else {
            throw PersistenceError.invalidEnumValue("ClubType", clubRawValue)
        }
        
        guard let startLie = Lie(rawValue: startLieRawValue) else {
            throw PersistenceError.invalidEnumValue("Lie", startLieRawValue)
        }
        
        guard let confirmationState = Shot.ConfirmationState(rawValue: confirmationStateRawValue) else {
            throw PersistenceError.invalidEnumValue("ConfirmationState", confirmationStateRawValue)
        }
        
        // 构建初始估计
        let initialEstimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: estimatedCarryYards),
            estimatedTotal: Distance(yards: estimatedTotalYards),
            estimatedDirection: estimatedDirection,
            estimatedLandingPosition: estimatedLandingPosition,
            dictationText: dictationText
        )
        
        // 构建实际结果（如果存在）
        var actualResult: Shot.ActualResult? = nil
        if let endPositionData = endPositionData,
           let endLieRaw = endLieRawValue,
           let totalYards = measuredTotalYards {
            
            let endPosition = try JSONDecoder().decode(PositionObservation.self, from: endPositionData)
            
            guard let endLie = Lie(rawValue: endLieRaw) else {
                throw PersistenceError.invalidEnumValue("Lie", endLieRaw)
            }
            
            var performanceRating: Shot.PerformanceRating? = nil
            if let ratingRaw = performanceRatingRawValue {
                performanceRating = Shot.PerformanceRating(rawValue: ratingRaw)
            }
            
            actualResult = Shot.ActualResult(
                endPosition: endPosition,
                endLie: endLie,
                measuredCarry: measuredCarryYards.map { Distance(yards: $0) },
                measuredTotal: Distance(yards: totalYards),
                performanceRating: performanceRating
            )
        }
        
        return Shot(
            id: id,
            timestamp: timestamp,
            club: club,
            startPosition: startPosition,
            startLie: startLie,
            initialEstimate: initialEstimate,
            actualResult: actualResult,
            confirmationState: confirmationState,
            notes: notes
        )
    }
}

// MARK: - 错误类型

enum PersistenceError: Error, LocalizedError {
    case invalidEnumValue(String, String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEnumValue(let type, let value):
            return "Invalid enum value for \(type): \(value)"
        case .encodingFailed(let reason):
            return "Encoding failed: \(reason)"
        case .decodingFailed(let reason):
            return "Decoding failed: \(reason)"
        }
    }
}
