import Foundation
import VouchedCore

/// Swift-native error surfaced by `VouchedFlowView` when a flow terminates with
/// an error. Wraps the underlying Kotlin throwable so callers don't need to
/// import KMP types.
public struct FlowError: LocalizedError {
    public let message: String
    let underlying: KotlinThrowable

    init(_ throwable: KotlinThrowable) {
        self.message = throwable.message ?? "Unknown error"
        self.underlying = throwable
    }

    public var errorDescription: String? { message }
}
