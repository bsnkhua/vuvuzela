import Foundation
import UserNotifications

@MainActor
final class GoalNotifier {
    private var previousScores: [String: (home: Int, away: Int)] = [:]
    private var notificationsAuthorized = false

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in self.notificationsAuthorized = granted }
        }
    }

    func check(matches: [Match], favoriteTeams: Set<String>) {
        guard notificationsAuthorized else { return }
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
                if newHome > prev.home {
                    sendGoalNotification(scorer: home, match: match)
                }
                if newAway > prev.away {
                    sendGoalNotification(scorer: away, match: match)
                }
            }
            previousScores[key] = (newHome, newAway)
        }
    }

    func notifyMatchStart(match: Match, favoriteTeams: Set<String>) {
        guard notificationsAuthorized else { return }
        let home = match.homeTeam.abbreviation
        let away = match.awayTeam.abbreviation
        guard favoriteTeams.contains(home) || favoriteTeams.contains(away) else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚽ Match started"
        content.body = "\(match.homeTeam.flag) \(home) vs \(match.awayTeam.flag) \(away)"
        content.sound = .default
        let req = UNNotificationRequest(identifier: "start-\(match.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    private func sendGoalNotification(scorer: String, match: Match) {
        let content = UNMutableNotificationContent()
        content.title = "⚽ GOAL! \(FlagEmoji.flag(for: scorer)) \(scorer)"
        content.body = "\(match.homeTeam.flag) \(match.homeTeam.abbreviation) \(match.homeTeam.score) – \(match.awayTeam.score) \(match.awayTeam.abbreviation) \(match.awayTeam.flag)"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("goal.caf"))
        let req = UNNotificationRequest(identifier: "goal-\(match.id)-\(scorer)-\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
