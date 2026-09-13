import SwiftData
import Testing
@testable import OrganizeItAll

@Suite("TaskItem")
struct TaskItemTests {
    @Test("Unassigned tasks belong to Inbox")
    @MainActor
    func unassignedTaskUsesInbox() throws {
        let context = try makeTestModelContext()
        let task = TaskItem(title: "Call dentist")

        context.insert(task)
        try context.save()

        #expect(task.list == nil)
        #expect(task.listName == "Inbox")
    }

    @Test("Completion updates completedAt")
    @MainActor
    func completionTracksDate() throws {
        let context = try makeTestModelContext()
        let task = TaskItem(title: "Finish tests")
        context.insert(task)

        task.setCompleted(true)
        try context.save()
        #expect(task.isCompleted)
        #expect(task.completedAt != nil)

        task.setCompleted(false)
        try context.save()
        #expect(!task.isCompleted)
        #expect(task.completedAt == nil)
    }

    @Test("High priority sorts before normal priority")
    func prioritySorting() {
        let normal = TaskItem(title: "Normal", priority: .normal)
        let high = TaskItem(title: "High", priority: .high)
        let sorted = [normal, high].sorted(by: TaskItem.displayOrder)

        #expect(sorted.first?.title == "High")
    }
}
