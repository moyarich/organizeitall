import SwiftData
import SwiftUI

private enum TaskListSheet: Identifiable {
    case editList
    case newTask
    case editTask(TaskItem)

    var id: String {
        switch self {
        case .editList: "edit-list"
        case .newTask: "new-task"
        case .editTask(let task): "edit-task-\(task.id.uuidString)"
        }
    }
}

private enum InboxSheet: Identifiable {
    case newTask
    case editTask(TaskItem)

    var id: String {
        switch self {
        case .newTask: "new-inbox-task"
        case .editTask(let task): "edit-inbox-task-\(task.id.uuidString)"
        }
    }
}

private enum TaskCollectionFilter: String, CaseIterable, Identifiable {
    case open = "Open"
    case all = "All"
    case completed = "Completed"

    var id: Self { self }
}

private enum TaskCollectionSort: String, CaseIterable, Identifiable {
    case smart = "Smart"
    case manual = "Manual"
    case dueDate = "Due date"
    case priority = "Priority"
    case recentlyModified = "Recently updated"
    case created = "Created"

    var id: Self { self }
}

private struct TaskCollectionControls: View {
    @Environment(\.materialColors) private var colors
    @Binding var searchText: String
    @Binding var filter: TaskCollectionFilter
    @Binding var sort: TaskCollectionSort
    @Binding var isSelecting: Bool
    let selectedCount: Int

    var body: some View {
        VStack(spacing: 10) {
            MaterialSearchBar(text: $searchText, prompt: "Search tasks")

            HStack(spacing: 8) {
                ForEach(TaskCollectionFilter.allCases) { option in
                    MaterialFilterChip(
                        title: option.rawValue,
                        systemImage: nil,
                        isSelected: filter == option
                    ) {
                        filter = option
                    }
                }
                Spacer(minLength: 0)
            }

            HStack {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(TaskCollectionSort.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort: \(sort.rawValue)", systemImage: "arrow.up.arrow.down")
                        .font(MaterialTypography.labelLarge)
                        .foregroundStyle(colors.primary)
                }

                Spacer()

                Button(isSelecting ? "Done" : "Select") {
                    isSelecting.toggle()
                }
                .font(MaterialTypography.labelLarge)
                .foregroundStyle(colors.primary)

                if isSelecting && selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(MaterialTypography.labelMedium)
                        .foregroundStyle(colors.onSecondaryContainer)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colors.secondaryContainer, in: Capsule())
                }
            }
            .frame(minHeight: 36)
        }
    }
}

struct InboxTaskListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.modifiedAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \TaskList.name) private var lists: [TaskList]

    @State private var activeSheet: InboxSheet?
    @State private var searchText = ""
    @State private var filter: TaskCollectionFilter = .open
    @State private var sort: TaskCollectionSort = .smart
    @State private var isSelecting = false
    @State private var selectedTaskIDs: Set<UUID> = []
    @State private var isConfirmingBulkDelete = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            colors.surface.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    inboxHeader

                    TaskCollectionControls(
                        searchText: $searchText,
                        filter: $filter,
                        sort: $sort,
                        isSelecting: $isSelecting,
                        selectedCount: selectedTaskIDs.count
                    )

                    if displayedTasks.isEmpty {
                        MaterialEmptyState(
                            title: emptyTitle,
                            message: emptyMessage,
                            systemImage: "tray"
                        )
                    } else {
                        ForEach(displayedTasks) { task in
                            taskCard(task)
                                .draggable(task.id.uuidString)
                                .dropDestination(for: String.self) { values, _ in
                                    guard canReorder,
                                          let value = values.first,
                                          let sourceID = UUID(uuidString: value) else {
                                        return false
                                    }
                                    return reorderTask(sourceID: sourceID, targetID: task.id)
                                }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, isSelecting ? 150 : 96)
            }

            if isSelecting {
                bulkActionBar
                    .padding(16)
            } else {
                MaterialFloatingActionButton(title: "New task", systemImage: "plus") {
                    activeSheet = .newTask
                }
                .padding(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newTask:
                TaskEditorView()
            case .editTask(let task):
                TaskEditorView(task: task)
            }
        }
        .confirmationDialog("Delete selected tasks?", isPresented: $isConfirmingBulkDelete, titleVisibility: .visible) {
            Button("Delete \(selectedTaskIDs.count) tasks", role: .destructive) {
                bulkDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onChange(of: isSelecting) { _, selecting in
            if !selecting { selectedTaskIDs.removeAll() }
        }
    }

    private var inboxTasks: [TaskItem] {
        tasks.filter(\.isInInbox)
    }

    private var displayedTasks: [TaskItem] {
        filteredAndSorted(tasks: inboxTasks, searchText: searchText, filter: filter, sort: sort)
    }

    private var activeLists: [TaskList] {
        lists.filter { !$0.isArchived }.sorted(by: TaskList.manualDisplayOrder)
    }

    private var canReorder: Bool {
        sort == .manual && filter == .all && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSelecting
    }

    private var inboxHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Back", systemImage: "chevron.left") { dismiss() }
                    .labelStyle(.iconOnly)
                    .font(.title3.bold())
                    .foregroundStyle(colors.onSurface)

                Spacer()

                Text("Default list")
                    .font(MaterialTypography.labelLarge)
                    .foregroundStyle(colors.onSecondaryContainer)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(colors.secondaryContainer, in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Inbox")
                    .font(MaterialTypography.headlineLarge)

                Text("Tasks not assigned to another list are collected here automatically.")
                    .font(MaterialTypography.bodyLarge)
                    .foregroundStyle(colors.onSurfaceVariant)

                Text("\(openInboxTaskCount) open · \(inboxTasks.count) total")
                    .font(MaterialTypography.labelLarge)
                    .foregroundStyle(colors.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func taskCard(_ task: TaskItem) -> some View {
        MaterialCard {
            HStack(alignment: .top, spacing: 10) {
                if isSelecting {
                    Image(systemName: selectedTaskIDs.contains(task.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selectedTaskIDs.contains(task.id) ? colors.primary : colors.onSurfaceVariant)
                }

                TaskRow(task: task) {
                    task.setCompleted(!task.isCompleted)
                    saveChanges()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                toggleSelection(task.id)
            } else {
                activeSheet = .editTask(task)
            }
        }
        .contextMenu {
            taskContextMenu(task)
        }
    }

    @ViewBuilder
    private func taskContextMenu(_ task: TaskItem) -> some View {
        Button(task.isCompleted ? "Mark incomplete" : "Mark complete", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark") {
            task.setCompleted(!task.isCompleted)
            saveChanges()
        }

        Menu("Move to", systemImage: "folder") {
            ForEach(activeLists) { list in
                Button(list.displayName) {
                    move(task, to: list)
                }
            }
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            modelContext.delete(task)
            saveChanges()
        }
    }

    private var bulkActionBar: some View {
        MaterialCard {
            HStack(spacing: 14) {
                Button("Complete", systemImage: "checkmark") {
                    setSelectedCompleted(true)
                }
                .disabled(selectedTaskIDs.isEmpty)

                Button("Reopen", systemImage: "arrow.uturn.backward") {
                    setSelectedCompleted(false)
                }
                .disabled(selectedTaskIDs.isEmpty)

                Menu {
                    ForEach(activeLists) { list in
                        Button(list.displayName) {
                            bulkMove(to: list)
                        }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }
                .disabled(selectedTaskIDs.isEmpty)

                Spacer()

                Button("Delete", systemImage: "trash", role: .destructive) {
                    isConfirmingBulkDelete = true
                }
                .disabled(selectedTaskIDs.isEmpty)
            }
            .font(MaterialTypography.labelLarge)
        }
    }

    private var openInboxTaskCount: Int {
        inboxTasks.lazy.filter { !$0.isCompleted }.count
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No matching tasks" }
        switch filter {
        case .open: return "Inbox is clear"
        case .all: return "Inbox is empty"
        case .completed: return "Nothing completed yet"
        }
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "Try a different search." }
        return "Tasks you create without choosing a list appear here automatically."
    }

    private func toggleSelection(_ id: UUID) {
        if selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        } else {
            selectedTaskIDs.insert(id)
        }
    }

    private func move(_ task: TaskItem, to list: TaskList?) {
        task.list = list
        task.manualOrder = Date.now.timeIntervalSinceReferenceDate
        task.modifiedAt = .now
        saveChanges()
    }

    private func setSelectedCompleted(_ completed: Bool) {
        for task in inboxTasks where selectedTaskIDs.contains(task.id) {
            task.setCompleted(completed)
        }
        finishBulkMutation()
    }

    private func bulkMove(to list: TaskList?) {
        for task in inboxTasks where selectedTaskIDs.contains(task.id) {
            task.list = list
            task.manualOrder = Date.now.timeIntervalSinceReferenceDate
            task.modifiedAt = .now
        }
        finishBulkMutation()
    }

    private func bulkDelete() {
        for task in inboxTasks where selectedTaskIDs.contains(task.id) {
            modelContext.delete(task)
        }
        finishBulkMutation()
    }

    private func finishBulkMutation() {
        saveChanges()
        selectedTaskIDs.removeAll()
        isSelecting = false
    }

    private func reorderTask(sourceID: UUID, targetID: UUID) -> Bool {
        reorderTasks(in: inboxTasks, sourceID: sourceID, targetID: targetID, modelContext: modelContext)
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save Inbox task changes: \(error)")
        }
    }
}

struct TaskListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.name) private var lists: [TaskList]

    let list: TaskList

    @State private var activeSheet: TaskListSheet?
    @State private var searchText = ""
    @State private var filter: TaskCollectionFilter = .open
    @State private var sort: TaskCollectionSort = .smart
    @State private var isSelecting = false
    @State private var selectedTaskIDs: Set<UUID> = []
    @State private var isConfirmingBulkDelete = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            colors.surface.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 12) {
                    header

                    TaskCollectionControls(
                        searchText: $searchText,
                        filter: $filter,
                        sort: $sort,
                        isSelecting: $isSelecting,
                        selectedCount: selectedTaskIDs.count
                    )

                    if displayedTasks.isEmpty {
                        MaterialEmptyState(
                            title: emptyTitle,
                            message: emptyMessage,
                            systemImage: "checkmark.circle"
                        )
                    } else {
                        ForEach(displayedTasks) { task in
                            taskCard(task)
                                .draggable(task.id.uuidString)
                                .dropDestination(for: String.self) { values, _ in
                                    guard canReorder,
                                          let value = values.first,
                                          let sourceID = UUID(uuidString: value) else {
                                        return false
                                    }
                                    return reorderTask(sourceID: sourceID, targetID: task.id)
                                }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, isSelecting ? 150 : 96)
            }

            if isSelecting {
                bulkActionBar
                    .padding(16)
            } else {
                MaterialFloatingActionButton(title: "New task", systemImage: "plus") {
                    activeSheet = .newTask
                }
                .padding(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editList:
                TaskListEditorView(list: list) {
                    dismiss()
                }
            case .newTask:
                TaskEditorView(defaultList: list)
            case .editTask(let task):
                TaskEditorView(task: task, defaultList: list)
            }
        }
        .confirmationDialog("Delete selected tasks?", isPresented: $isConfirmingBulkDelete, titleVisibility: .visible) {
            Button("Delete \(selectedTaskIDs.count) tasks", role: .destructive) {
                bulkDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onChange(of: isSelecting) { _, selecting in
            if !selecting { selectedTaskIDs.removeAll() }
        }
    }

    private var displayedTasks: [TaskItem] {
        filteredAndSorted(tasks: list.tasks, searchText: searchText, filter: filter, sort: sort)
    }

    private var activeLists: [TaskList] {
        lists.filter { !$0.isArchived }.sorted(by: TaskList.manualDisplayOrder)
    }

    private var canReorder: Bool {
        sort == .manual && filter == .all && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSelecting
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Back", systemImage: "chevron.left") { dismiss() }
                    .labelStyle(.iconOnly)
                    .font(.title3.bold())
                    .foregroundStyle(colors.onSurface)

                Spacer()

                Button("Edit", systemImage: "pencil") {
                    activeSheet = .editList
                }
                .font(MaterialTypography.labelLarge)
                .foregroundStyle(colors.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: list.iconName)
                        .foregroundStyle(colors.primary)
                    Text(list.displayName)
                        .font(MaterialTypography.headlineLarge)
                }

                if !list.displayNotes.isEmpty {
                    Text(list.displayNotes)
                        .font(MaterialTypography.bodyLarge)
                        .foregroundStyle(colors.onSurfaceVariant)
                }

                Text("\(list.openTaskCount) open · \(list.tasks.count) total")
                    .font(MaterialTypography.labelLarge)
                    .foregroundStyle(colors.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func taskCard(_ task: TaskItem) -> some View {
        MaterialCard {
            HStack(alignment: .top, spacing: 10) {
                if isSelecting {
                    Image(systemName: selectedTaskIDs.contains(task.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selectedTaskIDs.contains(task.id) ? colors.primary : colors.onSurfaceVariant)
                }

                TaskRow(task: task) {
                    task.setCompleted(!task.isCompleted)
                    saveChanges()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                toggleSelection(task.id)
            } else {
                activeSheet = .editTask(task)
            }
        }
        .contextMenu {
            taskContextMenu(task)
        }
    }

    @ViewBuilder
    private func taskContextMenu(_ task: TaskItem) -> some View {
        Button(task.isCompleted ? "Mark incomplete" : "Mark complete", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark") {
            task.setCompleted(!task.isCompleted)
            saveChanges()
        }

        Menu("Move to", systemImage: "folder") {
            Button("Inbox") {
                move(task, to: nil)
            }

            ForEach(activeLists.filter { $0.id != list.id }) { target in
                Button(target.displayName) {
                    move(task, to: target)
                }
            }
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            modelContext.delete(task)
            saveChanges()
        }
    }

    private var bulkActionBar: some View {
        MaterialCard {
            HStack(spacing: 14) {
                Button("Complete", systemImage: "checkmark") {
                    setSelectedCompleted(true)
                }
                .disabled(selectedTaskIDs.isEmpty)

                Button("Reopen", systemImage: "arrow.uturn.backward") {
                    setSelectedCompleted(false)
                }
                .disabled(selectedTaskIDs.isEmpty)

                Menu {
                    Button("Inbox") {
                        bulkMove(to: nil)
                    }

                    ForEach(activeLists.filter { $0.id != list.id }) { target in
                        Button(target.displayName) {
                            bulkMove(to: target)
                        }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }
                .disabled(selectedTaskIDs.isEmpty)

                Spacer()

                Button("Delete", systemImage: "trash", role: .destructive) {
                    isConfirmingBulkDelete = true
                }
                .disabled(selectedTaskIDs.isEmpty)
            }
            .font(MaterialTypography.labelLarge)
        }
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No matching tasks" }
        switch filter {
        case .open: return "No open tasks"
        case .all: return "No tasks in this list"
        case .completed: return "Nothing completed yet"
        }
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "Try a different search." }
        return "Add a task to \(list.displayName)."
    }

    private func toggleSelection(_ id: UUID) {
        if selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        } else {
            selectedTaskIDs.insert(id)
        }
    }

    private func move(_ task: TaskItem, to target: TaskList?) {
        task.list = target
        task.manualOrder = Date.now.timeIntervalSinceReferenceDate
        task.modifiedAt = .now
        saveChanges()
    }

    private func setSelectedCompleted(_ completed: Bool) {
        for task in list.tasks where selectedTaskIDs.contains(task.id) {
            task.setCompleted(completed)
        }
        finishBulkMutation()
    }

    private func bulkMove(to target: TaskList?) {
        for task in list.tasks where selectedTaskIDs.contains(task.id) {
            task.list = target
            task.manualOrder = Date.now.timeIntervalSinceReferenceDate
            task.modifiedAt = .now
        }
        finishBulkMutation()
    }

    private func bulkDelete() {
        for task in list.tasks where selectedTaskIDs.contains(task.id) {
            modelContext.delete(task)
        }
        finishBulkMutation()
    }

    private func finishBulkMutation() {
        saveChanges()
        selectedTaskIDs.removeAll()
        isSelecting = false
    }

    private func reorderTask(sourceID: UUID, targetID: UUID) -> Bool {
        reorderTasks(in: list.tasks, sourceID: sourceID, targetID: targetID, modelContext: modelContext)
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save task changes: \(error)")
        }
    }
}

private func filteredAndSorted(
    tasks: [TaskItem],
    searchText: String,
    filter: TaskCollectionFilter,
    sort: TaskCollectionSort
) -> [TaskItem] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    let filtered = tasks.filter { task in
        let matchesFilter: Bool
        switch filter {
        case .open: matchesFilter = !task.isCompleted
        case .all: matchesFilter = true
        case .completed: matchesFilter = task.isCompleted
        }

        guard matchesFilter else { return false }
        guard !query.isEmpty else { return true }
        return task.displayTitle.lowercased().contains(query)
            || task.displayNotes.lowercased().contains(query)
    }

    switch sort {
    case .smart:
        return filtered.sorted(by: TaskItem.displayOrder)
    case .manual:
        return filtered.sorted(by: TaskItem.manualDisplayOrder)
    case .dueDate:
        return filtered.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (left?, right?) where left != right: return left < right
            case (_?, nil): return true
            case (nil, _?): return false
            default: return TaskItem.displayOrder(lhs, rhs)
            }
        }
    case .priority:
        return filtered.sorted { lhs, rhs in
            if lhs.priorityRawValue != rhs.priorityRawValue {
                return lhs.priorityRawValue > rhs.priorityRawValue
            }
            return TaskItem.displayOrder(lhs, rhs)
        }
    case .recentlyModified:
        return filtered.sorted { $0.modifiedAt > $1.modifiedAt }
    case .created:
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
}

private func reorderTasks(
    in tasks: [TaskItem],
    sourceID: UUID,
    targetID: UUID,
    modelContext: ModelContext
) -> Bool {
    guard sourceID != targetID else { return false }

    var ordered = tasks.sorted(by: TaskItem.manualDisplayOrder)
    guard let sourceIndex = ordered.firstIndex(where: { $0.id == sourceID }),
          let targetIndex = ordered.firstIndex(where: { $0.id == targetID }) else {
        return false
    }

    let moved = ordered.remove(at: sourceIndex)
    ordered.insert(moved, at: targetIndex)

    for (index, task) in ordered.enumerated() {
        task.manualOrder = Double(index)
    }
    moved.modifiedAt = .now

    do {
        try modelContext.save()
        return true
    } catch {
        modelContext.rollback()
        assertionFailure("Unable to reorder tasks: \(error)")
        return false
    }
}
