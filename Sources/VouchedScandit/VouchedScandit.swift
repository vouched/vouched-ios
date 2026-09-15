import UIKit
import os

/// Entry point for the VouchedScandit SDK.
/// Defined as a caseless enum to act as a namespace. It cannot be instantiated.
///
/// Named `Scandit` (not `VouchedScandit`) to avoid shadowing the module name,
/// which would prevent access to other module-level types via qualification.
public enum Scandit {

    private static let lock = OSAllocatedUnfairLock<String?>(initialState: nil)

    public static func initialize(licenseKey: String) {
        lock.withLock { $0 = licenseKey }
    }

    public static func checkAvailability() -> Bool {
        return lock.withLock { $0 != nil }
    }

    static var licenseKey: String? {
        lock.withLock { $0 }
    }

    @MainActor
    public static func start(
        on presentingViewController: UIViewController,
        config: ScanditDocumentCaptureConfig = ScanditDocumentCaptureConfig(),
        externalTransactionId: String? = nil,
        completion: @escaping @MainActor (ScanditCaptureOutcome<ScanditDocumentCaptureResult>) -> Void
    ) {
        guard let licenseKey else {
            completion(.failure(.notInitialized))
            return
        }

        let scannerVC = DocumentCaptureViewController(
            licenseKey: licenseKey,
            config: config,
            externalTransactionId: externalTransactionId
        ) { outcome in
            presentingViewController.dismiss(animated: true) {
                completion(outcome)
            }
        }

        scannerVC.modalPresentationStyle = .fullScreen
        presentingViewController.present(scannerVC, animated: true)
    }
}
