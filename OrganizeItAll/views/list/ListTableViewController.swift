import SwiftData
import SwiftUI

@available(iOS 17.0, *)
struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \List.modifiedDate, order: .reverse) private var lists: [List]

    @State private var showingNewList = false

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    ContentUnavailableView(
                        "No lists yet",
                        systemImage: "folder.badge.plus",
                        description: Text("Create a list to group related tasks, or use the Tasks tab for inbox items.")
                    )
                } else {
                    SwiftUI.List {
                        ForEach(lists) { list in
                            NavigationLink(value: list.id) {
                                ListRow(list: list)
                            }
                        }
                        .onDelete(perform: deleteLists)
                    }
                    .navigationDestination(for: UUID.self) { id in
                        if let list = lists.first(where: { $0.id == id }) {
                            ListDetailView(list: list)
                        } else {
                            ContentUnavailableView("List Not Found", systemImage: "exclamationmark.folder")
                        }
                    }
                }
            }
            .navigationTitle("Lists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create List", systemImage: "plus") {
                        showingNewList = true
                    }
                }
            }
            .sheet(isPresented: $showingNewList) {
                ListEditorView()
            }
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        offsets.map { lists[$0] }.forEach(modelContext.delete)
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to delete list: \(error)")
        }
    }
}
