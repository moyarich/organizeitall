import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var createdAt: Date
    var modifiedAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var priorityRawValue: Int
    var list: TaskList?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority = .normal,
        list: TaskList? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.priorityRawValue = priority.rawValue
        self.list = list
    }
}

extension TaskItem {
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Task" : trimmed
    }

    var displayNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isInInbox: Bool {
        list == nil
    }

    var listName: String {
        isInInbox ? "Inbox" : list?.displayName ?? "Inbox"
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .normal }
        set { priorityRawValue = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard !isCompleted, let dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: .now)
    }

    func setCompleted(_ completed: Bool) {
        isCompleted = completed
        completedAt = completed ? .now : nil
        modifiedAt = .now
    }

    static func displayOrder(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
        if lhs.priorityRawValue != rhs.priorityRawValue { return lhs.priorityRawValue > rhs.priorityRawValue }

        switch (lhs.dueDate, rhs.dueDate) {
        case let (left?, right?) where left != right:
            return left < right
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            return lhs.modifiedAt > rhs.modifiedAt
        }
    }
}
