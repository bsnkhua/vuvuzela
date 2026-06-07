import SwiftUI

struct BracketView: View {
    let store: WorldCupStore
    private let matchHeight: CGFloat = 42
    private let matchSpacing: CGFloat = 6

    // Only show main rounds (not 3rd place)
    private var mainRounds: [BracketRound] {
        store.bracketRounds.filter { $0.id != "third" }
    }
    private var thirdPlace: BracketRound? {
        store.bracketRounds.first { $0.id == "third" }
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(mainRounds) { round in
                    RoundColumnView(
                        round: round,
                        matchHeight: matchHeight,
                        matchSpacing: matchSpacing
                    )
                    if round.id != mainRounds.last?.id {
                        connectorColumn(round: round)
                    }
                }

                // 3rd place below semi column
                if let third = thirdPlace {
                    VStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("3rd Place")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.textDim)
                                .tracking(0.5)
                            BracketMatchView(match: third.matches[0], height: matchHeight)
                        }
                        .padding(.top, 8)
                    }
                    .frame(width: 130)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 520)
    }

    // Vertical connector lines between rounds
    private func connectorColumn(round: BracketRound) -> some View {
        let count = round.matches.count
        let totalH = CGFloat(count) * matchHeight + CGFloat(max(count - 1, 0)) * matchSpacing
        let halfGap = (matchHeight + matchSpacing) / 2

        return Canvas { ctx, size in
            let stride = totalH / CGFloat(count)
            let midY = stride / 2
            for i in 0..<count/2 {
                let topY = CGFloat(i * 2) * stride + midY
                let botY = topY + stride
                let midMidY = (topY + botY) / 2
                var path = Path()
                path.move(to: CGPoint(x: 0, y: topY))
                path.addLine(to: CGPoint(x: size.width / 2, y: topY))
                path.addLine(to: CGPoint(x: size.width / 2, y: botY))
                path.addLine(to: CGPoint(x: 0, y: botY))
                path.move(to: CGPoint(x: size.width / 2, y: midMidY))
                path.addLine(to: CGPoint(x: size.width, y: midMidY))
                ctx.stroke(path, with: .color(Theme.cardBorder), lineWidth: 1)
            }
            _ = halfGap // suppress warning
        }
        .frame(width: 20, height: totalH)
    }
}

private struct RoundColumnView: View {
    let round: BracketRound
    let matchHeight: CGFloat
    let matchSpacing: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // Column header
            Text(round.shortName)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.textDim)
                .tracking(0.5)
                .frame(width: 130)
                .padding(.bottom, 6)

            // Matches with vertical centering
            VStack(spacing: matchSpacing) {
                ForEach(round.matches) { match in
                    BracketMatchView(match: match, height: matchHeight)
                }
            }
            .frame(width: 130)
        }
    }
}
