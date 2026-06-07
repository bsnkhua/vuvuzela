import Foundation

actor GroupsCollector {
    private static let standingsURL = URL(string:
        "https://site.api.espn.com/apis/v2/sports/soccer/fifa.world/standings"
    )!

    func fetch(favoriteTeams: Set<String>) async throws -> [GroupStanding] {
        let (data, response) = try await URLSession.shared.data(from: Self.standingsURL)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CollectorError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(ESPNStandingsResponse.self, from: data)
        return decoded.children.map { $0.toGroupStanding(favoriteTeams: favoriteTeams) }
    }
}
