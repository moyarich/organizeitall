import SwiftData
import SwiftUI

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
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.modifiedAt, order: .reverse) private var tasks: [TaskItem]

    @State private var searchText = ""
    @State private var filter: TaskFilter = .open
    @State private var activeSheet: TaskSheet?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Tasks")
                            .font(MaterialTypography.headlineLarge)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)

                        MaterialSearchBar(text: $searchText, prompt: "Search tasks")

                        HStack(spacing: 8) {
                            ForEach(TaskFilter.allCases) { option in
                                MaterialFilterChip(
                                    title: option.rawValue,
                                    systemImage: nil,
                                    isSelected: filter == option
                                ) {
                                    filter = option
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)

                        if filteredTasks.isEmpty {
                            MaterialEmptyState(
                                title: emptyTitle,
                                message: emptyMessage,
                                systemImage: emptySystemImage
                            )
                        } else {
                            ForEach(filteredTasks) { task in
                                MaterialCard {
                                    TaskRow(task: task) {
                                        task.setCompleted(!task.isCompleted)
                                        saveChanges()
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    activeSheet = .edit(task)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 96)
                }

                MaterialFloatingActionButton(title: "New task", systemImage: "plus") {
                    activeSheet = .newTask
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .newTask:
                    TaskEditorView()
                case .edit(let task):
                    TaskEditorView(task: task)
                }
            }
        }
    }

    private var filteredTasks: [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return tasks
            .filter { task in
                let matchesFilter = switch filter {
                case .open: !task.isCompleted
                case .all: true
                case .completed: task.isCompleted
                }

                guard matchesFilter else { return false }
                guard !query.isEmpty else { return true }

                return task.displayTitle.lowercased().contains(query)
                    || task.displayNotes.lowercased().contains(query)
                    || task.listName.lowercased().contains(query)
            }
            .sorted(by: TaskItem.displayOrder)
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No matching tasks" }

        return switch filter {
        case .open: "You're all caught up"
        case .all: "No tasks yet"
        case .completed: "Nothing completed yet"
        }
    }

    private var emptySystemImage: String {
        filter == .completed ? "checkmark.seal" : "checkmark.circle"
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "Try a different search." }

        return switch filter {
        case .open: "Add a task when something new needs your attention."
        case .all: "Create your first task to get organized."
        case .completed: "Completed tasks will appear here."
        }
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
