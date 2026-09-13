import SwiftData
import SwiftUI

@available(iOS 17.0, *)
struct ListEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let list: List?

    @State private var name: String
    @State private var detail: String

    init(list: List? = nil) {
        self.list = list
        _name = State(initialValue: list?.name ?? "")
        _detail = State(initialValue: list?.detail ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("List") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.sentences)

                    TextField("Description", text: $detail, axis: .vertical)
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

        let now = Date()
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        if let list {
            list.name = trimmedName
            list.detail = trimmedDetail
            list.modifiedDate = now
        } else {
            let list = List(
                name: trimmedName,
                detail: trimmedDetail,
                createdDate: now,
                modifiedDate: now
            )
            modelContext.insert(list)
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
