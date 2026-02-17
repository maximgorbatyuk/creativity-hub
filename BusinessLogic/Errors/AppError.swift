import Foundation

enum AppError: LocalizedError {
    case database(String)
    case validation(String)
    case notFound(String)
    case fileSystem(String)
    case network(String)
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case let .database(message): return "Database error: \(message)"
        case let .validation(message): return "Validation error: \(message)"
        case let .notFound(message): return "Not found: \(message)"
        case let .fileSystem(message): return "File system error: \(message)"
        case let .network(message): return "Network error: \(message)"
        case let .unexpected(message): return "Unexpected error: \(message)"
        }
    }
}
