import Foundation

enum TaskPriority: Int, CaseIterable, Identifiable, Sendable {
    case low = 0
    case normal = 1
    case high = 2

    var id: Self { self }

    var title: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }

    var systemImage: String {
        switch self {
        case .low: "arrow.down"
        case .normal: "minus"
        case .high: "exclamationmark"
        }
    }
}
