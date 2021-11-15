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
import MLKitBarcodeScanning

class IdViewControllerV2: UIViewController {
    @IBOutlet private weak var previewContainer: UIView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var instructionLabel: UILabel!

    var inputFirstName: String = ""
    var inputLastName: String = ""
    var onBarcodeStep = false
    var includeBarcode = false

    private var helper: VouchedCameraHelper?
    private let session = VouchedSession(apiKey: getValue(key:"API_KEY"), sessionParameters: VouchedSessionParameters())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Place Camera On ID"
        nextButton.isHidden = true
        loadingIndicator.isHidden = true
        instructionLabel.text = nil

        configureHelper(CardDetect.self)
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
        if segue.identifier == "ToFaceDetect"{
            let destVC = segue.destination as! FaceViewControllerV2
            destVC.session = self.session
        }
    }

    private func configureHelper(_ detector: Detector.Type) {
        helper = VouchedCameraHelper(with: detector, in: previewContainer)?.withCapture(delegate: { self.handleResult($0) })
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
                self.loadingToggle()
                self.instructionLabel.text = "Processing Image"
                DispatchQueue.global().async {
                    do {
                        let job: Job
                        if self.inputFirstName.isEmpty && self.inputLastName.isEmpty {
                            job = try self.session.postFrontId(detectedCard: result)
                        } else {
                            let details = Params(firstName: self.inputFirstName, lastName: self.inputLastName)
                            job = try self.session.postFrontId(detectedCard: result, details: details)
                        }
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
                        if self.includeBarcode {
                            self.onBarcodeStep = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.loadingToggle()
                                self.configureHelper(BarcodeDetect.self)
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
        @unknown default:
            str = "No Error Message"
        }
        
        DispatchQueue.main.async() {
            self.instructionLabel.text = str
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
}
