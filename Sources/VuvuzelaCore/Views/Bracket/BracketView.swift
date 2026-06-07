import SwiftUI

struct BracketView: View {
    let store: WorldCupStore

    // Layout constants
    private let mW: CGFloat = 90    // match card width
    private let mH: CGFloat = 38    // match card height (2 rows)
    private let connW: CGFloat = 14 // connector strip width

    private var unit: CGFloat { mH + 6 }          // 44: one R32 slot height
    private var totalH: CGFloat { 8 * unit - 6 }  // 346: total bracket height

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // Left half: R32(8) → R16(4) → QF(2) → SF(1)
                roundCol(slice("r32", from: 0, count: 8), round: 0)
                connector(round: 0, mirrored: false)
                roundCol(slice("r16", from: 0, count: 4), round: 1)
                connector(round: 1, mirrored: false)
                roundCol(slice("qf",  from: 0, count: 2), round: 2)
                connector(round: 2, mirrored: false)
                roundCol(slice("sf",  from: 0, count: 1), round: 3)
                connector(round: 3, mirrored: false)

                // Center: Final + 3rd place
                centerCol

                // Right half (mirrored): SF(1) → QF(2) → R16(4) → R32(8)
                connector(round: 3, mirrored: true)
                roundCol(slice("sf",  from: 1, count: 1), round: 3)
                connector(round: 2, mirrored: true)
                roundCol(slice("qf",  from: 2, count: 2), round: 2)
                connector(round: 1, mirrored: true)
                roundCol(slice("r16", from: 4, count: 4), round: 1)
                connector(round: 0, mirrored: true)
                roundCol(slice("r32", from: 8, count: 8), round: 0)
            }
            .padding(12)
        }
    }

    // MARK: - Round column

    @ViewBuilder
    private func roundCol(_ matches: [BracketMatch], round: Int) -> some View {
        let step   = CGFloat(1 << round) * unit
        let topPad = step / 2 - unit / 2

        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: mW, height: totalH)
            ForEach(Array(matches.enumerated()), id: \.element.id) { i, match in
                matchCard(match)
                    .offset(y: topPad + CGFloat(i) * step)
            }
        }
    }

    // MARK: - Connector

    @ViewBuilder
    private func connector(round: Int, mirrored: Bool) -> some View {
        let step   = CGFloat(1 << round) * unit
        let topPad = step / 2 - unit / 2
        let pairs  = (8 >> round) / 2   // number of pairs to draw; 0 when round==3

        Canvas { ctx, size in
            let w = size.width

            if pairs == 0 {
                // SF ↔ Final: plain horizontal line
                var p = Path()
                p.move(to:    CGPoint(x: 0, y: totalH / 2))
                p.addLine(to: CGPoint(x: w, y: totalH / 2))
                ctx.stroke(p, with: .color(Theme.cardBorder), lineWidth: 1)
                return
            }

            for i in 0..<pairs {
                let topY = topPad + mH / 2 + CGFloat(2 * i) * step
                let botY = topY + step
                let midY = (topY + botY) / 2

                var p = Path()
                if !mirrored {
                    p.move(to:    CGPoint(x: 0,   y: topY))
                    p.addLine(to: CGPoint(x: w/2, y: topY))
                    p.addLine(to: CGPoint(x: w/2, y: botY))
                    p.addLine(to: CGPoint(x: 0,   y: botY))
                    p.move(to:    CGPoint(x: w/2, y: midY))
                    p.addLine(to: CGPoint(x: w,   y: midY))
                } else {
                    p.move(to:    CGPoint(x: w,   y: topY))
                    p.addLine(to: CGPoint(x: w/2, y: topY))
                    p.addLine(to: CGPoint(x: w/2, y: botY))
                    p.addLine(to: CGPoint(x: w,   y: botY))
                    p.move(to:    CGPoint(x: w/2, y: midY))
                    p.addLine(to: CGPoint(x: 0,   y: midY))
                }
                ctx.stroke(p, with: .color(Theme.cardBorder), lineWidth: 1)
            }
        }
        .frame(width: connW, height: totalH)
    }

    // MARK: - Center column (Final + 3rd place)

    private var centerCol: some View {
        let finalMatch = store.bracketRounds.first { $0.id == "final" }?.matches.first
        let thirdMatch = store.bracketRounds.first { $0.id == "third" }?.matches.first
        let colW = mW + 20

        return ZStack(alignment: .topLeading) {
            Color.clear.frame(width: colW, height: totalH)

            // Final
            VStack(spacing: 2) {
                Text("FINAL")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.warning)
                    .tracking(0.5)
                if let m = finalMatch {
                    matchCard(m).frame(width: mW)
                }
            }
            .frame(width: colW)
            .offset(y: totalH / 2 - mH / 2 - 14)

            // 3rd place
            if let t = thirdMatch {
                VStack(spacing: 2) {
                    Text("3RD PLACE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.textDim)
                        .tracking(0.5)
                    matchCard(t).frame(width: mW)
                }
                .frame(width: colW)
                .offset(y: totalH / 2 + mH / 2 + 20)
            }
        }
    }

    // MARK: - Match card

    private func matchCard(_ match: BracketMatch) -> some View {
        VStack(spacing: 0) {
            teamSlot(match.teamA, score: match.scoreA,
                     isWinner: match.winner == match.teamA.abbreviation && match.winner != nil)
            Divider().background(Theme.cardBorder)
            teamSlot(match.teamB, score: match.scoreB,
                     isWinner: match.winner == match.teamB.abbreviation && match.winner != nil)
        }
        .frame(width: mW, height: mH)
        .background(Theme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func teamSlot(_ team: BracketTeam, score: Int?, isWinner: Bool) -> some View {
        HStack(spacing: 3) {
            if !team.isTBD {
                Text(team.flag).font(.system(size: 10))
            }
            Text(team.abbreviation)
                .font(.system(size: 9, weight: isWinner ? .semibold : .regular))
                .foregroundStyle(isWinner ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let s = score {
                Text("\(s)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isWinner ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.trailing, 4)
            }
        }
        .padding(.leading, 5)
        .frame(height: mH / 2)
    }

    // MARK: - Helpers

    private func slice(_ roundId: String, from: Int, count: Int) -> [BracketMatch] {
        let matches = store.bracketRounds.first { $0.id == roundId }?.matches ?? []
        let end = min(from + count, matches.count)
        guard from < end else { return [] }
        return Array(matches[from..<end])
    }
}
