import SwiftData
import SwiftUI

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.modifiedAt, order: .reverse) private var lists: [TaskList]
    @State private var isPresentingNewList = false

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    ContentUnavailableView("No Lists Yet", systemImage: "folder.badge.plus", description: Text("Create a list to organize related tasks. Unfiled tasks stay in Inbox."))
                } else {
                    List {
                        ForEach(lists) { list in
                            NavigationLink { ListDetailView(list: list) } label: { ListRow(list: list) }
                        }
                        .onDelete(perform: deleteLists)
                    }
                }
            }
            .navigationTitle("Lists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New List", systemImage: "plus") { isPresentingNewList = true }
                }
            }
            .sheet(isPresented: $isPresentingNewList) { ListEditorView() }
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(lists[index]) }
        save()
    }

    private func save() {
        do { try modelContext.save() }
        catch { modelContext.rollback(); assertionFailure("Unable to save list changes: \(error)") }
    }
}
