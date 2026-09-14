import SwiftData
import SwiftUI

struct TaskListEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.name) private var lists: [TaskList]

    private let list: TaskList?
    private let onDelete: (() -> Void)?

    @State private var name: String
    @State private var notes: String
    @State private var iconName: String
    @State private var colorToken: String
    @State private var isPinned: Bool
    @State private var isArchived: Bool
    @State private var isConfirmingDelete = false

    private let iconOptions = ["folder.fill", "briefcase.fill", "house.fill", "cart.fill", "book.fill", "heart.fill", "star.fill", "person.2.fill"]
    private let colorOptions = ["primary", "secondary", "tertiary", "error"]

    init(list: TaskList? = nil, onDelete: (() -> Void)? = nil) {
        self.list = list
        self.onDelete = onDelete
        _name = State(initialValue: list?.name ?? "")
        _notes = State(initialValue: list?.notes ?? "")
        _iconName = State(initialValue: list?.iconName ?? "folder.fill")
        _colorToken = State(initialValue: list?.colorToken ?? "primary")
        _isPinned = State(initialValue: list?.isPinned ?? false)
        _isArchived = State(initialValue: list?.isArchived ?? false)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        MaterialTextField(label: "List name", text: $name, systemImage: "folder")
                            .textInputAutocapitalization(.sentences)

                        if let validationMessage {
                            Text(validationMessage)
                                .font(MaterialTypography.bodyMedium)
                                .foregroundStyle(colors.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        MaterialMultilineField(label: "Notes", text: $notes, minHeight: 120)

                        MaterialCard {
                            VStack(alignment: .leading, spacing: 14) {
                                MaterialSectionTitle(title: "Icon")

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                    ForEach(iconOptions, id: \.self) { option in
                                        Button {
                                            iconName = option
                                        } label: {
                                            Image(systemName: option)
                                                .font(.title3)
                                                .foregroundStyle(iconName == option ? colors.onPrimaryContainer : colors.onSurfaceVariant)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 48)
                                                .background(iconName == option ? colors.primaryContainer : colors.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: MaterialShape.small))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        MaterialCard {
                            VStack(alignment: .leading, spacing: 14) {
                                MaterialSectionTitle(title: "Color")

                                HStack(spacing: 10) {
                                    ForEach(colorOptions, id: \.self) { option in
                                        Button {
                                            colorToken = option
                                        } label: {
                                            Circle()
                                                .fill(color(for: option))
                                                .frame(width: 34, height: 34)
                                                .overlay {
                                                    if colorToken == option {
                                                        Image(systemName: "checkmark")
                                                            .font(.caption.bold())
                                                            .foregroundStyle(.white)
                                                    }
                                                }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(option.capitalized)
                                        .accessibilityAddTraits(colorToken == option ? .isSelected : [])
                                    }
                                }
                            }
                        }

                        MaterialCard {
                            VStack(spacing: 12) {
                                Toggle("Pin list", isOn: $isPinned)
                                    .tint(colors.primary)

                                Divider().overlay(colors.outlineVariant)

                                Toggle("Archive list", isOn: $isArchived)
                                    .tint(colors.primary)
                            }
                            .font(MaterialTypography.bodyLarge)
                        }

                        if list != nil {
                            Button("Delete list", systemImage: "trash", role: .destructive) {
                                isConfirmingDelete = true
                            }
                            .font(MaterialTypography.labelLarge)
                            .foregroundStyle(colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay {
                                RoundedRectangle(cornerRadius: MaterialShape.extraLarge, style: .continuous)
                                    .stroke(colors.error, lineWidth: 1)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(list == nil ? "New list" : "Edit list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.primary)
                        .disabled(validationMessage != nil)
                }
            }
            .confirmationDialog("Delete this list?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete list", role: .destructive, action: deleteList)
            } message: {
                Text("Tasks in this list will be preserved in Inbox.")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validationMessage: String? {
        guard !trimmedName.isEmpty else { return "List name is required." }
        guard TaskList.normalizedName(trimmedName) != TaskList.normalizedName("Inbox") else {
            return "Inbox is the built-in default list and cannot be used as a custom list name."
        }

        let normalized = TaskList.normalizedName(trimmedName)
        if lists.contains(where: { candidate in
            candidate.id != list?.id && TaskList.normalizedName(candidate.name) == normalized
        }) {
            return "A list with this name already exists."
        }

        return nil
    }

    private func save() {
        guard validationMessage == nil else { return }

        let now = Date.now
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let list {
            list.name = trimmedName
            list.notes = trimmedNotes
            list.iconName = iconName
            list.colorToken = colorToken
            list.isPinned = isPinned
            list.isArchived = isArchived
            list.modifiedAt = now
        } else {
            modelContext.insert(
                TaskList(
                    name: trimmedName,
                    notes: trimmedNotes,
                    createdAt: now,
                    modifiedAt: now,
                    iconName: iconName,
                    colorToken: colorToken,
                    isPinned: isPinned,
                    isArchived: isArchived
                )
            )
        }

        persistAndDismiss()
    }

    private func deleteList() {
        guard let list else { return }
        modelContext.delete(list)

        do {
            try modelContext.save()
            onDelete?()
            dismiss()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to delete list: \(error)")
        }
    }

    private func persistAndDismiss() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save list: \(error)")
        }
    }

    private func color(for token: String) -> Color {
        switch token {
        case "secondary": colors.secondary
        case "tertiary": colors.tertiary
        case "error": colors.error
        default: colors.primary
        }
    }
}
