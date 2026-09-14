import SwiftData
import SwiftUI

struct TaskListEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext

    private let list: TaskList?
    @State private var name: String
    @State private var notes: String
    @State private var isConfirmingDelete = false

    init(list: TaskList? = nil) {
        self.list = list
        _name = State(initialValue: list?.name ?? "")
        _notes = State(initialValue: list?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        MaterialTextField(label: "List name", text: $name, systemImage: "folder")
                            .textInputAutocapitalization(.sentences)

                        if isInboxName {
                            Text("Inbox is the built-in default list and cannot be used as a custom list name.")
                                .font(MaterialTypography.bodyMedium)
                                .foregroundStyle(colors.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        MaterialMultilineField(label: "Notes", text: $notes, minHeight: 140)

                        if list != nil {
                            Button("Delete list", systemImage: "trash", role: .destructive) {
                                isConfirmingDelete = true
                            }
                            .font(MaterialTypography.labelLarge)
                            .foregroundStyle(colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay {
                                RoundedRectangle(cornerRadius: MaterialShape.extraLarge, style: .continuous)
                                    .stroke(colors.error, lineWidth: 1)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(list == nil ? "New list" : "Edit list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.primary)
                        .disabled(trimmedName.isEmpty || isInboxName)
                }
            }
            .confirmationDialog("Delete this list?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete list", role: .destructive, action: deleteList)
            } message: {
                Text("Tasks in this list will be preserved in Inbox.")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isInboxName: Bool {
        trimmedName.caseInsensitiveCompare("Inbox") == .orderedSame
    }

    private func save() {
        guard !trimmedName.isEmpty, !isInboxName else { return }

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

        persistAndDismiss()
    }

    private func deleteList() {
        guard let list else { return }
        modelContext.delete(list)
        persistAndDismiss()
    }

    private func persistAndDismiss() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save list: \(error)")
        }
    }
}
