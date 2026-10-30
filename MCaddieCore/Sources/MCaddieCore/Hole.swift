import Foundation

/// 球洞信息
/// 根据 ARCHITECTURE.md：Hole 包含球洞的基本信息和标准杆数
public struct Hole: Codable, Equatable, Identifiable, Sendable, Hashable {
    /// 球洞唯一标识符
    public let id: UUID
    
    /// 球洞号（1-18）
    public let number: Int
    
    /// 标准杆
    public let par: Int
    
    /// 从指定发球台到果岭的距离
    public let distance: Distance
    
    /// 发球台位置（可选）
    public let teePosition: PositionObservation?
    
    /// 果岭中心位置（可选）
    public let greenPosition: PositionObservation?
    
    /// 球洞描述（可选）
    public let description: String?
    
    /// 难度等级（1-5，5 最难）
    public let handicap: Int?
    
    public init(
        id: UUID = UUID(),
        number: Int,
        par: Int,
        distance: Distance,
        teePosition: PositionObservation? = nil,
        greenPosition: PositionObservation? = nil,
        description: String? = nil,
        handicap: Int? = nil
    ) {
        self.id = id
        self.number = number
        self.par = par
        self.distance = distance
        self.teePosition = teePosition
        self.greenPosition = greenPosition
        self.description = description
        self.handicap = handicap
    }
    
    /// 把球场数据调整为用户选择的洞数：
    /// 多于所需时只取前 count 个洞；少于所需时循环重复（如 9 洞球场打 18 洞）
    /// 返回的球洞按 1...count 重新编号
    public static func fitting(_ holes: [Hole], toCount count: Int) -> [Hole] {
        guard !holes.isEmpty, count > 0 else { return [] }
        let source = holes.sorted { $0.number < $1.number }
        return (0..<count).map { index in
            let hole = source[index % source.count]
            return Hole(
                number: index + 1,
                par: hole.par,
                distance: hole.distance,
                teePosition: hole.teePosition,
                greenPosition: hole.greenPosition,
                description: hole.description,
                handicap: hole.handicap
            )
        }
    }
    
    /// 球洞分类
    public var holeType: HoleType {
        switch par {
        case 3: return .par3
        case 4: return .par4
        case 5: return .par5
        default: return .other
        }
    }
    
    /// 球洞类型
    public enum HoleType: String, Codable, Sendable {
        case par3
        case par4
        case par5
        case other
        
        public var displayName: String {
            switch self {
            case .par3: return "Par 3"
            case .par4: return "Par 4"
            case .par5: return "Par 5"
            case .other: return "Other"
            }
        }
    }
}
