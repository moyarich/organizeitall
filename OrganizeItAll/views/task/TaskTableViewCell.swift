import SwiftUI

struct TaskRow: View {
    @ObservedObject var task: Task
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundColor(task.isComplete ? .brandAccent : .secondary)
                    .accessibilityLabel(task.isComplete ? "Mark incomplete" : "Mark complete")
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.wrappedTitle)
                    .font(.headline)
                    .strikethrough(task.isComplete)
                    .foregroundColor(task.isComplete ? .secondary : .primary)

                if !task.wrappedDetail.isEmpty {
                    Text(task.wrappedDetail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 5) {
                    Image(systemName: "folder")
                    Text(task.listName)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case open = "Open"
    case completed = "Done"
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .light))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search tasks", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
