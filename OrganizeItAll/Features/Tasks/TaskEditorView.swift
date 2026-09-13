import SwiftData
import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.name) private var lists: [TaskList]

    private let task: TaskItem?
    private let defaultList: TaskList?

    @State private var title: String
    @State private var notes: String
    @State private var selectedListID: UUID?
    @State private var priority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isConfirmingDelete = false

    init(task: TaskItem? = nil, defaultList: TaskList? = nil) {
        self.task = task
        self.defaultList = defaultList
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _selectedListID = State(initialValue: task?.list?.id ?? defaultList?.id)
        _priority = State(initialValue: task?.priority ?? .normal)
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: task?.dueDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        MaterialTextField(label: "Task title", text: $title, systemImage: "checkmark.circle")
                            .textInputAutocapitalization(.sentences)

                        MaterialCard {
                            VStack(alignment: .leading, spacing: 10) {
                                MaterialSectionTitle(title: "List")

                                Picker("List", selection: $selectedListID) {
                                    Label("Inbox", systemImage: "tray")
                                        .tag(Optional<UUID>.none)

                                    ForEach(lists) { list in
                                        Text(list.displayName)
                                            .tag(Optional(list.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(colors.primary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            MaterialSectionTitle(title: "Priority")

                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases) { option in
                                    MaterialFilterChip(
                                        title: option.title,
                                        systemImage: option.systemImage,
                                        isSelected: priority == option
                                    ) {
                                        priority = option
                                    }
                                }
                            }
                        }

                        MaterialCard {
                            VStack(spacing: 14) {
                                Toggle("Due date", isOn: $hasDueDate.animation())
                                    .font(MaterialTypography.bodyLarge)
                                    .tint(colors.primary)

                                if hasDueDate {
                                    Divider()
                                        .overlay(colors.outlineVariant)

                                    DatePicker(
                                        "Due",
                                        selection: $dueDate,
                                        displayedComponents: [.date]
                                    )
                                    .font(MaterialTypography.bodyLarge)
                                    .tint(colors.primary)
                                }
                            }
                        }

                        MaterialMultilineField(label: "Notes", text: $notes, minHeight: 150)

                        if let task {
                            Button {
                                task.setCompleted(!task.isCompleted)
                                persistAndDismiss()
                            } label: {
                                Label(
                                    task.isCompleted ? "Mark incomplete" : "Mark complete",
                                    systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                )
                                .font(MaterialTypography.labelLarge)
                                .foregroundStyle(colors.onSecondaryContainer)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(colors.secondaryContainer, in: Capsule())
                            }
                            .buttonStyle(.plain)

                            Button("Delete task", systemImage: "trash", role: .destructive) {
                                isConfirmingDelete = true
                            }
                            .font(MaterialTypography.labelLarge)
                            .foregroundStyle(colors.error)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay {
                                Capsule()
                                    .stroke(colors.error, lineWidth: 1)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(task == nil ? "New task" : "Edit task")
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
                        .disabled(trimmedTitle.isEmpty)
                }
            }
            .confirmationDialog("Delete this task?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete task", role: .destructive, action: deleteTask)
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedList: TaskList? {
        guard let selectedListID else { return nil }
        return lists.first(where: { $0.id == selectedListID }) ?? defaultList
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }

        let now = Date.now
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedDueDate = hasDueDate ? dueDate : nil

        if let task {
            task.title = trimmedTitle
            task.notes = trimmedNotes
            task.list = selectedList
            task.priority = priority
            task.dueDate = selectedDueDate
            task.modifiedAt = now
        } else {
            modelContext.insert(
                TaskItem(
                    title: trimmedTitle,
                    notes: trimmedNotes,
                    createdAt: now,
                    modifiedAt: now,
                    dueDate: selectedDueDate,
                    priority: priority,
                    list: selectedList
                )
            )
        }

        persistAndDismiss()
    }

    private func deleteTask() {
        guard let task else { return }
        modelContext.delete(task)
        persistAndDismiss()
    }

    private func persistAndDismiss() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save task: \(error)")
        }
    }
}
