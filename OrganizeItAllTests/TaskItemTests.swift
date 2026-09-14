import Foundation
import SwiftData
import Testing
@testable import OrganizeItAll

@Suite("TaskItem")
struct TaskItemTests {
    @Test("Unassigned tasks belong to Inbox by default")
    @MainActor
    func unassignedTaskUsesInbox() throws {
        let context = try makeTestModelContext()
        let task = TaskItem(title: "Call dentist")

        context.insert(task)
        try context.save()

        #expect(task.list == nil)
        #expect(task.isInInbox)
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

    @Test("Open tasks precede completed tasks regardless of priority")
    func openTasksSortFirst() {
        let open = TaskItem(title: "Open", priority: .low)
        let done = TaskItem(title: "Done", isCompleted: true, priority: .high)
        #expect([done, open].sorted(by: TaskItem.displayOrder).map(\.id) == [open.id, done.id])
    }

    @Test("Due dates precede undated tasks and earlier dates come first")
    func dueDateSorting() {
        let early = TaskItem(title: "Early", dueDate: Date(timeIntervalSince1970: 100))
        let late = TaskItem(title: "Late", dueDate: Date(timeIntervalSince1970: 200))
        let undated = TaskItem(title: "Undated")
        #expect([undated, late, early].sorted(by: TaskItem.displayOrder).map(\.id)
            == [early.id, late.id, undated.id])
    }

    @Test("Most recently modified tasks break equal due-date ties")
    func modificationSorting() {
        let older = TaskItem(title: "Older", modifiedAt: Date(timeIntervalSince1970: 100))
        let newer = TaskItem(title: "Newer", modifiedAt: Date(timeIntervalSince1970: 200))
        for dueDate in [nil, Date(timeIntervalSince1970: 300)] as [Date?] {
            older.dueDate = dueDate
            newer.dueDate = dueDate
            #expect([older, newer].sorted(by: TaskItem.displayOrder).map(\.id) == [newer.id, older.id])
            #expect(!TaskItem.displayOrder(newer, newer))
        }
    }

    @Test("Manual order sorts independently of smart task order")
    func manualSorting() {
        let first = TaskItem(title: "First", priority: .low, manualOrder: 1)
        let second = TaskItem(title: "Second", priority: .high, manualOrder: 2)

        #expect([second, first].sorted(by: TaskItem.manualDisplayOrder).map(\.title)
            == ["First", "Second"])
        #expect([second, first].sorted(by: TaskItem.displayOrder).first?.title == "Second")
    }

    @Test("Overdue excludes today's tasks, undated tasks, and completed tasks")
    func overdueBoundaries() throws {
        let today = Calendar.current.startOfDay(for: .now)
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let task = TaskItem(title: "Due", dueDate: yesterday)
        #expect(task.isOverdue)
        task.setCompleted(true)
        #expect(!task.isOverdue)
        task.setCompleted(false)
        task.dueDate = today
        #expect(!task.isOverdue)
        task.dueDate = nil
        #expect(!task.isOverdue)
    }

    @Test("Task edits survive a fresh model context")
    @MainActor
    func editsPersist() throws {
        let context = try makeTestModelContext()
        let task = TaskItem(title: "Draft")
        context.insert(task)
        try context.save()
        task.title = "Final"
        task.notes = "Details"
        task.priority = .high
        task.dueDate = Date(timeIntervalSince1970: 123456)
        task.manualOrder = 42
        task.setCompleted(true)
        try context.save()
        let fresh = ModelContext(context.container)
        let saved = try #require(fresh.fetch(FetchDescriptor<TaskItem>()).first)
        #expect(saved.id == task.id)
        #expect(saved.title == "Final")
        #expect(saved.notes == "Details")
        #expect(saved.priority == .high)
        #expect(saved.dueDate == task.dueDate)
        #expect(saved.manualOrder == 42)
        #expect(saved.isCompleted)
        #expect(saved.completedAt != nil)
        #expect(saved.modifiedAt == task.modifiedAt)
    }
}
