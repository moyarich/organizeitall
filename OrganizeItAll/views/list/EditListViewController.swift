import CoreData
import SwiftUI

private enum ListDetailSheet: Identifiable {
    case editList
    case newTask
    case editTask(Task)

    var id: String {
        switch self {
        case .editList:
            return "edit-list"
        case .newTask:
            return "new-task"
        case .editTask(let task):
            return "edit-\(task.objectID.uriRepresentation().absoluteString)"
        }
    }
}

struct ListDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var list: List

    @FetchRequest private var tasks: FetchedResults<Task>
    @State private var activeSheet: ListDetailSheet?

    init(list: List) {
        self.list = list
        _tasks = FetchRequest<Task>(
            entity: Task.entity(),
            sortDescriptors: [NSSortDescriptor(key: "modified_date", ascending: false)],
            predicate: NSPredicate(format: "list == %@", list)
        )
    }

    var body: some View {
        Group {
            if tasks.isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: "No tasks in this list",
                    message: "Add the first task and keep everything for \(list.wrappedName) together."
                )
            } else {
                SwiftUI.List {
                    ForEach(tasks, id: \.objectID) { task in
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
                .listStyle(PlainListStyle())
            }
        }
        .navigationBarTitle(list.wrappedName, displayMode: .large)
        .navigationBarItems(
            trailing: HStack(spacing: 16) {
                Button(action: { activeSheet = .editList }) {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit list")

                Button(action: { activeSheet = .newTask }) {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Create task")
            }
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editList:
                ListEditorView(list: list)
                    .environment(\.managedObjectContext, context)
            case .newTask:
                TaskEditorView(defaultList: list)
                    .environment(\.managedObjectContext, context)
            case .editTask(let task):
                TaskEditorView(task: task, defaultList: list)
                    .environment(\.managedObjectContext, context)
            }
        }
    }

    private func toggle(_ task: Task) {
        task.isComplete.toggle()
        task.modified_date = Date()
        save()
    }

    private func deleteTasks(at offsets: IndexSet) {
        offsets.map { tasks[$0] }.forEach(context.delete)
        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            context.rollback()
            assertionFailure("Unable to update task: \(error)")
        }
    }
}
