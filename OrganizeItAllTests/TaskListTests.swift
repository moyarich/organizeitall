import SwiftData
import Testing
@testable import OrganizeItAll

@Suite("TaskList")
struct TaskListTests {
    @Test("A task can belong to a list")
    @MainActor
    func taskRelationship() throws {
        let context = try makeTestModelContext()
        let list = TaskList(name: "Work")
        let task = TaskItem(title: "Ship release", list: list)

        context.insert(list)
        context.insert(task)
        try context.save()

        #expect(task.list?.name == "Work")
        #expect(list.tasks.contains(where: { $0.id == task.id }))
    }

    @Test("Deleting a list preserves its tasks in Inbox")
    @MainActor
    func deletingListNullifiesRelationship() throws {
        let context = try makeTestModelContext()
        let list = TaskList(name: "Errands")
        let task = TaskItem(title: "Buy milk", list: list)

        context.insert(list)
        context.insert(task)
        try context.save()

        context.delete(list)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        #expect(tasks.count == 1)
        #expect(tasks.first?.list == nil)
        #expect(tasks.first?.listName == "Inbox")
    }
}
