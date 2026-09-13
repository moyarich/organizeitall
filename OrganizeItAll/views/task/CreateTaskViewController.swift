import SwiftData
import SwiftUI

@available(iOS 17.0, *)
struct TaskEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \List.name) private var lists: [List]

    private let task: Task?
    private let defaultList: List?

    @State private var title: String
    @State private var detail: String
    @State private var selectedListID: UUID?

    init(task: Task? = nil, defaultList: List? = nil) {
        self.task = task
        self.defaultList = defaultList
        _title = State(initialValue: task?.title ?? "")
        _detail = State(initialValue: task?.detail ?? "")
        _selectedListID = State(initialValue: task?.list?.id ?? defaultList?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)

                    Picker("List", selection: $selectedListID) {
                        Text("Inbox").tag(Optional<UUID>.none)
                        ForEach(lists) { list in
                            Text(list.wrappedName)
                                .tag(Optional(list.id))
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $detail)
                        .frame(minHeight: 130)
                }

                if let task {
                    Section {
                        Button(task.isComplete ? "Mark Incomplete" : "Mark Complete") {
                            task.isComplete.toggle()
                            task.modifiedDate = .now
                            persistAndDismiss()
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }

        let now = Date()
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        if let task {
            task.title = trimmedTitle
            task.detail = trimmedDetail
            task.list = selectedList
            task.modifiedDate = now
        } else {
            let task = Task(
                title: trimmedTitle,
                detail: trimmedDetail,
                createdDate: now,
                modifiedDate: now,
                list: selectedList
            )
            modelContext.insert(task)
        }

        persistAndDismiss()
    }

    private var selectedList: List? {
        guard let selectedListID else { return nil }
        return lists.first { $0.id == selectedListID } ?? defaultList
    }

    private func persistAndDismiss() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save task: \(error)")
        }
    }
}
