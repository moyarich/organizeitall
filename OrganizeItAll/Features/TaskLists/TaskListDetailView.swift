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

struct InboxTaskListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.modifiedAt, order: .reverse) private var tasks: [TaskItem]
    @State private var activeSheet: TaskListSheet?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            colors.surface.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    inboxHeader

                    if inboxTasks.isEmpty {
                        MaterialEmptyState(
                            title: "Inbox is empty",
                            message: "Tasks you create without choosing a list will appear here automatically.",
                            systemImage: "tray"
                        )
                    } else {
                        ForEach(inboxTasks) { task in
                            MaterialCard {
                                TaskRow(task: task) {
                                    task.setCompleted(!task.isCompleted)
                                    saveChanges()
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeSheet = .editTask(task)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
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
            case .editList:
                EmptyView()
            case .newTask:
                TaskEditorView()
            case .editTask(let task):
                TaskEditorView(task: task)
            }
        }
    }

    private var inboxTasks: [TaskItem] {
        tasks.filter(\.isInInbox).sorted(by: TaskItem.displayOrder)
    }

    private var inboxHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
                .font(.title3.bold())
                .foregroundStyle(colors.onSurface)

                Spacer()

                Text("Default list")
                    .font(MaterialTypography.labelLarge)
                    .foregroundStyle(colors.onSecondaryContainer)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(colors.secondaryContainer, in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Inbox")
                    .font(MaterialTypography.headlineLarge)

                Text("Tasks not assigned to another list are collected here automatically.")
                    .font(MaterialTypography.bodyLarge)
                    .foregroundStyle(colors.onSurfaceVariant)

                Text("\(openInboxTaskCount) open · \(inboxTasks.count) total")
                    .font(MaterialTypography.labelLarge)
                    .foregroundStyle(colors.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    private var openInboxTaskCount: Int {
        inboxTasks.lazy.filter { !$0.isCompleted }.count
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save Inbox task changes: \(error)")
        }
    }
}

struct TaskListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    let list: TaskList
    @State private var activeSheet: TaskListSheet?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            colors.surface.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    header

                    if list.tasks.isEmpty {
                        MaterialEmptyState(
                            title: "No tasks in this list",
                            message: "Add a task to \(list.displayName).",
                            systemImage: "checkmark.circle"
                        )
                    } else {
                        ForEach(list.sortedTasks) { task in
                            MaterialCard {
                                TaskRow(task: task) {
                                    task.setCompleted(!task.isCompleted)
                                    saveChanges()
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeSheet = .editTask(task)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
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
            case .editList:
                TaskListEditorView(list: list)
            case .newTask:
                TaskEditorView(defaultList: list)
            case .editTask(let task):
                TaskEditorView(task: task, defaultList: list)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
                .font(.title3.bold())
                .foregroundStyle(colors.onSurface)

                Spacer()

                Button("Edit", systemImage: "pencil") {
                    activeSheet = .editList
                }
                .font(MaterialTypography.labelLarge)
                .foregroundStyle(colors.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(list.displayName)
                    .font(MaterialTypography.headlineLarge)

                if !list.displayNotes.isEmpty {
                    Text(list.displayNotes)
                        .font(MaterialTypography.bodyLarge)
                        .foregroundStyle(colors.onSurfaceVariant)
                }

                Text("\(list.openTaskCount) open · \(list.tasks.count) total")
                    .font(MaterialTypography.labelLarge)
                    .foregroundStyle(colors.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
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
