import SwiftData
import SwiftUI

struct TaskListsView: View {
    @Environment(\.materialColors) private var colors
    @Query(sort: \TaskList.modifiedAt, order: .reverse) private var lists: [TaskList]
    @State private var isPresentingNewList = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Lists")
                            .font(MaterialTypography.headlineLarge)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)

                        if lists.isEmpty {
                            MaterialEmptyState(
                                title: "No lists yet",
                                message: "Create a list to organize related tasks. Unfiled tasks stay in Inbox.",
                                systemImage: "folder.badge.plus"
                            )
                        } else {
                            ForEach(lists) { list in
                                NavigationLink {
                                    TaskListDetailView(list: list)
                                } label: {
                                    MaterialCard {
                                        TaskListRow(list: list)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 96)
                }

                MaterialFloatingActionButton(title: "New list", systemImage: "plus") {
                    isPresentingNewList = true
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isPresentingNewList) {
                TaskListEditorView()
            }
        }
    }
}
