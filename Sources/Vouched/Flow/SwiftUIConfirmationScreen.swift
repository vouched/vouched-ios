import SwiftUI
import UIKit
import VouchedCore

/// Adapts a SwiftUI view into an `IOSCustomConfirmationScreenProvider` by hosting it in a
/// `UIHostingController`. Instances are produced by the
/// `VouchedFlowView.withDocumentConfirmationScreen(content:)` extension and should not be
/// constructed directly.
internal final class SwiftUIConfirmationScreen: IOSCustomConfirmationScreenProvider {
    private let content: (VouchedFlowContext, UIImage, @escaping () -> Void, @escaping () -> Void) -> AnyView

    init(
        content: @escaping (VouchedFlowContext, UIImage, @escaping () -> Void, @escaping () -> Void) -> AnyView
    ) {
        self.content = content
    }

    func createViewController(
        context: VouchedFlowContext,
        image: UIImage,
        onConfirm: @escaping () -> Void,
        onRetake: @escaping () -> Void
    ) -> UIViewController {
        let view = content(context, image, onConfirm, onRetake)
        let hosting = UIHostingController(rootView: view)
        hosting.view.backgroundColor = .clear
        return hosting
    }
}
