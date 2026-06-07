import SwiftUI

struct BracketMatchView: View {
    let match: BracketMatch
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            teamSlot(match.teamA, score: match.scoreA, isWinner: match.winner == match.teamA.abbreviation)
            Divider().background(Theme.cardBorder)
            teamSlot(match.teamB, score: match.scoreB, isWinner: match.winner == match.teamB.abbreviation)
        }
        .frame(width: 110, height: height)
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var borderColor: Color {
        if match.status == .live || match.status == .halftime { return Theme.live.opacity(0.6) }
        return Theme.cardBorder
    }

    private func teamSlot(_ team: BracketTeam, score: Int?, isWinner: Bool) -> some View {
        HStack(spacing: 4) {
            Text(team.flag)
                .font(.system(size: 10))
            Text(team.isTBD ? "TBD" : team.abbreviation)
                .font(.system(size: 9, weight: isWinner ? .semibold : .regular))
                .foregroundStyle(team.isTBD ? Theme.textDim : (isWinner ? Theme.textPrimary : Theme.textSecondary))
                .lineLimit(1)
            Spacer()
            if let score {
                Text("\(score)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isWinner ? Theme.textPrimary : Theme.textSecondary)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: (height - 1) / 2)
        .background(isWinner ? Color(white: 1, opacity: 0.05) : Color.clear)
    }
}
