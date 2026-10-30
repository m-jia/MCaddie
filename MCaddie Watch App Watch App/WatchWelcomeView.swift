import SwiftUI

/// Watch 欢迎页 - 最小可见版本
struct WatchWelcomeView: View {
    var body: some View {
        Group {
            if #available(watchOS 10.0, *) {
                modernView
            } else {
                compatibleView
            }
        }
    }
    
    // watchOS 10+ 现代版本
    @available(watchOS 10.0, *)
    private var modernView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "figure.golf")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.green)
                    
                    Text("M-Caddie")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Watch-First Golf Caddie")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 主要操作按钮
                    NavigationLink {
                        Text("回合进行中...")
                            .font(.caption)
                            .navigationTitle("Round")
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            Text("Start Round")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    // 次要操作
                    NavigationLink {
                        Text("当前击球记录")
                            .font(.caption)
                            .navigationTitle("Shots")
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View Shots")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("M-Caddie")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // watchOS 7-9 兼容版本
    private var compatibleView: some View {
        NavigationView {
            List {
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
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                
                Section {
                    NavigationLink(destination: Text("Round in progress...").navigationTitle("Round")) {
                        Label("Start Round", systemImage: "play.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    NavigationLink(destination: Text("Shot history...").navigationTitle("Shots")) {
                        Label("View Shots", systemImage: "list.bullet")
                    }
                }
            }
            .navigationTitle("M-Caddie")
        }
    }
}

#Preview {
    WatchWelcomeView()
}
