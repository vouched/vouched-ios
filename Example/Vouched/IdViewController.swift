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

class IdViewController: UIViewController {
    @IBOutlet private weak var previewContainer: UIView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var confirmIdButton: UIButton!
    @IBOutlet private weak var retryIdButton: UIButton!
    @IBOutlet private weak var confirmPanel: UIView!

    var inputFirstName: String = ""
    var inputLastName: String = ""
    var useCameraFlash = false
    var confirmID = false
    // temp storage of current ID to be confirmed
    var confirmIDDetectionResult: CardDetectResult?

    private var helper: VouchedCameraHelper?
    private var detectionMgr: VouchedDetectionManager?
    private let session = VouchedSession(apiKey: getValue(key:"API_KEY"), sessionParameters: VouchedSessionParameters())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "ID Scan"
        nextButton.isHidden = true
        loadingIndicator.isHidden = true
        instructionLabel.text = nil
        confirmPanel.isHidden = true

        configureHelper(.id)
        configureDetectionManager()
        
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
            let destVC = segue.destination as! FaceViewController
            destVC.session = self.session
        }
    }

    private func startCapture() {
        detectionMgr?.startDetection()
    }

    private func stopCapture() {
        detectionMgr?.stopDetection()
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
        DispatchQueue.main.async {
            UIView.transition(with: self.confirmPanel, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.confirmPanel.isHidden = !isVisible
            })
            self.instructionLabel.isHidden = isVisible
            self.navigationController?.navigationBar.isHidden = isVisible
        }
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
        stopCapture()
        detectionMgr?.onConfirmIdResult(result: confirmedResult)
    }
    
    @IBAction func onRetryIDButton(_ sender: Any) {
        showConfirmOverlay(isVisible: false)
        startCapture()
    }
}

//MARK: - VouchedCameraHelper
extension IdViewController {
    private func configureHelper(_ mode: VouchedDetectionMode) {
        var options = VouchedCameraHelperOptions.defaultOptions
        if useCameraFlash {
            options += .useCameraFlash
        }
        let detectionOptions = [VouchedDetectionOptions.cardDetect(CardDetectOptionsBuilder().withEnhanceInfoExtraction(true).build())]
        helper = VouchedCameraHelper(with: mode, helperOptions: options, detectionOptions: detectionOptions, in: previewContainer)
    }
}
    
//MARK: - VouchedDetectionManager

extension IdViewController {
    private func configureDetectionManager() {
        guard let helper = helper else { return }
        guard let config = VouchedDetectionManagerConfig(session: session) else { return }
        // optional validation parameters are added here
        config.validationParams.firstName = inputFirstName
        config.validationParams.lastName = inputLastName

        config.progress = ProgressAnimation(loadingIndicator: loadingIndicator)
        let callbacks = DetectionCallbacks { change in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: nil, message: "Turn ID card over to backside", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { _ in
                    change.completion(true)
                })
                alert.addAction(ok)
                self.present(alert, animated: true)
            }
        }
        callbacks.detectionComplete = { result in
            switch result {
            case .success(let job):
                DispatchQueue.main.async {
                    print("\(job)")
                    self.buttonShow()
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
            self.instructionLabel.text = (options.mode == .barcode) ? "Focus camera on barcode" : "Show ID Card"
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
            self.instructionLabel.text = (options.mode == .barcode) ? "Focus camera on barcode" : "Show ID Card"
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
