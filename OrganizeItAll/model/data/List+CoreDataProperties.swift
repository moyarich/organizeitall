import Foundation

@available(iOS 17.0, *)
extension List {
    var wrappedName: String {
        let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Untitled List" : value
    }

    var wrappedDetail: String {
        detail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var tasksArray: [Task] {
        tasks.sorted { $0.modifiedDate > $1.modifiedDate }
    }

    var openTaskCount: Int {
        tasks.lazy.filter { !$0.isComplete }.count
    }
}
