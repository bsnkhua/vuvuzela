import Foundation

struct BracketRound: Identifiable, Sendable {
    let id: String
    let name: String      // "Round of 32", "Round of 16", "Quarterfinals", …
    let shortName: String // "R32", "R16", "QF", "SF", "F"
    var matches: [BracketMatch]
}

struct BracketMatch: Identifiable, Sendable {
    let id: String
    var teamA: BracketTeam
    var teamB: BracketTeam
    var status: MatchStatus
    var scoreA: Int?
    var scoreB: Int?
    var kickoff: Date?
    var winner: String?   // abbreviation of winner
}

struct BracketTeam: Sendable {
    var abbreviation: String  // "MEX" or "TBD"
    var displayName: String
    var isTBD: Bool

    static let tbd = BracketTeam(abbreviation: "TBD", displayName: "TBD", isTBD: true)
    var flag: String { isTBD ? "🏳️" : FlagEmoji.flag(for: abbreviation) }
}

// Placeholder bracket for pre-tournament display
extension BracketRound {
    static func placeholder() -> [BracketRound] {
        let r32Matches = (1...16).map { i in
            BracketMatch(
                id: "r32-\(i)",
                teamA: .tbd, teamB: .tbd,
                status: .scheduled, scoreA: nil, scoreB: nil,
                kickoff: nil, winner: nil
            )
        }
        let r16Matches = (1...8).map { i in
            BracketMatch(id: "r16-\(i)", teamA: .tbd, teamB: .tbd, status: .scheduled, scoreA: nil, scoreB: nil, kickoff: nil, winner: nil)
        }
        let qfMatches = (1...4).map { i in
            BracketMatch(id: "qf-\(i)", teamA: .tbd, teamB: .tbd, status: .scheduled, scoreA: nil, scoreB: nil, kickoff: nil, winner: nil)
        }
        let sfMatches = (1...2).map { i in
            BracketMatch(id: "sf-\(i)", teamA: .tbd, teamB: .tbd, status: .scheduled, scoreA: nil, scoreB: nil, kickoff: nil, winner: nil)
        }
        let final_ = BracketMatch(id: "final", teamA: .tbd, teamB: .tbd, status: .scheduled, scoreA: nil, scoreB: nil, kickoff: nil, winner: nil)
        let third = BracketMatch(id: "third", teamA: .tbd, teamB: .tbd, status: .scheduled, scoreA: nil, scoreB: nil, kickoff: nil, winner: nil)

        return [
            BracketRound(id: "r32", name: "Round of 32", shortName: "R32", matches: r32Matches),
            BracketRound(id: "r16", name: "Round of 16", shortName: "R16", matches: r16Matches),
            BracketRound(id: "qf", name: "Quarterfinals", shortName: "QF", matches: qfMatches),
            BracketRound(id: "sf", name: "Semifinals", shortName: "SF", matches: sfMatches),
            BracketRound(id: "final", name: "Final", shortName: "F", matches: [final_]),
            BracketRound(id: "third", name: "3rd Place", shortName: "3rd", matches: [third]),
        ]
    }
}
