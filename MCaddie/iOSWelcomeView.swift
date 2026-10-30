import SwiftUI
import MCaddieCore

/// iPhone 欢迎页 - 连接到实际功能
struct iOSWelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "figure.golf")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.green)
                
                Text("M-Caddie")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your AI Golf Caddie")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(spacing: 16) {
                    // 查看所有回合
                    NavigationLink {
                        RoundListView()
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("我的回合")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                    }
                    
                    // 快速开始新回合
                    NavigationLink {
                        NewRoundView()
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("开始新回合")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                    }
                    
                    // 球杆档案（占位）
                    NavigationLink {
                        ClubProfilePlaceholderView()
                    } label: {
                        HStack {
                            Image(systemName: "figure.golf.circle")
                            Text("球杆档案")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                        .font(.headline)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationTitle("M-Caddie")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 球杆档案占位视图
struct ClubProfilePlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.golf.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.orange)
            
            Text("球杆档案")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("即将推出")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("您将能够在这里管理球杆性能数据，包括每支球杆的 carry 和 total 距离。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .navigationTitle("球杆档案")
    }
}

#Preview("Welcome") {
    iOSWelcomeView()
        .dataManager(try! DataManager.preview())
}

#Preview("Club Profile") {
    NavigationStack {
        ClubProfilePlaceholderView()
    }
}
