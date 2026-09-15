import SwiftUI
import VouchedCore

/// SwiftUI view that hosts the Compose Multiplatform `FlowErrorScreen`.
///
/// Wraps the KMP composable in a `UIViewControllerRepresentable` so it can be
/// used as `VouchedFlowView`'s default error screen when no `.errorScreen`
/// builder has been provided.
struct ComposeFlowErrorView: UIViewControllerRepresentable {
    let message: String
    let onRetry: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        FlowErrorViewControllerKt.FlowErrorViewController(
            message: message,
            onRetry: onRetry
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op: Compose manages its own state internally
    }
}
