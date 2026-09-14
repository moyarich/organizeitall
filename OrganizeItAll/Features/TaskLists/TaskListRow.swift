import SwiftUI

struct TaskListRow: View {
    @Environment(\.materialColors) private var colors
    let list: TaskList

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: list.iconName)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(iconForeground)
                .frame(width: 48, height: 48)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: MaterialShape.medium, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(list.displayName)
                        .font(MaterialTypography.titleMedium)
                        .foregroundStyle(colors.onSurface)

                    if list.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(colors.primary)
                            .accessibilityLabel("Pinned")
                    }

                    if list.isArchived {
                        Text("Archived")
                            .font(MaterialTypography.labelMedium)
                            .foregroundStyle(colors.onSurfaceVariant)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(colors.surfaceContainerHigh, in: Capsule())
                    }
                }

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

    private var iconForeground: Color {
        switch list.colorToken {
        case "secondary": colors.onSecondaryContainer
        case "tertiary": colors.onTertiaryContainer
        case "error": colors.onErrorContainer
        default: colors.onPrimaryContainer
        }
    }

    private var iconBackground: Color {
        switch list.colorToken {
        case "secondary": colors.secondaryContainer
        case "tertiary": colors.tertiaryContainer
        case "error": colors.errorContainer
        default: colors.primaryContainer
        }
    }
}
