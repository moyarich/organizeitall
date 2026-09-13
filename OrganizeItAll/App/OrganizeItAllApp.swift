import SwiftData
import SwiftUI

@main
struct OrganizeItAllApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .materialTheme()
        }
        .modelContainer(for: [TaskList.self, TaskItem.self])
    }
}
