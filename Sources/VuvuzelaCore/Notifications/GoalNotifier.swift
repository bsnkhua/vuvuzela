import Foundation
import UserNotifications

@MainActor
final class GoalNotifier {
    private var previousScores: [String: (home: Int, away: Int)] = [:]
    private var previousStatus: [String: MatchStatus] = [:]
    private var notificationsAuthorized = false

    func requestAuthorization() {
        // UNUserNotificationCenter requires a bundled app; skip in bare-binary dev runs
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in self.notificationsAuthorized = granted }
        }
    }

    func check(matches: [Match], favoriteTeams: Set<String>) {
        for match in matches where match.isLive {
            let key = match.id
            let home = match.homeTeam.abbreviation
            let away = match.awayTeam.abbreviation
            let isFavorite = favoriteTeams.contains(home) || favoriteTeams.contains(away)
            guard isFavorite else { continue }

            let prev = previousScores[key]
            let newHome = match.homeTeam.score
            let newAway = match.awayTeam.score

            if let prev {
                if newHome > prev.home { handleGoal(scorer: home, match: match) }
                if newAway > prev.away { handleGoal(scorer: away, match: match) }
            }
            previousScores[key] = (newHome, newAway)
        }
    }

    // Sound is unconditional (always audible); the banner is best-effort and only
    // when the user has granted notification permission.
    private func handleGoal(scorer: String, match: Match) {
        SoundPlayer.shared.playGoal()
        guard notificationsAuthorized else { return }
        sendGoalNotification(scorer: scorer, match: match)
    }

    private enum Lifecycle { case kickoff, halfTime, fullTime }

    // Plays the lifecycle sound and posts a banner the moment a favorite team's
    // match flips scheduled → live (kick-off), live → halftime, or live → finished
    // (full time). The sound is unconditional (always audible, respects mute);
    // the banner is best-effort, only when notifications are authorized. Tracks
    // per-match status so matches already in progress when first observed (cold
    // start) are recorded silently, not announced.
    func checkMatchLifecycle(matches: [Match], favoriteTeams: Set<String>) {
        for match in matches {
            let prev = previousStatus[match.id]
            previousStatus[match.id] = match.status

            let home = match.homeTeam.abbreviation
            let away = match.awayTeam.abbreviation
            guard favoriteTeams.contains(home) || favoriteTeams.contains(away) else { continue }

            if prev == .scheduled, match.status == .live || match.status == .halftime {
                handle(.kickoff, match)
            } else if prev == .live, match.status == .halftime {
                handle(.halfTime, match)
            } else if (prev == .live || prev == .halftime), match.isFinished {
                handle(.fullTime, match)
            }
        }
    }

    private func handle(_ event: Lifecycle, _ match: Match) {
        // Sound is always audible (respects mute); kick-off and half-time share the
        // start sound, full time gets its own.
        switch event {
        case .kickoff, .halfTime: SoundPlayer.shared.playStart()
        case .fullTime:           SoundPlayer.shared.playFinish()
        }

        guard notificationsAuthorized else { return } // banner only when allowed
        switch event {
        case .kickoff:  postLifecycleBanner(id: "start", title: "⚽ Match started", match: match, showScore: false)
        case .halfTime: postLifecycleBanner(id: "half",  title: "⏸️ Half time",    match: match, showScore: true)
        case .fullTime: postLifecycleBanner(id: "end",   title: "⏱️ Full time",    match: match, showScore: true)
        }
    }

    private func postLifecycleBanner(id: String, title: String, match: Match, showScore: Bool) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let home = match.homeTeam.abbreviation
        let away = match.awayTeam.abbreviation
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = showScore
            ? "\(match.homeTeam.flag) \(home) \(match.homeTeam.score) – \(match.awayTeam.score) \(away) \(match.awayTeam.flag)"
            : "\(match.homeTeam.flag) \(home) vs \(match.awayTeam.flag) \(away)"
        content.sound = nil   // audio handled by SoundPlayer (start/finish), not the banner
        let req = UNNotificationRequest(identifier: "\(id)-\(match.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    private func sendGoalNotification(scorer: String, match: Match) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = "⚽ GOAL! \(FlagEmoji.flag(for: scorer)) \(scorer)"
        content.body = "\(match.homeTeam.flag) \(match.homeTeam.abbreviation) \(match.homeTeam.score) – \(match.awayTeam.score) \(match.awayTeam.abbreviation) \(match.awayTeam.flag)"
        content.sound = nil   // audio handled by SoundPlayer (the vuvuzela), not the banner
        let req = UNNotificationRequest(identifier: "goal-\(match.id)-\(scorer)-\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
