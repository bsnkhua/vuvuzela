import Foundation

struct UpdateChecker {
    static let releasesPageURL = URL(string: "https://github.com/bsnkhua/vuvuzela/releases")!
    static let repoPageURL = URL(string: "https://github.com/bsnkhua/vuvuzela")!
    static let issuesPageURL = URL(string: "https://github.com/bsnkhua/vuvuzela/issues")!

    private static let latestReleaseAPI =
        URL(string: "https://api.github.com/repos/bsnkhua/vuvuzela/releases/latest")!

    /// Latest release tag (e.g. "v1.0.0") or nil on any failure.
    func latestReleaseTag() async -> String? {
        var request = URLRequest(url: Self.latestReleaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        return Self.parseTag(fromJSON: data)
    }

    static func parseTag(fromJSON data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = object["tag_name"] as? String,
              !tag.isEmpty
        else { return nil }
        return tag
    }
}

/// Returns true if `remote` (e.g. "v1.2.0") is newer than `current` (e.g. "1.0.0").
func isNewerVersion(_ remote: String, than current: String) -> Bool {
    func parts(_ s: String) -> [Int] {
        s.trimmingCharacters(in: .init(charactersIn: "v"))
            .split(separator: ".").compactMap { Int($0) }
    }
    let r = parts(remote), c = parts(current)
    for i in 0..<max(r.count, c.count) {
        let rv = i < r.count ? r[i] : 0
        let cv = i < c.count ? c[i] : 0
        if rv != cv { return rv > cv }
    }
    return false
}
