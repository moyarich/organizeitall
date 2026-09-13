import SwiftData
import SwiftUI

@available(iOS 17.0, *)
private enum TaskSheet: Identifiable {
    case new
    case edit(Task)

    var id: String {
        switch self {
        case .new:
            "new-task"
        case .edit(let task):
            "edit-\(task.id.uuidString)"
        }
    }
}

@available(iOS 17.0, *)
struct AllTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.modifiedDate, order: .reverse) private var tasks: [Task]

    @State private var query = ""
    @State private var filter: TaskFilter = .open
    @State private var activeSheet: TaskSheet?

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Picker("Filter", selection: $filter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if filteredTasks.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: filter == .completed ? "checkmark.seal" : "checkmark.circle",
                        description: Text(emptyMessage)
                    )
                } else {
                    SwiftUI.List {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task) {
                                toggle(task)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeSheet = .edit(task)
                            }
                        }
                        .onDelete(perform: deleteTasks)
                    }
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $query, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create Task", systemImage: "plus") {
                        activeSheet = .new
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .new:
                    TaskEditorView()
                case .edit(let task):
                    TaskEditorView(task: task)
                }
            }
        }
    }

    private var filteredTasks: [Task] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return tasks.filter { task in
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .open:
                matchesFilter = !task.isComplete
            case .completed:
                matchesFilter = task.isComplete
            }

            guard matchesFilter else { return false }
            guard !needle.isEmpty else { return true }

            return task.wrappedTitle.lowercased().contains(needle)
                || task.wrappedDetail.lowercased().contains(needle)
                || task.listName.lowercased().contains(needle)
        }
    }

    private var emptyTitle: String {
        if !query.isEmpty { return "No matching tasks" }
        switch filter {
        case .all: return "No tasks yet"
        case .open: return "You're all caught up"
        case .completed: return "Nothing completed yet"
        }
    }

    private var emptyMessage: String {
        if !query.isEmpty { return "Try a different title, note, or list name." }
        switch filter {
        case .all: return "Create a task to start organizing your work."
        case .open: return "Add a task whenever something new needs your attention."
        case .completed: return "Completed tasks will appear here."
        }
    }

    private func toggle(_ task: Task) {
        task.isComplete.toggle()
        task.modifiedDate = .now
        save()
    }

    private func deleteTasks(at offsets: IndexSet) {
        let visibleTasks = filteredTasks
        offsets.map { visibleTasks[$0] }.forEach(modelContext.delete)
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to update tasks: \(error)")
        }
    }
}
