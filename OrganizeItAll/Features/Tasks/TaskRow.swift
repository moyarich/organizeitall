import SwiftUI

struct TaskRow: View {
    @Environment(\.materialColors) private var colors
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(task.isCompleted ? colors.primary : colors.onSurfaceVariant)
                    .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(task.displayTitle)
                        .font(MaterialTypography.titleMedium)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? colors.onSurfaceVariant : colors.onSurface)

                    if task.priority != .normal {
                        Label(task.priority.title, systemImage: task.priority.systemImage)
                            .labelStyle(.iconOnly)
                            .font(.caption.bold())
                            .foregroundStyle(task.priority == .high ? colors.error : colors.tertiary)
                            .accessibilityLabel("\(task.priority.title) priority")
                    }
                }

                if !task.displayNotes.isEmpty {
                    Text(task.displayNotes)
                        .font(MaterialTypography.bodyMedium)
                        .foregroundStyle(colors.onSurfaceVariant)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    metadataChip(task.listName, systemImage: "folder")

                    if let dueDate = task.dueDate {
                        metadataChip(
                            dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar",
                            isError: task.isOverdue
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func metadataChip(_ title: String, systemImage: String, isError: Bool = false) -> some View {
        Label(title, systemImage: systemImage)
            .font(MaterialTypography.labelMedium)
            .foregroundStyle(isError ? colors.onErrorContainer : colors.onSurfaceVariant)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isError ? colors.errorContainer : colors.surfaceContainerHigh,
                in: Capsule()
            )
    }
}
