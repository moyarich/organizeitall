import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TaskListsView()
                .tabItem {
                    Label("Lists", systemImage: "folder")
                }

            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
        }
        .tint(.indigo)
    }
}
