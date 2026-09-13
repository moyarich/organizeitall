import SwiftUI

struct MaterialCard<Content: View>: View {
    @Environment(\.materialColors) private var colors
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.surfaceContainer, in: RoundedRectangle(cornerRadius: MaterialShape.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MaterialShape.medium, style: .continuous)
                    .stroke(colors.outlineVariant.opacity(0.55), lineWidth: 0.5)
            }
    }
}

struct MaterialFloatingActionButton: View {
    @Environment(\.materialColors) private var colors
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(MaterialTypography.labelLarge)
                .foregroundStyle(colors.onPrimaryContainer)
                .padding(.horizontal, 20)
                .frame(height: 56)
                .background(colors.primaryContainer, in: RoundedRectangle(cornerRadius: MaterialShape.large, style: .continuous))
                .shadow(color: .black.opacity(0.16), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct MaterialSearchBar: View {
    @Environment(\.materialColors) private var colors
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(colors.onSurfaceVariant)

            TextField(prompt, text: $text)
                .font(MaterialTypography.bodyLarge)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(colors.onSurfaceVariant)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(colors.surfaceContainerHigh, in: Capsule())
    }
}

struct MaterialFilterChip: View {
    @Environment(\.materialColors) private var colors
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                }
                Text(title)
                    .font(MaterialTypography.labelLarge)
            }
            .foregroundStyle(isSelected ? colors.onSecondaryContainer : colors.onSurfaceVariant)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(
                isSelected ? colors.secondaryContainer : Color.clear,
                in: RoundedRectangle(cornerRadius: MaterialShape.small, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: MaterialShape.small, style: .continuous)
                    .stroke(isSelected ? Color.clear : colors.outline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MaterialTextField: View {
    @Environment(\.materialColors) private var colors
    let label: String
    @Binding var text: String
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(MaterialTypography.labelMedium)
                .foregroundStyle(colors.primary)

            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(colors.onSurfaceVariant)
                }
                TextField(label, text: $text)
                    .font(MaterialTypography.bodyLarge)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colors.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: MaterialShape.extraSmall, style: .continuous))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(colors.primary)
                .frame(height: 2)
        }
    }
}

struct MaterialMultilineField: View {
    @Environment(\.materialColors) private var colors
    let label: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(MaterialTypography.labelMedium)
                .foregroundStyle(colors.primary)

            TextEditor(text: $text)
                .font(MaterialTypography.bodyLarge)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colors.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: MaterialShape.extraSmall, style: .continuous))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(colors.primary)
                .frame(height: 2)
        }
    }
}

struct MaterialEmptyState: View {
    @Environment(\.materialColors) private var colors
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(colors.primary)
                .frame(width: 72, height: 72)
                .background(colors.primaryContainer, in: Circle())

            Text(title)
                .font(MaterialTypography.titleLarge)
                .multilineTextAlignment(.center)

            Text(message)
                .font(MaterialTypography.bodyMedium)
                .foregroundStyle(colors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
    }
}

struct MaterialNavigationBarItem: View {
    @Environment(\.materialColors) private var colors
    let title: String
    let systemImage: String
    let selectedSystemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? selectedSystemImage : systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 64, height: 32)
                    .background(isSelected ? colors.secondaryContainer : Color.clear, in: Capsule())

                Text(title)
                    .font(MaterialTypography.labelMedium)
            }
            .foregroundStyle(isSelected ? colors.onSecondaryContainer : colors.onSurfaceVariant)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct MaterialSectionTitle: View {
    @Environment(\.materialColors) private var colors
    let title: String

    var body: some View {
        Text(title)
            .font(MaterialTypography.titleMedium)
            .foregroundStyle(colors.onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
