import SwiftUI
import CoreLocation
import MCaddieCore

/// 位置权限测试视图
struct LocationPermissionTestView: View {
    @StateObject private var locationService = LocationService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var testLocation: PositionObservation?
    
    var body: some View {
        NavigationStack {
            List {
                Section("当前状态") {
                    StatusRow(
                        title: "位置服务",
                        value: locationService.isLocationServiceAvailable ? "可用" : "不可用",
                        color: locationService.isLocationServiceAvailable ? .green : .red
                    )
                    
                    StatusRow(
                        title: "授权状态",
                        value: authorizationStatusText,
                        color: authorizationStatusColor
                    )
                    
                    if let location = locationService.currentLocation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("当前位置")
                                .font(.headline)
                            
                            Text("纬度: \(location.latitude, specifier: "%.6f")")
                            Text("经度: \(location.longitude, specifier: "%.6f")")
                            Text("精度: \(location.horizontalAccuracy, specifier: "%.1f") 米")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Section("测试操作") {
                    Button(action: requestPermission) {
                        Label("请求位置权限", systemImage: "location.circle")
                    }
                    
                    Button(action: testGetLocation) {
                        Label("测试获取位置", systemImage: "location.fill")
                    }
                    .disabled(!locationService.hasLocationPermission)
                    
                    Button(action: openSettings) {
                        Label("打开设置", systemImage: "gear")
                    }
                }
                
                Section("测试结果") {
                    if let location = testLocation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("✅ 成功获取位置")
                                .foregroundStyle(.green)
                                .fontWeight(.bold)
                            
                            Text("纬度: \(location.latitude, specifier: "%.6f")")
                            Text("经度: \(location.longitude, specifier: "%.6f")")
                            Text("精度: \(location.horizontalAccuracy, specifier: "%.1f") 米")
                            Text("时间: \(location.timestamp.formatted())")
                        }
                        .font(.caption)
                    } else {
                        Text("尚未测试")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Info.plist 检查") {
                    VStack(alignment: .leading, spacing: 12) {
                        ChecklistItem(
                            text: "NSLocationWhenInUseUsageDescription",
                            checked: true
                        )
                        ChecklistItem(
                            text: "NSLocationAlwaysAndWhenInUseUsageDescription",
                            checked: true
                        )
                        
                        Text("如果权限弹窗不出现，可能是因为：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 之前已经拒绝过权限")
                            Text("• 需要删除 App 重新安装")
                            Text("• 或在设置中手动开启")
                        }
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("位置权限测试")
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var authorizationStatusText: String {
        switch locationService.authorizationStatus {
        case .notDetermined:
            return "未询问"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终允许"
        case .authorizedWhenInUse:
            return "使用时允许"
        @unknown default:
            return "未知"
        }
    }
    
    private var authorizationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .notDetermined:
            return .orange
        case .denied, .restricted:
            return .red
        @unknown default:
            return .gray
        }
    }
    
    private func requestPermission() {
        print("📍 请求位置权限...")
        locationService.requestAuthorization()
        
        // 等待一下看状态是否改变
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if locationService.authorizationStatus == .notDetermined {
                alertMessage = "权限请求已发送。如果没有弹窗，请检查 Info.plist 或删除 App 重新安装。"
                showAlert = true
            }
        }
    }
    
    private func testGetLocation() {
        Task {
            do {
                let location = try await locationService.getCurrentLocation()
                testLocation = location
                alertMessage = "成功获取位置！\n精度: \(String(format: "%.1f", location.horizontalAccuracy)) 米"
                showAlert = true
            } catch {
                alertMessage = "获取位置失败：\(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(color)
                .fontWeight(.semibold)
        }
    }
}

struct ChecklistItem: View {
    let text: String
    let checked: Bool
    
    var body: some View {
        HStack {
            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(checked ? .green : .gray)
            Text(text)
                .font(.caption)
        }
    }
}

#Preview {
    LocationPermissionTestView()
}
