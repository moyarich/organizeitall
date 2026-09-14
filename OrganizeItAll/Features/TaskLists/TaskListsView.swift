import SwiftData
import SwiftUI

struct TaskListsView: View {
    @Environment(\.materialColors) private var colors
    @Query(sort: \TaskList.modifiedAt, order: .reverse) private var lists: [TaskList]
    @Query(sort: \TaskItem.modifiedAt, order: .reverse) private var tasks: [TaskItem]
    @State private var isPresentingNewList = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                colors.surface.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Lists")
                            .font(MaterialTypography.headlineLarge)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)

                        NavigationLink {
                            InboxTaskListView()
                        } label: {
                            MaterialCard {
                                InboxTaskListRow(tasks: inboxTasks)
                            }
                        }
                        .buttonStyle(.plain)

                        ForEach(lists) { list in
                            NavigationLink {
                                TaskListDetailView(list: list)
                            } label: {
                                MaterialCard {
                                    TaskListRow(list: list)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 96)
                }

                MaterialFloatingActionButton(title: "New list", systemImage: "plus") {
                    isPresentingNewList = true
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isPresentingNewList) {
                TaskListEditorView()
            }
        }
    }

    private var inboxTasks: [TaskItem] {
        tasks.filter(\.isInInbox).sorted(by: TaskItem.displayOrder)
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
                        .font(MaterialTypography.labelSmall)
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
