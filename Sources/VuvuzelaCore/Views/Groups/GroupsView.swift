import SwiftUI

struct GroupsView: View {
    let store: WorldCupStore
    // 3 columns
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        if store.groups.isEmpty {
            emptyState
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(store.groups) { group in
                    GroupCardView(group: group, store: store)
                }
            }
            .padding(10)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("⚽")
                .font(.system(size: 32))
            Text(store.error != nil ? "Failed to load standings" : "Loading standings…")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            if let err = store.error {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
