import SwiftUI

@available(iOS 17.0, *)
struct ListRow: View {
    let list: List

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: "folder.fill")
                    .foregroundStyle(Color.brandAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(list.wrappedName)
                    .font(.headline)

                if !list.wrappedDetail.isEmpty {
                    Text(list.wrappedDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let total = list.tasks.count
        let open = list.openTaskCount
        if total == 0 { return "No tasks" }
        return "\(open) open · \(total) total"
    }
}
