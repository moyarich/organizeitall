import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .indigo : .secondary)
                    .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
            }
            .buttonStyle(.borderless)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(task.displayTitle).font(.headline).strikethrough(task.isCompleted).foregroundStyle(task.isCompleted ? .secondary : .primary)
                    if task.priority != .normal {
                        Image(systemName: task.priority.systemImage).font(.caption.bold()).foregroundStyle(task.priority == .high ? .orange : .secondary).accessibilityLabel("\(task.priority.title) priority")
                    }
                }
                if !task.displayNotes.isEmpty {
                    Text(task.displayNotes).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                HStack(spacing: 10) {
                    Label(task.listName, systemImage: "folder")
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar").foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
