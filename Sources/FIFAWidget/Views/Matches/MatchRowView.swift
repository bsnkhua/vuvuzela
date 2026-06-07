import SwiftUI

struct MatchRowView: View {
    let match: Match
    let store: WorldCupStore

    private var homeFavorite: Bool { store.favoriteTeams.contains(match.homeTeam.abbreviation) }
    private var awayFavorite: Bool { store.favoriteTeams.contains(match.awayTeam.abbreviation) }

    var body: some View {
        HStack(spacing: 8) {
            // Status / time column
            statusColumn
                .frame(width: 52)

            Spacer()

            // Home team
            teamLabel(match.homeTeam, isFavorite: homeFavorite, alignment: .trailing)

            // Score or vs
            scoreView
                .frame(width: 52)

            // Away team
            teamLabel(match.awayTeam, isFavorite: awayFavorite, alignment: .leading)

            Spacer()

            // Group tag
            if let group = match.groupName {
                Text(group)
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.textDim)
                    .frame(width: 52, alignment: .trailing)
            } else {
                Spacer().frame(width: 52)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(highlightBackground)
    }

    @ViewBuilder
    private var statusColumn: some View {
        switch match.status {
        case .live, .halftime:
            VStack(spacing: 2) {
                Circle()
                    .fill(Theme.live)
                    .frame(width: 5, height: 5)
                if let min = match.minute {
                    Text("\(min)'")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.live)
                } else {
                    Text(match.status == .halftime ? "HT" : "LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.live)
                }
            }
        case .finished:
            Text("FT")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.textDim)
        case .scheduled:
            VStack(spacing: 1) {
                Text(match.kickoff, format: .dateTime.hour().minute())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(match.kickoff, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.textSecondary)
            }
        case .postponed:
            Text("PST")
                .font(.system(size: 9))
                .foregroundStyle(Theme.textDim)
        case .unknown:
            EmptyView()
        }
    }

    @ViewBuilder
    private var scoreView: some View {
        if match.isLive || match.isFinished || match.status == .halftime {
            HStack(spacing: 4) {
                Text("\(match.homeTeam.score)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("–")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(match.awayTeam.score)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        } else {
            Text("vs")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textDim)
        }
    }

    private func teamLabel(_ team: MatchTeam, isFavorite: Bool, alignment: HorizontalAlignment) -> some View {
        HStack(spacing: 4) {
            if alignment == .trailing {
                Text(team.abbreviation)
                    .font(.system(size: 11, weight: isFavorite ? .semibold : .regular))
                    .foregroundStyle(isFavorite ? Color.yellow : Theme.textPrimary)
                Text(team.flag)
                    .font(.system(size: 14))
            } else {
                Text(team.flag)
                    .font(.system(size: 14))
                Text(team.abbreviation)
                    .font(.system(size: 11, weight: isFavorite ? .semibold : .regular))
                    .foregroundStyle(isFavorite ? Color.yellow : Theme.textPrimary)
            }
        }
        .frame(width: 72, alignment: alignment == .trailing ? .trailing : .leading)
    }

    @ViewBuilder
    private var highlightBackground: some View {
        if homeFavorite || awayFavorite {
            Color.yellow.opacity(0.04)
        } else {
            Color.clear
        }
    }
}
