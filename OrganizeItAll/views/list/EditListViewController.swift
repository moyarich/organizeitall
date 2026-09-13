import SwiftData
import SwiftUI

@available(iOS 17.0, *)
private enum ListDetailSheet: Identifiable {
    case editList
    case newTask
    case editTask(Task)

    var id: String {
        switch self {
        case .editList:
            "edit-list"
        case .newTask:
            "new-task"
        case .editTask(let task):
            "edit-\(task.id.uuidString)"
        }
    }
}

@available(iOS 17.0, *)
struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: List
    @State private var activeSheet: ListDetailSheet?

    private var tasks: [Task] {
        list.tasks.sorted { $0.modifiedDate > $1.modifiedDate }
    }

    var body: some View {
        Group {
            if tasks.isEmpty {
                ContentUnavailableView(
                    "No tasks in this list",
                    systemImage: "checkmark.circle",
                    description: Text("Add the first task and keep everything for \(list.wrappedName) together.")
                )
            } else {
                SwiftUI.List {
                    ForEach(tasks) { task in
                        TaskRow(task: task) {
                            toggle(task)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            activeSheet = .editTask(task)
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .navigationTitle(list.wrappedName)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit List", systemImage: "pencil") {
                    activeSheet = .editList
                }

                Button("Create Task", systemImage: "plus") {
                    activeSheet = .newTask
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editList:
                ListEditorView(list: list)
            case .newTask:
                TaskEditorView(defaultList: list)
            case .editTask(let task):
                TaskEditorView(task: task, defaultList: list)
            }
        }
    }

    private func toggle(_ task: Task) {
        task.isComplete.toggle()
        task.modifiedDate = .now
        save()
    }

    private func deleteTasks(at offsets: IndexSet) {
        offsets.map { tasks[$0] }.forEach(modelContext.delete)
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to update task: \(error)")
        }
    }
}
