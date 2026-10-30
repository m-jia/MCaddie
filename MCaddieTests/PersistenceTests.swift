import Testing
import Foundation
import MCaddieCore
@testable import MCaddie

@Suite("SwiftData 持久化测试")
@MainActor
struct PersistenceTests {
    
    // MARK: - DataManager 基础测试
    
    @Test("创建测试用 DataManager")
    func createTestDataManager() async throws {
        let manager = try DataManager.preview()
        #expect(manager.modelContainer != nil)
    }
    
    @Test("创建生产环境 DataManager")
    func createProductionDataManager() async throws {
        // 注意：这会在真实文件系统中创建数据库
        // 测试后应清理
        let manager = try DataManager.production()
        #expect(manager.modelContainer != nil)
        
        // 清理测试数据
        try manager.clearAllData()
    }
    
    // MARK: - Round 持久化测试
    
    @Test("保存和读取回合")
    func saveAndFetchRound() async throws {
        let manager = try DataManager.preview()
        
        let courseInfo = Round.CourseInfo(
            name: "春城湖畔高尔夫球场",
            location: "昆明",
            numberOfHoles: 18
        )
        
        let round = Round(
            course: courseInfo,
            status: .inProgress
        )
        
        // 保存
        try manager.saveRound(round)
        
        // 读取
        let fetchedRound = try manager.fetchRound(id: round.id)
        
        // 验证
        #expect(fetchedRound != nil)
        #expect(fetchedRound?.id == round.id)
        #expect(fetchedRound?.course.name == "春城湖畔高尔夫球场")
        #expect(fetchedRound?.course.location == "昆明")
        #expect(fetchedRound?.course.numberOfHoles == 18)
        #expect(fetchedRound?.status == .inProgress)
    }
    
    @Test("更新回合状态")
    func updateRoundStatus() async throws {
        let manager = try DataManager.preview()
        
        // 创建并保存初始回合
        var round = Round(
            course: Round.CourseInfo(name: "测试球场", numberOfHoles: 18),
            status: .inProgress
        )
        try manager.saveRound(round)
        
        // 完成回合
        round.complete()
        try manager.updateRound(round)
        
        // 验证
        let updated = try manager.fetchRound(id: round.id)
        #expect(updated?.status == .completed)
        #expect(updated?.endTime != nil)
    }
    
    @Test("获取所有回合")
    func fetchAllRounds() async throws {
        let manager = try DataManager.preview()
        
        // 创建多个回合
        for i in 1...3 {
            let round = Round(
                course: Round.CourseInfo(name: "球场 \(i)", numberOfHoles: 18)
            )
            try manager.saveRound(round)
        }
        
        // 获取所有回合
        let rounds = try manager.fetchAllRounds()
        #expect(rounds.count == 3)
    }
    
    @Test("获取进行中的回合")
    func fetchActiveRounds() async throws {
        let manager = try DataManager.preview()
        
        // 创建进行中的回合
        let activeRound = Round(
            course: Round.CourseInfo(name: "进行中", numberOfHoles: 18),
            status: .inProgress
        )
        try manager.saveRound(activeRound)
        
        // 创建已完成的回合
        var completedRound = Round(
            course: Round.CourseInfo(name: "已完成", numberOfHoles: 18),
            status: .inProgress
        )
        completedRound.complete()
        try manager.saveRound(completedRound)
        
        // 只获取进行中的
        let activeRounds = try manager.fetchActiveRounds()
        #expect(activeRounds.count == 1)
        #expect(activeRounds.first?.course.name == "进行中")
    }
    
    @Test("删除回合")
    func deleteRound() async throws {
        let manager = try DataManager.preview()
        
        let round = Round(
            course: Round.CourseInfo(name: "待删除", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        // 确认已保存
        var fetched = try manager.fetchRound(id: round.id)
        #expect(fetched != nil)
        
        // 删除
        try manager.deleteRound(id: round.id)
        
        // 确认已删除
        fetched = try manager.fetchRound(id: round.id)
        #expect(fetched == nil)
    }
    
    // MARK: - Shot 持久化测试
    
    @Test("保存击球到回合")
    func saveShotToRound() async throws {
        let manager = try DataManager.preview()
        
        // 创建回合
        let round = Round(
            course: Round.CourseInfo(name: "测试球场", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        // 创建击球
        let position = PositionObservation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160),
            dictationText: "7号铁，向右偏"
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: position,
            startLie: .fairway,
            initialEstimate: estimate
        )
        
        // 保存击球
        try manager.saveShot(shot, toRoundID: round.id)
        
        // 验证
        let shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 1)
        #expect(shots.first?.id == shot.id)
        #expect(shots.first?.club == .iron7)
        #expect(shots.first?.startLie == .fairway)
    }
    
    @Test("更新击球结果")
    func updateShotResult() async throws {
        let manager = try DataManager.preview()
        
        // 创建回合和初始击球
        let round = Round(
            course: Round.CourseInfo(name: "测试", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        let startPosition = PositionObservation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160)
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: startPosition,
            startLie: .fairway,
            initialEstimate: estimate
        )
        
        try manager.saveShot(shot, toRoundID: round.id)
        
        // 更新实际结果
        let endPosition = PositionObservation(
            latitude: 37.7750,
            longitude: -122.4195,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        
        let actualResult = Shot.ActualResult(
            endPosition: endPosition,
            endLie: .green,
            measuredTotal: startPosition.distance(to: endPosition),
            performanceRating: .good
        )
        
        let updatedShot = shot.withActualResult(actualResult)
        try manager.updateShot(updatedShot)
        
        // 验证
        let shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.first?.isCompleted == true)
        #expect(shots.first?.actualResult?.endLie == .green)
        #expect(shots.first?.actualResult?.performanceRating == .good)
    }
    
    @Test("保存多个击球到同一回合")
    func saveMultipleShots() async throws {
        let manager = try DataManager.preview()
        
        let round = Round(
            course: Round.CourseInfo(name: "测试", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        // 创建 5 个击球
        for i in 1...5 {
            let position = PositionObservation(
                latitude: 37.7749 + Double(i) * 0.0001,
                longitude: -122.4194,
                horizontalAccuracy: 5.0,
                source: .gps
            )
            
            let estimate = Shot.InitialEstimate(
                estimatedCarry: Distance(yards: Double(100 + i * 10)),
                estimatedTotal: Distance(yards: Double(110 + i * 10))
            )
            
            let shot = Shot(
                club: ClubType.allCases[i],
                startPosition: position,
                startLie: .fairway,
                initialEstimate: estimate
            )
            
            try manager.saveShot(shot, toRoundID: round.id)
        }
        
        // 验证
        let shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 5)
    }
    
    @Test("删除击球")
    func deleteShot() async throws {
        let manager = try DataManager.preview()
        
        let round = Round(
            course: Round.CourseInfo(name: "测试", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        let position = PositionObservation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160)
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: position,
            startLie: .fairway,
            initialEstimate: estimate
        )
        
        try manager.saveShot(shot, toRoundID: round.id)
        
        // 确认已保存
        var shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 1)
        
        // 删除
        try manager.deleteShot(id: shot.id)
        
        // 确认已删除
        shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 0)
    }
    
    // MARK: - 关系和级联删除测试
    
    @Test("删除回合时级联删除击球")
    func cascadeDeleteShots() async throws {
        let manager = try DataManager.preview()
        
        let round = Round(
            course: Round.CourseInfo(name: "测试", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        // 添加击球
        for _ in 1...3 {
            let position = PositionObservation(
                latitude: 37.7749,
                longitude: -122.4194,
                horizontalAccuracy: 5.0,
                source: .gps
            )
            
            let estimate = Shot.InitialEstimate(
                estimatedCarry: Distance(yards: 150),
                estimatedTotal: Distance(yards: 160)
            )
            
            let shot = Shot(
                club: .iron7,
                startPosition: position,
                startLie: .fairway,
                initialEstimate: estimate
            )
            
            try manager.saveShot(shot, toRoundID: round.id)
        }
        
        // 确认击球已保存
        var shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 3)
        
        // 删除回合
        try manager.deleteRound(id: round.id)
        
        // 击球应该被级联删除
        shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 0)
    }
    
    // MARK: - 统计和查询测试
    
    @Test("获取回合和击球统计")
    func getStatistics() async throws {
        let manager = try DataManager.preview()
        
        // 创建 2 个回合
        for i in 1...2 {
            let round = Round(
                course: Round.CourseInfo(name: "球场 \(i)", numberOfHoles: 18)
            )
            try manager.saveRound(round)
            
            // 每个回合 3 个击球
            for _ in 1...3 {
                let position = PositionObservation(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    horizontalAccuracy: 5.0,
                    source: .gps
                )
                
                let estimate = Shot.InitialEstimate(
                    estimatedCarry: Distance(yards: 150),
                    estimatedTotal: Distance(yards: 160)
                )
                
                let shot = Shot(
                    club: .iron7,
                    startPosition: position,
                    startLie: .fairway,
                    initialEstimate: estimate
                )
                
                try manager.saveShot(shot, toRoundID: round.id)
            }
        }
        
        // 验证统计
        let roundsCount = try manager.getTotalRoundsCount()
        let shotsCount = try manager.getTotalShotsCount()
        
        #expect(roundsCount == 2)
        #expect(shotsCount == 6)
    }
    
    @Test("获取最近的回合")
    func getRecentRounds() async throws {
        let manager = try DataManager.preview()
        
        // 创建 10 个回合
        for i in 1...10 {
            let round = Round(
                startTime: Date().addingTimeInterval(-Double(i) * 86400), // 每个回合间隔一天
                course: Round.CourseInfo(name: "球场 \(i)", numberOfHoles: 18)
            )
            try manager.saveRound(round)
        }
        
        // 获取最近 5 个
        let recentRounds = try manager.fetchRecentRounds(limit: 5)
        
        #expect(recentRounds.count == 5)
        // 应该是最近的（球场 1 是最新的）
        #expect(recentRounds.first?.course.name == "球场 1")
    }
    
    // MARK: - 数据完整性测试
    
    @Test("验证距离单位转换")
    func verifyDistanceConversion() async throws {
        let manager = try DataManager.preview()
        
        let round = Round(
            course: Round.CourseInfo(name: "测试", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        let position = PositionObservation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160)
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: position,
            startLie: .fairway,
            initialEstimate: estimate
        )
        
        try manager.saveShot(shot, toRoundID: round.id)
        
        // 读取并验证距离
        let shots = try manager.fetchShots(forRoundID: round.id)
        let retrievedShot = try #require(shots.first)
        
        #expect(retrievedShot.initialEstimate.estimatedCarry.yards == 150)
        #expect(retrievedShot.initialEstimate.estimatedTotal.yards == 160)
    }
    
    @Test("验证枚举值保存和读取")
    func verifyEnumPersistence() async throws {
        let manager = try DataManager.preview()
        
        let round = Round(
            course: Round.CourseInfo(name: "测试", numberOfHoles: 18)
        )
        try manager.saveRound(round)
        
        // 测试所有球杆类型
        for clubType in ClubType.allCases {
            let position = PositionObservation(
                latitude: 37.7749,
                longitude: -122.4194,
                horizontalAccuracy: 5.0,
                source: .gps
            )
            
            let estimate = Shot.InitialEstimate(
                estimatedCarry: Distance(yards: 150),
                estimatedTotal: Distance(yards: 160)
            )
            
            let shot = Shot(
                club: clubType,
                startPosition: position,
                startLie: .fairway,
                initialEstimate: estimate
            )
            
            try manager.saveShot(shot, toRoundID: round.id)
        }
        
        // 验证所有球杆都正确保存
        let shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == ClubType.allCases.count)
        
        let retrievedClubs = Set(shots.map { $0.club })
        let allClubs = Set(ClubType.allCases)
        #expect(retrievedClubs == allClubs)
    }
}
