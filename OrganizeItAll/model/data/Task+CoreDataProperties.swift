import CoreData
import Foundation

extension Task {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var created_date: Date?
    @NSManaged public var detail: String?
    @NSManaged public var isComplete: Bool
    @NSManaged public var modified_date: Date?
    @NSManaged public var title: String?
    @NSManaged public var list: List?
}

extension Task {
    var wrappedTitle: String {
        let value = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Untitled Task" : value
    }

    var wrappedDetail: String {
        detail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var listName: String {
        list?.wrappedName ?? "Inbox"
    }
}
