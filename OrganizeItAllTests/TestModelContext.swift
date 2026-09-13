import SwiftData

@MainActor
func makeTestModelContext() throws -> ModelContext {
    let schema = Schema([TaskList.self, TaskItem.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
}
