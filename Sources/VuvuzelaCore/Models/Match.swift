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

// MARK: - ESPN Scoreboard Decodable

// site.api scoreboard returns events at the top level. This is the real-time feed
// the app reads from. (The cdn.espn.com/core endpoint nests under content.sbData and
// is heavily CDN-cached — it lagged 15+ minutes behind kickoff, so we don't use it.)
struct ESPNSiteScoreboardResponse: Decodable {
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

        // ESPN soccer never sends STATUS_IN_PROGRESS — it sends STATUS_FIRST_HALF,
        // STATUS_SECOND_HALF, STATUS_EXTRA_TIME, STATUS_FINAL_PEN, and many more.
        // The stable signal is the `state` bucket (pre / in / post); we only special-case
        // the names that carry meaning `state` can't (halftime, postponements).
        let statusName = comp.status?.type?.name ?? ""
        let statusState = comp.status?.type?.state ?? ""
        let matchStatus: MatchStatus
        switch statusName {
        case "STATUS_HALFTIME":
            matchStatus = .halftime
        case "STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_CANCELLED", "STATUS_ABANDONED":
            matchStatus = .postponed
        default:
            switch statusState {
            case "pre":  matchStatus = .scheduled
            case "in":   matchStatus = .live
            case "post": matchStatus = .finished
            default:     matchStatus = .unknown
            }
        }

        // Prefer the human clock ("14'", "90'+3") — parse its leading minutes. Fall back
        // to the numeric clock (seconds) only when no displayClock is present.
        let minute: Int?
        if matchStatus == .live, let dc = comp.status?.displayClock,
           let parsed = Int(dc.prefix { $0.isNumber }), parsed > 0 {
            minute = parsed
        } else {
            let clock = comp.status?.clock ?? 0
            minute = (matchStatus == .live && clock > 0) ? Int(clock / 60) : nil
        }

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
