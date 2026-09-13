import SwiftData
import SwiftUI

struct TaskListEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let list: TaskList?
    @State private var name: String
    @State private var notes: String

    init(list: TaskList? = nil) {
        self.list = list
        _name = State(initialValue: list?.name ?? "")
        _notes = State(initialValue: list?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("List") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.sentences)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(list == nil ? "New List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }

        let now = Date.now
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let list {
            list.name = trimmedName
            list.notes = trimmedNotes
            list.modifiedAt = now
        } else {
            modelContext.insert(
                TaskList(
                    name: trimmedName,
                    notes: trimmedNotes,
                    createdAt: now,
                    modifiedAt: now
                )
            )
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save list: \(error)")
        }
    }
}
