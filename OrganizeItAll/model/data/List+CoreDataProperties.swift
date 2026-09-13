import CoreData
import Foundation

extension List {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<List> {
        NSFetchRequest<List>(entityName: "List")
    }

    @NSManaged public var created_date: Date?
    @NSManaged public var detail: String?
    @NSManaged public var modified_date: Date?
    @NSManaged public var name: String?
    @NSManaged public var listId: Int16
    @NSManaged public var task: NSSet?
}

extension List {
    @objc(addTaskObject:)
    @NSManaged public func addToTask(_ value: Task)

    @objc(removeTaskObject:)
    @NSManaged public func removeFromTask(_ value: Task)

    @objc(addTask:)
    @NSManaged public func addToTask(_ values: NSSet)

    @objc(removeTask:)
    @NSManaged public func removeFromTask(_ values: NSSet)
}

extension List {
    var wrappedName: String {
        let value = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Untitled List" : value
    }

    var wrappedDetail: String {
        detail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var tasksArray: [Task] {
        let tasks = task?.allObjects as? [Task] ?? []
        return tasks.sorted {
            ($0.modified_date ?? .distantPast) > ($1.modified_date ?? .distantPast)
        }
    }

    var openTaskCount: Int {
        tasksArray.filter { !$0.isComplete }.count
    }
}
