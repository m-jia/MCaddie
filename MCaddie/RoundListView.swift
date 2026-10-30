import SwiftUI
import MCaddieCore

/// 回合列表视图 - 展示所有保存的回合
struct RoundListView: View {
    @Environment(\.dataManager) private var dataManager
    @State private var rounds: [Round] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    /// 正在继续记分的回合
    @State private var scoringRound: Round?
    /// 正在修改参数的回合
    @State private var editingRound: Round?
    /// 等待确认删除的回合
    @State private var roundPendingDeletion: Round?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                } else if rounds.isEmpty {
                    emptyStateView
                } else {
                    roundsList
                }
            }
            .navigationTitle("我的回合")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        NewRoundView()
                    } label: {
                        Label("新回合", systemImage: "plus")
                    }
                }
            }
            .task {
                await loadRounds()
            }
            .refreshable {
                await loadRounds()
            }
            .sheet(item: $editingRound) { round in
                EditRoundView(round: round) {
                    Task { await loadRounds() }
                }
                .environment(\.dataManager, dataManager)
            }
            .confirmationDialog(
                "删除此回合？",
                isPresented: Binding(
                    get: { roundPendingDeletion != nil },
                    set: { if !$0 { roundPendingDeletion = nil } }
                ),
                titleVisibility: .visible,
                presenting: roundPendingDeletion
            ) { round in
                Button("删除", role: .destructive) { deleteRound(round) }
                Button("取消", role: .cancel) {}
            } message: { round in
                Text("\(round.course.name) 的所有记分将被删除，无法恢复。")
            }
            .fullScreenCover(item: $scoringRound, onDismiss: {
                Task { await loadRounds() }
            }) { round in
                HoleScoringView(round: round)
                    .environment(\.dataManager, dataManager)
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.golf")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.secondary)
            
            Text("还没有回合记录")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("点击右上角的 + 号开始新回合")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink {
                NewRoundView()
            } label: {
                Label("开始新回合", systemImage: "play.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var roundsList: some View {
        List {
            ForEach(rounds) { round in
                Group {
                    if round.isInProgress || round.isCompleted {
                        // 进行中的回合回到尚未记分的洞继续记录；已完成的回合可以修改记分
                        Button {
                            scoringRound = round
                        } label: {
                            HStack {
                                RoundRowView(round: round)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .foregroundStyle(.primary)
                    } else {
                        NavigationLink {
                            RoundDetailView(round: round)
                        } label: {
                            RoundRowView(round: round)
                        }
                    }
                }
                // 向右滑动：删除、修改回合参数
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        roundPendingDeletion = round
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .tint(.red)

                    Button {
                        editingRound = round
                    } label: {
                        Label("修改", systemImage: "slider.horizontal.3")
                    }
                    .tint(.blue)
                }
            }
        }
    }
    
    private func loadRounds() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let manager = dataManager else {
            errorMessage = "数据管理器未初始化"
            return
        }
        
        do {
            rounds = try manager.fetchAllRounds()
        } catch {
            errorMessage = "加载回合失败: \(error.localizedDescription)"
        }
    }
    
    private func deleteRound(_ round: Round) {
        guard let manager = dataManager else { return }
        
        do {
            try manager.deleteRound(id: round.id)
            rounds.removeAll { $0.id == round.id }
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
    }
}

/// 回合行视图
struct RoundRowView: View {
    let round: Round
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(round.course.name)
                    .font(.headline)
                
                Spacer()
                
                statusBadge
            }
            
            Label(scoreSummary, systemImage: "figure.golf")
                .font(.subheadline)
                .foregroundStyle(round.holeScores.isEmpty ? .secondary : .primary)
            
            HStack(spacing: 16) {
                Label(
                    formattedDate,
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if let progress = holeProgress {
                    Label(progress, systemImage: "flag")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            if let location = round.course.location {
                Text(location)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        Group {
            switch round.status {
            case .inProgress:
                Text("进行中")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            case .completed:
                Text("已完成")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            case .abandoned:
                Text("已放弃")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(8)
            case .paused:
                Text("已暂停")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
    }
    
    /// 已记录的杆数和对应洞的标准杆，如 "42 杆 · Par 36 · +6"
    private var scoreSummary: String {
        guard round.holeScores.contains(where: \.isScored) else { return "未记分" }
        return "\(round.totalStrokes) 杆 · Par \(round.scoredPar) · \(HoleScoringView.formatToPar(round.scoreToPar))"
    }
    
    /// 进行中回合的进度，如"第 5 洞"
    private var holeProgress: String? {
        guard round.isInProgress else { return nil }
        if let next = round.nextHoleToScore {
            return "第 \(next) 洞"
        }
        return "已打完 \(round.course.numberOfHoles) 洞"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: round.startTime)
    }
}

#Preview {
    RoundListView()
        .dataManager(try! DataManager.preview())
}

#Preview("New Round") {
    NewRoundView()
        .dataManager(try! DataManager.preview())
}
