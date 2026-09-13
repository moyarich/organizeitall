import SwiftData
import SwiftUI

private enum TaskListSheet: Identifiable {
    case editList
    case newTask
    case editTask(TaskItem)

    var id: String {
        switch self {
        case .editList: "edit-list"
        case .newTask: "new-task"
        case .editTask(let task): "edit-task-\(task.id.uuidString)"
        }
    }
}

struct TaskListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let list: TaskList
    @State private var activeSheet: TaskListSheet?

    var body: some View {
        Group {
            if list.tasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks in This List",
                    systemImage: "checkmark.circle",
                    description: Text("Add a task to \(list.displayName).")
                )
            } else {
                List {
                    ForEach(list.sortedTasks) { task in
                        TaskRow(task: task) {
                            task.setCompleted(!task.isCompleted)
                            saveChanges()
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
        .navigationTitle(list.displayName)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit List", systemImage: "pencil") {
                    activeSheet = .editList
                }
                Button("New Task", systemImage: "plus") {
                    activeSheet = .newTask
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editList:
                TaskListEditorView(list: list)
            case .newTask:
                TaskEditorView(defaultList: list)
            case .editTask(let task):
                TaskEditorView(task: task, defaultList: list)
            }
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        let visibleTasks = list.sortedTasks
        for index in offsets {
            modelContext.delete(visibleTasks[index])
        }
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save task changes: \(error)")
        }
    }
}
