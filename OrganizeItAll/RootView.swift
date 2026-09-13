import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ListsView()
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
