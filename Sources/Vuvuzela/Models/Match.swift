import Foundation

struct Match: Identifiable, Sendable {
    let id: String
    let homeTeam: MatchTeam
    let awayTeam: MatchTeam
    let kickoff: Date
    let status: MatchStatus
    let minute: Int?
    let groupName: String?
    let roundName: String?

    var isLive: Bool { status == .live }
    var isFinished: Bool { status == .finished }
}

struct MatchTeam: Sendable {
    let abbreviation: String
    let displayName: String
    var score: Int

    var flag: String { FlagEmoji.flag(for: abbreviation) }
}

enum MatchStatus: Sendable, Equatable {
    case scheduled
    case live
    case halftime
    case finished
    case postponed
    case unknown
}

// MARK: - ESPN CDN Scoreboard Decodable

struct ESPNCDNScoreboardResponse: Decodable {
    let content: ESPNCDNContent
}

struct ESPNCDNContent: Decodable {
    let sbData: ESPNScoreboardData
}

struct ESPNScoreboardData: Decodable {
    let events: [ESPNEvent]?
}

struct ESPNEvent: Decodable {
    let id: String
    let name: String
    let date: String
    let competitions: [ESPNCompetition]?
    let season: ESPNEventSeason?
}

struct ESPNEventSeason: Decodable {
    let slug: String?
}

struct ESPNCompetition: Decodable {
    let status: ESPNCompStatus?
    let competitors: [ESPNCompetitor]?
    let notes: [ESPNCompNote]?
}

struct ESPNCompNote: Decodable {
    let headline: String?
}

struct ESPNCompStatus: Decodable {
    let clock: Double?
    let displayClock: String?
    let period: Int?
    let type: ESPNStatusType?
}

struct ESPNStatusType: Decodable {
    let name: String?
    let state: String?
    let completed: Bool?
    let description: String?
    let detail: String?
    let shortDetail: String?
}

struct ESPNCompetitor: Decodable {
    let homeAway: String?
    let team: ESPNCompTeam
    let score: String?
}

struct ESPNCompTeam: Decodable {
    let id: String
    let abbreviation: String
    let displayName: String
}

// MARK: - Mapping

// ESPN uses "2026-06-11T19:00Z" (no seconds). ISO8601DateFormatter requires seconds,
// so we use DateFormatter with explicit formats instead.
private let espnDateFull: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return f
}()

private let espnDateShort: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd'T'HH:mmZZZZZ"
    return f
}()

private func parseESPNDate(_ string: String) -> Date {
    espnDateFull.date(from: string) ?? espnDateShort.date(from: string) ?? Date()
}

extension ESPNEvent {
    func toMatch() -> Match? {
        guard let comp = competitions?.first else { return nil }
        guard let comps = comp.competitors, comps.count >= 2 else { return nil }

        let home = comps.first { $0.homeAway == "home" } ?? comps[0]
        let away = comps.first { $0.homeAway == "away" } ?? comps[1]

        let kickoff = parseESPNDate(date)

        let statusName = comp.status?.type?.name ?? ""
        let matchStatus: MatchStatus
        switch statusName {
        case "STATUS_SCHEDULED": matchStatus = .scheduled
        case "STATUS_IN_PROGRESS": matchStatus = .live
        case "STATUS_HALFTIME": matchStatus = .halftime
        case "STATUS_FINAL", "STATUS_FULL_TIME": matchStatus = .finished
        case "STATUS_POSTPONED", "STATUS_CANCELED": matchStatus = .postponed
        default: matchStatus = .unknown
        }

        let clock = comp.status?.clock ?? 0
        let minute = clock > 0 ? Int(clock / 60) : nil

        let note = comp.notes?.first?.headline
        let groupName = note.flatMap { $0.contains("Group") ? $0 : nil }

        return Match(
            id: id,
            homeTeam: MatchTeam(
                abbreviation: home.team.abbreviation,
                displayName: home.team.displayName,
                score: Int(home.score ?? "0") ?? 0
            ),
            awayTeam: MatchTeam(
                abbreviation: away.team.abbreviation,
                displayName: away.team.displayName,
                score: Int(away.score ?? "0") ?? 0
            ),
            kickoff: kickoff,
            status: matchStatus,
            minute: minute,
            groupName: groupName,
            roundName: nil
        )
    }
}
