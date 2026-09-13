import SwiftUI

struct ListRow: View {
    @ObservedObject var list: List

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: "folder.fill")
                    .foregroundColor(.brandAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(list.wrappedName)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !list.wrappedDetail.isEmpty {
                    Text(list.wrappedDetail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let total = list.tasksArray.count
        let open = list.openTaskCount
        if total == 0 { return "No tasks" }
        return "\(open) open · \(total) total"
    }
}
