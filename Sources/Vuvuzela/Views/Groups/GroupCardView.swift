import SwiftUI

struct GroupCardView: View {
    let group: GroupStanding
    let store: WorldCupStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(group.name.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.5)
                Spacer()
                if group.teams.contains(where: { $0.isFavorite }) {
                    Text("★")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.yellow)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)

            // Column headers
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 14, alignment: .center)
                Text("Team")
                    .frame(width: 58, alignment: .leading)
                Spacer()
                Text("P")
                    .frame(width: 20, alignment: .center)
                Text("W")
                    .frame(width: 20, alignment: .center)
                Text("D")
                    .frame(width: 20, alignment: .center)
                Text("L")
                    .frame(width: 20, alignment: .center)
                Text("GD")
                    .frame(width: 24, alignment: .center)
                Text("Pts")
                    .frame(width: 24, alignment: .center)
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Theme.textDim)
            .padding(.horizontal, 7)
            .padding(.bottom, 3)

            Divider()
                .background(Theme.cardBorder)

            // Team rows
            ForEach(group.teams) { team in
                TeamRowView(team: team, store: store)
                if team.id != group.teams.last?.id {
                    Divider()
                        .background(Theme.cardBorder.opacity(0.5))
                        .padding(.horizontal, 4)
                }
            }
        }
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct TeamRowView: View {
    let team: TeamRow
    let store: WorldCupStore

    var body: some View {
        HStack(spacing: 0) {
            // Qualification color bar
            qualBar
                .frame(width: 3)

            HStack(spacing: 0) {
                // Rank
                Text("\(team.rank)")
                    .font(.system(size: 10))
                    .foregroundStyle(team.rank <= 2 ? Theme.textPrimary : Theme.textSecondary)
                    .frame(width: 14, alignment: .center)

                // Flag + abbreviation
                HStack(spacing: 3) {
                    Text(team.flag)
                        .font(.system(size: 11))
                    Text(team.abbreviation)
                        .font(.system(size: 10, weight: team.isFavorite ? .semibold : .regular))
                        .foregroundStyle(team.isFavorite ? Color.yellow : Theme.textPrimary)
                }
                .frame(width: 58, alignment: .leading)

                Spacer()

                // Stats
                statCell(team.gamesPlayed)
                statCell(team.wins)
                statCell(team.draws)
                statCell(team.losses)

                // GD with sign
                Text(team.goalDiff >= 0 ? "+\(team.goalDiff)" : "\(team.goalDiff)")
                    .font(.system(size: 10))
                    .foregroundStyle(team.goalDiff > 0 ? Theme.qualifyGreen : (team.goalDiff < 0 ? Theme.eliminated : Theme.textSecondary))
                    .frame(width: 24, alignment: .center)

                // Points (bold)
                Text("\(team.points)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 24, alignment: .center)
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 22)
        .contentShape(Rectangle())
        .onTapGesture {
            store.toggleFavorite(team.abbreviation)
        }
        .help("Tap to \(team.isFavorite ? "unmark" : "mark") \(team.displayName) as favourite")
    }

    @ViewBuilder
    private var qualBar: some View {
        switch team.qualificationStatus {
        case .direct:
            Theme.qualifyGreen
        case .bestThirdIn:
            Theme.bestThird
        case .bestThirdOut, .eliminated, .unknown:
            Color.clear
        }
    }

    private func statCell(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 10))
            .foregroundStyle(Theme.textSecondary)
            .frame(width: 20, alignment: .center)
    }
}
