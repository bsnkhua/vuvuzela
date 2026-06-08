import Foundation

// Synthetic data + a scripted match timeline for the local demo/simulation mode
// (enabled with the DEMO=1 environment variable). Kept fully separate from the
// production data path so none of this can leak into a real run.
//
// The story it tells, in Group A on the final group matchday (two matches kicking
// off together so the standings churn live):
//   • FRA vs MEX  — MEX is a favorite; it scores at 22' and 70' → goal alerts + sound
//   • ARG vs CRO
// Group B is static, just to show a second group with a non-live favorite (ESP).

/// A mutable fixture the simulator drives. Separate from the production `Match`
/// (whose fields are immutable) so the demo can mutate scores/status freely and
/// rebuild a fresh `Match` snapshot on every tick.
struct DemoFixture {
    let id: String
    let groupAbbr: String
    let home: (abbr: String, name: String)
    let away: (abbr: String, name: String)
    var homeScore = 0
    var awayScore = 0
    var status: MatchStatus = .scheduled
    var minute = 0

    func toMatch(kickoff: Date) -> Match {
        Match(
            id: id,
            homeTeam: MatchTeam(abbreviation: home.abbr, displayName: home.name, score: homeScore),
            awayTeam: MatchTeam(abbreviation: away.abbr, displayName: away.name, score: awayScore),
            kickoff: kickoff,
            status: status,
            minute: minute > 0 ? minute : nil,
            groupName: "Group \(groupAbbr)",
            roundName: nil
        )
    }
}

enum DemoData {
    /// Two live-action favorites: MEX (Group A) and ESP (Group B). Both score
    /// during the demo so each group has a live match that churns its table.
    static let favorites: Set<String> = ["MEX", "ESP"]

    /// Seconds of wall-clock per simulated match minute.
    static let secondsPerMinute: TimeInterval = 0.8

    static func fixtures() -> [DemoFixture] {
        [
            DemoFixture(id: "demo-A-FRAMEX", groupAbbr: "A",
                        home: ("FRA", "France"), away: ("MEX", "Mexico")),
            DemoFixture(id: "demo-A-ARGCRO", groupAbbr: "A",
                        home: ("ARG", "Argentina"), away: ("CRO", "Croatia")),
            DemoFixture(id: "demo-B-ESPPOR", groupAbbr: "B",
                        home: ("ESP", "Spain"), away: ("POR", "Portugal")),
            DemoFixture(id: "demo-B-BRANED", groupAbbr: "B",
                        home: ("BRA", "Brazil"), away: ("NED", "Netherlands")),
        ]
    }

    private enum Side { case home, away }

    /// Applies the scripted events for the given simulated minute, mutating the
    /// fixtures in place. Idempotent per minute as long as it's called once.
    static func apply(minute: Int, to fixtures: inout [DemoFixture]) {
        switch minute {
        case 1:  fixtures.indices.forEach { fixtures[$0].status = .live }   // all kick off
        // Group A — FRA vs MEX (MEX favorite), ARG vs CRO
        case 10: score(&fixtures, "demo-A-ARGCRO", .home)   // ARG 1-0 CRO
        case 22: score(&fixtures, "demo-A-FRAMEX", .away)   // FRA 0-1 MEX ⚽ favorite
        case 35: score(&fixtures, "demo-A-FRAMEX", .home)   // FRA 1-1 MEX
        case 44: score(&fixtures, "demo-A-ARGCRO", .home)   // ARG 2-0 CRO
        case 58: score(&fixtures, "demo-A-FRAMEX", .home)   // FRA 2-1 MEX
        case 70: score(&fixtures, "demo-A-FRAMEX", .away)   // FRA 2-2 MEX ⚽ favorite
        case 80: score(&fixtures, "demo-A-ARGCRO", .away)   // ARG 2-1 CRO
        case 88: score(&fixtures, "demo-A-FRAMEX", .home)   // FRA 3-2 MEX
        // Group B — ESP vs POR (ESP favorite), BRA vs NED
        case 15: score(&fixtures, "demo-B-BRANED", .home)   // BRA 1-0 NED
        case 28: score(&fixtures, "demo-B-ESPPOR", .home)   // ESP 1-0 POR ⚽ favorite
        case 52: score(&fixtures, "demo-B-ESPPOR", .away)   // ESP 1-1 POR
        case 63: score(&fixtures, "demo-B-ESPPOR", .home)   // ESP 2-1 POR ⚽ favorite
        case 75: score(&fixtures, "demo-B-BRANED", .home)   // BRA 2-0 NED
        // Break and full time apply to every match together.
        case 45: fixtures.indices.forEach { fixtures[$0].status = .halftime }   // ⏸️ break
        case 47: fixtures.indices.forEach { fixtures[$0].status = .live }       // 2nd half
        case 90: fixtures.indices.forEach { fixtures[$0].status = .finished }
        default: break
        }

        // Advance the live clock after applying status changes, so a freshly
        // kicked-off match already shows its minute on the same tick.
        for i in fixtures.indices where fixtures[i].status == .live {
            fixtures[i].minute = minute
        }
    }

    private static func score(_ fixtures: inout [DemoFixture], _ id: String, _ side: Side) {
        guard let i = fixtures.firstIndex(where: { $0.id == id }) else { return }
        switch side {
        case .home: fixtures[i].homeScore += 1
        case .away: fixtures[i].awayScore += 1
        }
    }

    /// Standings after matchday 1 (each team played once) — the base the live
    /// matchday-2 scores get projected on top of.
    static func baseGroups(favorites: Set<String>) -> [GroupStanding] {
        func row(_ rank: Int, _ abbr: String, _ name: String,
                 w: Int, d: Int, l: Int, gf: Int, ga: Int,
                 _ q: TeamRow.QualificationStatus) -> TeamRow {
            TeamRow(
                id: abbr, abbreviation: abbr, displayName: name, logoURL: nil,
                rank: rank, gamesPlayed: w + d + l, wins: w, draws: d, losses: l,
                goalsFor: gf, goalsAgainst: ga, goalDiff: gf - ga, points: w * 3 + d,
                qualificationStatus: q, isFavorite: favorites.contains(abbr)
            )
        }

        let groupA = GroupStanding(id: "A", name: "Group A", abbreviation: "A", teams: [
            row(1, "ARG", "Argentina",   w: 1, d: 0, l: 0, gf: 2, ga: 0, .direct),
            row(2, "MEX", "Mexico",      w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(3, "FRA", "France",      w: 0, d: 0, l: 1, gf: 0, ga: 1, .bestThirdIn),
            row(4, "CRO", "Croatia",     w: 0, d: 0, l: 1, gf: 0, ga: 2, .eliminated),
        ])
        let groupB = GroupStanding(id: "B", name: "Group B", abbreviation: "B", teams: [
            row(1, "BRA", "Brazil",      w: 1, d: 0, l: 0, gf: 3, ga: 0, .direct),
            row(2, "ESP", "Spain",       w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(3, "POR", "Portugal",    w: 0, d: 0, l: 1, gf: 0, ga: 1, .bestThirdIn),
            row(4, "NED", "Netherlands", w: 0, d: 0, l: 1, gf: 0, ga: 3, .eliminated),
        ])
        return [groupA, groupB]
    }
}
