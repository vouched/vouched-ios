import Foundation

public enum ScanditDocumentCaptureError: Error, Sendable {
    case notInitialized
    case cameraUnavailable
    case timeout
    case runtimeError(message: String)
}
