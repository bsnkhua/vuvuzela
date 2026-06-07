import Foundation

actor MatchesCollector {
    private static let scoreboardBaseURL =
        "https://cdn.espn.com/core/soccer/scoreboard?sport=soccer&league=fifa.world&xhr=1&limit=50"

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
        if let date { urlString += "&date=\(date)" }
        guard let url = URL(string: urlString) else { throw CollectorError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CollectorError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(ESPNCDNScoreboardResponse.self, from: data)
        return decoded.content.sbData.events?.compactMap { $0.toMatch() } ?? []
    }
}
