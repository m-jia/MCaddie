import SwiftUI
import MCaddieCore

/// 回合详情视图
struct RoundDetailView: View {
    let round: Round
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager
    @State private var shots: [Shot] = []
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        List {
            Section("回合信息") {
                LabeledContent("球场", value: round.course.name)
                if let location = round.course.location {
                    LabeledContent("城市/地区", value: location)
                }
                LabeledContent("球洞数", value: "\(round.course.numberOfHoles)")
                LabeledContent("状态", value: statusText)
                LabeledContent("总击球数", value: "\(round.totalShots)")
                
                if let endTime = round.endTime {
                    LabeledContent("完成时间", value: endTime.formatted(date: .abbreviated, time: .shortened))
                }
            }
            
            Section("击球记录") {
                if shots.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.golf")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("暂无击球记录")
                            .foregroundStyle(.secondary)
                        
                        NavigationLink {
                            RecordShotView(round: round)
                        } label: {
                            Label("记录第一杆", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                } else {
                    ForEach(shots) { shot in
                        NavigationLink {
                            ShotDetailView(shot: shot, round: round)
                        } label: {
                            ShotRowView(shot: shot)
                        }
                    }
                }
            }
            
            if !shots.isEmpty {
                Section("统计") {
                    let stats = round.statistics
                    LabeledContent("平均距离", value: String(format: "%.1f 码", stats.averageDistance.yards))
                    if let longest = stats.longestShot {
                        LabeledContent("最长击球", value: String(format: "%.1f 码", longest.yards))
                    }
                    if let shortest = stats.shortestShot {
                        LabeledContent("最短击球", value: String(format: "%.1f 码", shortest.yards))
                    }
                }
            }
            
            Section {
                Button(role: .destructive, action: { showDeleteAlert = true }) {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Label("删除此回合", systemImage: "trash")
                        }
                        Spacer()
                    }
                }
                .disabled(isDeleting)
            }
        }
        .navigationTitle("回合详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if round.status == .inProgress && !shots.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        RecordShotView(round: round)
                    } label: {
                        Label("记录击球", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .task {
            await loadShots()
        }
        .refreshable {
            await loadShots()
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteRound()
            }
        } message: {
            Text("确定要删除这个回合吗？这将同时删除所有击球记录，此操作无法撤销。")
        }
    }
    
    private var statusText: String {
        switch round.status {
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .abandoned: return "已放弃"
        case .paused: return "已暂停"
        }
    }
    
    private func loadShots() async {
        guard let manager = dataManager else { return }
        
        do {
            shots = try manager.fetchShots(forRoundID: round.id)
        } catch {
            print("加载击球记录失败: \(error)")
        }
    }
    
    private func deleteRound() {
        guard let manager = dataManager else { return }
        
        isDeleting = true
        
        Task {
            do {
                try manager.deleteRound(id: round.id)
                
                // 删除成功，返回上一页
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("删除失败: \(error)")
                isDeleting = false
            }
        }
    }
}

/// 击球行视图（用于列表）
struct ShotRowView: View {
    let shot: Shot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(shot.club.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "%.0f 码", shot.finalTotalDistance.yards))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label(shot.startLie.displayName, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if shot.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RoundDetailView(
            round: Round(
                course: Round.CourseInfo(
                    name: "春城湖畔高尔夫球场",
                    location: "昆明",
                    numberOfHoles: 18
                ),
                status: .inProgress
            )
        )
    }
    .dataManager(try! DataManager.preview())
}
