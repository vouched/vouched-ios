import UIKit

public func createLivenessView(
    config: AmplifyLivenessConfig,
    onComplete: @escaping @MainActor () -> Void,
    onError: @escaping @MainActor (AmplifyLivenessError) -> Void
) -> UIView {
    LivenessView(config: config, onComplete: onComplete, onError: onError)
}
