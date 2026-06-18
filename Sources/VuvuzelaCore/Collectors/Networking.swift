import Foundation

extension URLSession {
    // Shared session for all ESPN polling. URLSession.shared defaults to a 7-day
    // resource timeout, so a socket wedged by a sleep/wake or network change can
    // leave `data(from:)` awaiting forever. That stalls WorldCupStore.refresh()
    // mid-await, leaving isLoading stuck true — the defer that reschedules polling
    // never runs, the timer chain dies, and the widget freezes until a restart.
    // Bounding both timeouts guarantees a hung request throws instead, so refresh()
    // always completes and the poll cadence self-heals.
    static let api: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20   // no progress for 20s → fail
        config.timeoutIntervalForResource = 30  // hard cap on the whole request
        config.waitsForConnectivity = false     // fail fast instead of parking offline
        return URLSession(configuration: config)
    }()
}
