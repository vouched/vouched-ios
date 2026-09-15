import SwiftUI
import Vouched

struct IDVFlowView: View {
    private let appConfig = AppConfig(
        type: .idv,
        sessionParams: .init(apiKey: Secrets.vouchedAPIKey),
        documentCaptureConfig: DocumentCaptureConfig(
            detectionMode: .classicOnly,
            classicDocumentDetectionOptions: .init(
                enableDistanceCheck: true,
                captureMethod: .both
            ),
            includeBarcodeScanning: true,
            options: .init(userImageConfirmation: true)
        )
    )

    var body: some View {
        VouchedFlowView(config: appConfig)
            .successScreen { job in
                CompletionView(jobResult: job.result, jobId: job.id)
            }
            .cancelledScreen { reason in
                terminalView(
                    icon: "xmark.circle.fill",
                    color: .gray,
                    title: "Flow cancelled",
                    detail: reason ?? "The verification was cancelled."
                )
            }
            .errorScreen { error, retry in
                errorView(
                    detail: error.localizedDescription,
                    onRetry: retry
                )
            }
            .withIdStageInstructionsScreen { onContinue in
                IdInstructionsScreen(onContinue: onContinue)
            }
            .withFaceStageInstructionsScreen { onContinue in
                FaceInstructionsScreen(onContinue: onContinue)
            }
            .onStageChange { previousStage, currentStage in
                debugPrint("STATE CHANGED: \(previousStage) -> \(currentStage)")
            }
    }

    private func terminalView(icon: String, color: Color, title: String, detail: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.onBackground)

            Text(detail)
                .font(.body)
                .foregroundColor(AppColors.onBackgroundVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func errorView(detail: String, onRetry: @escaping () -> Void) -> some View {
        VStack(spacing: 24) {
            terminalView(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                title: "Something went wrong",
                detail: detail
            )

            Button(action: onRetry) {
                Text("Retry")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    IDVFlowView()
}
