import SwiftUI

enum AppTab: Hashable {
    case overview, accounts, tasks, data, more
}

struct MainTabsView: View {
    @State private var selection: AppTab = .overview
    @State private var toast: Toast?

    var body: some View {
        // iOS 16 兼容：`Tab(...)`（iOS 18）与 `.tabBarMinimizeBehavior`（iOS 26）均不可用，
        // 回到经典的 `.tabItem` + `.tag` 写法。
        TabView(selection: $selection) {
            OverviewView()
                .tabItem { Label("概览", systemImage: "gauge.with.dots.needle.50percent") }
                .tag(AppTab.overview)
            AccountsView()
                .tabItem { Label("账号", systemImage: "person.2.fill") }
                .tag(AppTab.accounts)
            TasksView()
                .tabItem { Label("任务", systemImage: "checklist") }
                .tag(AppTab.tasks)
            DataView()
                .tabItem { Label("数据", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.data)
            MoreView()
                .tabItem { Label("更多", systemImage: "ellipsis") }
                .tag(AppTab.more)
        }
        .tint(Accent.primary)
        .toast($toast)
    }
}
