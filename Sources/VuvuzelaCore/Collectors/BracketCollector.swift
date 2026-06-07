import Foundation

// Bracket data becomes available from ESPN once the knockout stage begins.
// Until then we return a placeholder structure.
actor BracketCollector {
    func fetch() async -> [BracketRound] {
        // TODO: implement when ESPN exposes knockout bracket endpoint
        return BracketRound.placeholder()
    }
}
