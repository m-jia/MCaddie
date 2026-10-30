import SwiftUI
import MCaddieCore

// MARK: - Tee 台

/// 球场的一个 Tee 台（来自 GolfCourseAPI）
struct TeeInfo: Identifiable, Equatable {
    let id: String // 可用 tee_name + gender 组合而成
    let teeName: String
    let gender: String // "male" 或 "female"
    let courseRating: Double?
    let slopeRating: Int?
    let totalYards: Int?
    let holes: [HoleDetail]?
    let parTotal: Int?

    struct HoleDetail: Equatable {
        let par: Int?
        let yardage: Int?
        let meters: Int?
        let handicap: Int?
    }

    /// 总长度（码）：优先使用 API 的 total_yards，缺失时累加各洞码数
    var displayTotalYards: Int? {
        if let totalYards { return totalYards }
        let yardages = holes?.compactMap(\.yardage) ?? []
        return yardages.isEmpty ? nil : yardages.reduce(0, +)
    }

    /// 转换为领域模型 Hole，并按洞数截取或重复（缺少标准杆时默认 4）
    func makeHoles(count: Int) -> [Hole]? {
        guard let holes, !holes.isEmpty else { return nil }
        let converted = holes.enumerated().map { index, detail in
            Hole(
                number: index + 1,
                par: detail.par ?? 4,
                distance: Distance(yards: Double(detail.yardage ?? 0)),
                handicap: detail.handicap
            )
        }
        return Hole.fitting(converted, toCount: count)
    }

    static func == (lhs: TeeInfo, rhs: TeeInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - API

enum GolfCourseAPIError: Error, LocalizedError {
    case invalidRequest
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidRequest: return "无效的请求"
        case .missingAPIKey: return "未配置球场数据库密钥（MCaddie/Secrets.plist）"
        }
    }
}

/// GolfCourseAPI 的搜索和球场详情请求
enum GolfCourseAPI {
    private static let baseURL = "https://api.golfcourseapi.com/v1"

    /// 密钥从 App 包内的 Secrets.plist 读取；该文件不进入 Git，模板见 Config/Secrets.example.plist
    private static let apiKey: String? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = plist["GolfCourseAPIKey"] as? String,
              !key.isEmpty else {
            print("❌ 未找到 GolfCourseAPIKey，请参照 Config/Secrets.example.plist 创建 MCaddie/Secrets.plist")
            return nil
        }
        return key
    }()

    /// 按关键词搜索球场，忽略解析失败的条目
    static func searchCourses(keyword: String) async throws -> [GolfCourseResult] {
        guard let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?search_query=\(encoded)&fuzzy_match=true") else {
            throw GolfCourseAPIError.invalidRequest
        }
        let data = try await get(url)
        let response = try JSONDecoder().decode(GolfCourseSearchResponse.self, from: data)
        let courses = response.courses.compactMap(\.value)
        print("球场搜索 \"\(keyword)\": 共 \(response.courses.count) 条，有效 \(courses.count) 条")
        return courses
    }

    /// 加载球场的所有 Tee 台（male 和 female），按名称排序
    static func fetchTees(courseID: String) async throws -> [TeeInfo] {
        guard let url = URL(string: "\(baseURL)/courses/\(courseID)") else {
            throw GolfCourseAPIError.invalidRequest
        }
        let data = try await get(url)
        let detail = try JSONDecoder().decode(CourseDetailResponse.self, from: data)

        // gender 不在 Tee 里，而是由 male / female 两个数组区分
        func convert(_ tee: CourseDetailResponse.Course.Tee, gender: String) -> TeeInfo? {
            guard let name = tee.tee_name, !name.isEmpty else { return nil }
            return TeeInfo(
                id: name + "_" + gender,
                teeName: name,
                gender: gender,
                courseRating: tee.course_rating,
                slopeRating: tee.slope_rating,
                totalYards: tee.total_yards,
                holes: tee.holes?.map {
                    TeeInfo.HoleDetail(par: $0.par, yardage: $0.yardage, meters: $0.meters, handicap: $0.handicap)
                },
                parTotal: tee.par
            )
        }

        let male = detail.course.tees.male?.compactMap { convert($0, gender: "male") } ?? []
        let female = detail.course.tees.female?.compactMap { convert($0, gender: "female") } ?? []
        let tees = (male + female).sorted { $0.teeName < $1.teeName }
        print("球场 \(courseID) Tee 台数: \(tees.count)")
        return tees
    }

    /// 按名称查找球场 ID（用于没有保存球场 ID 的旧回合），要求名称完全一致
    static func findCourseID(named name: String) async throws -> String? {
        try await searchCourses(keyword: name).first { $0.course_name == name }?.id
    }

    private static func get(_ url: URL) async throws -> Data {
        guard let apiKey else { throw GolfCourseAPIError.missingAPIKey }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            print("❌ GolfCourseAPI HTTP \(http.statusCode): \(url.absoluteString)")
        }
        return data
    }
}

// MARK: - API 数据模型

struct GolfCourseSearchResponse: Decodable {
    let courses: [FailableDecodable<GolfCourseResult>]
}

struct GolfCourseResult: Identifiable, Decodable {
    let id: String
    let club_name: String
    let course_name: String
    let location: CourseLocation

    struct CourseLocation: Decodable {
        let address: String?
        let city: String?
        let state: String?
        let country: String?
        let latitude: Double
        let longitude: Double
    }

    var distanceMeters: Double? = nil // 可变属性，用于存储计算的距离
}

struct FailableDecodable<Base: Decodable>: Decodable {
    let value: Base?
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try? container.decode(Base.self)
    }
}

struct CourseDetailResponse: Decodable {
    let course: Course

    struct Course: Decodable {
        let id: String?
        let club_name: String
        let course_name: String
        let location: CourseLocation

        struct CourseLocation: Decodable {
            let address: String?
            let city: String?
            let state: String?
            let country: String?
            let latitude: Double
            let longitude: Double
        }

        let tees: Tees

        struct Tees: Decodable {
            let male: [Tee]?
            let female: [Tee]?
        }

        struct Tee: Decodable {
            let id: String?
            let tee_name: String?
            let course_rating: Double?
            let slope_rating: Int?
            let total_yards: Int?
            let total_meters: Int?
            let number_of_holes: Int?
            let par_total: Int?
            let holes: [HoleDetail]?
            let par: Int?
        }

        struct HoleDetail: Decodable {
            let par: Int?
            let yardage: Int?
            let meters: Int?
            let handicap: Int?
        }
    }
}

// MARK: - Tee 台选择列表

/// Tee 台选择列表（开始新回合和修改回合共用）
struct TeeSelectionList: View {
    let tees: [TeeInfo]
    let isLoading: Bool
    var selectedID: String? = nil
    let onSelect: (TeeInfo) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("加载 Tee 台中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !tees.isEmpty {
                    List(tees, id: \.id) { tee in
                        Button {
                            onSelect(tee)
                        } label: {
                            row(for: tee)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("该球场未提供 Tee 台数据。")
                            .foregroundColor(.secondary)
                        Button("关闭", action: onCancel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("选择 Tee 台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
            }
        }
    }

    private func row(for tee: TeeInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tee.teeName)
                    .font(.headline)
                if tee.id == selectedID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
                Spacer()
                if let yards = tee.displayTotalYards {
                    Text("\(yards) 码")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            HStack {
                if let rating = tee.courseRating {
                    Text("评分: \(rating, specifier: "%.1f")")
                }
                if let slope = tee.slopeRating {
                    Text("坡度: \(slope)")
                }
                Text("性别: \(tee.gender)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .foregroundStyle(.primary)
    }
}
