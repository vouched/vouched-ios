import UIKit
import ScanditCaptureCore
import ScanditIdCapture
import VouchedCore

// MARK: - Container UIView

internal final class ScanditContainerUIView: UIView {
    
    private let config: VouchedCore.ScanditContainerConfig
    private var context: DataCaptureContext?
    private var idCapture: IdCapture?
    private var captureView: DataCaptureView?
    private var camera: Camera?
    private var hasCompleted = false
    private let listenerDelegate = ScanditContainerListenerDelegate()
    private let contextDelegate = ScanditContainerContextDelegate()
    
    init(config: VouchedCore.ScanditContainerConfig) {
        self.config = config
        super.init(frame: .zero)
        setupScandit()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup
    
    private func setupScandit() {
        let dataCaptureContext = DataCaptureContext(licenseKey: config.licenseKey)
        self.context = dataCaptureContext
        
        contextDelegate.onStatusChanged = { [weak self] status in
            guard let self, !self.hasCompleted else { return }
            DispatchQueue.main.async {
                if !status.isValid {
                    self.config.onStateChange(
                        ScanditContainerState.Error(error:
                                                        ScanditContainerError.InvalidContextError(
                                                            code: Int32(status.code),
                                                            message: status.message
                                                        )
                                                   )
                    )
                } else {
                    self.config.onStateChange(ScanditContainerState.Loaded.shared)
                }
            }
        }
        dataCaptureContext.addListener(contextDelegate)
        
        guard let cam = Camera.default else {
            config.onStateChange(
                ScanditContainerState.Error(error: ScanditContainerError.NoCameraError.shared)
            )
            return
        }
        self.camera = cam
        cam.apply(IdCapture.recommendedCameraSettings)
        dataCaptureContext.setFrameSource(cam, completionHandler: nil)
        
        let settings = buildIdCaptureSettings()
        let capture = IdCapture(context: dataCaptureContext, settings: settings)
        self.idCapture = capture
        
        if let transactionId = config.transactionId as String? {
            capture.externalTransactionId = transactionId
        }
        
        listenerDelegate.onCapture = { [weak self] capturedId in
            self?.handleCapture(capturedId)
        }
        capture.addListener(listenerDelegate)
        
        let dcView = DataCaptureView(context: dataCaptureContext, frame: bounds)
        dcView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(dcView)
        self.captureView = dcView
        
        _ = IdCaptureOverlay(idCapture: capture, view: dcView)
        
        cam.switch(toDesiredState: .on)
        capture.isEnabled = true
    }
    
    private func buildIdCaptureSettings() -> IdCaptureSettings {
        let settings = IdCaptureSettings()
        
        settings.acceptedDocuments = [
            IdCard(region: .any),
            Passport(region: .any),
            DriverLicense(region: .any)
        ]
        
        if config.includeBackId {
            settings.scanner = .init(physicalDocument: FullDocumentScanner())
        } else {
            settings.scanner = .init(
                physicalDocument: SingleSideScanner(
                    enablingBarcode: config.includeBarcodeScanning,
                    machineReadableZone: true,
                    visualInspectionZone: true
                )
            )
        }

        settings.setIncludeImage(true, for: .croppedDocument)
        settings.setIncludeImage(true, for: .frame)
        
        return settings
    }
    
    // MARK: - Lifecycle
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !hasCompleted else { return }
        if window != nil {
            camera?.switch(toDesiredState: .on)
            idCapture?.isEnabled = true
        } else {
            camera?.switch(toDesiredState: .off)
            idCapture?.isEnabled = false
        }
    }
    
    override func removeFromSuperview() {
        cleanup()
        super.removeFromSuperview()
    }
    
    private func cleanup() {
        camera?.switch(toDesiredState: .off)
        idCapture?.isEnabled = false
        context?.dispose()
        context = nil
    }
    
    // MARK: - Result handling
    
    private func handleCapture(_ capturedId: CapturedId) {
        guard !hasCompleted else { return }
        
        let result = buildFullIdDetectResult(from: capturedId)
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.hasCompleted else { return }
            self.hasCompleted = true
            self.camera?.switch(toDesiredState: .off)
            self.idCapture?.isEnabled = false
            
            if let result {
                self.config.onStateChange(
                    ScanditContainerState.Success(result: result)
                )
            } else {
                self.config.onStateChange(
                    ScanditContainerState.Error(error: ScanditContainerError.InvalidResults.shared)
                )
            }
        }
    }
    
    // MARK: - Image extraction (matches Android's CapturedId.toFullIdDetectResult)
    
    private nonisolated func buildFullIdDetectResult(
        from capturedId: CapturedId
    ) -> VouchedCore.FullIdDetectResult? {
        let images = capturedId.images
        
        guard let frontFrameImage = images.frame(for: .front) ?? images.frame,
              let frontFrameBase64 = frontFrameImage.jpegData(compressionQuality: 0.85)?
            .base64EncodedString() else {
            return nil
        }
        
        let frontCroppedBase64 = images.croppedDocument(for: .front)?
            .jpegData(compressionQuality: 0.85)?
            .base64EncodedString()
        
        let backFrameBase64 = images.frame(for: .back)?
            .jpegData(compressionQuality: 0.85)?
            .base64EncodedString()
        
        let backCroppedBase64 = images.croppedDocument(for: .back)?
            .jpegData(compressionQuality: 0.85)?
            .base64EncodedString()
        
        let frontImageCapture = VouchedCore.ImageCapture(
            full: frontFrameBase64,
            cropped: frontCroppedBase64
        )
        
        let backImageCapture: VouchedCore.ImageCapture?
        if let backBase64 = backFrameBase64 {
            backImageCapture = VouchedCore.ImageCapture(
                full: backBase64,
                cropped: backCroppedBase64
            )
        } else {
            backImageCapture = nil
        }
        
        let idCaptureJson = capturedId.jsonString ?? "{}"
        
        return VouchedCore.FullIdDetectResult(
            idCapture: idCaptureJson,
            front: frontImageCapture,
            back: backImageCapture
        )
    }
}

// MARK: - IdCapture Listener Delegate

private final class ScanditContainerListenerDelegate: NSObject, IdCaptureListener {
    var onCapture: (@Sendable (CapturedId) -> Void)?
    
    func idCapture(_ idCapture: IdCapture, didCapture capturedId: CapturedId) {
        onCapture?(capturedId)
    }
    
    func idCapture(
        _ idCapture: IdCapture,
        didReject capturedId: CapturedId?,
        reason rejectionReason: RejectionReason
    ) {
        // Rejections are silently ignored (matching Android behavior)
    }
}

// MARK: - DataCaptureContext Status Delegate

private final class ScanditContainerContextDelegate: NSObject, DataCaptureContextListener {
    var onStatusChanged: ((ContextStatus) -> Void)?
    
    func context(_ context: DataCaptureContext, didChange contextStatus: ContextStatus) {
        onStatusChanged?(contextStatus)
    }
    
    func context(_ context: DataCaptureContext, didChange frameSource: (any FrameSource)?) {}
    
    func context(_ context: DataCaptureContext, didAdd mode: any DataCaptureMode) {}
    
    func context(_ context: DataCaptureContext, didRemove mode: any DataCaptureMode) {}
}
