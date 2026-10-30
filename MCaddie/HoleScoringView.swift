import SwiftUI
import MCaddieCore

/// 逐洞记分视图：从第一个未记分的洞开始，依次进入后面的洞
struct HoleScoringView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager

    @State private var round: Round
    @State private var currentHole: Int
    @State private var draft: HoleScore
    @State private var errorMessage: String?

    init(round: Round) {
        // 已完成的回合从第 1 洞开始修改；进行中的回合从第一个未记分的洞继续，
        // 全部记完但未结束回合时停在最后一洞
        let firstUnscored = round.isCompleted
            ? 1
            : round.nextHoleToScore ?? max(1, round.course.numberOfHoles)
        _round = State(initialValue: round)
        _currentHole = State(initialValue: firstUnscored)
        _draft = State(initialValue: round.holeScore(forHole: firstUnscored))
    }

    private var isLastHole: Bool {
        currentHole >= round.course.numberOfHoles
    }

    /// 最后一洞的按钮文字；修改已完成的回合时只保存
    private var lastHoleButtonTitle: String? {
        guard isLastHole else { return nil }
        return round.isCompleted ? "保存" : "结束回合"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    holeHeader
                    strokesSection
                    puttsSection
                    if draft.tracksFairway {
                        discSection(title: "Fairway Hit", centerLabel: "FH", selection: autoFilling(\.fairway, trigger: .fairway))
                    }
                    discSection(title: "Green in Regulation", centerLabel: "GIR", selection: $draft.green)
                    troubleShotsSection
                    recoverySection
                    sandSaveSection
                    upAndDownSection
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) { navigationBar }
            .navigationTitle(round.course.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // 总是保存后退出，回合保持进行中
                    Button("退出") {
                        if commitDraft() { dismiss() }
                    }
                }
            }
            .alert("保存失败", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - 洞信息

    private var holeHeader: some View {
        let hole = round.course.holes?.first { $0.number == currentHole }
        return VStack(spacing: 6) {
            Text("第 \(currentHole) 洞")
                .font(.largeTitle.bold())
            HStack(spacing: 12) {
                Text("Par \(draft.par)")
                if let yards = hole?.distance.yards, yards > 0 {
                    Text("\(Int(yards.rounded())) 码")
                }
                if let handicap = hole?.handicap {
                    Text("难度 \(handicap)")
                }
            }
            .font(.headline)
            .foregroundStyle(.secondary)

            if !round.holeScores.isEmpty {
                Text("已打 \(round.holeScores.filter(\.isScored).count) 洞 · 总杆 \(round.totalStrokes) · \(Self.formatToPar(round.scoreToPar))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 总杆数

    private var strokesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("总杆数", value: draft.strokes.map { "\($0) · \(ScoreType(strokes: $0, par: draft.par).displayName)" })
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(Array(draft.strokeOptions), id: \.self) { strokes in
                    let type = ScoreType(strokes: strokes, par: draft.par)
                    let isSelected = draft.strokes == strokes
                    Button {
                        selectStrokes(strokes)
                    } label: {
                        ScoreBadge(
                            text: "\(strokes)",
                            appearance: ScoreAppearance(toPar: strokes - draft.par),
                            isSelected: isSelected
                        )
                        .frame(width: 52, height: 52)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(strokes) 杆，\(type.displayName)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - 推杆数

    private var puttsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("推杆数", value: draft.putts.map(Self.puttsLabel))
            ChoiceRow(
                options: Array(0...HoleScore.maxPuttsOption),
                selection: autoFilling(\.putts, trigger: .putts),
                label: Self.puttsLabel,
                style: Self.puttStyle,
                // 推杆数不能超过总杆数
                isDisabled: { putts in draft.strokes.map { putts > $0 } ?? false }
            )
        }
    }

    /// 0、1 淡绿；2 绿；3 橙；4+ 红
    private static func puttStyle(_ putts: Int) -> ChoiceStyle {
        switch putts {
        case ...1: return ChoiceStyle(fill: ScoreAppearance.lightGreen, selectedText: ScoreAppearance.darkGreen)
        case 2: return ChoiceStyle(fill: .green)
        case 3: return ChoiceStyle(fill: .orange)
        default: return ChoiceStyle(fill: .red)
        }
    }

    // MARK: - 其他统计

    /// Trouble Shot 缺省为 0，不可清空
    private var troubleShotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Trouble Shot", value: Self.troubleShotsLabel(draft.troubleShots))
            ChoiceRow(
                options: Array(0...HoleScore.maxTroubleShotsOption),
                selection: Binding(
                    get: { draft.troubleShots },
                    set: { draft.troubleShots = $0 ?? 0 }
                ),
                label: Self.troubleShotsLabel
            )
        }
    }

    private var recoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Recovery", value: draft.recovery?.label)
            ChoiceRow(options: RecoveryResult.allCases, selection: $draft.recovery, label: \.label)
        }
    }

    private var sandSaveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Sand Save", value: draft.sandSave?.label)
            ChoiceRow(options: SandSaveResult.allCases, selection: $draft.sandSave, label: \.label)
        }
    }

    private var upAndDownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Up & Down", value: draft.upAndDown?.label)
            ChoiceRow(options: UpAndDownResult.allCases, selection: $draft.upAndDown, label: \.label)
        }
    }

    // MARK: - FH / GIR

    private func discSection(title: String, centerLabel: String, selection: Binding<TargetResult?>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title, value: selection.wrappedValue?.label(hitLabel: centerLabel))
            TargetDiscView(selection: selection, centerLabel: centerLabel)
                .frame(maxWidth: .infinity)
        }
    }

    /// 项目标题，右侧显示当前所选的值，未选择时显示"未选"
    private func sectionTitle(_ title: String, value: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value ?? "未选")
                .font(.subheadline.weight(value == nil ? .regular : .semibold))
                .foregroundStyle(value == nil ? Color.secondary : Color.accentColor)
            Spacer()
        }
    }

    private static func puttsLabel(_ putts: Int) -> String {
        putts == HoleScore.maxPuttsOption ? "\(putts)+" : "\(putts)"
    }

    private static func troubleShotsLabel(_ count: Int) -> String {
        count == HoleScore.maxTroubleShotsOption ? "\(count)+" : "\(count)"
    }

    // MARK: - 底部导航

    private var navigationBar: some View {
        HStack(spacing: 12) {
            Button {
                goToHole(currentHole - 1)
            } label: {
                Label("上一洞", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(currentHole <= 1)

            Button {
                if isLastHole {
                    finishRound()
                } else {
                    goToHole(currentHole + 1)
                }
            } label: {
                Label(lastHoleButtonTitle ?? "下一洞",
                      systemImage: isLastHole ? "checkmark" : "chevron.right")
                    .labelStyle(TrailingIconLabelStyle())
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!draft.isScored)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - 操作

    /// 再次点击已选的杆数会取消选择
    private func selectStrokes(_ strokes: Int) {
        guard draft.strokes != strokes else {
            draft.strokes = nil
            return
        }
        draft.strokes = strokes
        if let putts = draft.putts, putts > strokes {
            draft.putts = nil
        }
        draft.autoFill(after: .strokes)
    }

    /// 修改该项后，按规则自动推算其他项目（仅 Par 和 +1 时生效）
    private func autoFilling<Value>(
        _ keyPath: WritableKeyPath<HoleScore, Value>,
        trigger: HoleScore.AutoFillTrigger
    ) -> Binding<Value> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { newValue in
                draft[keyPath: keyPath] = newValue
                draft.autoFill(after: trigger)
            }
        )
    }

    private func goToHole(_ number: Int) {
        guard (1...round.course.numberOfHoles).contains(number), commitDraft() else { return }
        currentHole = number
        draft = round.holeScore(forHole: number)
    }

    private func finishRound() {
        round.setHoleScore(draft)
        // 修改已完成的回合时保留原结束时间
        if !round.isCompleted {
            round.complete()
        }
        if persist() { dismiss() }
    }

    /// 把当前洞写入回合并保存到本地；未录入杆数的洞不保存
    @discardableResult
    private func commitDraft() -> Bool {
        guard draft.isScored else { return true }
        round.setHoleScore(draft)
        return persist()
    }

    private func persist() -> Bool {
        guard let manager = dataManager else {
            errorMessage = "数据管理器未初始化"
            return false
        }
        do {
            try manager.updateRound(round)
            return true
        } catch {
            errorMessage = "无法保存记分：\(error.localizedDescription)"
            return false
        }
    }

    static func formatToPar(_ value: Int) -> String {
        value == 0 ? "E" : (value > 0 ? "+\(value)" : "\(value)")
    }
}

/// 文字在前、图标在后的 Label 样式
private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

// MARK: - 成绩类型的显示

extension ScoreType {
    var displayName: String {
        switch self {
        case .eagleOrBetter: return "老鹰"
        case .birdie: return "小鸟"
        case .par: return "Par"
        case .bogey: return "Bogey"
        case .doubleBogey: return "双 Bogey"
        case .tripleBogey: return "+3"
        case .quadrupleBogeyOrWorse: return "+4+"
        }
    }
}

/// 杆数按钮的外观：颜色和边框形状由相对标准杆的杆数决定
/// - 低于标准杆：淡绿色、圆形边框；杆数越少颜色越淡，老鹰及以上边框更粗
/// - Par：绿色
/// - Bogey：淡蓝色、方形边框；双 Bogey：蓝色、更粗的方形边框
/// - +3：橙色；+4 及以上：红色
struct ScoreAppearance {
    enum Border {
        case none
        case circle(lineWidth: CGFloat)
        case square(lineWidth: CGFloat)
    }

    let fill: Color
    let borderColor: Color
    let border: Border
    /// 选中（实心填充）时的文字颜色
    let selectedTextColor: Color

    static let lightGreen = Color(red: 0.45, green: 0.78, blue: 0.45)
    static let darkGreen = Color(red: 0.05, green: 0.3, blue: 0.1)

    init(toPar: Int) {
        switch toPar {
        case ...(-1):
            // -1 最深，每少一杆更淡
            let steps = Double(min(-toPar, 4) - 1)
            let lightness = 0.45 + steps * 0.15
            fill = Color(red: lightness, green: 0.78 + steps * 0.05, blue: lightness)
            borderColor = Color(red: 0.1, green: 0.55, blue: 0.2)
            border = .circle(lineWidth: toPar == -1 ? 1.5 : 3.5)
            selectedTextColor = Self.darkGreen
        case 0:
            fill = .green
            borderColor = .green
            border = .none
            selectedTextColor = .white
        case 1:
            fill = Color(red: 0.6, green: 0.8, blue: 1.0)
            borderColor = .blue
            border = .square(lineWidth: 1.5)
            selectedTextColor = Color(red: 0.05, green: 0.2, blue: 0.5)
        case 2:
            fill = .blue
            borderColor = Color(red: 0.0, green: 0.2, blue: 0.6)
            border = .square(lineWidth: 3.5)
            selectedTextColor = .white
        case 3:
            fill = .orange
            borderColor = .orange
            border = .none
            selectedTextColor = .white
        default:
            fill = .red
            borderColor = .red
            border = .none
            selectedTextColor = .white
        }
    }
}

/// 带记分卡样式（圆形 / 方形边框）的杆数徽章
struct ScoreBadge: View {
    let text: String
    let appearance: ScoreAppearance
    let isSelected: Bool

    var body: some View {
        ZStack {
            background
            Text(text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? appearance.selectedTextColor : .primary)
        }
    }

    @ViewBuilder
    private var background: some View {
        // 未选中时颜色变淡但保留边框形状，选中后实心填充
        let fill = isSelected ? appearance.fill : appearance.fill.opacity(0.3)
        switch appearance.border {
        case .none:
            RoundedRectangle(cornerRadius: 10)
                .fill(fill)
        case .circle(let lineWidth):
            Circle()
                .fill(fill)
                .overlay(Circle().strokeBorder(appearance.borderColor, lineWidth: lineWidth))
        case .square(let lineWidth):
            Rectangle()
                .fill(fill)
                .overlay(Rectangle().strokeBorder(appearance.borderColor, lineWidth: lineWidth))
        }
    }
}

// MARK: - 选项行

/// 选项按钮的颜色
struct ChoiceStyle {
    var fill: Color = .accentColor
    var selectedText: Color = .white
}

/// 一排等宽的单选按钮；再次点击已选项可取消选择
struct ChoiceRow<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option?
    let label: (Option) -> String
    var style: (Option) -> ChoiceStyle = { _ in ChoiceStyle() }
    var isDisabled: (Option) -> Bool = { _ in false }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                let optionStyle = style(option)
                let disabled = isDisabled(option)
                Button {
                    selection = isSelected ? nil : option
                } label: {
                    Text(label(option))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(isSelected ? optionStyle.selectedText : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? optionStyle.fill : optionStyle.fill.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
                .disabled(disabled)
                .opacity(disabled ? 0.35 : 1)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - 统计选项的显示文字

extension TargetResult {
    /// hitLabel 为命中时显示的文字，如 "FH"、"GIR"
    func label(hitLabel: String) -> String {
        switch self {
        case .hit: return hitLabel
        case .missLeft: return "Miss Left"
        case .missRight: return "Miss Right"
        case .missLong: return "Miss Long"
        case .missShort: return "Miss Short"
        }
    }
}

extension RecoveryResult {
    var label: String {
        switch self {
        case .green: return "REC-G"
        case .one: return "REC-1"
        case .two: return "REC-2"
        case .threeOrMore: return "REC-3+"
        }
    }
}

extension SandSaveResult {
    var label: String {
        switch self {
        case .one: return "SS-1"
        case .twoOrMore: return "SS-2+"
        }
    }
}

extension UpAndDownResult {
    var label: String {
        switch self {
        case .ok: return "UD-OK"
        case .one: return "UD-1"
        case .twoOrMore: return "UD-2+"
        }
    }
}

#Preview {
    HoleScoringView(round: Round(course: Round.CourseInfo(name: "示例球场", numberOfHoles: 18)))
}
