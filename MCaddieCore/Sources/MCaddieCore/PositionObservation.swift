import Foundation

/// 位置观测
/// 根据 ARCHITECTURE.md：PositionObservation 是独立的观测记录，
/// 包含 GPS 坐标、精度、时间戳和来源标记
public struct PositionObservation: Codable, Equatable, Sendable, Hashable {
    /// 观测的唯一标识符
    public let id: UUID
    
    /// 纬度（度）
    public let latitude: Double
    
    /// 经度（度）
    public let longitude: Double
    
    /// 海拔高度（米），可选
    public let altitude: Double?
    
    /// 水平精度（米）
    public let horizontalAccuracy: Double
    
    /// 垂直精度（米），可选
    public let verticalAccuracy: Double?
    
    /// 观测时间戳
    public let timestamp: Date
    
    /// 观测来源
    public let source: PositionSource
    
    /// 位置来源类型
    public enum PositionSource: String, Codable, Sendable {
        /// GPS 自动定位
        case gps
        
        /// 用户手动标记
        case manual
        
        /// 从地图选择
        case mapSelection
        
        /// 从球场数据库
        case courseDatabase
    }
    
    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double,
        verticalAccuracy: Double? = nil,
        timestamp: Date = Date(),
        source: PositionSource
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        self.source = source
    }
    
    /// 计算到另一个位置的距离
    public func distance(to other: PositionObservation) -> Distance {
        DistanceCalculator.distance(
            from: (latitude: self.latitude, longitude: self.longitude),
            to: (latitude: other.latitude, longitude: other.longitude)
        )
    }
    
    /// 位置精度是否足够可靠（小于 10 米）
    public var isReliable: Bool {
        horizontalAccuracy < 10.0
    }
    
    /// 位置精度是否高精度（小于 5 米）
    public var isHighPrecision: Bool {
        horizontalAccuracy < 5.0
    }
}
