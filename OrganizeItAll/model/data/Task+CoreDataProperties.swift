import Foundation

@available(iOS 17.0, *)
extension Task {
    var wrappedTitle: String {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Untitled Task" : value
    }

    var wrappedDetail: String {
        detail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var listName: String {
        list?.wrappedName ?? "Inbox"
    }
}
