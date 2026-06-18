import Foundation

actor MatchesCollector {
    // Real-time scoreboard. We deliberately avoid cdn.espn.com/core/... here: that
    // endpoint is CDN-cached and lagged 15+ minutes behind kickoff (showing matches as
    // SCHEDULED while they were already in the 14th minute). site.api updates live.
    private static let scoreboardBaseURL =
        "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard?limit=50"

    // Fetches every day in [startDate, endDate] concurrently.
    // Per-day failures are silently swallowed so one bad date doesn't abort the whole range.
    func fetchRange(from startDate: Date, to endDate: Date) async -> [Match] {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"

        var dates: [String] = []
        var cur = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        while cur <= end {
            dates.append(fmt.string(from: cur))
            cur = calendar.date(byAdding: .day, value: 1, to: cur)!
        }

        return await withTaskGroup(of: [Match].self) { group in
            for date in dates {
                group.addTask { (try? await self.fetch(date: date)) ?? [] }
            }
            var all: [Match] = []
            for await matches in group { all.append(contentsOf: matches) }
            // ESPN can return the same match with different IDs across date queries —
            // deduplicate by (kickoff, home, away) which is stable across queries.
            var seen = Set<String>()
            return all.filter { m in
                let key = "\(Int(m.kickoff.timeIntervalSince1970))-\(m.homeTeam.abbreviation)-\(m.awayTeam.abbreviation)"
                return seen.insert(key).inserted
            }
        }
    }

    func fetch(date: String?) async throws -> [Match] {
        var urlString = Self.scoreboardBaseURL
        if let date { urlString += "&dates=\(date)" }
        guard let url = URL(string: urlString) else { throw CollectorError.invalidURL }

        let (data, response) = try await URLSession.api.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CollectorError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(ESPNSiteScoreboardResponse.self, from: data)
        return decoded.events?.compactMap { $0.toMatch() } ?? []
    }
}
