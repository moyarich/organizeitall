import SwiftUI

struct TaskListRow: View {
    @Environment(\.materialColors) private var colors
    let list: TaskList

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(colors.onPrimaryContainer)
                .frame(width: 48, height: 48)
                .background(colors.primaryContainer, in: RoundedRectangle(cornerRadius: MaterialShape.medium, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(list.displayName)
                    .font(MaterialTypography.titleMedium)
                    .foregroundStyle(colors.onSurface)

                if !list.displayNotes.isEmpty {
                    Text(list.displayNotes)
                        .font(MaterialTypography.bodyMedium)
                        .foregroundStyle(colors.onSurfaceVariant)
                        .lineLimit(1)
                }

                Text(summary)
                    .font(MaterialTypography.labelMedium)
                    .foregroundStyle(colors.onSurfaceVariant)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(colors.onSurfaceVariant)
        }
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let total = list.tasks.count
        guard total > 0 else { return "No tasks" }
        return "\(list.openTaskCount) open · \(total) total"
    }
}
