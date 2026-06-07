import Foundation

enum CollectorError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code): return "HTTP \(code)"
        case .decodingError(let msg): return "Decode error: \(msg)"
        }
    }
}
