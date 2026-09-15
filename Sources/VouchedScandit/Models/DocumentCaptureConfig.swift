import Foundation

public enum ScanditDocumentDetectionMode: Sendable {
    case classicOnly
    case enhancedWithFallback
}

public struct ScanditDocumentCaptureConfig: Sendable {
    public let timeoutMs: Int?
    public let holdSteadyDurationMs: Int
    public let userImageConfirmation: Bool
    public let includeBarcodeScanning: Bool
    public let captureBackSide: Bool
    public let detectionMode: ScanditDocumentDetectionMode

    public init(
        timeoutMs: Int? = 30000,
        holdSteadyDurationMs: Int = 1000,
        userImageConfirmation: Bool = false,
        includeBarcodeScanning: Bool = false,
        captureBackSide: Bool = false,
        detectionMode: ScanditDocumentDetectionMode = .enhancedWithFallback
    ) {
        if let timeoutMs {
            precondition(timeoutMs > 0, "Timeout must be positive")
        }
        precondition(holdSteadyDurationMs > 0, "Hold steady duration must be positive")
        self.timeoutMs = timeoutMs
        self.holdSteadyDurationMs = holdSteadyDurationMs
        self.userImageConfirmation = userImageConfirmation
        self.includeBarcodeScanning = includeBarcodeScanning
        self.captureBackSide = captureBackSide
        self.detectionMode = detectionMode
    }
}
