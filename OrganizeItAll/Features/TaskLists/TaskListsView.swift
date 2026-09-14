import SwiftData
import SwiftUI

private enum TaskListsSheet: Identifiable {
    case newList
    case editList(TaskList)

    var id: String {
        switch self {
        case .newList: "new-list"
        case .editList(let list): "edit-list-\(list.id.uuidString)"
        }
    }
}

private enum TaskListsScope: String, CaseIterable, Identifiable {
    case active = "Active"
    case archived = "Archived"

    var id: Self { self }
}

struct TaskListsView: View {
    @Environment(\.materialColors) private var colors
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.modifiedAt, order: .reverse) private var lists: [TaskList]
    @Query(sort: \TaskItem.modifiedAt, order: .reverse) private var tasks: [TaskItem]

    @State private var searchText = ""
    @State private var scope: TaskListsScope = .active
    @State private var activeSheet: TaskListsSheet?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Lists")
                            .font(MaterialTypography.headlineLarge)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)

                        MaterialSearchBar(text: $searchText, prompt: "Search lists")

                        HStack(spacing: 8) {
                            ForEach(TaskListsScope.allCases) { option in
                                MaterialFilterChip(
                                    title: option.rawValue,
                                    systemImage: option == .archived ? "archivebox" : "folder",
                                    isSelected: scope == option
                                ) {
                                    scope = option
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)

                        if scope == .active && matchesInboxSearch {
                            NavigationLink {
                                InboxTaskListView()
                            } label: {
                                MaterialCard {
                                    InboxTaskListRow(tasks: inboxTasks)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if displayedLists.isEmpty && !(scope == .active && matchesInboxSearch) {
                            MaterialEmptyState(
                                title: emptyTitle,
                                message: emptyMessage,
                                systemImage: scope == .archived ? "archivebox" : "folder"
                            )
                        } else {
                            ForEach(displayedLists) { list in
                                NavigationLink {
                                    TaskListDetailView(list: list)
                                } label: {
                                    MaterialCard {
                                        TaskListRow(list: list)
                                    }
                                }
                                .buttonStyle(.plain)
                                .draggable(list.id.uuidString)
                                .dropDestination(for: String.self) { values, _ in
                                    guard let value = values.first,
                                          let sourceID = UUID(uuidString: value) else {
                                        return false
                                    }
                                    return reorderList(sourceID: sourceID, targetID: list.id)
                                }
                                .contextMenu {
                                    Button(list.isPinned ? "Unpin" : "Pin", systemImage: list.isPinned ? "pin.slash" : "pin") {
                                        list.isPinned.toggle()
                                        list.modifiedAt = .now
                                        saveChanges()
                                    }

                                    Button(list.isArchived ? "Restore" : "Archive", systemImage: list.isArchived ? "arrow.uturn.backward" : "archivebox") {
                                        list.isArchived.toggle()
                                        list.modifiedAt = .now
                                        saveChanges()
                                    }

                                    Button("Edit", systemImage: "pencil") {
                                        activeSheet = .editList(list)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 96)
                }

                MaterialFloatingActionButton(title: "New list", systemImage: "plus") {
                    activeSheet = .newList
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .newList:
                    TaskListEditorView()
                case .editList(let list):
                    TaskListEditorView(list: list)
                }
            }
        }
    }

    private var inboxTasks: [TaskItem] {
        tasks.filter(\.isInInbox).sorted(by: TaskItem.displayOrder)
    }

    private var displayedLists: [TaskList] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return lists
            .filter { list in
                guard list.isArchived == (scope == .archived) else { return false }
                guard !query.isEmpty else { return true }
                return list.displayName.lowercased().contains(query)
                    || list.displayNotes.lowercased().contains(query)
            }
            .sorted(by: TaskList.manualDisplayOrder)
    }

    private var matchesInboxSearch: Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return query.isEmpty || "inbox".contains(query)
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No matching lists" }
        return scope == .archived ? "No archived lists" : "No custom lists"
    }

    private var emptyMessage: String {
        if !searchText.isEmpty { return "Try a different search." }
        return scope == .archived
            ? "Archived lists will appear here."
            : "Create a list to organize related tasks."
    }

    private func reorderList(sourceID: UUID, targetID: UUID) -> Bool {
        guard sourceID != targetID,
              let source = lists.first(where: { $0.id == sourceID }),
              let target = lists.first(where: { $0.id == targetID }),
              source.isArchived == target.isArchived,
              source.isPinned == target.isPinned else {
            return false
        }

        var ordered = lists
            .filter { $0.isArchived == source.isArchived && $0.isPinned == source.isPinned }
            .sorted {
                if $0.manualOrder != $1.manualOrder { return $0.manualOrder < $1.manualOrder }
                return $0.modifiedAt > $1.modifiedAt
            }

        guard let sourceIndex = ordered.firstIndex(where: { $0.id == sourceID }),
              let targetIndex = ordered.firstIndex(where: { $0.id == targetID }) else {
            return false
        }

        let moved = ordered.remove(at: sourceIndex)
        ordered.insert(moved, at: targetIndex)

        for (index, list) in ordered.enumerated() {
            list.manualOrder = Double(index)
        }
        source.modifiedAt = .now
        saveChanges()
        return true
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Unable to save task list changes: \(error)")
        }
    }
}

private struct InboxTaskListRow: View {
    @Environment(\.materialColors) private var colors
    let tasks: [TaskItem]

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(colors.onSecondaryContainer)
                .frame(width: 48, height: 48)
                .background(
                    colors.secondaryContainer,
                    in: RoundedRectangle(cornerRadius: MaterialShape.medium, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("Inbox")
                        .font(MaterialTypography.titleMedium)
                        .foregroundStyle(colors.onSurface)

                    Text("Default")
                        .font(MaterialTypography.labelMedium)
                        .foregroundStyle(colors.onSecondaryContainer)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colors.secondaryContainer, in: Capsule())
                }

                Text("Tasks not assigned to another list")
                    .font(MaterialTypography.bodyMedium)
                    .foregroundStyle(colors.onSurfaceVariant)
                    .lineLimit(1)

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
        .accessibilityLabel("Inbox, default list, \(summary)")
    }

    private var summary: String {
        let total = tasks.count
        guard total > 0 else { return "No tasks" }
        let open = tasks.lazy.filter { !$0.isCompleted }.count
        return "\(open) open · \(total) total"
    }
}
