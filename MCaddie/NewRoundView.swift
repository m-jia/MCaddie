import SwiftUI
import Combine
import MCaddieCore
import CoreLocation

/// 新建回合视图
struct NewRoundView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager

    @State private var courseName = ""
    @State private var courseLocation = ""
    @State private var numberOfHoles = 18
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var navigationPath = NavigationPath()
    @State private var createdRound: Round?

    @State private var isSearching = false
    @State private var searchResults: [GolfCourseResult] = []
    @State private var showingSearchResults = false
    @State private var searching = false
    @State private var searchError: String?
    @State private var selectedCourse: GolfCourseResult?

    // 新增 tee 选择相关状态
    @State private var teeSelectionSheet = false
    @State private var availableTees: [TeeInfo] = []
    @State private var selectedTee: TeeInfo?
    @State private var isFetchingTee = false
    @State private var fetchTeeError: String?

    @StateObject var locationManager = CLLocationManagerShim()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                Section {
                    HStack {
                        TextField("球场名称", text: $courseName)
                            .autocorrectionDisabled()

                        Button {
                            Task { await self.searchCourses(keyword: courseName) }
                        } label: {
                            Image(systemName: searching ? "hourglass" : "magnifyingglass")
                        }
                        .disabled(courseName.isEmpty || searching)
                    }

                    TextField("城市或地区", text: $courseLocation)
                        .autocorrectionDisabled()

                    Picker("球洞数", selection: $numberOfHoles) {
                        Text("9 洞").tag(9)
                        Text("18 洞").tag(18)
                    }
                } header: {
                    Text("球场信息")
                } footer: {
                    Text("城市或地区是可选的，例如：昆明、北京、深圳等")
                        .font(.caption)
                }

                // 新增显示当前选中tee信息
                Section {
                    if let tee = selectedTee {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("已选 Tee 台")
                                .font(.headline)
                            Text("名称: \(tee.teeName)")
                            if let yards = tee.displayTotalYards {
                                Text("总长: \(yards) 码")
                            }
                            if let rating = tee.courseRating {
                                Text("评分: \(rating, specifier: "%.1f")")
                            }
                            if let slope = tee.slopeRating {
                                Text("坡度: \(slope)")
                            }
                            Text("性别: \(tee.gender)")
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("请先选择球场后选择 Tee 台")
                            .foregroundColor(.secondary)
                    }

                    Button {
                        if selectedCourse != nil {
                            teeSelectionSheet = true
                        }
                    } label: {
                        Text(selectedTee == nil ? "选择 Tee 台" : "更改 Tee 台")
                    }
                    .disabled(selectedCourse == nil || isFetchingTee)
                } header: {
                    Text("Tee 台选择")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("温馨提示")
                                .fontWeight(.semibold)
                        }

                        Text("• 球场名称是必填的")
                        Text("• 城市/地区可以帮助您记住在哪里打的球")
                        Text("• 创建后将直接进入回合页面")
                        Text("• Tee 台选择可影响记分及距离")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("开始新回合")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("开始") {
                        startRound()
                    }
                    .disabled(courseName.isEmpty || isSaving)
                }
            }
            .fullScreenCover(item: $createdRound, onDismiss: { dismiss() }) { round in
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
            .alert("搜索失败", isPresented: .constant(searchError != nil)) {
                Button("确定") { searchError = nil }
            } message: { Text(searchError ?? "") }
            .alert("加载 Tee 台失败", isPresented: .constant(fetchTeeError != nil)) {
                Button("确定") { fetchTeeError = nil }
            } message: {
                Text(fetchTeeError ?? "")
            }
            .sheet(isPresented: $showingSearchResults) {
                NavigationView {
                    List(searchResults) { result in
                        Button {
                            courseName = result.course_name
                            // 自动填充 city+state 到 courseLocation
                            if let city = result.location.city {
                                if let state = result.location.state, !state.isEmpty {
                                    courseLocation = city + ", " + state
                                } else {
                                    courseLocation = city
                                }
                            } else {
                                courseLocation = ""
                            }
                            selectedCourse = result
                            showingSearchResults = false
                            // 选中球场后自动请求详情
                            Task {
                                await fetchCourseDetail(id: result.id)
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(result.course_name)
                                    if let distance = result.distanceMeters {
                                        Text(String(format: "%.1f km", distance / 1000))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(result.location.address ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .navigationTitle("选择球场")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { showingSearchResults = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $teeSelectionSheet) {
                TeeSelectionList(
                    tees: availableTees,
                    isLoading: isFetchingTee,
                    onSelect: { tee in
                        selectedTee = tee
                        teeSelectionSheet = false
                    },
                    onCancel: { teeSelectionSheet = false }
                )
            }
            .onAppear {
                locationManager.request()
            }
        }
    }

    private func startRound() {
        guard let manager = dataManager else {
            errorMessage = "数据管理器未初始化"
            return
        }

        isSaving = true

        Task {
            defer { isSaving = false }

            // 洞数以用户选择为准；Tee 台数据按该洞数截取或重复
            let holes = selectedTee?.makeHoles(count: numberOfHoles)

            let courseInfo = Round.CourseInfo(
                name: courseName,
                location: courseLocation.isEmpty ? nil : courseLocation,
                numberOfHoles: numberOfHoles,
                holes: holes?.isEmpty == false ? holes : nil,
                externalCourseID: selectedCourse?.id,
                teeName: selectedTee?.teeName,
                teeGender: selectedTee?.gender
            )

            let round = Round(
                course: courseInfo,
                status: .inProgress
            )

            do {
                try manager.saveRound(round)

                // 保存成功后，直接进入第一洞记分
                await MainActor.run {
                    createdRound = round
                }
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
            }
        }
    }

    func searchCourses(keyword: String) async {
        searching = true
        searchError = nil
        searchResults = []

        // Clear previous selection when searching new keyword
        selectedCourse = nil
        selectedTee = nil
        availableTees = []

        do {
            var validCourses = try await GolfCourseAPI.searchCourses(keyword: keyword)

            // 计算距离（如果有用户位置）
            if let userLocation = locationManager.location {
                print("用户位置: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
                for i in 0..<validCourses.count {
                    let courseLocation = CLLocation(
                        latitude: validCourses[i].location.latitude,
                        longitude: validCourses[i].location.longitude
                    )
                    let distance = userLocation.distance(from: courseLocation)
                    validCourses[i].distanceMeters = distance
                    print("球场 \(validCourses[i].course_name) 距离: \(distance/1000) km")
                }
            } else {
                print("没有用户位置信息")
            }
            
            // 只显示100公里以内的球场
            let filteredCourses = validCourses.filter { course in
                if let distance = course.distanceMeters {
                    return distance <= 100_000 // 100公里 = 100,000米
                }
                return true // 如果没有距离信息，保留该球场
            }
            print("100公里内球场数: \(filteredCourses.count)")
            
            // 按距离排序
            let sortedCourses = filteredCourses.sorted { course1, course2 in
                guard let d1 = course1.distanceMeters, let d2 = course2.distanceMeters else {
                    return false
                }
                return d1 < d2
            }
            print("=========================")

            await MainActor.run {
                searchResults = sortedCourses
                showingSearchResults = true
            }
        } catch {
            await MainActor.run {
                searchError = "搜索失败，请稍后重试"
            }
        }

        await MainActor.run {
            searching = false
        }
    }

    // MARK: - 加载 Tee 台

    func fetchCourseDetail(id: String) async {
        isFetchingTee = true
        fetchTeeError = nil
        availableTees = []
        defer { isFetchingTee = false }

        do {
            availableTees = try await GolfCourseAPI.fetchTees(courseID: id)
        } catch {
            print("❌ 加载 Tee 台失败: \(error)")
            fetchTeeError = "加载 Tee 台数据失败，请稍后重试"
        }
    }

    class CLLocationManagerShim: NSObject, ObservableObject, CLLocationManagerDelegate {
        @Published var location: CLLocation?
        private let manager = CLLocationManager()
        override init() {
            super.init()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        func request() {
            manager.requestWhenInUseAuthorization()
            manager.startUpdatingLocation()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let loc = locations.last {
                location = loc
                manager.stopUpdatingLocation()
            }
        }
    }
}

#Preview {
    NewRoundView()
        .dataManager(try! DataManager.preview())
}
