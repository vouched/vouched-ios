import UIKit
import SwiftUI
import FaceLiveness
import AWSPluginsCore

public final class LivenessView: UIView {

    private let config: AmplifyLivenessConfig
    private let onComplete: @MainActor () -> Void
    private let onError: @MainActor (AmplifyLivenessError) -> Void
    private var hostingController: UIHostingController<FaceLivenessDetectorView>?
    private var hasCompleted = false

    init(
        config: AmplifyLivenessConfig,
        onComplete: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor (AmplifyLivenessError) -> Void
    ) {
        self.config = config
        self.onComplete = onComplete
        self.onError = onError
        super.init(frame: .zero)
        embedLivenessView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        cleanup()
    }

    override public func removeFromSuperview() {
        cleanup()
        super.removeFromSuperview()
    }

    private func cleanup() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }

    private func embedLivenessView() {
        let credentialsProvider = StaticCredentialsProvider(
            accessKeyId: config.credentials.accessKeyId,
            secretAccessKey: config.credentials.secretAccessKey,
            sessionToken: config.credentials.sessionToken,
            expiration: config.credentials.expiration
        )

        let livenessView = FaceLivenessDetectorView(
            sessionID: config.sessionId,
            credentialsProvider: credentialsProvider,
            region: config.region,
            isPresented: .constant(true),
            onCompletion: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.finishWithSuccess()
                case .failure(let error):
                    self.finishWithError(.sessionError(message: error.localizedDescription))
                }
            }
        )

        let hosting = UIHostingController(rootView: livenessView)
        hosting.view.frame = bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(hosting.view)
        self.hostingController = hosting
    }

    private func finishWithSuccess() {
        guard !hasCompleted else { return }
        hasCompleted = true
        onComplete()
    }

    private func finishWithError(_ error: AmplifyLivenessError) {
        guard !hasCompleted else { return }
        hasCompleted = true
        onError(error)
    }
}

// MARK: - AWSCredentialsProvider

private struct StaticCredentialsProvider: AWSCredentialsProvider, AWSTemporaryCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date

    func fetchAWSCredentials() async throws -> AWSPluginsCore.AWSCredentials {
        self
    }
}
