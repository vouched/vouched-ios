import SwiftUI
import VouchedCore

/// Adapts a SwiftUI view into an `IOSCustomScreenProvider` by hosting it in a
/// `UIHostingController`. Instances are produced by the
/// `VouchedFlowView.withIdStageInstructionsScreen(content:)` and
/// `VouchedFlowView.withFaceStageInstructionsScreen(content:)` extensions and
/// should not be constructed directly.
internal final class SwiftUICustomScreen: IOSCustomScreenProvider {
    private let content: (VouchedFlowContext, @escaping () -> Void) -> AnyView

    init(content: @escaping (VouchedFlowContext, @escaping () -> Void) -> AnyView) {
        self.content = content
    }

    func createViewController(
        context: VouchedFlowContext,
        onContinue: @escaping () -> Void
    ) -> UIViewController {
        let view = content(context, onContinue)
        let hosting = UIHostingController(rootView: view)
        hosting.view.backgroundColor = .clear
        return hosting
    }
}
