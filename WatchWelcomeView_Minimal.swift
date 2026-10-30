import SwiftUI

/// Watch 欢迎页 - 最小测试版
/// 用于验证 Watch App 基础功能是否正常
struct WatchWelcomeView_Minimal: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.golf")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("M-Caddie")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Watch App")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("✅ Running")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding()
    }
}

#Preview {
    WatchWelcomeView_Minimal()
}
