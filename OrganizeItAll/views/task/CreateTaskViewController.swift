import CoreData
import SwiftUI
import UIKit

struct TaskEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentationMode

    @FetchRequest(
        entity: List.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var lists: FetchedResults<List>

    private let task: Task?
    private let defaultList: List?

    @State private var title: String
    @State private var detail: String
    @State private var selectedListURI: String

    private static let inboxSelection = "__inbox__"

    init(task: Task? = nil, defaultList: List? = nil) {
        self.task = task
        self.defaultList = defaultList
        _title = State(initialValue: task?.title ?? "")
        _detail = State(initialValue: task?.detail ?? "")

        let initialList = task?.list ?? defaultList
        _selectedListURI = State(
            initialValue: initialList?.objectID.uriRepresentation().absoluteString ?? Self.inboxSelection
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task")) {
                    TextField("Title", text: $title)
                        .autocapitalization(.sentences)

                    Picker("List", selection: $selectedListURI) {
                        Text("Inbox").tag(Self.inboxSelection)
                        ForEach(lists, id: \.objectID) { list in
                            Text(list.wrappedName)
                                .tag(list.objectID.uriRepresentation().absoluteString)
                        }
                    }
                }

                Section(header: Text("Notes")) {
                    ZStack(alignment: .topLeading) {
                        if detail.isEmpty {
                            Text("Add notes")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.top, 9)
                                .padding(.leading, 5)
                        }

                        MultilineTextView(text: $detail)
                            .frame(minHeight: 130)
                    }
                }

                if let task = task {
                    Section {
                        Button(task.isComplete ? "Mark Incomplete" : "Mark Complete") {
                            task.isComplete.toggle()
                            task.modified_date = Date()
                            persistAndDismiss()
                        }
                    }
                }
            }
            .navigationBarTitle(task == nil ? "New Task" : "Edit Task", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save", action: save)
                    .disabled(trimmedTitle.isEmpty)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }

        let item = task ?? Task(context: context)
        let now = Date()

        if item.created_date == nil {
            item.created_date = now
        }
        item.modified_date = now
        item.title = trimmedTitle
        item.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        item.list = selectedList

        if task == nil {
            item.isComplete = false
        }

        persistAndDismiss()
    }

    private var selectedList: List? {
        guard selectedListURI != Self.inboxSelection else { return nil }
        return lists.first {
            $0.objectID.uriRepresentation().absoluteString == selectedListURI
        } ?? defaultList
    }

    private func persistAndDismiss() {
        do {
            try context.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            context.rollback()
            assertionFailure("Unable to save task: \(error)")
        }
    }
}

struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}
