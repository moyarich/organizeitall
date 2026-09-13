import SwiftUI

@available(iOS 17.0, *)
struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundStyle(task.isComplete ? Color.brandAccent : Color.secondary)
                    .accessibilityLabel(task.isComplete ? "Mark incomplete" : "Mark complete")
            }
            .buttonStyle(.borderless)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.wrappedTitle)
                    .font(.headline)
                    .strikethrough(task.isComplete)
                    .foregroundStyle(task.isComplete ? Color.secondary : Color.primary)

                if !task.wrappedDetail.isEmpty {
                    Text(task.wrappedDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Label(task.listName, systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case open = "Open"
    case completed = "Done"
}
