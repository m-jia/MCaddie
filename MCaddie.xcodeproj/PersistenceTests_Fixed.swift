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
        let manager = try DataManager.production()
        #expect(manager.modelContainer != nil)
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
        
        try manager.saveRound(round)
        let fetchedRound = try manager.fetchRound(id: round.id)
        
        #expect(fetchedRound != nil)
        #expect(fetchedRound?.id == round.id)
        #expect(fetchedRound?.course.name == "春城湖畔高尔夫球场")
    }
    
    @Test("更新回合状态")
    func updateRoundStatus() async throws {
        let manager = try DataManager.preview()
        
        var round = Round(
            course: Round.CourseInfo(name: "测试球场", numberOfHoles: 18),
            status: .inProgress
        )
        try manager.saveRound(round)
        
        round.complete()
        try manager.updateRound(round)
        
        let updated = try manager.fetchRound(id: round.id)
        #expect(updated?.status == .completed)
        #expect(updated?.endTime != nil)
    }
    
    @Test("获取所有回合")
    func fetchAllRounds() async throws {
        let manager = try DataManager.preview()
        
        for i in 1...3 {
            let round = Round(
                course: Round.CourseInfo(name: "球场 \(i)", numberOfHoles: 18)
            )
            try manager.saveRound(round)
        }
        
        let rounds = try manager.fetchAllRounds()
        #expect(rounds.count == 3)
    }
    
    @Test("获取进行中的回合")
    func fetchActiveRounds() async throws {
        let manager = try DataManager.preview()
        
        let activeRound = Round(
            course: Round.CourseInfo(name: "进行中", numberOfHoles: 18),
            status: .inProgress
        )
        try manager.saveRound(activeRound)
        
        var completedRound = Round(
            course: Round.CourseInfo(name: "已完成", numberOfHoles: 18),
            status: .inProgress
        )
        completedRound.complete()
        try manager.saveRound(completedRound)
        
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
        
        var fetched = try manager.fetchRound(id: round.id)
        #expect(fetched != nil)
        
        try manager.deleteRound(id: round.id)
        
        fetched = try manager.fetchRound(id: round.id)
        #expect(fetched == nil)
    }
    
    // MARK: - Shot 持久化测试
    
    @Test("保存击球到回合")
    func saveShotToRound() async throws {
        let manager = try DataManager.preview()
        
        let round = Round(
            course: Round.CourseInfo(name: "测试球场", numberOfHoles: 18)
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
            estimatedTotal: Distance(yards: 160),
            dictationText: "7号铁，向右偏"
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: position,
            startLie: .fairway,
            initialEstimate: estimate
        )
        
        try manager.saveShot(shot, toRoundID: round.id)
        
        let shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 1)
        #expect(shots.first?.id == shot.id)
        #expect(shots.first?.club == .iron7)
    }
    
    @Test("更新击球结果")
    func updateShotResult() async throws {
        let manager = try DataManager.preview()
        
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
        
        let shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.first?.isCompleted == true)
        #expect(shots.first?.actualResult?.endLie == .green)
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
        
        var shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 1)
        
        try manager.deleteShot(id: shot.id)
        
        shots = try manager.fetchShots(forRoundID: round.id)
        #expect(shots.count == 0)
    }
    
    // MARK: - 统计测试
    
    @Test("获取统计信息")
    func getStatistics() async throws {
        let manager = try DataManager.preview()
        
        for i in 1...2 {
            let round = Round(
                course: Round.CourseInfo(name: "球场 \(i)", numberOfHoles: 18)
            )
            try manager.saveRound(round)
            
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
        
        let roundsCount = try manager.getTotalRoundsCount()
        let shotsCount = try manager.getTotalShotsCount()
        
        #expect(roundsCount == 2)
        #expect(shotsCount == 6)
    }
}
