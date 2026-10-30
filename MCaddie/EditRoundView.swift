import SwiftUI
import MCaddieCore

/// 修改回合参数：球场不可修改，可以修改洞数和 Tee 台
struct EditRoundView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager

    let round: Round
    /// 保存成功后回调
    var onSaved: () -> Void = {}

    @State private var numberOfHoles: Int
    @State private var courseID: String?
    @State private var availableTees: [TeeInfo] = []
    @State private var selectedTee: TeeInfo?
    @State private var isFetchingTee = false
    @State private var fetchTeeError: String?
    @State private var showingTeeSelection = false
    @State private var errorMessage: String?

    init(round: Round, onSaved: @escaping () -> Void = {}) {
        self.round = round
        self.onSaved = onSaved
        _numberOfHoles = State(initialValue: round.course.numberOfHoles)
        _courseID = State(initialValue: round.course.externalCourseID)
    }

    /// 当前回合原本的 Tee 台 ID（与 TeeInfo.id 的组成方式一致）
    private var originalTeeID: String? {
        guard let name = round.course.teeName, let gender = round.course.teeGender else { return nil }
        return name + "_" + gender
    }

    /// 减少洞数后会被删除记分的洞号
    private var holesToDrop: [Int] {
        round.holeScores.filter { $0.isScored && $0.holeNumber > numberOfHoles }.map(\.holeNumber)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("球场", value: round.course.name)
                    if let location = round.course.location {
                        LabeledContent("城市或地区", value: location)
                    }
                    Picker("球洞数", selection: $numberOfHoles) {
                        Text("9 洞").tag(9)
                        Text("18 洞").tag(18)
                    }
                } header: {
                    Text("球场信息")
                } footer: {
                    if let first = holesToDrop.first, let last = holesToDrop.last {
                        Text("保存后将删除第 \(first)–\(last) 洞的记分。")
                            .foregroundStyle(.red)
                    } else {
                        Text("球场不可修改。")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        if let tee = selectedTee {
                            Text("名称: \(tee.teeName)")
                            if let yards = tee.displayTotalYards {
                                Text("总长: \(yards) 码")
                            }
                            Text("性别: \(tee.gender)")
                        } else if let name = round.course.teeName {
                            Text("名称: \(name)")
                        } else {
                            Text("未选择 Tee 台")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(isFetchingTee ? "加载 Tee 台中..." : "更改 Tee 台") {
                        showingTeeSelection = true
                    }
                    .disabled(isFetchingTee || courseID == nil)
                } header: {
                    Text("Tee 台")
                } footer: {
                    if let fetchTeeError {
                        Text(fetchTeeError)
                    } else {
                        Text("更改 Tee 台会更新各洞的标准杆和码数，已记录的杆数不变。")
                    }
                }
            }
            .navigationTitle("修改回合")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(isFetchingTee)
                }
            }
            .sheet(isPresented: $showingTeeSelection) {
                TeeSelectionList(
                    tees: availableTees,
                    isLoading: isFetchingTee,
                    selectedID: selectedTee?.id,
                    onSelect: { tee in
                        selectedTee = tee
                        showingTeeSelection = false
                    },
                    onCancel: { showingTeeSelection = false }
                )
            }
            .alert("保存失败", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task { await loadTees() }
        }
    }

    // MARK: - 操作

    /// 加载该球场的 Tee 台，并选中回合原本使用的 Tee 台
    private func loadTees() async {
        isFetchingTee = true
        defer { isFetchingTee = false }

        do {
            // 旧回合没有保存球场 ID 时，按球场名称查找
            if courseID == nil {
                courseID = try await GolfCourseAPI.findCourseID(named: round.course.name)
            }
            guard let courseID else {
                fetchTeeError = "在球场数据库中找不到该球场，只能修改洞数。"
                return
            }
            availableTees = try await GolfCourseAPI.fetchTees(courseID: courseID)
            selectedTee = availableTees.first { $0.id == originalTeeID }
        } catch {
            print("❌ 加载 Tee 台失败: \(error)")
            fetchTeeError = "加载 Tee 台失败，目前只能修改洞数。"
        }
    }

    private func save() {
        guard let manager = dataManager else {
            errorMessage = "数据管理器未初始化"
            return
        }

        // 有 Tee 台数据时以其为准；否则沿用回合原有的球洞数据
        let holes = selectedTee?.makeHoles(count: numberOfHoles)
            ?? round.course.holes.map { Hole.fitting($0, toCount: numberOfHoles) }

        var updated = round
        updated.reconfigure(
            numberOfHoles: numberOfHoles,
            holes: holes?.isEmpty == false ? holes : nil,
            teeName: selectedTee?.teeName ?? round.course.teeName,
            teeGender: selectedTee?.gender ?? round.course.teeGender,
            externalCourseID: courseID
        )

        do {
            try manager.updateRound(updated)
            onSaved()
            dismiss()
        } catch {
            errorMessage = "无法保存：\(error.localizedDescription)"
        }
    }
}

#Preview {
    EditRoundView(round: Round(course: Round.CourseInfo(name: "示例球场", location: "Coquitlam, BC", numberOfHoles: 9)))
        .dataManager(try! DataManager.preview())
}
