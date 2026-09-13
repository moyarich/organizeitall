import CoreData
import SwiftUI

struct ListsView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        entity: List.entity(),
        sortDescriptors: [NSSortDescriptor(key: "modified_date", ascending: false)]
    ) private var lists: FetchedResults<List>

    @State private var showingNewList = false

    var body: some View {
        NavigationView {
            Group {
                if lists.isEmpty {
                    EmptyStateView(
                        systemImage: "folder.badge.plus",
                        title: "No lists yet",
                        message: "Create a list to group related tasks, or use the Tasks tab for inbox items."
                    )
                } else {
                    SwiftUI.List {
                        ForEach(lists, id: \.objectID) { list in
                            NavigationLink(destination: ListDetailView(list: list)) {
                                ListRow(list: list)
                            }
                        }
                        .onDelete(perform: deleteLists)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarTitle("Lists", displayMode: .large)
            .navigationBarItems(
                leading: EditButton(),
                trailing: Button(action: { showingNewList = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Create list")
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingNewList) {
            ListEditorView()
                .environment(\.managedObjectContext, context)
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        offsets.map { lists[$0] }.forEach(context.delete)
        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            context.rollback()
            assertionFailure("Unable to delete list: \(error)")
        }
    }
}
