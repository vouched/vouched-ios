import Foundation

public struct AmplifyLivenessCredentials: Sendable {
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String
    public let expiration: Date

    public init(
        accessKeyId: String,
        secretAccessKey: String,
        sessionToken: String,
        expiration: Date
    ) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
        self.expiration = expiration
    }
}
