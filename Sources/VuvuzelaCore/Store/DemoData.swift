import Foundation

// Synthetic data + a scripted match timeline for the local demo/simulation mode
// (enabled with the DEMO=1 environment variable). Kept fully separate from the
// production data path so none of this can leak into a real run.
//
// The story it tells: every group has one live match on the final group matchday,
// so the standings churn live. The two favorites are the home sides that score
// repeatedly → goal alerts + sound:
//   • Group A — MEX vs FRA — MEX scores at 20', 40' and 70' (final 3-1)
//   • Group B — ESP vs BRA — ESP scores at 12', 50' and 80' (final 3-0)

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
    /// One live favorite per group: MEX (A) and ESP (B) trigger goal notifications.
    static let favorites: Set<String> = ["MEX", "ESP"]

    /// Seconds of wall-clock per simulated match minute.
    /// At 0.3 s/min the full 90-minute match runs in ~27 seconds.
    static let secondsPerMinute: TimeInterval = 0.3

    static func fixtures() -> [DemoFixture] {
        [
            DemoFixture(id: "demo-A", groupAbbr: "A", home: ("MEX", "Mexico"),      away: ("FRA", "France")),
            DemoFixture(id: "demo-B", groupAbbr: "B", home: ("ESP", "Spain"),        away: ("BRA", "Brazil")),
            DemoFixture(id: "demo-C", groupAbbr: "C", home: ("ENG", "England"),      away: ("USA", "USA")),
            DemoFixture(id: "demo-D", groupAbbr: "D", home: ("DEN", "Denmark"),      away: ("ECU", "Ecuador")),
            DemoFixture(id: "demo-E", groupAbbr: "E", home: ("GER", "Germany"),      away: ("JPN", "Japan")),
            DemoFixture(id: "demo-F", groupAbbr: "F", home: ("BEL", "Belgium"),      away: ("MAR", "Morocco")),
            DemoFixture(id: "demo-G", groupAbbr: "G", home: ("URU", "Uruguay"),      away: ("KOR", "South Korea")),
            DemoFixture(id: "demo-H", groupAbbr: "H", home: ("SUI", "Switzerland"), away: ("SEN", "Senegal")),
            DemoFixture(id: "demo-I", groupAbbr: "I", home: ("POL", "Poland"),       away: ("TUR", "Turkey")),
            DemoFixture(id: "demo-J", groupAbbr: "J", home: ("NOR", "Norway"),       away: ("EGY", "Egypt")),
            DemoFixture(id: "demo-K", groupAbbr: "K", home: ("CHI", "Chile"),        away: ("BOL", "Bolivia")),
            DemoFixture(id: "demo-L", groupAbbr: "L", home: ("VEN", "Venezuela"),    away: ("HUN", "Hungary")),
        ]
    }

    private enum Side { case home, away }

    /// Applies the scripted events for the given simulated minute, mutating the
    /// fixtures in place. Idempotent per minute as long as it's called once.
    static func apply(minute: Int, to fixtures: inout [DemoFixture]) {
        switch minute {
        case 1:  fixtures.indices.forEach { fixtures[$0].status = .live }

        // — first half: roughly one event every 3 match minutes —
        case  5: score(&fixtures, "demo-C", .home)  // ENG 1-0 USA
        case  8: score(&fixtures, "demo-E", .home)  // GER 1-0 JPN
        case 10: score(&fixtures, "demo-I", .home)  // POL 1-0 TUR
        case 12: score(&fixtures, "demo-B", .home)  // ESP 1-0 BRA ⚽ favorite
        case 15: score(&fixtures, "demo-D", .home)  // DEN 1-0 ECU
        case 18: score(&fixtures, "demo-G", .home)  // URU 1-0 KOR
        case 20: score(&fixtures, "demo-A", .home)  // MEX 1-0 FRA ⚽ favorite
        case 22: score(&fixtures, "demo-F", .home)  // BEL 1-0 MAR
        case 25: score(&fixtures, "demo-J", .home)  // NOR 1-0 EGY
        case 28: score(&fixtures, "demo-H", .home)  // SUI 1-0 SEN
        case 30: score(&fixtures, "demo-A", .away)  // MEX 1-1 FRA
        case 33: score(&fixtures, "demo-E", .away)  // GER 1-1 JPN
        case 35: score(&fixtures, "demo-K", .home)  // CHI 1-0 BOL
        case 38: score(&fixtures, "demo-C", .home)  // ENG 2-0 USA
        case 40: score(&fixtures, "demo-A", .home)  // MEX 2-1 FRA ⚽ favorite
        case 42: score(&fixtures, "demo-L", .home)  // VEN 1-0 HUN

        case 45: fixtures.indices.forEach { fixtures[$0].status = .halftime }
        case 47: fixtures.indices.forEach { fixtures[$0].status = .live }

        // — second half —
        case 50: score(&fixtures, "demo-B", .home)  // ESP 2-0 BRA ⚽ favorite
        case 52: score(&fixtures, "demo-D", .away)  // DEN 1-1 ECU
        case 54: score(&fixtures, "demo-I", .home)  // POL 2-0 TUR
        case 57: score(&fixtures, "demo-E", .home)  // GER 2-1 JPN
        case 60: score(&fixtures, "demo-G", .away)  // URU 1-1 KOR
        case 62: score(&fixtures, "demo-F", .away)  // BEL 1-1 MAR
        case 65: score(&fixtures, "demo-H", .away)  // SUI 1-1 SEN
        case 68: score(&fixtures, "demo-I", .away)  // POL 2-1 TUR
        case 70: score(&fixtures, "demo-A", .home)  // MEX 3-1 FRA ⚽ favorite
        case 72: score(&fixtures, "demo-J", .home)  // NOR 2-0 EGY
        case 75: score(&fixtures, "demo-L", .away)  // VEN 1-1 HUN
        case 78: score(&fixtures, "demo-K", .home)  // CHI 2-0 BOL
        case 80: score(&fixtures, "demo-B", .home)  // ESP 3-0 BRA ⚽ favorite
        case 82: score(&fixtures, "demo-D", .home)  // DEN 2-1 ECU
        case 85: score(&fixtures, "demo-H", .home)  // SUI 2-1 SEN
        case 88: score(&fixtures, "demo-G", .home)  // URU 2-1 KOR

        case 90: fixtures.indices.forEach { fixtures[$0].status = .finished }
        default: break
        }

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

        // MD1: MEX beat CRO 1-0, ARG beat FRA 2-0 → MD2 live: MEX vs FRA
        let groupA = GroupStanding(id: "A", name: "Group A", abbreviation: "A", teams: [
            row(1, "ARG", "Argentina",   w: 1, d: 0, l: 0, gf: 2, ga: 0, .direct),
            row(2, "MEX", "Mexico",      w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(3, "FRA", "France",      w: 0, d: 0, l: 1, gf: 0, ga: 2, .bestThirdIn),
            row(4, "CRO", "Croatia",     w: 0, d: 0, l: 1, gf: 0, ga: 1, .eliminated),
        ])
        let groupB = GroupStanding(id: "B", name: "Group B", abbreviation: "B", teams: [
            row(1, "BRA", "Brazil",      w: 1, d: 0, l: 0, gf: 3, ga: 0, .direct),
            row(2, "ESP", "Spain",       w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(3, "POR", "Portugal",    w: 0, d: 0, l: 1, gf: 0, ga: 1, .bestThirdIn),
            row(4, "NED", "Netherlands", w: 0, d: 0, l: 1, gf: 0, ga: 3, .eliminated),
        ])
        let groupC = GroupStanding(id: "C", name: "Group C", abbreviation: "C", teams: [
            row(1, "ENG", "England",     w: 1, d: 0, l: 0, gf: 3, ga: 0, .direct),
            row(2, "USA", "USA",         w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(3, "IRN", "Iran",        w: 0, d: 0, l: 1, gf: 0, ga: 1, .bestThirdIn),
            row(4, "WAL", "Wales",       w: 0, d: 0, l: 1, gf: 0, ga: 3, .eliminated),
        ])
        let groupD = GroupStanding(id: "D", name: "Group D", abbreviation: "D", teams: [
            row(1, "DEN", "Denmark",     w: 1, d: 0, l: 0, gf: 2, ga: 1, .direct),
            row(2, "AUS", "Australia",   w: 0, d: 1, l: 0, gf: 1, ga: 1, .direct),
            row(3, "TUN", "Tunisia",     w: 0, d: 1, l: 0, gf: 1, ga: 1, .bestThirdIn),
            row(4, "ECU", "Ecuador",     w: 0, d: 0, l: 1, gf: 1, ga: 2, .eliminated),
        ])
        let groupE = GroupStanding(id: "E", name: "Group E", abbreviation: "E", teams: [
            row(1, "GER", "Germany",     w: 1, d: 0, l: 0, gf: 4, ga: 1, .direct),
            row(2, "JPN", "Japan",       w: 1, d: 0, l: 0, gf: 2, ga: 1, .direct),
            row(3, "COS", "Costa Rica",  w: 0, d: 0, l: 1, gf: 1, ga: 2, .bestThirdIn),
            row(4, "COL", "Colombia",    w: 0, d: 0, l: 1, gf: 1, ga: 4, .eliminated),
        ])
        let groupF = GroupStanding(id: "F", name: "Group F", abbreviation: "F", teams: [
            row(1, "BEL", "Belgium",     w: 1, d: 0, l: 0, gf: 2, ga: 0, .direct),
            row(2, "CAN", "Canada",      w: 0, d: 1, l: 0, gf: 0, ga: 0, .direct),
            row(3, "MAR", "Morocco",     w: 0, d: 1, l: 0, gf: 0, ga: 0, .bestThirdIn),
            row(4, "CMR", "Cameroon",    w: 0, d: 0, l: 1, gf: 0, ga: 2, .eliminated),
        ])
        let groupG = GroupStanding(id: "G", name: "Group G", abbreviation: "G", teams: [
            row(1, "URU", "Uruguay",     w: 1, d: 0, l: 0, gf: 2, ga: 0, .direct),
            row(2, "KOR", "South Korea", w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(3, "GHA", "Ghana",       w: 0, d: 0, l: 1, gf: 0, ga: 1, .bestThirdIn),
            row(4, "SRB", "Serbia",      w: 0, d: 0, l: 1, gf: 0, ga: 2, .eliminated),
        ])
        let groupH = GroupStanding(id: "H", name: "Group H", abbreviation: "H", teams: [
            row(1, "SUI", "Switzerland", w: 1, d: 0, l: 0, gf: 3, ga: 1, .direct),
            row(2, "SEN", "Senegal",     w: 1, d: 0, l: 0, gf: 2, ga: 1, .direct),
            row(3, "NGA", "Nigeria",     w: 0, d: 0, l: 1, gf: 1, ga: 2, .bestThirdIn),
            row(4, "PAR", "Paraguay",    w: 0, d: 0, l: 1, gf: 1, ga: 3, .eliminated),
        ])
        let groupI = GroupStanding(id: "I", name: "Group I", abbreviation: "I", teams: [
            row(1, "POL", "Poland",      w: 1, d: 0, l: 0, gf: 3, ga: 2, .direct),
            row(2, "SAU", "Saudi Arabia",w: 0, d: 1, l: 0, gf: 2, ga: 2, .direct),
            row(3, "TUR", "Turkey",      w: 0, d: 1, l: 0, gf: 2, ga: 2, .bestThirdIn),
            row(4, "ALG", "Algeria",     w: 0, d: 0, l: 1, gf: 2, ga: 3, .eliminated),
        ])
        let groupJ = GroupStanding(id: "J", name: "Group J", abbreviation: "J", teams: [
            row(1, "NOR", "Norway",          w: 1, d: 0, l: 0, gf: 2, ga: 0, .direct),
            row(2, "GRE", "Greece",          w: 0, d: 1, l: 0, gf: 1, ga: 1, .direct),
            row(3, "EGY", "Egypt",           w: 0, d: 1, l: 0, gf: 1, ga: 1, .bestThirdIn),
            row(4, "CIV", "Côte d'Ivoire",   w: 0, d: 0, l: 1, gf: 0, ga: 2, .eliminated),
        ])
        let groupK = GroupStanding(id: "K", name: "Group K", abbreviation: "K", teams: [
            row(1, "CHI", "Chile",       w: 1, d: 0, l: 0, gf: 2, ga: 0, .direct),
            row(2, "AUT", "Austria",     w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(3, "QAT", "Qatar",       w: 0, d: 0, l: 1, gf: 0, ga: 1, .bestThirdIn),
            row(4, "BOL", "Bolivia",     w: 0, d: 0, l: 1, gf: 0, ga: 2, .eliminated),
        ])
        let groupL = GroupStanding(id: "L", name: "Group L", abbreviation: "L", teams: [
            row(1, "VEN", "Venezuela",   w: 1, d: 0, l: 0, gf: 1, ga: 0, .direct),
            row(2, "HUN", "Hungary",     w: 0, d: 1, l: 0, gf: 0, ga: 0, .direct),
            row(3, "PAN", "Panama",      w: 0, d: 1, l: 0, gf: 0, ga: 0, .bestThirdIn),
            row(4, "PER", "Peru",        w: 0, d: 0, l: 1, gf: 0, ga: 1, .eliminated),
        ])
        return [groupA, groupB, groupC, groupD, groupE, groupF,
                groupG, groupH, groupI, groupJ, groupK, groupL]
    }
}
