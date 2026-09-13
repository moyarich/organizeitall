enum TaskFilter: String, CaseIterable, Identifiable, Sendable {
    case open = "Open"
    case all = "All"
    case completed = "Done"

    var id: Self { self }
}
