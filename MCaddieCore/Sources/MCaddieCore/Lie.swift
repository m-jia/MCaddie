import Foundation

/// 球位分类
/// 根据 ARCHITECTURE.md：Lie 包含球的位置和状态信息
public enum Lie: String, Codable, CaseIterable, Sendable {
    /// 发球台
    case tee
    
    /// 球道
    case fairway
    
    /// 长草区（浅）
    case firstCut
    
    /// 长草区（深）
    case roughDeep
    
    /// 沙坑
    case bunker
    
    /// 果岭
    case green
    
    /// 水障碍区（内）
    case waterHazard
    
    /// 树林/灌木
    case trees
    
    /// 其他（未分类）
    case other
    
    /// 人类可读的描述
    public var displayName: String {
        switch self {
        case .tee: return "发球台"
        case .fairway: return "球道"
        case .firstCut: return "浅草区"
        case .roughDeep: return "深草区"
        case .bunker: return "沙坑"
        case .green: return "果岭"
        case .waterHazard: return "水障碍"
        case .trees: return "树林"
        case .other: return "其他"
        }
    }
    
    /// 难度系数（用于后续决策算法）
    public var difficultyCoefficent: Double {
        switch self {
        case .tee: return 1.0
        case .fairway: return 1.0
        case .firstCut: return 1.1
        case .roughDeep: return 1.3
        case .bunker: return 1.4
        case .green: return 0.5
        case .waterHazard: return 2.0
        case .trees: return 1.5
        case .other: return 1.2
        }
    }
}
