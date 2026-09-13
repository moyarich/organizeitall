import Foundation
import SwiftData

@available(iOS 17.0, *)
@Model
final class Task: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var isComplete: Bool
    var createdDate: Date
    var modifiedDate: Date
    var list: List?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        isComplete: Bool = false,
        createdDate: Date = .now,
        modifiedDate: Date = .now,
        list: List? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isComplete = isComplete
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.list = list
    }
}
