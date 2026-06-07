import Foundation

actor MatchesCollector {
    private static let scoreboardBaseURL =
        "https://cdn.espn.com/core/soccer/scoreboard?sport=soccer&league=fifa.world&xhr=1&limit=50"

    func fetchToday() async throws -> [Match] {
        return try await fetch(date: nil)
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
