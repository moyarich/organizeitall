import Foundation
import SwiftData

@Model
final class TaskList {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.list)
    var tasks: [TaskItem]

    init(id: UUID = UUID(), name: String, notes: String = "", createdAt: Date = .now, modifiedAt: Date = .now, tasks: [TaskItem] = []) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
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
}
