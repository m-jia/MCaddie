import SwiftUI

/// Watch 欢迎页 - NavigationView 兼容版
/// 支持 watchOS 7.0+，使用旧的 NavigationView API
struct WatchWelcomeView_Compatible: View {
    var body: some View {
        NavigationView {
            List {
                // 标题部分
                VStack(spacing: 16) {
                    Image(systemName: "figure.golf")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.green)
                    
                    Text("M-Caddie")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Watch Golf Caddie")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                
                // 操作按钮
                Section {
                    NavigationLink(destination: RoundInProgressView()) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                            Text("Start Round")
                        }
                    }
                    
                    NavigationLink(destination: ShotHistoryView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View Shots")
                        }
                    }
                }
            }
            .navigationTitle("M-Caddie")
        }
    }
}

// 占位视图
struct RoundInProgressView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.golf.circle")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text("Round in progress...")
                .font(.caption)
        }
        .navigationTitle("Round")
    }
}

struct ShotHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.circle")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("No shots recorded yet")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Shots")
    }
}

#Preview {
    WatchWelcomeView_Compatible()
}
