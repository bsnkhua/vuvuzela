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
    @ObservationIgnored private var scheduleLastFetched: Date?

    // Tournament ends July 19 2026
    private static let tournamentEnd: Date = {
        var c = DateComponents(); c.year = 2026; c.month = 7; c.day = 19
        return Calendar.current.date(from: c) ?? Date()
    }()

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

        // Project live match scores onto standings so positions update mid-game
        if !liveMatches.isEmpty {
            var projected = groups
            applyLiveScores(&projected, from: liveMatches)
            groups = projected
        }
    }

    private func refreshGroups() async {
        do {
            var fetched = try await groupsCollector.fetch(favoriteTeams: favoriteTeams)
            applyBestThirdCalculation(&fetched)
            groups = fetched
        } catch {
            self.error = error.localizedDescription
        }
    }

    // Recalculates which rank-3 teams are in the best-8 using FIFA tiebreakers.
    // ESPN marks ALL 12 rank-3 teams as conditional — we override that here.
    private func applyBestThirdCalculation(_ groups: inout [GroupStanding]) {
        var thirdPlace: [(gi: Int, ti: Int, team: TeamRow)] = []
        for (gi, group) in groups.enumerated() {
            if let ti = group.teams.firstIndex(where: { $0.rank == 3 }) {
                thirdPlace.append((gi, ti, group.teams[ti]))
            }
        }

        // Before tournament starts all stats are 0 — show no indicator
        if thirdPlace.allSatisfy({ $0.team.gamesPlayed == 0 }) {
            for entry in thirdPlace {
                groups[entry.gi].teams[entry.ti].qualificationStatus = .unknown
            }
            return
        }

        // Sort by points → goal diff → goals scored (FIFA tiebreakers 1-3)
        let sorted = thirdPlace.sorted {
            let a = $0.team, b = $1.team
            if a.points != b.points { return a.points > b.points }
            if a.goalDiff != b.goalDiff { return a.goalDiff > b.goalDiff }
            return a.goalsFor > b.goalsFor
        }

        for (i, entry) in sorted.enumerated() {
            groups[entry.gi].teams[entry.ti].qualificationStatus = i < 8 ? .bestThirdIn : .bestThirdOut
        }
    }

    // Applies in-progress match scores to group standings so positions update live.
    // Only affects groups where both competitors are found in the same group (= group stage).
    private func applyLiveScores(_ groups: inout [GroupStanding], from matches: [Match]) {
        for match in matches {
            let ha = match.homeTeam.abbreviation
            let aa = match.awayTeam.abbreviation
            let hs = match.homeTeam.score
            let as_ = match.awayTeam.score

            // Confirm both teams belong to the same group (rules out knockout matches)
            guard let gi = groups.firstIndex(where: { g in
                g.teams.contains { $0.abbreviation == ha } &&
                g.teams.contains { $0.abbreviation == aa }
            }) else { continue }

            guard let hi = groups[gi].teams.firstIndex(where: { $0.abbreviation == ha }),
                  let ai = groups[gi].teams.firstIndex(where: { $0.abbreviation == aa })
            else { continue }

            groups[gi].teams[hi].gamesPlayed += 1
            groups[gi].teams[hi].goalsFor     += hs
            groups[gi].teams[hi].goalsAgainst += as_
            groups[gi].teams[hi].goalDiff     += hs - as_

            groups[gi].teams[ai].gamesPlayed += 1
            groups[gi].teams[ai].goalsFor     += as_
            groups[gi].teams[ai].goalsAgainst += hs
            groups[gi].teams[ai].goalDiff     += as_ - hs

            if hs > as_ {
                groups[gi].teams[hi].wins   += 1; groups[gi].teams[hi].points += 3
                groups[gi].teams[ai].losses += 1
            } else if hs == as_ {
                groups[gi].teams[hi].draws  += 1; groups[gi].teams[hi].points += 1
                groups[gi].teams[ai].draws  += 1; groups[gi].teams[ai].points += 1
            } else {
                groups[gi].teams[hi].losses += 1
                groups[gi].teams[ai].wins   += 1; groups[gi].teams[ai].points += 3
            }
        }

        // Re-sort within each group and update ranks + qualification indicators
        for gi in groups.indices {
            groups[gi].teams.sort {
                if $0.points   != $1.points   { return $0.points   > $1.points   }
                if $0.goalDiff != $1.goalDiff { return $0.goalDiff > $1.goalDiff }
                if $0.goalsFor != $1.goalsFor { return $0.goalsFor > $1.goalsFor }
                return $0.abbreviation < $1.abbreviation
            }
            for ti in groups[gi].teams.indices {
                groups[gi].teams[ti].rank = ti + 1
                switch ti + 1 {
                case 1, 2: groups[gi].teams[ti].qualificationStatus = .direct
                case 4:    groups[gi].teams[ti].qualificationStatus = .eliminated
                default:   break   // rank 3 recalculated below
                }
            }
        }

        applyBestThirdCalculation(&groups)
    }

    private func refreshMatches() async {
        // Always fetch today for live scores
        let todayMatches = (try? await matchesCollector.fetch(date: nil)) ?? []
        liveMatches    = todayMatches.filter { $0.isLive || $0.status == .halftime }
        recentMatches  = todayMatches.filter { $0.isFinished }.sorted { $0.kickoff > $1.kickoff }
        goalNotifier.check(matches: liveMatches, favoriteTeams: favoriteTeams)

        // Refresh full tournament schedule at most once per hour
        let scheduleStale = scheduleLastFetched.map { Date().timeIntervalSince($0) > 3600 } ?? true
        if scheduleStale {
            let all = await matchesCollector.fetchRange(from: Date(), to: Self.tournamentEnd)
            scheduleLastFetched = Date()
            upcomingMatches = all.filter { $0.status == .scheduled }.sorted { $0.kickoff < $1.kickoff }
        } else {
            // Replace only today's scheduled matches; keep future cache intact
            let todayUpcoming = todayMatches.filter {
                $0.status == .scheduled && Calendar.current.isDateInToday($0.kickoff)
            }
            let future = upcomingMatches.filter {
                !Calendar.current.isDateInToday($0.kickoff)
            }
            upcomingMatches = (todayUpcoming + future).sorted { $0.kickoff < $1.kickoff }
        }
    }

    private func refreshBracket() async {
        bracketRounds = await bracketCollector.fetch()
    }
}
