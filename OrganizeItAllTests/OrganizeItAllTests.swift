import SwiftData
import XCTest
@testable import OrganizeItAll

@available(iOS 17.0, *)
final class OrganizeItAllTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            List.self,
            Task.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        return ModelContext(container)
    }

    func testTaskCanBelongToList() throws {
        let context = try makeContext()
        let list = List(name: "Work")
        let task = Task(title: "Ship release", list: list)

        context.insert(list)
        context.insert(task)
        try context.save()

        XCTAssertEqual(task.list?.name, "Work")
        XCTAssertTrue(list.tasks.contains(where: { $0.id == task.id }))
    }

    func testTaskWithoutListIsInboxTask() throws {
        let context = try makeContext()
        let task = Task(title: "Call dentist")

        context.insert(task)
        try context.save()

        XCTAssertNil(task.list)
        XCTAssertEqual(task.listName, "Inbox")
    }

    func testCompletionPersists() throws {
        let context = try makeContext()
        let task = Task(title: "Finish tests")
        context.insert(task)
        try context.save()

        task.isComplete = true
        task.modifiedDate = .now
        try context.save()

        let completed = try context.fetch(
            FetchDescriptor<Task>(predicate: #Predicate { $0.isComplete })
        )
        XCTAssertEqual(completed.map(\.id), [task.id])
    }

    func testDeletingListMovesTaskToInbox() throws {
        let context = try makeContext()
        let list = List(name: "Errands")
        let task = Task(title: "Buy milk", list: list)

        context.insert(list)
        context.insert(task)
        try context.save()

        context.delete(list)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(tasks.count, 1)
        XCTAssertNil(tasks.first?.list)
        XCTAssertEqual(tasks.first?.listName, "Inbox")
    }
}
