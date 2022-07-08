//
//  IdViewControllerV2.swift
//  Vouched
//
//  Copyright © 2021 Vouched.id. All rights reserved.
//

import UIKit
import TensorFlowLite
import VouchedCore
import VouchedBarcode

func getValue(key:String)-> String?{
    let v = Bundle.main.infoDictionary?[key] as? String
    if v == "" {
        return nil
    }
    return v
}

class IdViewControllerV2: UIViewController {
    @IBOutlet private weak var previewContainer: UIView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var confirmIdButton: UIButton!
    @IBOutlet private weak var retryIdButton: UIButton!
    @IBOutlet private weak var confirmPanel: UIView!

    var inputFirstName: String = ""
    var inputLastName: String = ""
    var onBarcodeStep = false
    var includeBarcode = false
    var useCameraFlash = false
    var useDetectionManager = false
    var confirmID = false
    // temp storage of current ID to be confirmed
    var confirmIDDetectionResult: CardDetectResult?

    private var helper: VouchedCameraHelper?
    private var detectionMgr: VouchedDetectionManager?
    private let session = VouchedSession(apiKey: getValue(key:"API_KEY"), sessionParameters: VouchedSessionParameters())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Place Camera On ID"
        nextButton.isHidden = true
        loadingIndicator.isHidden = true
        instructionLabel.text = nil
        confirmPanel.isHidden = true

        configureHelper(.id)
        if self.useDetectionManager {
            configureDetectionManager()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopCapture()
    }

    override func prepare(for segue: UIStoryboardSegue, sender:Any?){
        if segue.identifier == "ToFaceDetect"{
            let destVC = segue.destination as! FaceViewControllerV2
            destVC.session = self.session
        }
    }

    private func startCapture() {
        if self.useDetectionManager {
            detectionMgr?.startDetection()
        } else {
            helper?.startCapture()
        }
    }

    private func stopCapture() {
        if self.useDetectionManager {
            detectionMgr?.stopDetection()
        } else {
            helper?.stopCapture()
        }
    }

    private func updateLabel(_ instruction: Instruction) {
        var str: String
        switch instruction {
        case .moveCloser:
            str = "Move Closer"
        case .moveAway:
            str = "Move Away"
        case .holdSteady:
            str = "Hold Steady"
        case .onlyOne:
            str = "Multiple IDs"
        default:
            str = "Show ID"
        }
        DispatchQueue.main.async() {
            self.instructionLabel.text = str
        }
    }
        
    private func updateLabel(_ insight: Insight) {
        var str: String

        switch insight {
        case .nonGlare:
            str = "image has glare"
        case .quality:
            str = "image is blurry"
        case .brightness:
            str = "image needs to be brighter"
        case .face:
            str = "image is missing required visual markers"
        case .glasses:
            str = "please take off your glasses"
        case .unknown:
            str = "No Error Message"
        case .idPhoto:
            str = "ID needs a valid photo"
        @unknown default:
            str = "No Error Message"
        }
        
        DispatchQueue.main.async() {
            self.instructionLabel.text = str
        }
    }
    
    private func confirmIDCaptureIsGood(isVisible: Bool, result: CardDetectResult) {
            self.confirmIDDetectionResult = result
            self.showConfirmOverlay(isVisible: isVisible)
    }
    
    func showConfirmOverlay(isVisible: Bool) {
        UIView.transition(with: self.confirmPanel, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.confirmPanel.isHidden = !isVisible
        })
        instructionLabel.isHidden = isVisible
        navigationController?.navigationBar.isHidden = isVisible
    }


    private func buttonShow() {
        DispatchQueue.main.async() {
            self.nextButton.isHidden = false
            self.loadingIndicator.isHidden = true
            self.instructionLabel.text = nil
       }
    }

    private func loadingToggle() {
        self.loadingIndicator.isHidden = !self.loadingIndicator.isHidden
    }
    
    @IBAction func onConfirmIDButton(_ sender: Any) {
        guard let confirmedResult = self.confirmIDDetectionResult else {
            print("no confirmed result to post")
            return
        }
        showConfirmOverlay(isVisible: false)
        if useDetectionManager {
            detectionMgr?.onConfirmIdResult(result: confirmedResult)
        } else {
            onConfirmIdResult(confirmedResult)
        }
    }
    
    @IBAction func onRetryIDButton(_ sender: Any) {
        showConfirmOverlay(isVisible: false)
        startCapture()
    }
}

//MARK: - VouchedCameraHelper
extension IdViewControllerV2 {
    private func configureHelper(_ mode: VouchedDetectionMode) {
        var options = VouchedCameraHelperOptions.defaultOptions
        if useCameraFlash {
            options += .useCameraFlash
        }
        let detectionOptions = [VouchedDetectionOptions.cardDetect(CardDetectOptionsBuilder().withEnhanceInfoExtraction(true).build())]
        helper = VouchedCameraHelper(with: mode, helperOptions: options, detectionOptions: detectionOptions, in: previewContainer)?.withCapture(delegate: { self.handleResult($0) })
    }
    
    fileprivate func onConfirmIdResult(_ result: CardDetectResult) {
        self.loadingToggle()
        self.instructionLabel.text = "Processing Image"
        DispatchQueue.global().async {
            do {
                let job: Job
                if self.inputFirstName.isEmpty && self.inputLastName.isEmpty {
                    job = try self.session.postCardId(detectedCard: result)
                } else {
                    let details = Params(firstName: self.inputFirstName, lastName: self.inputLastName)
                    job = try self.session.postCardId(detectedCard: result, details: details)
                }
                print(job)
                
                // if there are job insights, update label and retry card detection
                let insights = VouchedUtils.extractInsights(job)
                if !insights.isEmpty {
                    self.updateLabel(insights.first!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.helper?.resetDetection()
                        self.loadingToggle()
                        self.helper?.startCapture()
                    }
                    return
                }
                if self.includeBarcode {
                    self.onBarcodeStep = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.loadingToggle()
                        self.configureHelper(.barcode)
                        self.helper?.startCapture()
                    }
                } else {
                    self.buttonShow()
                }
            } catch {
                print("Error FrontId: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleResult(_ result: VouchedCore.CaptureResult) {
        switch result {
        case .empty:
            self.instructionLabel.text = self.onBarcodeStep ? "Focus camera on barcode" : "Show ID Card"
        case .id(let result):
            guard let result = result as? CardDetectResult else { return }
            switch result.step {
            case .preDetected:
                self.instructionLabel.text = "Show ID Card"
            case .detected:
                self.updateLabel(result.instruction)
            case .postable:
                helper?.stopCapture()
                onConfirmIdResult(result as CardDetectResult)
            @unknown default:
                self.instructionLabel.text = self.onBarcodeStep ? "Focus camera on barcode" : "Show ID Card"
            }
        case .selfie(_):
            break
        case .barcode(let result):
            helper?.stopCapture()
            self.loadingToggle()
            self.instructionLabel.text = "Processing"

            do {
                let job = try session.postBackId(detectedBarcode: result)
                print(job)
                
                // if there are job insights, update label and retry card detection
                let insights = VouchedUtils.extractInsights(job)
                if !insights.isEmpty {
                    self.updateLabel(insights.first!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.loadingToggle()
                        self.helper?.startCapture()
                    }
                    return
                }
                self.buttonShow()
            } catch {
                print("Error Barcode: \(error.localizedDescription)")
            }
        case .error(let error):
            if let error = error as? VouchedError, let description = error.errorDescription {
                print("Error processing: \(description)")
            } else {
                print("Error processing: \(error.localizedDescription)")
            }
        @unknown default:
            print("Unknown Error")
        }
    }
}

//MARK: - VouchedDetectionManager

extension IdViewControllerV2 {
    private func configureDetectionManager() {
        guard let helper = helper else { return }
        guard let config = VouchedDetectionManagerConfig(session: session) else { return }

        config.progress = ProgressAnimation(loadingIndicator: loadingIndicator)
        let callbacks = DetectionCallbacks { change in
            let alert = UIAlertController(title: nil, message: "Turn ID card over to backside", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { _ in
                change.completion(true)
            })
            alert.addAction(ok)
            DispatchQueue.main.async {
                self.present(alert, animated: true)
            }
        }
        callbacks.detectionComplete = { result in
            switch result {
            case .success(let job):
                DispatchQueue.main.async {
                    print("\(job)")
                    
                    if self.includeBarcode {
                        if !self.onBarcodeStep {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.onBarcodeStep = true
                                self.detectionMgr?.startDetection(.barcode)
                            }
                        } else {
                            self.buttonShow()
                        }
                    } else {
                        self.buttonShow()
                    }
                }
            case .failure(let err):
                print("Error Card ID: \(err.localizedDescription)")
            }
        }
        callbacks.validateSubmission = { [self] result in
            if self.confirmID {
                stopCapture()
                confirmIDCaptureIsGood(isVisible: true, result: result as! CardDetectResult)
                return false
            }
            return true
        }
        callbacks.onResultProcessing = { self.onResultProcessing($0) }
        config.callbacks = callbacks
        detectionMgr = VouchedDetectionManager(helper: helper, config: config)
    }

    private func onResultProcessing(_ options: VouchedResultProcessingOptions) {
        guard options.step != nil else {
            self.instructionLabel.text = self.onBarcodeStep ? "Focus camera on barcode" : "Show ID Card"
            return
        }
        switch options.step! {
        case .preDetected:
            self.instructionLabel.text = "Show ID Card"
        case .detected:
            if let instruction = options.instruction {
                self.updateLabel(instruction)
            }
        case .postable:
            if let insight = options.insight {
                self.updateLabel(insight)
            } else {
                self.instructionLabel.text = "Processing"
            }
        @unknown default:
            self.instructionLabel.text = self.onBarcodeStep ? "Focus camera on barcode" : "Show ID Card"
        }
    }
}

private struct ProgressAnimation: VouchedProgressAnimation {
    let loadingIndicator: UIActivityIndicatorView?
    
    func startAnimating() {
        self.loadingIndicator?.isHidden = false
    }
    
    func stopAnimating() {
        self.loadingIndicator?.isHidden = true
    }
}

private class DetectionCallbacks: VouchedDetectionManagerCallbacks {
    var onStartDetection: ((VouchedDetectionMode) -> Void)?
    var onStopDetection: ((VouchedDetectionMode) -> Void)?
    var onResultProcessing: ((VouchedResultProcessingOptions) -> Void)?
    var onModeChange: ((VouchedModeChange) -> Void)
    var validateSubmission: ((DetectionResult) -> Bool)?
    var detectionComplete: ((Result<Job, Error>) -> Void)?
    
    init(modeChange: @escaping (VouchedModeChange) -> Void) {
        self.onModeChange = modeChange
    }
}
