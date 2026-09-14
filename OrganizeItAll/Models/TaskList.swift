import Foundation
import SwiftData

@Model
final class TaskList {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String
    var createdAt: Date
    var modifiedAt: Date
    var iconName: String = "folder.fill"
    var colorToken: String = "primary"
    var isPinned: Bool = false
    var isArchived: Bool = false
    var manualOrder: Double = 0

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.list)
    var tasks: [TaskItem]

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        iconName: String = "folder.fill",
        colorToken: String = "primary",
        isPinned: Bool = false,
        isArchived: Bool = false,
        manualOrder: Double = Date.now.timeIntervalSinceReferenceDate,
        tasks: [TaskItem] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.iconName = iconName
        self.colorToken = colorToken
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.manualOrder = manualOrder
        self.tasks = tasks
    }
}

extension TaskList {
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled List" : trimmed
    }

    var displayNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var openTaskCount: Int {
        tasks.lazy.filter { !$0.isCompleted }.count
    }

    var sortedTasks: [TaskItem] {
        tasks.sorted(by: TaskItem.displayOrder)
    }

    var manuallySortedTasks: [TaskItem] {
        tasks.sorted(by: TaskItem.manualDisplayOrder)
    }

    static func normalizedName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    static func manualDisplayOrder(_ lhs: TaskList, _ rhs: TaskList) -> Bool {
        if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
        if lhs.manualOrder != rhs.manualOrder { return lhs.manualOrder < rhs.manualOrder }
        return lhs.modifiedAt > rhs.modifiedAt
    }
}
