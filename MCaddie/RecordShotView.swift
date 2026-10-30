import SwiftUI
import CoreLocation
import MCaddieCore

/// 记录击球视图 - Watch 和 iOS 通用逻辑
struct RecordShotView: View {
    let round: Round
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager
    
    // 表单状态
    @State private var selectedClub: ClubType = .iron7
    @State private var selectedLie: Lie = .tee
    @State private var estimatedCarryYards: Double = 150
    @State private var estimatedTotalYards: Double = 160
    @State private var estimatedDirection: Double? = nil
    @State private var dictationText: String = ""
    @State private var notes: String = ""
    
    // GPS 和位置
    @State private var currentLocation: PositionObservation?
    @State private var isGettingLocation = false
    
    // UI 状态
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("击球信息") {
                    Picker("球杆", selection: $selectedClub) {
                        ForEach(ClubType.allCases, id: \.self) { club in
                            Text(club.rawValue).tag(club)
                        }
                    }
                    
                    Picker("球位", selection: $selectedLie) {
                        ForEach(Lie.allCases, id: \.self) { lie in
                            Text(lie.displayName).tag(lie)
                        }
                    }
                }
                
                Section("距离估计") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Carry 距离: \(Int(estimatedCarryYards)) 码")
                            .font(.subheadline)
                        Slider(value: $estimatedCarryYards, in: 10...300, step: 5)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total 距离: \(Int(estimatedTotalYards)) 码")
                            .font(.subheadline)
                        Slider(value: $estimatedTotalYards, in: 10...300, step: 5)
                    }
                }
                
                Section("当前位置") {
                    if let location = currentLocation {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("位置已获取")
                                .font(.headline)
                            
                            Text("精度: \(String(format: "%.1f", location.horizontalAccuracy)) 米")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if !location.isReliable {
                                Label("GPS 精度较低", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    } else {
                        Button(action: getCurrentLocation) {
                            HStack {
                                if isGettingLocation {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else {
                                    Image(systemName: "location.fill")
                                }
                                Text(isGettingLocation ? "定位中..." : "获取当前位置")
                            }
                        }
                        .disabled(isGettingLocation)
                    }
                }
                
                Section("备注") {
                    TextField("口述记录或备注", text: $dictationText, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("记录击球")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveShot()
                    }
                    .disabled(currentLocation == nil || isSaving)
                }
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
            .alert("成功", isPresented: $showSuccessMessage) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("击球记录已保存")
            }
            .task {
                // 自动获取位置
                if currentLocation == nil {
                    getCurrentLocation()
                }
            }
        }
    }
    
    private func getCurrentLocation() {
        isGettingLocation = true
        
        Task {
            defer { isGettingLocation = false }
            
            do {
                // 使用真实的位置服务
                let location = try await LocationService.shared.getCurrentLocation()
                currentLocation = location
            } catch {
                errorMessage = "获取位置失败: \(error.localizedDescription)"
                // 如果失败，使用模拟位置（仅用于开发）
                #if DEBUG
                currentLocation = PositionObservation(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    altitude: 10.0,
                    horizontalAccuracy: 5.0,
                    source: .gps
                )
                #endif
            }
        }
    }
    
    private func saveShot() {
        guard let startPosition = currentLocation else {
            errorMessage = "请先获取当前位置"
            return
        }
        
        guard let manager = dataManager else {
            errorMessage = "数据管理器未初始化"
            return
        }
        
        isSaving = true
        
        Task {
            defer { isSaving = false }
            
            let initialEstimate = Shot.InitialEstimate(
                estimatedCarry: Distance(yards: estimatedCarryYards),
                estimatedTotal: Distance(yards: estimatedTotalYards),
                estimatedDirection: estimatedDirection,
                estimatedLandingPosition: nil,
                dictationText: dictationText.isEmpty ? nil : dictationText
            )
            
            let shot = Shot(
                club: selectedClub,
                startPosition: startPosition,
                startLie: selectedLie,
                initialEstimate: initialEstimate,
                confirmationState: .initial,
                notes: notes.isEmpty ? nil : notes
            )
            
            do {
                try manager.saveShot(shot, toRoundID: round.id)
                showSuccessMessage = true
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
            }
        }
    }
}

/// 更新击球结果视图 - 走到球位后更新实际位置
struct UpdateShotResultView: View {
    let shot: Shot
    let round: Round
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager
    
    @State private var endLie: Lie = .fairway
    @State private var performanceRating: Shot.PerformanceRating = .good
    @State private var currentLocation: PositionObservation?
    @State private var isGettingLocation = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("击球信息") {
                    LabeledContent("球杆", value: shot.club.rawValue)
                    LabeledContent("估计距离", value: String(format: "%.0f 码", shot.initialEstimate.estimatedTotal.yards))
                }
                
                Section("实际结果") {
                    Picker("球位", selection: $endLie) {
                        ForEach(Lie.allCases, id: \.self) { lie in
                            Text(lie.displayName).tag(lie)
                        }
                    }
                    
                    Picker("表现评级", selection: $performanceRating) {
                        Text("非常好").tag(Shot.PerformanceRating.excellent)
                        Text("好").tag(Shot.PerformanceRating.good)
                        Text("一般").tag(Shot.PerformanceRating.average)
                        Text("不理想").tag(Shot.PerformanceRating.poor)
                        Text("失误").tag(Shot.PerformanceRating.mistake)
                    }
                }
                
                Section("当前位置") {
                    if let location = currentLocation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("位置已获取")
                                .font(.headline)
                            
                            if let distance = calculateDistance() {
                                Text("实际距离: \(String(format: "%.1f", distance.yards)) 码")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("精度: \(String(format: "%.1f", location.horizontalAccuracy)) 米")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button(action: getCurrentLocation) {
                            HStack {
                                if isGettingLocation {
                                    ProgressView()
                                } else {
                                    Image(systemName: "location.fill")
                                }
                                Text(isGettingLocation ? "定位中..." : "获取当前位置")
                            }
                        }
                        .disabled(isGettingLocation)
                    }
                }
            }
            .navigationTitle("更新击球结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") {
                        updateShot()
                    }
                    .disabled(currentLocation == nil || isSaving)
                }
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
            .alert("成功", isPresented: $showSuccessMessage) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("击球结果已更新")
            }
            .task {
                getCurrentLocation()
            }
        }
    }
    
    private func getCurrentLocation() {
        isGettingLocation = true
        
        Task {
            defer { isGettingLocation = false }
            
            do {
                // 使用真实的位置服务
                let location = try await LocationService.shared.getCurrentLocation()
                currentLocation = location
            } catch {
                errorMessage = "获取位置失败: \(error.localizedDescription)"
                // 如果失败，使用模拟位置（仅用于开发）
                #if DEBUG
                currentLocation = PositionObservation(
                    latitude: 37.7750,
                    longitude: -122.4195,
                    altitude: 10.0,
                    horizontalAccuracy: 5.0,
                    source: .gps
                )
                #endif
            }
        }
    }
    
    private func calculateDistance() -> Distance? {
        guard let endPosition = currentLocation else { return nil }
        return shot.startPosition.distance(to: endPosition)
    }
    
    private func updateShot() {
        guard let endPosition = currentLocation else {
            errorMessage = "请先获取当前位置"
            return
        }
        
        guard let manager = dataManager else {
            errorMessage = "数据管理器未初始化"
            return
        }
        
        isSaving = true
        
        Task {
            defer { isSaving = false }
            
            let measuredTotal = shot.startPosition.distance(to: endPosition)
            
            let actualResult = Shot.ActualResult(
                endPosition: endPosition,
                endLie: endLie,
                measuredCarry: nil, // 暂时没有 carry 的 GPS 数据
                measuredTotal: measuredTotal,
                performanceRating: performanceRating
            )
            
            let updatedShot = shot.withActualResult(actualResult)
            
            do {
                try manager.updateShot(updatedShot)
                showSuccessMessage = true
            } catch {
                errorMessage = "更新失败: \(error.localizedDescription)"
            }
        }
    }
}

#Preview("Record Shot") {
    let manager = try! DataManager.preview()
    let courseInfo = Round.CourseInfo(name: "测试球场", numberOfHoles: 18)
    let round = Round(course: courseInfo)
    
    return RecordShotView(round: round)
        .dataManager(manager)
}

#Preview("Update Shot") {
    let manager = try! DataManager.preview()
    
    let position = PositionObservation(
        latitude: 37.7749,
        longitude: -122.4194,
        horizontalAccuracy: 5.0,
        source: .gps
    )
    
    let estimate = Shot.InitialEstimate(
        estimatedCarry: Distance(yards: 150),
        estimatedTotal: Distance(yards: 160)
    )
    
    let shot = Shot(
        club: .iron7,
        startPosition: position,
        startLie: .fairway,
        initialEstimate: estimate
    )
    
    let courseInfo = Round.CourseInfo(name: "测试球场", numberOfHoles: 18)
    let round = Round(course: courseInfo)
    
    return UpdateShotResultView(shot: shot, round: round)
        .dataManager(manager)
}
