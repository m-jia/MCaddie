import Foundation
import CoreLocation
import Combine
import MCaddieCore

/// GPS 位置服务
/// 封装 CoreLocation，提供简单的位置获取接口
@MainActor
class LocationService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LocationService()
    
    // MARK: - Published Properties
    
    /// 当前位置
    @Published var currentLocation: PositionObservation?
    
    /// 位置精度状态
    @Published var accuracyStatus: AccuracyStatus = .unknown
    
    /// 授权状态
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// 错误信息
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<PositionObservation, Error>?
    
    // MARK: - Initialization
    
    private override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // 移动 5 米才更新
    }
    
    // MARK: - Public Methods
    
    /// 请求位置权限
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 开始持续更新位置（用于回合进行中）
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// 停止更新位置
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// 获取当前位置（一次性）
    func getCurrentLocation() async throws -> PositionObservation {
        // 检查授权状态
        switch authorizationStatus {
        case .notDetermined:
            requestAuthorization()
            // 等待用户响应
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
            
        case .restricted, .denied:
            throw LocationError.authorizationDenied
            
        case .authorizedWhenInUse, .authorizedAlways:
            break
            
        @unknown default:
            throw LocationError.unknown
        }
        
        // 请求位置
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    /// 检查位置服务是否可用
    var isLocationServiceAvailable: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// 检查是否有位置权限
    var hasLocationPermission: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            
            // 创建 PositionObservation
            let observation = PositionObservation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                horizontalAccuracy: location.horizontalAccuracy,
                verticalAccuracy: location.verticalAccuracy,
                timestamp: location.timestamp,
                source: .gps
            )
            
            // 更新状态
            self.currentLocation = observation
            self.accuracyStatus = self.determineAccuracyStatus(observation)
            
            // 如果有等待的 continuation，返回结果
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(returning: observation)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            
            // 如果有等待的 continuation，返回错误
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineAccuracyStatus(_ observation: PositionObservation) -> AccuracyStatus {
        let accuracy = observation.horizontalAccuracy
        
        if accuracy < 0 {
            return .invalid
        } else if accuracy < 5 {
            return .excellent
        } else if accuracy < 10 {
            return .good
        } else if accuracy < 20 {
            return .fair
        } else {
            return .poor
        }
    }
}

// MARK: - Supporting Types

extension LocationService {
    
    /// 位置精度状态
    enum AccuracyStatus {
        case unknown
        case invalid
        case excellent  // < 5m
        case good       // < 10m
        case fair       // < 20m
        case poor       // >= 20m
        
        var description: String {
            switch self {
            case .unknown: return "未知"
            case .invalid: return "无效"
            case .excellent: return "优秀"
            case .good: return "良好"
            case .fair: return "一般"
            case .poor: return "较差"
            }
        }
        
        var color: String {
            switch self {
            case .unknown, .invalid: return "gray"
            case .excellent, .good: return "green"
            case .fair: return "orange"
            case .poor: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "location.slash"
            case .invalid: return "location.slash.fill"
            case .excellent: return "location.fill"
            case .good: return "location.fill"
            case .fair: return "location"
            case .poor: return "location"
            }
        }
    }
    
    /// 位置错误
    enum LocationError: LocalizedError {
        case authorizationDenied
        case locationUnavailable
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                return "位置访问被拒绝。请在设置中允许访问位置。"
            case .locationUnavailable:
                return "无法获取位置信息。"
            case .unknown:
                return "未知错误。"
            }
        }
    }
}

// MARK: - SwiftUI Preview Support

#if DEBUG
extension LocationService {
    /// 创建模拟的位置服务（用于预览）
    static func mock(withLocation location: PositionObservation? = nil) -> LocationService {
        let service = LocationService.shared
        service.currentLocation = location ?? PositionObservation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 5.0,
            source: .gps
        )
        service.accuracyStatus = .excellent
        service.authorizationStatus = .authorizedWhenInUse
        return service
    }
}
#endif
