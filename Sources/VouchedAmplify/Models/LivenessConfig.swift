import Foundation

public struct AmplifyLivenessConfig: Sendable {
    public let sessionId: String
    public let credentials: AmplifyLivenessCredentials
    public let region: String

    public init(
        sessionId: String,
        credentials: AmplifyLivenessCredentials,
        region: String
    ) {
        self.sessionId = sessionId
        self.credentials = credentials
        self.region = region
    }
}
