import UIKit
import ScanditCaptureCore
import ScanditIdCapture

// MARK: - Listener delegate (non-MainActor, called from Scandit's background thread)

private final class IdCaptureListenerDelegate: NSObject, IdCaptureListener {
    
    var onCapture: (@Sendable (CapturedId) -> Void)?
    var onReject: (@Sendable (RejectionReason) -> Void)?
    
    func idCapture(_ idCapture: IdCapture, didCapture capturedId: CapturedId) {
        onCapture?(capturedId)
    }
    
    func idCapture(_ idCapture: IdCapture, didReject capturedId: CapturedId?, reason rejectionReason: RejectionReason) {
        onReject?(rejectionReason)
    }
}

// MARK: - ViewController

final class DocumentCaptureViewController: UIViewController {
    
    private let config: ScanditDocumentCaptureConfig
    private let externalTransactionId: String?
    private let completion: @MainActor (ScanditCaptureOutcome<ScanditDocumentCaptureResult>) -> Void
    
    private var context: DataCaptureContext!
    private var idCapture: IdCapture!
    private var captureView: DataCaptureView!
    private var camera: Camera?
    private var timeoutTimer: Timer?
    private var hasCompleted = false
    private let listenerDelegate = IdCaptureListenerDelegate()
    
    init(
        licenseKey: String,
        config: ScanditDocumentCaptureConfig,
        externalTransactionId: String? = nil,
        completion: @escaping @MainActor (ScanditCaptureOutcome<ScanditDocumentCaptureResult>) -> Void
    ) {
        self.config = config
        self.externalTransactionId = externalTransactionId
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        
        context = DataCaptureContext(licenseKey: licenseKey)
        setupCamera()
        setupIdCapture()
        bindListenerCallbacks()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCaptureView()
        startTimeoutTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        camera?.switch(toDesiredState: .on)
        idCapture.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        camera?.switch(toDesiredState: .off)
        idCapture.isEnabled = false
        timeoutTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupCamera() {
        guard let camera = Camera.default else { return }
        self.camera = camera
        let cameraSettings = IdCapture.recommendedCameraSettings
        camera.apply(cameraSettings)
        context.setFrameSource(camera, completionHandler: nil)
    }
    
    private func setupIdCapture() {
        let settings = IdCaptureSettings()
        
        settings.acceptedDocuments = [
            IdCard(region: .any),
            Passport(region: .any)
        ]
        
        if config.captureBackSide {
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
        
        idCapture = IdCapture(context: context, settings: settings)
        idCapture.addListener(listenerDelegate)
        
        if let externalTransactionId {
            idCapture.externalTransactionId = externalTransactionId
        }
    }
    
    private func bindListenerCallbacks() {
        listenerDelegate.onCapture = { [weak self] capturedId in
            guard let self else { return }
            let result = self.buildResult(from: capturedId)
            DispatchQueue.main.async {
                guard let result else {
                    self.finishWith(.failure(.runtimeError(message: "Failed to extract image from captured document")))
                    return
                }
                self.finishWith(.success(result))
            }
        }
        
        listenerDelegate.onReject = { [weak self] reason in
            DispatchQueue.main.async {
                self?.finishWith(.failure(.runtimeError(message: "Document rejected: \(reason)")))
            }
        }
    }
    
    private func setupCaptureView() {
        captureView = DataCaptureView(context: context, frame: view.bounds)
        captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(captureView)
        
        _ = IdCaptureOverlay(idCapture: idCapture, view: captureView)
    }
    
    private func startTimeoutTimer() {
        guard let timeoutMs = config.timeoutMs else { return }
        let interval = TimeInterval(timeoutMs) / 1000.0
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.finishWith(.failure(.timeout))
            }
        }
    }
    
    // MARK: - Result handling
    
    private func finishWith(_ outcome: ScanditCaptureOutcome<ScanditDocumentCaptureResult>) {
        guard !hasCompleted else { return }
        hasCompleted = true
        timeoutTimer?.invalidate()
        idCapture.isEnabled = false
        camera?.switch(toDesiredState: .off)
        completion(outcome)
    }
    
    // MARK: - Image extraction (called off main thread)
    
    private nonisolated func buildResult(from capturedId: CapturedId) -> ScanditDocumentCaptureResult? {
        let images = capturedId.images
        
        // Prefer the cropped document image; fall back to the full frame
        guard let uiImage = images.croppedDocument(for: .front) ?? images.frame else {
            return nil
        }
        
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.85) else {
            return nil
        }
        
        let width = Int(uiImage.size.width * uiImage.scale)
        let height = Int(uiImage.size.height * uiImage.scale)
        
        let capturedImage = ScanditCapturedImage(
            data: jpegData,
            width: width,
            height: height,
            format: "JPEG",
            nativeData: uiImage
        )
        
        // The cropped image already represents the document bounds,
        // so the rectangle covers the full image.
        let documentRect = ScanditDocumentRectangle(
            corners: [
                ScanditPoint(x: 0, y: 0),
                ScanditPoint(x: Double(width), y: 0),
                ScanditPoint(x: Double(width), y: Double(height)),
                ScanditPoint(x: 0, y: Double(height))
            ],
            boundingBox: ScanditBoundingBox(x: 0, y: 0, width: 1.0, height: 1.0)
        )
        
        let guideBox = ScanditGuideBox(width: 0.9, height: 0.6)
        
        return ScanditDocumentCaptureResult(
            image: capturedImage,
            distanceImage: nil,
            documentRectangle: documentRect,
            score: nil,
            guideBox: guideBox
        )
    }
}
