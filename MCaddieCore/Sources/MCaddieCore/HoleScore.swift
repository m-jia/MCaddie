import Foundation

/// 单洞记分
/// 每洞一条记录，以 holeNumber 区分；未填写的项目为 nil
public struct HoleScore: Codable, Equatable, Sendable, Hashable {
    /// 球洞号（从 1 开始）
    public let holeNumber: Int

    /// 该洞标准杆（修改回合的洞数或 Tee 台时可能更新）
    public var par: Int

    /// 总杆数
    public var strokes: Int?

    /// 推杆数
    public var putts: Int?

    /// 开球上球道情况（Par 3 通常不记录）
    public var fairway: TargetResult?

    /// 标准杆上果岭情况
    public var green: TargetResult?

    /// 麻烦球杆数（0 到 3，3 表示 "3+"）
    public var troubleShots: Int

    /// 救球结果
    public var recovery: RecoveryResult?

    /// 沙坑救球结果
    public var sandSave: SandSaveResult?

    /// Up & Down 结果
    public var upAndDown: UpAndDownResult?

    public init(
        holeNumber: Int,
        par: Int,
        strokes: Int? = nil,
        putts: Int? = nil,
        fairway: TargetResult? = nil,
        green: TargetResult? = nil,
        troubleShots: Int = 0,
        recovery: RecoveryResult? = nil,
        sandSave: SandSaveResult? = nil,
        upAndDown: UpAndDownResult? = nil
    ) {
        self.holeNumber = holeNumber
        self.par = par
        self.strokes = strokes
        self.putts = putts
        self.fairway = fairway
        self.green = green
        self.troubleShots = troubleShots
        self.recovery = recovery
        self.sandSave = sandSave
        self.upAndDown = upAndDown
    }

    /// 兼容旧数据：缺少的新字段使用缺省值
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        holeNumber = try container.decode(Int.self, forKey: .holeNumber)
        par = try container.decode(Int.self, forKey: .par)
        strokes = try container.decodeIfPresent(Int.self, forKey: .strokes)
        putts = try container.decodeIfPresent(Int.self, forKey: .putts)
        fairway = try container.decodeIfPresent(TargetResult.self, forKey: .fairway)
        green = try container.decodeIfPresent(TargetResult.self, forKey: .green)
        troubleShots = try container.decodeIfPresent(Int.self, forKey: .troubleShots) ?? 0
        recovery = try container.decodeIfPresent(RecoveryResult.self, forKey: .recovery)
        sandSave = try container.decodeIfPresent(SandSaveResult.self, forKey: .sandSave)
        upAndDown = try container.decodeIfPresent(UpAndDownResult.self, forKey: .upAndDown)
    }

    /// 可选的总杆数范围：1 到 2N+1（N 为标准杆）
    public var strokeOptions: ClosedRange<Int> {
        1...(2 * par + 1)
    }

    /// 推杆数的上限，界面上显示为 "4+"
    public static let maxPuttsOption = 4

    /// 麻烦球杆数的上限，界面上显示为 "3+"
    public static let maxTroubleShotsOption = 3

    /// 成绩类型（未录入杆数时为 nil）
    public var scoreType: ScoreType? {
        strokes.map { ScoreType(strokes: $0, par: par) }
    }

    /// 是否已录入杆数（视为该洞已完成）
    public var isScored: Bool {
        strokes != nil
    }

    /// 是否需要记录 Fairway Hit（Par 3 不需要）
    public var tracksFairway: Bool {
        par > 3
    }
}

/// 击球目标结果：命中，或偏离的方向
/// 同时用于 Fairway Hit 和 Green in Regulation
public enum TargetResult: String, Codable, CaseIterable, Sendable, Hashable {
    case hit
    case missLeft
    case missRight
    case missLong
    case missShort
}

/// 救球结果（REC-G / REC-1 / REC-2 / REC-3+）
public enum RecoveryResult: String, Codable, CaseIterable, Sendable, Hashable {
    case green
    case one
    case two
    case threeOrMore
}

/// 沙坑救球结果（SS-1 / SS-2+）
public enum SandSaveResult: String, Codable, CaseIterable, Sendable, Hashable {
    case one
    case twoOrMore
}

/// Up & Down 结果（UD-OK / UD-1 / UD-2+）
public enum UpAndDownResult: String, Codable, CaseIterable, Sendable, Hashable {
    case ok
    case one
    case twoOrMore
}

/// 相对标准杆的成绩类型
public enum ScoreType: String, Codable, CaseIterable, Sendable, Hashable {
    /// 低于标准杆 2 杆或更多
    case eagleOrBetter
    case birdie
    case par
    case bogey
    case doubleBogey
    case tripleBogey
    /// 高于标准杆 4 杆或更多
    case quadrupleBogeyOrWorse

    public init(strokes: Int, par: Int) {
        switch strokes - par {
        case ...(-2): self = .eagleOrBetter
        case -1: self = .birdie
        case 0: self = .par
        case 1: self = .bogey
        case 2: self = .doubleBogey
        case 3: self = .tripleBogey
        default: self = .quadrupleBogeyOrWorse
        }
    }
}

// MARK: - 自动填写

extension HoleScore {
    /// 触发自动填写的用户操作
    public enum AutoFillTrigger: Sendable {
        case strokes
        case putts
        case fairway
    }

    /// 是否对当前杆数启用自动填写（Par 和 +1）
    public var isAutoFillEnabled: Bool {
        guard let strokes else { return false }
        return (0...1).contains(strokes - par)
    }

    /// 根据总杆数、推杆数和 FH 推算其他项目，用户之后仍可手动修改
    ///
    /// 仅在杆数为 Par 或 +1 时生效：
    /// - 选择杆数后：推杆缺省为 2，FH 缺省为命中（Par 3 不记录 FH）
    /// - GIR：上果岭用杆（总杆 − 推杆）≤ Par − 2 即为命中；否则取消"命中"，保留用户选的偏离方向
    /// - Up & Down（仅未上 GIR 时）：推杆 ≤ 1 为 UD-OK，2 为 UD-1，3 及以上为 UD-2+
    /// - Recovery（仅 FH 偏离时）：GIR 命中为 REC-G，否则按晚上果岭的杆数为 REC-1 / REC-2 / REC-3+
    public mutating func autoFill(after trigger: AutoFillTrigger) {
        guard isAutoFillEnabled, let strokes else { return }

        if trigger == .strokes {
            if putts == nil {
                putts = min(2, strokes)
            }
            if tracksFairway && fairway == nil {
                fairway = .hit
            }
        }

        guard let putts else { return }

        // 比标准上果岭用杆多出的杆数，≤ 0 表示 GIR
        let strokesLate = (strokes - putts) - (par - 2)
        let isGIR = strokesLate <= 0

        if isGIR {
            green = .hit
            upAndDown = nil
        } else {
            if green == .hit { green = nil }
            switch putts {
            case ...1: upAndDown = .ok
            case 2: upAndDown = .one
            default: upAndDown = .twoOrMore
            }
        }

        if let fairway, fairway != .hit {
            switch strokesLate {
            case ...0: recovery = .green
            case 1: recovery = .one
            case 2: recovery = .two
            default: recovery = .threeOrMore
            }
        } else if trigger == .fairway {
            // FH 改为命中或取消时，之前推算的 Recovery 不再成立
            recovery = nil
        }
    }
}
