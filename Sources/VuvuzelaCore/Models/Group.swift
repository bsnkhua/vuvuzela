import Foundation

struct GroupStanding: Identifiable, Sendable {
    let id: String
    let name: String           // "Group A"
    let abbreviation: String   // "A"
    var teams: [TeamRow]
}

struct TeamRow: Identifiable, Sendable {
    let id: String
    let abbreviation: String   // "MEX"
    let displayName: String    // "Mexico"
    let logoURL: String?
    var rank: Int
    var gamesPlayed: Int
    var wins: Int
    var draws: Int
    var losses: Int
    var goalsFor: Int
    var goalsAgainst: Int
    var goalDiff: Int
    var points: Int
    var qualificationStatus: QualificationStatus
    var isFavorite: Bool = false

    // Set while the team is in a live match (nil otherwise) — drives the
    // standings-row "who's playing / who's winning" highlight.
    var liveState: LiveState? = nil
    var liveScoreFor: Int? = nil       // this team's goals in the live match
    var liveScoreAgainst: Int? = nil   // the opponent's goals
    var liveClock: String? = nil       // "67'" while playing, "HT" at the break

    enum LiveState: Sendable, Equatable {
        case winning
        case losing
        case drawing
    }

    enum QualificationStatus: Sendable, Equatable {
        case direct        // top 2 → guaranteed R32
        case bestThirdIn   // rank 3, currently in top-8 third-place
        case bestThirdOut  // rank 3, currently outside top-8
        case eliminated
        case unknown
    }

    var flag: String { FlagEmoji.flag(for: abbreviation) }
}

// MARK: - ESPN API Decodable

struct ESPNStandingsResponse: Decodable {
    let children: [ESPNGroup]
}

struct ESPNGroup: Decodable {
    let name: String
    let abbreviation: String
    let standings: ESPNGroupStandings
}

struct ESPNGroupStandings: Decodable {
    let entries: [ESPNEntry]
}

struct ESPNEntry: Decodable {
    let team: ESPNTeam
    let note: ESPNNote?
    let stats: [ESPNStat]
}

struct ESPNTeam: Decodable {
    let id: String
    let abbreviation: String
    let displayName: String
    let logos: [ESPNLogo]?
}

struct ESPNLogo: Decodable {
    let href: String
}

struct ESPNNote: Decodable {
    let color: String?
    let description: String?
    let rank: Int?
}

struct ESPNStat: Decodable {
    let name: String
    let value: Double?
    let displayValue: String?
    let summary: String?

    private enum CodingKeys: String, CodingKey {
        case name, value, displayValue, summary
    }
}

// MARK: - Mapping ESPN → domain

extension ESPNEntry {
    func toTeamRow(favoriteTeams: Set<String>) -> TeamRow {
        var statsDict: [String: Double] = [:]
        for s in stats {
            if let v = s.value { statsDict[s.name] = v }
        }

        let rank = Int(statsDict["rank"] ?? 0)
        let qualStatus: TeamRow.QualificationStatus
        switch note?.color {
        case "#81D6AC": qualStatus = .direct
        case "#B5E7CE": qualStatus = .bestThirdIn  // WorldCupStore will recalculate best-8
        case "#FF7F84": qualStatus = .eliminated
        default:        qualStatus = .unknown
        }

        return TeamRow(
            id: team.id,
            abbreviation: team.abbreviation,
            displayName: team.displayName,
            logoURL: team.logos?.first?.href,
            rank: rank,
            gamesPlayed: Int(statsDict["gamesPlayed"] ?? 0),
            wins: Int(statsDict["wins"] ?? 0),
            draws: Int(statsDict["ties"] ?? 0),
            losses: Int(statsDict["losses"] ?? 0),
            goalsFor: Int(statsDict["pointsFor"] ?? 0),
            goalsAgainst: Int(statsDict["pointsAgainst"] ?? 0),
            goalDiff: Int(statsDict["pointDifferential"] ?? 0),
            points: Int(statsDict["points"] ?? 0),
            qualificationStatus: qualStatus,
            isFavorite: favoriteTeams.contains(team.abbreviation)
        )
    }
}

extension ESPNGroup {
    func toGroupStanding(favoriteTeams: Set<String>) -> GroupStanding {
        let letter = name.components(separatedBy: " ").last ?? abbreviation
        var teams = standings.entries.map { $0.toTeamRow(favoriteTeams: favoriteTeams) }
        teams.sort { $0.rank < $1.rank }
        return GroupStanding(id: letter, name: name, abbreviation: letter, teams: teams)
    }
}
