import Testing
import Foundation
@testable import MCaddieCore

@Suite("Distance Tests")
struct DistanceTests {
    
    @Test("Distance conversion between yards and meters")
    func distanceConversion() {
        let distance = Distance(yards: 100)
        #expect(abs(distance.meters - 91.44) < 0.01, "100 yards should be approximately 91.44 meters")
        
        let distanceFromMeters = Distance(meters: 91.44)
        #expect(abs(distanceFromMeters.yards - 100) < 0.01, "91.44 meters should be approximately 100 yards")
    }
    
    @Test("ClubPerformance stores carry and total separately")
    func clubPerformanceCarryAndTotal() {
        let driver = ClubPerformance(
            clubType: .driver,
            averageCarry: Distance(yards: 180),
            averageTotal: Distance(yards: 200),
            swingSpeedMPH: 77.5
        )
        
        #expect(driver.averageCarry.yards == 180)
        #expect(driver.averageTotal.yards == 200)
        #expect(driver.swingSpeedMPH == 77.5)
    }
    
    @Test("Distance calculator computes approximate distance")
    func distanceCalculation() {
        // 测试两个已知距离的点（约 111 km 的纬度差）
        let point1 = (latitude: 0.0, longitude: 0.0)
        let point2 = (latitude: 1.0, longitude: 0.0)
        
        let distance = DistanceCalculator.distance(from: point1, to: point2)
        
        // 1 度纬度约 111 km = 111000 m ≈ 121,391 yards
        #expect(distance.yards > 121000, "Distance should be approximately 121,391 yards")
        #expect(distance.yards < 122000, "Distance should be approximately 121,391 yards")
    }
}
