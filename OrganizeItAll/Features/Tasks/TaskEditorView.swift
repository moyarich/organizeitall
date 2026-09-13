import SwiftData
import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.name) private var lists: [TaskList]
    private let task: TaskItem?
    private let defaultList: TaskList?
    @State private var title: String
    @State private var notes: String
    @State private var selectedListID: UUID?
    @State private var priority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isConfirmingDelete = false

    init(task: TaskItem? = nil, defaultList: TaskList? = nil) {
        self.task = task
        self.defaultList = defaultList
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _selectedListID = State(initialValue: task?.list?.id ?? defaultList?.id)
        _priority = State(initialValue: task?.priority ?? .normal)
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: task?.dueDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title).textInputAutocapitalization(.sentences)
                    Picker("List", selection: $selectedListID) {
                        Text("Inbox").tag(Optional<UUID>.none)
                        ForEach(lists) { list in Text(list.displayName).tag(Optional(list.id)) }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in Label(priority.title, systemImage: priority.systemImage).tag(priority) }
                    }
                }
                Section("Schedule") {
                    Toggle("Due Date", isOn: $hasDueDate.animation())
                    if hasDueDate { DatePicker("Due", selection: $dueDate, displayedComponents: [.date]) }
                }
                Section("Notes") { TextEditor(text: $notes).frame(minHeight: 120) }
                if let task {
                    Section { Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") { task.setCompleted(!task.isCompleted); persistAndDismiss() } }
                    Section { Button("Delete Task", role: .destructive) { isConfirmingDelete = true } }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(trimmedTitle.isEmpty) }
            }
            .confirmationDialog("Delete this task?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete Task", role: .destructive, action: deleteTask)
            } message: { Text("This action cannot be undone.") }
        }
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var selectedList: TaskList? {
        guard let selectedListID else { return nil }
        return lists.first(where: { $0.id == selectedListID }) ?? defaultList
    }
    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        let now = Date.now
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedDueDate = hasDueDate ? dueDate : nil
        if let task {
            task.title = trimmedTitle; task.notes = trimmedNotes; task.list = selectedList; task.priority = priority; task.dueDate = selectedDueDate; task.modifiedAt = now
        } else {
            modelContext.insert(TaskItem(title: trimmedTitle, notes: trimmedNotes, createdAt: now, modifiedAt: now, dueDate: selectedDueDate, priority: priority, list: selectedList))
        }
        persistAndDismiss()
    }
    private func deleteTask() { guard let task else { return }; modelContext.delete(task); persistAndDismiss() }
    private func persistAndDismiss() {
        do { try modelContext.save(); dismiss() }
        catch { modelContext.rollback(); assertionFailure("Unable to save task: \(error)") }
    }
}
