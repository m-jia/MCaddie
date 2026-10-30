import Testing
import Foundation
@testable import MCaddieCore

@Suite("Shot Tests")
struct ShotTests {
    
    // MARK: - 测试数据
    
    let startPosition = PositionObservation(
        latitude: 35.6762,
        longitude: 139.6503,
        altitude: 10.0,
        horizontalAccuracy: 5.0,
        source: .gps
    )
    
    let endPosition = PositionObservation(
        latitude: 35.6780,
        longitude: 139.6520,
        altitude: 12.0,
        horizontalAccuracy: 4.0,
        source: .gps
    )
    
    // MARK: - PositionObservation 测试
    
    @Test("PositionObservation can be created")
    func positionObservationCreation() {
        let position = PositionObservation(
            latitude: 35.6762,
            longitude: 139.6503,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        
        #expect(position.latitude == 35.6762)
        #expect(position.longitude == 139.6503)
        #expect(position.horizontalAccuracy == 5.0)
        #expect(position.source == .gps)
    }
    
    @Test("PositionObservation can calculate distance")
    func positionDistance() {
        let distance = startPosition.distance(to: endPosition)
        
        // 距离应该大于 0
        #expect(distance.yards > 0)
        
        // 这两个点之间大约 230 米
        #expect(distance.meters > 200)
        #expect(distance.meters < 300)
    }
    
    @Test("PositionObservation reliability check")
    func positionReliability() {
        let reliable = PositionObservation(
            latitude: 0.0,
            longitude: 0.0,
            horizontalAccuracy: 3.0,
            source: .gps
        )
        
        let unreliable = PositionObservation(
            latitude: 0.0,
            longitude: 0.0,
            horizontalAccuracy: 15.0,
            source: .gps
        )
        
        #expect(reliable.isReliable)
        #expect(reliable.isHighPrecision)
        #expect(!unreliable.isReliable)
        #expect(!unreliable.isHighPrecision)
    }
    
    // MARK: - Lie 测试
    
    @Test("Lie has correct display names")
    func lieDisplayNames() {
        #expect(Lie.tee.displayName == "发球台")
        #expect(Lie.fairway.displayName == "球道")
        #expect(Lie.bunker.displayName == "沙坑")
        #expect(Lie.green.displayName == "果岭")
    }
    
    @Test("Lie difficulty coefficients are reasonable")
    func lieDifficulty() {
        // 发球台和球道应该是最简单的
        #expect(Lie.tee.difficultyCoefficent == 1.0)
        #expect(Lie.fairway.difficultyCoefficent == 1.0)
        
        // 果岭应该更容易
        #expect(Lie.green.difficultyCoefficent < 1.0)
        
        // 沙坑、树林、水障碍应该更难
        #expect(Lie.bunker.difficultyCoefficent > 1.0)
        #expect(Lie.trees.difficultyCoefficent > 1.0)
        #expect(Lie.waterHazard.difficultyCoefficent > 1.0)
    }
    
    // MARK: - Shot 基本测试
    
    @Test("Shot can be created with initial estimate")
    func shotCreation() {
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160),
            estimatedDirection: 45.0,
            dictationText: "7铁，150码"
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: startPosition,
            startLie: .tee,
            initialEstimate: estimate
        )
        
        #expect(shot.club == .iron7)
        #expect(shot.startLie == .tee)
        #expect(shot.initialEstimate.estimatedCarry.yards == 150)
        #expect(shot.initialEstimate.estimatedTotal.yards == 160)
        #expect(shot.confirmationState == .initial)
        #expect(!shot.isCompleted)
    }
    
    @Test("Shot separates carry and total distances")
    func shotCarryAndTotal() {
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 180),
            estimatedTotal: Distance(yards: 200)
        )
        
        let shot = Shot(
            club: .driver,
            startPosition: startPosition,
            startLie: .tee,
            initialEstimate: estimate
        )
        
        // 初始值应该来自估计
        #expect(shot.finalCarryDistance.yards == 180)
        #expect(shot.finalTotalDistance.yards == 200)
        
        // carry 应该小于 total
        #expect(shot.initialEstimate.estimatedCarry.yards < shot.initialEstimate.estimatedTotal.yards)
    }
    
    @Test("Shot can be updated with actual result")
    func shotUpdate() {
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160)
        )
        
        let initialShot = Shot(
            club: .iron7,
            startPosition: startPosition,
            startLie: .tee,
            initialEstimate: estimate
        )
        
        let actualResult = Shot.ActualResult(
            endPosition: endPosition,
            endLie: .fairway,
            measuredCarry: Distance(yards: 145),
            measuredTotal: Distance(yards: 155),
            performanceRating: .good
        )
        
        let updatedShot = initialShot.withActualResult(actualResult)
        
        #expect(updatedShot.id == initialShot.id) // ID 保持不变
        #expect(updatedShot.isCompleted)
        #expect(updatedShot.confirmationState == .confirmed)
        #expect(updatedShot.actualResult?.endLie == .fairway)
        #expect(updatedShot.finalTotalDistance.yards == 155) // 使用实际值
    }
    
    @Test("Shot calculates distance deviation")
    func shotDeviation() {
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160)
        )
        
        let shot = Shot(
            club: .iron7,
            startPosition: startPosition,
            startLie: .tee,
            initialEstimate: estimate
        )
        
        let actualResult = Shot.ActualResult(
            endPosition: endPosition,
            endLie: .fairway,
            measuredTotal: Distance(yards: 155)
        )
        
        let updatedShot = shot.withActualResult(actualResult)
        let deviation = updatedShot.totalDistanceDeviation
        
        #expect(deviation != nil)
        #expect(deviation!.yards == 5.0) // |155 - 160| = 5
    }
    
    @Test("Shot can be marked as lost")
    func shotLost() {
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 200),
            estimatedTotal: Distance(yards: 220)
        )
        
        let shot = Shot(
            club: .driver,
            startPosition: startPosition,
            startLie: .tee,
            initialEstimate: estimate
        )
        
        let lostShot = shot.markAsLost()
        
        #expect(lostShot.confirmationState == .lost)
        #expect(lostShot.id == shot.id) // ID 不变
    }
    
    // MARK: - Hole 测试
    
    @Test("Hole can be created")
    func holeCreation() {
        let hole = Hole(
            number: 1,
            par: 4,
            distance: Distance(yards: 380),
            teePosition: startPosition,
            greenPosition: endPosition,
            description: "直线球道，右侧有水障碍",
            handicap: 5
        )
        
        #expect(hole.number == 1)
        #expect(hole.par == 4)
        #expect(hole.distance.yards == 380)
        #expect(hole.holeType == .par4)
    }
    
    @Test("Hole type classification")
    func holeTypeClassification() {
        let par3 = Hole(number: 3, par: 3, distance: Distance(yards: 180))
        let par4 = Hole(number: 4, par: 4, distance: Distance(yards: 380))
        let par5 = Hole(number: 5, par: 5, distance: Distance(yards: 520))
        
        #expect(par3.holeType == .par3)
        #expect(par4.holeType == .par4)
        #expect(par5.holeType == .par5)
    }
    
    // MARK: - Round 测试
    
    @Test("Round can be created")
    func roundCreation() {
        let course = Round.CourseInfo(
            name: "测试球场",
            location: "东京",
            numberOfHoles: 18
        )
        
        let round = Round(
            startTime: Date(),
            course: course
        )
        
        #expect(round.course.name == "测试球场")
        #expect(round.totalShots == 0)
        #expect(round.isInProgress)
        #expect(!round.isCompleted)
    }
    
    @Test("Round can manage shots")
    func roundShotManagement() {
        let course = Round.CourseInfo(name: "测试球场")
        var round = Round(course: course)
        
        let estimate = Shot.InitialEstimate(
            estimatedCarry: Distance(yards: 150),
            estimatedTotal: Distance(yards: 160)
        )
        
        let shot1 = Shot(
            club: .driver,
            startPosition: startPosition,
            startLie: .tee,
            initialEstimate: estimate
        )
        
        let shot2 = Shot(
            club: .iron7,
            startPosition: endPosition,
            startLie: .fairway,
            initialEstimate: estimate
        )
        
        round.addShot(shot1)
        round.addShot(shot2)
        
        #expect(round.totalShots == 2)
        #expect(round.confirmedShots == 0) // 都未确认
        
        // 更新第一杆
        let result = Shot.ActualResult(
            endPosition: endPosition,
            endLie: .fairway,
            measuredTotal: Distance(yards: 155)
        )
        
        let confirmedShot = shot1.withActualResult(result)
        round.updateShot(confirmedShot)
        
        #expect(round.confirmedShots == 1)
    }
    
    @Test("Round can be completed")
    func roundCompletion() {
        let course = Round.CourseInfo(name: "测试球场")
        var round = Round(course: course)
        
        #expect(round.isInProgress)
        #expect(round.endTime == nil)
        
        round.complete()
        
        #expect(round.isCompleted)
        #expect(round.endTime != nil)
        #expect(round.duration != nil)
        #expect(round.duration! > 0)
    }
    
    @Test("Round statistics calculation")
    func roundStatistics() {
        let course = Round.CourseInfo(name: "测试球场")
        var round = Round(course: course)
        
        // 添加几杆
        for i in 0..<5 {
            let estimate = Shot.InitialEstimate(
                estimatedCarry: Distance(yards: Double(100 + i * 20)),
                estimatedTotal: Distance(yards: Double(110 + i * 20))
            )
            
            var shot = Shot(
                club: .iron7,
                startPosition: startPosition,
                startLie: .tee,
                initialEstimate: estimate
            )
            
            // 确认部分击球
            if i < 3 {
                let result = Shot.ActualResult(
                    endPosition: endPosition,
                    endLie: .fairway,
                    measuredTotal: Distance(yards: Double(110 + i * 20))
                )
                shot = shot.withActualResult(result)
            }
            
            round.addShot(shot)
        }
        
        let stats = round.statistics
        
        #expect(stats.totalShots == 5)
        #expect(stats.confirmedShots == 3)
        #expect(stats.averageDistance.yards > 0)
        #expect(stats.longestShot != nil)
        #expect(stats.shortestShot != nil)
        #expect(stats.clubUsage[.iron7] == 5)
    }
}
