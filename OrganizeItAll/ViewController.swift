import SwiftUI

struct OrganizeItAllRootView: View {
    var body: some View {
        TabView {
            ListsView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Lists")
                }

            AllTasksView()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Tasks")
                }
        }
        .accentColor(.brandAccent)
    }
}
