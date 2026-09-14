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

    @Test("Moving a task updates both lists and returning it to Inbox removes membership")
    @MainActor
    func moveTaskBetweenListsAndInbox() throws {
        let context = try makeTestModelContext()
        let source = TaskList(name: "Source")
        let destination = TaskList(name: "Destination")
        context.insert(source)
        context.insert(destination)
        let task = TaskItem(title: "Move me", list: source)
        context.insert(task)
        try context.save()
        task.list = destination
        try context.save()
        #expect(source.tasks.isEmpty)
        #expect(destination.tasks.map(\.id) == [task.id])
        #expect(task.listName == "Destination")
        task.list = nil
        try context.save()
        #expect(destination.tasks.isEmpty)
        let fresh = ModelContext(context.container)
        let saved = try #require(fresh.fetch(FetchDescriptor<TaskItem>()).first)
        #expect(saved.list == nil)
        #expect(saved.listName == "Inbox")
    }

    @Test("Deleting one task preserves its list and sibling tasks")
    @MainActor
    func deleteTaskPreservesList() throws {
        let context = try makeTestModelContext()
        let list = TaskList(name: "Work")
        context.insert(list)
        let removed = TaskItem(title: "Remove", list: list)
        let retained = TaskItem(title: "Keep", list: list)
        context.insert(removed)
        context.insert(retained)
        try context.save()
        context.delete(removed)
        try context.save()
        let fresh = ModelContext(context.container)
        let savedList = try #require(fresh.fetch(FetchDescriptor<TaskList>()).first)
        #expect(savedList.tasks.map(\.id) == [retained.id])
        #expect(try fresh.fetch(FetchDescriptor<TaskItem>()).count == 1)
    }

    @Test("Open task count follows completion and reopening")
    @MainActor
    func openCountTracksCompletion() throws {
        let context = try makeTestModelContext()
        let list = TaskList(name: "Work")
        context.insert(list)
        let task = TaskItem(title: "Do work", list: list)
        context.insert(task)
        try context.save()
        #expect(list.openTaskCount == 1)
        task.setCompleted(true)
        #expect(list.openTaskCount == 0)
        task.setCompleted(false)
        #expect(list.openTaskCount == 1)
    }
}
