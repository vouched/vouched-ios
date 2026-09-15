import Foundation

public enum ScanditCaptureOutcome<T> {
    case success(T)
    case failure(ScanditDocumentCaptureError)
}
