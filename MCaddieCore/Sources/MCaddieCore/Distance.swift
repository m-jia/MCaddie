import Foundation

/// 距离单位：内部统一使用码(yards)
/// 根据 ARCHITECTURE.md 要求，必须区分 carry 和 total
public struct Distance: Equatable, Codable, Sendable, Hashable {
    public let yards: Double
    
    public init(yards: Double) {
        self.yards = yards
    }
    
    public init(meters: Double) {
        self.yards = meters * 1.09361
    }
    
    public var meters: Double {
        yards / 1.09361
    }
}

/// 球杆类型
public enum ClubType: String, Codable, CaseIterable, Sendable {
    case driver
    case wood3
    case wood5
    case hybrid
    case iron3
    case iron4
    case iron5
    case iron6
    case iron7
    case iron8
    case iron9
    case pitchingWedge
    case gapWedge
    case sandWedge
    case lobWedge
    case putter
}

/// 球杆距离性能（区分 carry 和 total）
public struct ClubPerformance: Codable, Equatable, Sendable {
    public let clubType: ClubType
    public let averageCarry: Distance
    public let averageTotal: Distance
    public let swingSpeedMPH: Double?
    
    public init(
        clubType: ClubType,
        averageCarry: Distance,
        averageTotal: Distance,
        swingSpeedMPH: Double? = nil
    ) {
        self.clubType = clubType
        self.averageCarry = averageCarry
        self.averageTotal = averageTotal
        self.swingSpeedMPH = swingSpeedMPH
    }
}

/// 简单的距离计算工具
public struct DistanceCalculator {
    
    public init() {}
    
    /// 计算两点之间的直线距离（使用 Haversine 公式）
    public static func distance(
        from: (latitude: Double, longitude: Double),
        to: (latitude: Double, longitude: Double)
    ) -> Distance {
        let lat1Rad = from.latitude * .pi / 180
        let lat2Rad = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        let earthRadiusMeters = 6371000.0
        let meters = earthRadiusMeters * c
        
        return Distance(meters: meters)
    }
}
