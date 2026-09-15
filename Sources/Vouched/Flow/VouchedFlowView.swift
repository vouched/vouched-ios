import SwiftUI
import UIKit
import VouchedCore

/// SwiftUI host for a Vouched verification flow.
///
/// Construct with an `AppConfig` and chain modifiers to register terminal-state
/// screens, side-effect callbacks, and custom instruction screens. The view drives
/// the entire flow: it shows the SDK's capture UI until the flow finishes, then
/// swaps to the success/cancelled/error screen you've configured.
///
/// `config` is captured on first creation; later changes are ignored.
///
/// ## Usage
/// ```swift
/// VouchedFlowView(config: appConfig)
///     .successScreen { job in CompletionView(jobResult: job.result, jobId: job.id) }
///     .cancelledScreen { reason in CancelledView(reason: reason) }
///     .errorScreen { error, retry in ErrorView(message: error.localizedDescription, onRetry: retry) }
///     .withIdStageInstructionsScreen { onContinue in
///         IdInstructionsScreen(onContinue: onContinue)
///     }
/// ```
public struct VouchedFlowView: View {
    private let config: AppConfig
    private var successScreenBuilder: ((_ job: APIJobResponse) -> AnyView)?
    private var cancelledScreenBuilder: ((_ reason: String?) -> AnyView)?
    private var errorScreenBuilder: ((_ error: FlowError, _ retry: @escaping @MainActor () -> Void) -> AnyView)?
    private var stageChangeCallback: (@MainActor (_ from: FlowStage, _ to: FlowStage) -> Void)?
    private var idInstructionsProvider: IOSCustomScreenProvider?
    private var faceInstructionsProvider: IOSCustomScreenProvider?
    private var confirmationScreenProvider: IOSCustomConfirmationScreenProvider?
    private var trackingConsent: Bool?

    @State private var result: VouchedFlowResult?
    @State private var sessionHolder = SessionHolder()

    public init(config: AppConfig) {
        self.config = config
    }

    public var body: some View {
        switch result {
        case let success as VouchedFlowResult.Success:
            if let builder = successScreenBuilder {
                builder(success.job)
            } else {
                defaultTerminalPlaceholder("Verification complete")
            }
        case let cancelled as VouchedFlowResult.Cancelled:
            if let builder = cancelledScreenBuilder {
                builder(cancelled.reason)
            } else {
                defaultTerminalPlaceholder("Verification cancelled")
            }
        case let error as VouchedFlowResult.Error:
            if let builder = errorScreenBuilder {
                builder(FlowError(error.error), { result = nil })
            } else {
                ComposeFlowErrorView(message: error.message, onRetry: { result = nil })
            }
        default:
            FlowHost(
                session: sessionHolder.session(config: config),
                stageChangeCallback: stageChangeCallback,
                idInstructionsProvider: idInstructionsProvider,
                faceInstructionsProvider: faceInstructionsProvider,
                confirmationScreenProvider: confirmationScreenProvider,
                trackingConsent: trackingConsent,
                onComplete: { result = $0 }
            )
        }
    }

    // TODO: Replace with proper default terminal screens.
    private func defaultTerminalPlaceholder(_ message: String) -> some View {
        Text(message)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func with<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T) -> Self {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}

public extension VouchedFlowView {
    /// View shown when the flow completes successfully.
    func successScreen<Content: View>(
        @ViewBuilder _ content: @escaping (_ job: APIJobResponse) -> Content
    ) -> VouchedFlowView {
        with(\.successScreenBuilder) { job in AnyView(content(job)) }
    }

    /// View shown when the user cancels the flow. `reason` is non-nil only for
    /// programmatic cancellations.
    func cancelledScreen<Content: View>(
        @ViewBuilder _ content: @escaping (_ reason: String?) -> Content
    ) -> VouchedFlowView {
        with(\.cancelledScreenBuilder) { reason in AnyView(content(reason)) }
    }

    /// View shown when the flow terminates due to an error. The `retry` closure
    /// re-enters the flow on the same session and job.
    func errorScreen<Content: View>(
        @ViewBuilder _ content: @escaping (_ error: FlowError, _ retry: @escaping @MainActor () -> Void) -> Content
    ) -> VouchedFlowView {
        with(\.errorScreenBuilder) { error, retry in AnyView(content(error, retry)) }
    }

    /// Called on every stage transition.
    func onStageChange(
        _ callback: @escaping @MainActor (_ from: FlowStage, _ to: FlowStage) -> Void
    ) -> VouchedFlowView {
        with(\.stageChangeCallback, callback)
    }

    /// SwiftUI custom instructions screen shown before ID capture.
    func withIdStageInstructionsScreen<Content: View>(
        @ViewBuilder content: @escaping (_ onContinue: @escaping () -> Void) -> Content
    ) -> VouchedFlowView {
        let provider = SwiftUICustomScreen { _, onContinue in
            AnyView(content(onContinue))
        }
        return with(\.idInstructionsProvider, provider)
    }

    /// SwiftUI custom instructions screen shown before face capture.
    func withFaceStageInstructionsScreen<Content: View>(
        @ViewBuilder content: @escaping (_ onContinue: @escaping () -> Void) -> Content
    ) -> VouchedFlowView {
        let provider = SwiftUICustomScreen { _, onContinue in
            AnyView(content(onContinue))
        }
        return with(\.faceInstructionsProvider, provider)
    }

    /// SwiftUI screen shown after document capture, letting the user review the captured
    /// image and either accept or retake it. Only takes effect when
    /// `DocumentCaptureOptions.userImageConfirmation` is enabled.
    func withDocumentConfirmationScreen<Content: View>(
        @ViewBuilder content: @escaping (
            _ image: UIImage,
            _ onConfirm: @escaping () -> Void,
            _ onRetake: @escaping () -> Void
        ) -> Content
    ) -> VouchedFlowView {
        let provider = SwiftUIConfirmationScreen { _, image, onConfirm, onRetake in
            AnyView(content(image, onConfirm, onRetake))
        }
        return with(\.confirmationScreenProvider, provider)
    }

    /// Sets initial analytics tracking consent before the flow starts.
    func trackingConsent(_ granted: Bool) -> VouchedFlowView {
        with(\.trackingConsent, granted)
    }
}

/// Builds the flow's `VouchedSession` once and keeps it across retries, which tear down and
/// rebuild `FlowHost` but leave this holder's `@State` storage intact.
private final class SessionHolder {
    private var stored: VouchedSession?

    func session(config: AppConfig) -> VouchedSession {
        if let stored { return stored }
        let session = VouchedSession(config: config)
        stored = session
        return session
    }
}

private struct FlowHost: UIViewControllerRepresentable {
    let session: VouchedSession
    let stageChangeCallback: (@MainActor (_ from: FlowStage, _ to: FlowStage) -> Void)?
    let idInstructionsProvider: IOSCustomScreenProvider?
    let faceInstructionsProvider: IOSCustomScreenProvider?
    let confirmationScreenProvider: IOSCustomConfirmationScreenProvider?
    let trackingConsent: Bool?
    let onComplete: @MainActor (_ result: VouchedFlowResult) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        Vouched.registerNativeComponents()

        let builder = VouchedSDK.shared.createFlow(config: session.appConfig)

        builder.onFlowComplete { result in
            MainActor.assumeIsolated { onComplete(result) }
        }

        if let stageChangeCallback {
            builder.onStageChange { from, to in
                MainActor.assumeIsolated { stageChangeCallback(from, to) }
            }
        }

        if let idInstructionsProvider {
            builder.withIdStageInstructionsScreen(provider: idInstructionsProvider)
        }
        if let faceInstructionsProvider {
            builder.withFaceStageInstructionsScreen(provider: faceInstructionsProvider)
        }
        if let confirmationScreenProvider {
            builder.withDocumentConfirmationScreen(provider: confirmationScreenProvider)
        }
        if let trackingConsent {
            builder.withTrackingConsent(granted: trackingConsent)
        }

        return VouchedFlowViewControllerKt.VouchedFlowViewController(builder: builder, session: session)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op: the flow host manages its own state internally
    }
}
