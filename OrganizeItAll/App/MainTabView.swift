import SwiftUI

private enum AppTab: Hashable {
    case lists
    case tasks
}

struct MainTabView: View {
    @Environment(\.materialColors) private var colors
    @State private var selectedTab: AppTab = .tasks

    var body: some View {
        ZStack {
            colors.surface.ignoresSafeArea()

            switch selectedTab {
            case .lists:
                TaskListsView()
            case .tasks:
                TasksView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 8) {
                MaterialNavigationBarItem(
                    title: "Lists",
                    systemImage: "folder",
                    selectedSystemImage: "folder.fill",
                    isSelected: selectedTab == .lists
                ) {
                    selectedTab = .lists
                }

                MaterialNavigationBarItem(
                    title: "Tasks",
                    systemImage: "checkmark.circle",
                    selectedSystemImage: "checkmark.circle.fill",
                    isSelected: selectedTab == .tasks
                ) {
                    selectedTab = .tasks
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(colors.surfaceContainer)
        }
    }
}
