import SwiftData
import SwiftUI

enum TaskFilter: String, CaseIterable, Identifiable {
    case open = "Open"
    case all = "All"
    case completed = "Done"
    var id: Self { self }
}

private enum TaskSheet: Identifiable {
    case newTask
    case edit(TaskItem)
    var id: String {
        switch self {
        case .newTask: "new-task"
        case .edit(let task): "edit-task-\(task.id.uuidString)"
        }
    }
}

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.modifiedAt, order: .reverse) private var tasks: [TaskItem]
    @State private var searchText = ""
    @State private var filter: TaskFilter = .open
    @State private var activeSheet: TaskSheet?

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Picker("Task Filter", selection: $filter) {
                    ForEach(TaskFilter.allCases) { filter in Text(filter.rawValue).tag(filter) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                if filteredTasks.isEmpty {
                    ContentUnavailableView(emptyTitle, systemImage: emptySystemImage, description: Text(emptyMessage))
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task, onToggle: { toggle(task) })
                                .contentShape(Rectangle())
                                .onTapGesture { activeSheet = .edit(task) }
                        }
                        .onDelete(perform: deleteTasks)
                    }
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks, notes, or lists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) { Button("New Task", systemImage: "plus") { activeSheet = .newTask } }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .newTask: TaskEditorView()
                case .edit(let task): TaskEditorView(task: task)
                }
            }
        }
    }

    private var filteredTasks: [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return tasks.filter { task in
            let matchesFilter = switch filter {
            case .open: !task.isCompleted
            case .all: true
            case .completed: task.isCompleted
            }
            guard matchesFilter else { return false }
            guard !query.isEmpty else { return true }
            return task.displayTitle.lowercased().contains(query) || task.displayNotes.lowercased().contains(query) || task.listName.lowercased().contains(query)
        }.sorted(by: TaskItem.displayOrder)
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No Matching Tasks" }
        switch filter { case .open: "You're All Caught Up"; case .all: "No Tasks Yet"; case .completed: "Nothing Completed Yet" }
    }
    private var emptySystemImage: String { filter == .completed ? "checkmark.seal" : "checkmark.circle" }
    private var emptyMessage: String {
        if !searchText.isEmpty { return "Try a different search." }
        switch filter { case .open: "Add a task when something new needs your attention."; case .all: "Create your first task to get organized."; case .completed: "Completed tasks will appear here." }
    }
    private func toggle(_ task: TaskItem) { task.setCompleted(!task.isCompleted); save() }
    private func deleteTasks(at offsets: IndexSet) {
        let visibleTasks = filteredTasks
        for index in offsets { modelContext.delete(visibleTasks[index]) }
        save()
    }
    private func save() {
        do { try modelContext.save() }
        catch { modelContext.rollback(); assertionFailure("Unable to save task changes: \(error)") }
    }
}
