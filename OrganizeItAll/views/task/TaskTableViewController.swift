import CoreData
import SwiftUI

private enum TaskSheet: Identifiable {
    case new
    case edit(Task)

    var id: String {
        switch self {
        case .new:
            return "new-task"
        case .edit(let task):
            return "edit-\(task.objectID.uriRepresentation().absoluteString)"
        }
    }
}

struct AllTasksView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        entity: Task.entity(),
        sortDescriptors: [NSSortDescriptor(key: "modified_date", ascending: false)]
    ) private var tasks: FetchedResults<Task>

    @State private var query = ""
    @State private var filter: TaskFilter = .open
    @State private var activeSheet: TaskSheet?

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                SearchField(text: $query)

                Picker("Filter", selection: $filter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if filteredTasks.isEmpty {
                    EmptyStateView(
                        systemImage: filter == .completed ? "checkmark.seal" : "checkmark.circle",
                        title: emptyTitle,
                        message: emptyMessage
                    )
                } else {
                    SwiftUI.List {
                        ForEach(filteredTasks, id: \.objectID) { task in
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
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarTitle("Tasks", displayMode: .large)
            .navigationBarItems(
                leading: EditButton(),
                trailing: Button(action: { activeSheet = .new }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Create task")
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                TaskEditorView()
                    .environment(\.managedObjectContext, context)
            case .edit(let task):
                TaskEditorView(task: task)
                    .environment(\.managedObjectContext, context)
            }
        }
    }

    private var filteredTasks: [Task] {
        tasks.filter { task in
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
            guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }

            let needle = query.lowercased()
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
        task.modified_date = Date()
        save()
    }

    private func deleteTasks(at offsets: IndexSet) {
        let visibleTasks = filteredTasks
        offsets.map { visibleTasks[$0] }.forEach(context.delete)
        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            context.rollback()
            assertionFailure("Unable to update tasks: \(error)")
        }
    }
}
