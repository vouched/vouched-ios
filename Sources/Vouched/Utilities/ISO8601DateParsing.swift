import Foundation

/// Parses an ISO 8601 date string, handling both with and without fractional seconds.
/// AWS STS returns expiration timestamps with fractional seconds (e.g., `2026-03-25T18:30:00.000Z`),
/// which the default `ISO8601DateFormatter` does not support.
internal func parseISO8601Date(_ string: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: string) {
        return date
    }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string)
}
