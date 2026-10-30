import SwiftUI
import MCaddieCore

/// 击球详情视图
struct ShotDetailView: View {
    let shot: Shot
    let round: Round
    @Environment(\.dataManager) private var dataManager
    
    var body: some View {
        List {
            Section("击球信息") {
                LabeledContent("球杆", value: shot.club.rawValue)
                LabeledContent("起始球位", value: shot.startLie.displayName)
                LabeledContent("时间", value: shot.timestamp.formatted(date: .abbreviated, time: .shortened))
            }
            
            Section("距离估计") {
                LabeledContent("Carry", value: String(format: "%.0f 码", shot.initialEstimate.estimatedCarry.yards))
                LabeledContent("Total", value: String(format: "%.0f 码", shot.initialEstimate.estimatedTotal.yards))
                
                if let direction = shot.initialEstimate.estimatedDirection {
                    LabeledContent("方向", value: String(format: "%.0f°", direction))
                }
                
                if let dictation = shot.initialEstimate.dictationText {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("口述记录")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(dictation)
                            .font(.body)
                    }
                }
            }
            
            if let actualResult = shot.actualResult {
                Section("实际结果") {
                    LabeledContent("终点球位", value: actualResult.endLie.displayName)
                    LabeledContent("实际距离", value: String(format: "%.0f 码", actualResult.measuredTotal.yards))
                    
                    if let carry = actualResult.measuredCarry {
                        LabeledContent("实际 Carry", value: String(format: "%.0f 码", carry.yards))
                    }
                    
                    if let rating = actualResult.performanceRating {
                        LabeledContent("表现评级", value: performanceText(rating))
                    }
                }
                
                if let deviation = shot.totalDistanceDeviation {
                    Section("分析") {
                        HStack {
                            Text("距离偏差")
                            Spacer()
                            Text(String(format: "%.0f 码", deviation.yards))
                                .foregroundStyle(deviation.yards < 10 ? .green : .orange)
                        }
                        
                        // 显示准确度百分比
                        if shot.initialEstimate.estimatedTotal.yards > 0 {
                            let accuracy = (1.0 - deviation.yards / shot.initialEstimate.estimatedTotal.yards) * 100
                            HStack {
                                Text("准确度")
                                Spacer()
                                Text(String(format: "%.0f%%", max(0, accuracy)))
                                    .foregroundStyle(accuracy >= 90 ? .green : accuracy >= 80 ? .orange : .red)
                            }
                        }
                    }
                }
            } else {
                Section {
                    NavigationLink {
                        UpdateShotResultView(shot: shot, round: round)
                    } label: {
                        HStack {
                            Spacer()
                            Label("更新击球结果", systemImage: "location.fill")
                            Spacer()
                        }
                    }
                }
            }
            
            if let notes = shot.notes {
                Section("备注") {
                    Text(notes)
                }
            }
        }
        .navigationTitle("击球详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performanceText(_ rating: Shot.PerformanceRating) -> String {
        switch rating {
        case .excellent: return "非常好 ⭐️⭐️⭐️"
        case .good: return "好 ⭐️⭐️"
        case .average: return "一般 ⭐️"
        case .poor: return "不理想"
        case .mistake: return "失误"
        }
    }
}

#Preview {
    NavigationStack {
        ShotDetailView(
            shot: Shot(
                club: .iron7,
                startPosition: PositionObservation(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    horizontalAccuracy: 5.0,
                    source: .gps
                ),
                startLie: .fairway,
                initialEstimate: Shot.InitialEstimate(
                    estimatedCarry: Distance(yards: 150),
                    estimatedTotal: Distance(yards: 160),
                    dictationText: "7号铁，向右偏"
                )
            ),
            round: Round(
                course: Round.CourseInfo(name: "测试球场", numberOfHoles: 18)
            )
        )
    }
}
