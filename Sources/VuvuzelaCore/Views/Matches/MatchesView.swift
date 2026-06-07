import SwiftUI

struct MatchesView: View {
    let store: WorldCupStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let live     = store.liveMatches
                let groups   = upcomingGroups(store.upcomingMatches)
                let recent   = store.recentMatches

                if live.isEmpty && groups.isEmpty && recent.isEmpty {
                    emptyState
                } else {
                    if !live.isEmpty {
                        dayHeader("LIVE", accent: Theme.live, isFirst: true)
                        ForEach(live) { match in
                            MatchRowView(match: match, store: store)
                            matchDivider()
                        }
                    }
                    ForEach(Array(groups.enumerated()), id: \.element.label) { idx, group in
                        let isFirst = live.isEmpty && idx == 0
                        dayHeader(group.label, accent: nil, isFirst: isFirst)
                        ForEach(group.matches) { match in
                            MatchRowView(match: match, store: store)
                            matchDivider()
                        }
                    }
                    if !recent.isEmpty {
                        dayHeader("RESULTS", accent: Theme.qualifyGreen, isFirst: live.isEmpty && groups.isEmpty)
                        ForEach(recent.prefix(8)) { match in
                            MatchRowView(match: match, store: store)
                            matchDivider()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Grouping

    private struct DayGroup {
        let label: String
        let matches: [Match]
    }

    private func upcomingGroups(_ matches: [Match]) -> [DayGroup] {
        let calendar = Calendar.current
        let todayStart    = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        let fmt = DateFormatter()
        fmt.dateFormat = "EEE · MMM d"

        var byDay: [Date: [Match]] = [:]
        for match in matches {
            let day = calendar.startOfDay(for: match.kickoff)
            byDay[day, default: []].append(match)
        }

        return byDay.keys.sorted().map { day in
            let label: String
            if day == todayStart         { label = "TODAY" }
            else if day == tomorrowStart { label = "TOMORROW" }
            else                         { label = fmt.string(from: day).uppercased() }
            return DayGroup(label: label, matches: byDay[day]!.sorted { $0.kickoff < $1.kickoff })
        }
    }

    // MARK: - Helpers

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("⚽")
                .font(.system(size: 28))
            Text("No matches in the next 7 days")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Text("Group stage starts June 11, 2026")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private func dayHeader(_ title: String, accent: Color?, isFirst: Bool) -> some View {
        HStack(spacing: 5) {
            if let accent {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(accent)
                    .frame(width: 3, height: 10)
            }
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(accent ?? Theme.textSecondary)
                .tracking(1.0)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color(white: 1, opacity: 0.04))
        .padding(.top, isFirst ? 0 : 6)
    }

    private func matchDivider() -> some View {
        Divider()
            .background(Theme.cardBorder)
            .padding(.horizontal, 10)
    }
}
