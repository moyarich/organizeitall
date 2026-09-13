import SwiftUI

struct ListRow: View {
    let list: TaskList

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 38, height: 38)
                .background(.indigo.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(list.displayName).font(.headline)
                if !list.displayNotes.isEmpty {
                    Text(list.displayNotes).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
                Text(summary).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let total = list.tasks.count
        guard total > 0 else { return "No tasks" }
        return "\(list.openTaskCount) open · \(total) total"
    }
}
