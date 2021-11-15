//
//  FaceViewControllerV2.swift
//  Vouched_Example
//
//  Copyright © 2021 Vouched.id. All rights reserved.
//

import UIKit
import VouchedCore

class FaceViewControllerV2: UIViewController {
    @IBOutlet private weak var previewContainer: UIView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var instructionLabel: UILabel!

    private var helper: VouchedCameraHelper?
    var session: VouchedSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Place Camera On ID"
        nextButton.isHidden = true
        loadingIndicator.isHidden = true
        instructionLabel.text = nil

        configureHelper(FaceDetect.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        helper?.startCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        helper?.stopCapture()
    }

    override func prepare(for segue: UIStoryboardSegue, sender:Any?){
        if segue.identifier == "ToResultPage" {
            let destVC = segue.destination as! ResultsViewController
            destVC.session = self.session
        }
    }

    private func configureHelper(_ detector: Detector.Type) {
        helper = VouchedCameraHelper(with: detector, detectionOptions: [.faceDetect(FaceDetectOptionsBuilder().withLivenessMode(.mouthMovement).build())], in: previewContainer)?.withCapture(delegate: { self.handleResult($0) })
    }
    
    private func handleResult(_ result: VouchedCore.CaptureResult) {
        switch result {
        case .empty:
            self.instructionLabel.text = "Look into the Camera"
        case .selfie(let result):
            guard let result = result as? FaceDetectResult else { return }
            switch result.step {
            case .preDetected:
                self.instructionLabel.text = "Look into the Camera"
            case .detected:
                self.updateLabel(result.instruction)
            case .postable:
                helper?.stopCapture()
                self.loadingToggle()
                self.instructionLabel.text = "Processing Image"
                DispatchQueue.global().async {
                    do {
                        let job = try self.session?.postFace(detectedFace: result)
                        print(job)

                        // if there are job insights, update label and retry card detection
                        let insights = VouchedUtils.extractInsights(job)
                        if !insights.isEmpty {
                            self.updateLabel(insights.first!)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.helper?.resetDetection()
                                self.loadingToggle()
                                self.helper?.startCapture()
                            }
                            return
                        }
                        self.buttonShow()
                    } catch {
                        print("Error Selfie: \(error.localizedDescription)")
                    }
                }
            }
        default:
            break
        }
    }
    
//MARK: -
    private func updateLabel(_ instruction:Instruction) {
        var str: String
        switch instruction {
        case .closeMouth:
            str = "Close Mouth"
        case .openMouth:
            str = "Open Mouth"
        case .moveCloser:
            str = "Come Closer to Camera"
        case .holdSteady:
            str = "Hold Steady"
        case .lookForward:
            str = "Look Forward"
        case .onlyOne:
            str = "Multiple Faces"
        case .moveAway:
            str = "Move Away"
        case .blinkEyes:
            str = "Slowly Blink"
        default:
            str = "Look Forward"
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
        }
        DispatchQueue.main.async() {
            self.instructionLabel.text = str
        }
    }

    private func loadingToggle() {
        self.loadingIndicator.isHidden = !self.loadingIndicator.isHidden
    }

    func buttonShow() {
        DispatchQueue.main.async() {
            self.nextButton.isHidden = false
            self.loadingIndicator.isHidden = true
            self.instructionLabel.text = nil
        }
    }
}
