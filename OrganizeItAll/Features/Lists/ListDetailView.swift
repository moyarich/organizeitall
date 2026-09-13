import SwiftData
import SwiftUI

private enum ListSheet: Identifiable {
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

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let list: TaskList
    @State private var activeSheet: ListSheet?

    var body: some View {
        Group {
            if list.tasks.isEmpty {
                ContentUnavailableView("No Tasks in This List", systemImage: "checkmark.circle", description: Text("Add a task to \(list.displayName)."))
            } else {
                List {
                    ForEach(list.sortedTasks) { task in
                        TaskRow(task: task, onToggle: { toggle(task) })
                            .contentShape(Rectangle())
                            .onTapGesture { activeSheet = .editTask(task) }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .navigationTitle(list.displayName)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit List", systemImage: "pencil") { activeSheet = .editList }
                Button("New Task", systemImage: "plus") { activeSheet = .newTask }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editList: ListEditorView(list: list)
            case .newTask: TaskEditorView(defaultList: list)
            case .editTask(let task): TaskEditorView(task: task, defaultList: list)
            }
        }
    }

    private func toggle(_ task: TaskItem) { task.setCompleted(!task.isCompleted); save() }
    private func deleteTasks(at offsets: IndexSet) {
        let visibleTasks = list.sortedTasks
        for index in offsets { modelContext.delete(visibleTasks[index]) }
        save()
    }
    private func save() {
        do { try modelContext.save() }
        catch { modelContext.rollback(); assertionFailure("Unable to save task changes: \(error)") }
    }
}
