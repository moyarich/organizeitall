import Foundation
import SwiftData

@available(iOS 17.0, *)
@Model
final class List: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var detail: String
    var createdDate: Date
    var modifiedDate: Date

    @Relationship(deleteRule: .nullify, inverse: \Task.list)
    var tasks: [Task]

    init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        createdDate: Date = .now,
        modifiedDate: Date = .now,
        tasks: [Task] = []
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.tasks = tasks
    }
}
