//
//  MCaddieApp.swift
//  MCaddie
//
//  Created by Michael Jia on 2026-10-18.
//

import SwiftUI
import SwiftData

@main
struct MCaddieApp: App {
    /// SwiftData ModelContainer 配置
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RoundModel.self,
            ShotModel.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    /// 数据管理器
    var dataManager: DataManager {
        DataManager(modelContainer: sharedModelContainer)
    }

    init() {
        // 在 App 启动时请求位置权限
        Task { @MainActor in
            LocationService.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            iOSWelcomeView()
                .dataManager(dataManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
