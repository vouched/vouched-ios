import Foundation

public enum AmplifyLivenessError: Error, Sendable {
    case credentialsExpired
    case sessionError(message: String)
}
