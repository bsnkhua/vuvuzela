import SwiftUI

struct MatchesView: View {
    let store: WorldCupStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let live = store.liveMatches
                let upcoming = store.upcomingMatches
                let recent = store.recentMatches

                if live.isEmpty && upcoming.isEmpty && recent.isEmpty {
                    emptyState
                } else {
                    if !live.isEmpty {
                        sectionHeader("🔴 LIVE")
                        ForEach(live) { match in
                            MatchRowView(match: match, store: store)
                            matchDivider()
                        }
                    }
                    if !upcoming.isEmpty {
                        sectionHeader("📅 UPCOMING")
                        ForEach(upcoming.prefix(12)) { match in
                            MatchRowView(match: match, store: store)
                            matchDivider()
                        }
                    }
                    if !recent.isEmpty {
                        sectionHeader("✅ RESULTS")
                        ForEach(recent.prefix(8)) { match in
                            MatchRowView(match: match, store: store)
                            matchDivider()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 480)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("📅")
                .font(.system(size: 28))
            Text("No matches today")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Text("Group stage starts June 11, 2026")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.textDim)
                .tracking(0.8)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func matchDivider() -> some View {
        Divider()
            .background(Theme.cardBorder)
            .padding(.horizontal, 10)
    }
}
