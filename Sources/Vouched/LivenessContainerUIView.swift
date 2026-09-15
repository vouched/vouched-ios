import UIKit
import VouchedCore
import VouchedAmplify

internal final class LivenessContainerUIView: UIView {

    private let config: VouchedCore.AWSLivenessContainerConfig
    private var livenessView: UIView?

    init(config: VouchedCore.AWSLivenessContainerConfig) {
        self.config = config
        super.init(frame: .zero)
        setupLiveness()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        cleanup()
    }

    override func removeFromSuperview() {
        cleanup()
        super.removeFromSuperview()
    }

    private func setupLiveness() {
        let credentials = config.credentials
        guard let expiration = parseISO8601Date(credentials.expiration) else {
            config.onError(FaceLivenessContainerError(message: "Invalid credential expiration format"))
            return
        }

        let amplifyConfig = AmplifyLivenessConfig(
            sessionId: config.sessionId,
            credentials: AmplifyLivenessCredentials(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: expiration
            ),
            region: config.region
        )

        let view = createLivenessView(
            config: amplifyConfig,
            onComplete: { [weak self] in
                guard let self else { return }
                self.config.onComplete()
            },
            onError: { [weak self] error in
                guard let self else { return }
                let message: String
                switch error {
                case .credentialsExpired:
                    message = "Credentials have expired"
                case .sessionError(let msg):
                    message = msg
                }
                self.config.onError(FaceLivenessContainerError(message: message))
            }
        )

        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        self.livenessView = view
    }

    private func cleanup() {
        livenessView?.removeFromSuperview()
        livenessView = nil
    }
}
