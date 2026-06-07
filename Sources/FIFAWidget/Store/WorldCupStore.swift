import Foundation
import Observation

@MainActor
@Observable
final class WorldCupStore {
    // Published data
    private(set) var groups: [GroupStanding] = []
    private(set) var liveMatches: [Match] = []
    private(set) var upcomingMatches: [Match] = []
    private(set) var recentMatches: [Match] = []
    private(set) var bracketRounds: [BracketRound] = BracketRound.placeholder()
    private(set) var lastUpdated: Date?
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var favoriteTeams: Set<String> = WidgetSettings.favoriteTeams

    // Notifier
    let goalNotifier = GoalNotifier()

    @ObservationIgnored private let groupsCollector = GroupsCollector()
    @ObservationIgnored private let matchesCollector = MatchesCollector()
    @ObservationIgnored private let bracketCollector = BracketCollector()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var isSuspended = false

    init() {}

    func start() {
        stop()
        goalNotifier.requestAuthorization()
        Task { await refresh() }
        scheduleNextTick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func suspend() { isSuspended = true }

    func resume() {
        guard isSuspended else { return }
        isSuspended = false
        Task { await refresh() }
        scheduleNextTick()
    }

    func toggleFavorite(_ abbreviation: String) {
        if favoriteTeams.contains(abbreviation) {
            favoriteTeams.remove(abbreviation)
        } else {
            favoriteTeams.insert(abbreviation)
        }
        WidgetSettings.favoriteTeams = favoriteTeams
        // Refresh isFavorite flags in existing groups
        groups = groups.map { group in
            var g = group
            g.teams = g.teams.map { team in
                var t = team
                t.isFavorite = favoriteTeams.contains(t.abbreviation)
                return t
            }
            return g
        }
    }

    // MARK: - Private

    private func scheduleNextTick() {
        timer?.invalidate()
        let interval = computeInterval()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.isSuspended else { return }
                await self.refresh()
                self.scheduleNextTick()
            }
        }
    }

    private func computeInterval() -> TimeInterval {
        if !liveMatches.isEmpty { return 60 }   // live: every minute
        // Match starting in < 1 hour?
        if let next = upcomingMatches.first, next.kickoff.timeIntervalSinceNow < 3600 {
            return 300  // 5 min
        }
        return 3600     // otherwise 1 hour
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false; lastUpdated = Date() }

        async let groupsTask: Void = refreshGroups()
        async let matchesTask: Void = refreshMatches()
        async let bracketTask: Void = refreshBracket()
        _ = await (groupsTask, matchesTask, bracketTask)
    }

    private func refreshGroups() async {
        do {
            let fetched = try await groupsCollector.fetch(favoriteTeams: favoriteTeams)
            groups = fetched
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func refreshMatches() async {
        do {
            let all = try await matchesCollector.fetchToday()
            liveMatches = all.filter { $0.isLive || $0.status == .halftime }
            upcomingMatches = all.filter { $0.status == .scheduled }.sorted { $0.kickoff < $1.kickoff }
            recentMatches = all.filter { $0.isFinished }.sorted { $0.kickoff > $1.kickoff }
            goalNotifier.check(matches: liveMatches, favoriteTeams: favoriteTeams)
        } catch {
            // Matches may return 404 before tournament starts — not a fatal error
        }
    }

    private func refreshBracket() async {
        bracketRounds = await bracketCollector.fetch()
    }
}
