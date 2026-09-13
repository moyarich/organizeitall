import CoreData
import SwiftUI

struct ListEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentationMode

    private let list: List?

    @State private var name: String
    @State private var detail: String

    init(list: List? = nil) {
        self.list = list
        _name = State(initialValue: list?.name ?? "")
        _detail = State(initialValue: list?.detail ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("List")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.sentences)

                    ZStack(alignment: .topLeading) {
                        if detail.isEmpty {
                            Text("Description")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 9)
                                .padding(.leading, 5)
                        }

                        MultilineTextView(text: $detail)
                            .frame(minHeight: 90)
                    }
                }
            }
            .navigationBarTitle(list == nil ? "New List" : "Edit List", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save", action: save)
                    .disabled(trimmedName.isEmpty)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }

        let item = list ?? List(context: context)
        let now = Date()

        if item.created_date == nil {
            item.created_date = now
        }
        item.modified_date = now
        item.name = trimmedName
        item.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try context.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            context.rollback()
            assertionFailure("Unable to save list: \(error)")
        }
    }
}
