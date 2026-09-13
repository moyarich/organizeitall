import SwiftData
import XCTest
@testable import OrganizeItAll

final class OrganizeItAllTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([TaskList.self, TaskItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    func testTaskCanBelongToList() throws {
        let context = try makeContext()
        let list = TaskList(name: "Work")
        let task = TaskItem(title: "Ship release", list: list)
        context.insert(list); context.insert(task); try context.save()
        XCTAssertEqual(task.list?.name, "Work")
        XCTAssertTrue(list.tasks.contains(where: { $0.id == task.id }))
    }

    func testTaskWithoutListIsInInbox() throws {
        let context = try makeContext()
        let task = TaskItem(title: "Call dentist")
        context.insert(task); try context.save()
        XCTAssertNil(task.list)
        XCTAssertEqual(task.listName, "Inbox")
    }

    func testCompletionTracksCompletedDate() throws {
        let context = try makeContext()
        let task = TaskItem(title: "Finish tests")
        context.insert(task)
        task.setCompleted(true); try context.save()
        XCTAssertTrue(task.isCompleted); XCTAssertNotNil(task.completedAt)
        task.setCompleted(false); try context.save()
        XCTAssertFalse(task.isCompleted); XCTAssertNil(task.completedAt)
    }

    func testDeletingListPreservesTaskInInbox() throws {
        let context = try makeContext()
        let list = TaskList(name: "Errands")
        let task = TaskItem(title: "Buy milk", list: list)
        context.insert(list); context.insert(task); try context.save()
        context.delete(list); try context.save()
        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertNil(tasks.first?.list)
        XCTAssertEqual(tasks.first?.listName, "Inbox")
    }

    func testHigherPriorityTasksSortBeforeNormalPriority() {
        let normal = TaskItem(title: "Normal", priority: .normal)
        let high = TaskItem(title: "High", priority: .high)
        let sorted = [normal, high].sorted(by: TaskItem.displayOrder)
        XCTAssertEqual(sorted.first?.title, "High")
    }
}
