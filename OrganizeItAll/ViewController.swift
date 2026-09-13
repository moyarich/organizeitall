import SwiftUI

@available(iOS 17.0, *)
struct OrganizeItAllRootView: View {
    var body: some View {
        TabView {
            ListsView()
                .tabItem {
                    Label("Lists", systemImage: "folder")
                }

            AllTasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }
        }
        .tint(.brandAccent)
    }
}
