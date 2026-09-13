import XCTest
@testable import OrganizeItAll

final class OrganizeItAllTests: XCTestCase {
    private var stack: CoreDataStack!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
    }

    override func tearDown() {
        stack = nil
        super.tearDown()
    }

    func testTaskCanBelongToList() throws {
        let context = stack.viewContext
        let list = List(context: context)
        list.name = "Home"

        let task = Task(context: context)
        task.title = "Replace air filter"
        task.list = list
        task.created_date = Date()
        task.modified_date = Date()

        try context.save()

        XCTAssertEqual(task.list?.wrappedName, "Home")
        XCTAssertEqual(list.tasksArray.count, 1)
        XCTAssertEqual(list.openTaskCount, 1)
    }

    func testDeletingListPreservesTaskInInbox() throws {
        let context = stack.viewContext
        let list = List(context: context)
        list.name = "Errands"

        let task = Task(context: context)
        task.title = "Pick up groceries"
        task.list = list

        try context.save()
        context.delete(list)
        try context.save()

        XCTAssertNil(task.list)
        XCTAssertEqual(task.listName, "Inbox")
    }

    func testCompletedTaskIsNotCountedAsOpen() {
        let context = stack.viewContext
        let list = List(context: context)
        list.name = "Work"

        let task = Task(context: context)
        task.title = "Ship release"
        task.list = list
        task.isComplete = true

        XCTAssertEqual(list.tasksArray.count, 1)
        XCTAssertEqual(list.openTaskCount, 0)
    }
}
