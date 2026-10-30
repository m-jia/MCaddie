import Foundation
import SwiftData
import MCaddieCore

/// 数据管理服务
/// 提供统一的数据访问接口，封装 SwiftData 操作
@MainActor
final class DataManager {
    
    /// SwiftData ModelContainer
    let modelContainer: ModelContainer
    
    /// 主线程的 ModelContext
    var mainContext: ModelContext {
        modelContainer.mainContext
    }
    
    // MARK: - 初始化
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    /// 创建内存中的测试容器
    static func preview() throws -> DataManager {
        let schema = Schema([
            RoundModel.self,
            ShotModel.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        return DataManager(modelContainer: container)
    }
    
    /// 创建生产环境容器
    static func production() throws -> DataManager {
        let schema = Schema([
            RoundModel.self,
            ShotModel.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        return DataManager(modelContainer: container)
    }
    
    // MARK: - Round 操作
    
    /// 保存新回合
    func saveRound(_ round: Round) throws {
        let roundModel = try RoundModel(from: round)
        mainContext.insert(roundModel)
        
        // 保存关联的击球记录
        for shot in round.shots {
            let shotModel = try ShotModel(from: shot)
            shotModel.round = roundModel
            mainContext.insert(shotModel)
        }
        
        try mainContext.save()
    }
    
    /// 更新回合
    func updateRound(_ round: Round) throws {
        let descriptor = FetchDescriptor<RoundModel>(
            predicate: #Predicate { $0.id == round.id }
        )
        
        guard let existingModel = try mainContext.fetch(descriptor).first else {
            throw DataManagerError.roundNotFound(round.id)
        }
        
        // 更新基本属性
        existingModel.endTime = round.endTime
        existingModel.statusRawValue = round.status.rawValue
        existingModel.notes = round.notes
        existingModel.updatedAt = Date()
        
        // 更新球场配置（洞数和 Tee 台可修改）
        existingModel.numberOfHoles = round.course.numberOfHoles
        existingModel.holesData = try round.course.holes.map { try JSONEncoder().encode($0) }
        existingModel.courseExternalID = round.course.externalCourseID
        existingModel.teeName = round.course.teeName
        existingModel.teeGender = round.course.teeGender
        
        existingModel.holeScoresData = try JSONEncoder().encode(round.holeScores)
        
        try mainContext.save()
    }
    
    /// 获取所有回合
    func fetchAllRounds() throws -> [Round] {
        let descriptor = FetchDescriptor<RoundModel>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        let roundModels = try mainContext.fetch(descriptor)
        
        return try roundModels.map { roundModel in
            // 获取关联的击球记录
            let shots = try roundModel.shots.map { try $0.toDomain() }
            return try roundModel.toDomain(with: shots)
        }
    }
    
    /// 获取进行中的回合
    func fetchActiveRounds() throws -> [Round] {
        let descriptor = FetchDescriptor<RoundModel>(
            predicate: #Predicate { $0.statusRawValue == "inProgress" },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        let roundModels = try mainContext.fetch(descriptor)
        
        return try roundModels.map { roundModel in
            let shots = try roundModel.shots.map { try $0.toDomain() }
            return try roundModel.toDomain(with: shots)
        }
    }
    
    /// 获取特定回合
    func fetchRound(id: UUID) throws -> Round? {
        let descriptor = FetchDescriptor<RoundModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let roundModel = try mainContext.fetch(descriptor).first else {
            return nil
        }
        
        let shots = try roundModel.shots.map { try $0.toDomain() }
        return try roundModel.toDomain(with: shots)
    }
    
    /// 删除回合
    func deleteRound(id: UUID) throws {
        let descriptor = FetchDescriptor<RoundModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let roundModel = try mainContext.fetch(descriptor).first else {
            throw DataManagerError.roundNotFound(id)
        }
        
        mainContext.delete(roundModel)
        try mainContext.save()
    }
    
    // MARK: - Shot 操作
    
    /// 保存新击球记录到指定回合
    func saveShot(_ shot: Shot, toRoundID roundID: UUID) throws {
        let roundDescriptor = FetchDescriptor<RoundModel>(
            predicate: #Predicate { $0.id == roundID }
        )
        
        guard let roundModel = try mainContext.fetch(roundDescriptor).first else {
            throw DataManagerError.roundNotFound(roundID)
        }
        
        let shotModel = try ShotModel(from: shot)
        shotModel.round = roundModel
        mainContext.insert(shotModel)
        
        roundModel.updatedAt = Date()
        try mainContext.save()
    }
    
    /// 更新击球记录
    func updateShot(_ shot: Shot) throws {
        let descriptor = FetchDescriptor<ShotModel>(
            predicate: #Predicate { $0.id == shot.id }
        )
        
        guard let existingModel = try mainContext.fetch(descriptor).first else {
            throw DataManagerError.shotNotFound(shot.id)
        }
        
        // 更新可变属性
        existingModel.confirmationStateRawValue = shot.confirmationState.rawValue
        existingModel.notes = shot.notes
        
        // 更新实际结果（如果有）
        if let actualResult = shot.actualResult {
            existingModel.endPositionData = try JSONEncoder().encode(actualResult.endPosition)
            existingModel.endLieRawValue = actualResult.endLie.rawValue
            existingModel.measuredCarryYards = actualResult.measuredCarry?.yards
            existingModel.measuredTotalYards = actualResult.measuredTotal.yards
            existingModel.performanceRatingRawValue = actualResult.performanceRating?.rawValue
        }
        
        existingModel.updatedAt = Date()
        try mainContext.save()
    }
    
    /// 获取回合的所有击球记录
    func fetchShots(forRoundID roundID: UUID) throws -> [Shot] {
        let descriptor = FetchDescriptor<ShotModel>(
            predicate: #Predicate { $0.round?.id == roundID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        let shotModels = try mainContext.fetch(descriptor)
        return try shotModels.map { try $0.toDomain() }
    }
    
    /// 删除击球记录
    func deleteShot(id: UUID) throws {
        let descriptor = FetchDescriptor<ShotModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let shotModel = try mainContext.fetch(descriptor).first else {
            throw DataManagerError.shotNotFound(id)
        }
        
        mainContext.delete(shotModel)
        try mainContext.save()
    }
    
    // MARK: - 统计查询
    
    /// 获取总回合数
    func getTotalRoundsCount() throws -> Int {
        let descriptor = FetchDescriptor<RoundModel>()
        return try mainContext.fetchCount(descriptor)
    }
    
    /// 获取总击球数
    func getTotalShotsCount() throws -> Int {
        let descriptor = FetchDescriptor<ShotModel>()
        return try mainContext.fetchCount(descriptor)
    }
    
    /// 获取最近的 N 个回合
    func fetchRecentRounds(limit: Int = 10) throws -> [Round] {
        var descriptor = FetchDescriptor<RoundModel>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        let roundModels = try mainContext.fetch(descriptor)
        
        return try roundModels.map { roundModel in
            let shots = try roundModel.shots.map { try $0.toDomain() }
            return try roundModel.toDomain(with: shots)
        }
    }
    
    // MARK: - 批量操作
    
    /// 清除所有数据（用于测试）
    func clearAllData() throws {
        try mainContext.delete(model: RoundModel.self)
        try mainContext.delete(model: ShotModel.self)
        try mainContext.save()
    }
}

// MARK: - 错误类型

enum DataManagerError: Error, LocalizedError {
    case roundNotFound(UUID)
    case shotNotFound(UUID)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .roundNotFound(let id):
            return "Round not found with ID: \(id)"
        case .shotNotFound(let id):
            return "Shot not found with ID: \(id)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        }
    }
}

// MARK: - 环境值扩展

import SwiftUI

private struct DataManagerKey: EnvironmentKey {
    static let defaultValue: DataManager? = nil
}

extension EnvironmentValues {
    var dataManager: DataManager? {
        get { self[DataManagerKey.self] }
        set { self[DataManagerKey.self] = newValue }
    }
}

extension View {
    func dataManager(_ manager: DataManager) -> some View {
        environment(\.dataManager, manager)
    }
}
