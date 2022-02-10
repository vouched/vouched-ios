//
//  IdViewController.swift
//  Vouched
//
//  Copyright © 2021 Vouched.id. All rights reserved.
//

import UIKit
import AVFoundation
import VouchedCore
import VouchedBarcode

func getValue(key:String)-> String?{
    let v = Bundle.main.infoDictionary?[key] as? String
    if v == "" {
        return nil
    }
    return v
}

class IdViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    var device: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraImage: UIImage?
    var cardDetect = CardDetect(options: CardDetectOptionsBuilder().withEnableDistanceCheck(false).build())
    var barCodeDetect = BarcodeDetect()
    var count: Int = 0
    let session = VouchedSession(apiKey: getValue(key:"API_KEY"), sessionParameters: VouchedSessionParameters())
    var inputFirstName: String = ""
    var inputLastName: String = ""

    var onBarcodeStep = false;
    var includeBarcode = false;

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Place Camera On ID"
        
        nextButton.isHidden = true
        loadingIndicator.isHidden = true
        setupCamera()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     This method sets up the Camera device details
     */
    func setupCamera() {
        let discoverySession =
            AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                             mediaType: AVMediaType.video,
                                             position: .back)
        
        if  discoverySession.devices.count == 0 {
            return
        }
        device = discoverySession.devices[0]
        
        if(device!.isFocusModeSupported(.continuousAutoFocus)) {
            try! device!.lockForConfiguration()
            device!.focusMode = .continuousAutoFocus
            device!.unlockForConfiguration()
        }
        
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device!)
        } catch {
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        
        let queue = DispatchQueue(label: "cameraQueue")
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: kCVPixelFormatType_32BGRA]
        
        startCapture(input:input, output:output)
    }
    
    /**
     This method sets up captureSession and starts session with previewLayer
     */
    func startCapture(input: AVCaptureDeviceInput, output: AVCaptureVideoDataOutput){
        captureSession = AVCaptureSession()
        captureSession?.addInput(input)
        captureSession?.addOutput(output)
        captureSession?.sessionPreset = AVCaptureSession.Preset.photo
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: view.frame.height)
        
        self.cameraView?.layer.insertSublayer(previewLayer!, at: 0)
        
        captureSession?.startRunning()
    }
    
    func loadingToggle() {
        DispatchQueue.main.async() {
            self.loadingIndicator.isHidden = !self.loadingIndicator.isHidden

        }
    }
    
    func buttonShow() {
        DispatchQueue.main.async() { // Correct
            self.nextButton.isHidden = false
            self.loadingIndicator.isHidden = true

        }
    }
    
    func updateLabel(_ instruction: Instruction) {
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
    
    func updateLabel(_ retryableError: RetryableError) {
        var str: String

        switch retryableError {
        case .blurryIdPhotoError:
            str = "Photo is blurry"
        case .glareIdPhotoError:
            str = "Photo has glare"
        case .invalidIdPhotoError:
            str = "Invalid Photo ID"
        case .invalidUserPhotoError:
            str = "Invalid Photo ID"
        @unknown default:
            str = "Unknown error"
        }
        DispatchQueue.main.async() {
            self.instructionLabel.text = str
        }
    }
    
    func updateLabel(_ insight: Insight) {
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
    
    /**
     This method called from AVCaptureVideoDataOutputSampleBufferDelegate - passed in sampleBuffer
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if onBarcodeStep {
            captureBarcode(sampleBuffer)
        } else {
            captureFrontId(sampleBuffer)
        }
    }

    func captureBarcode(_ sampleBuffer: CMSampleBuffer) {
        var result: VouchedCore.DetectionResult?
        do {
            result = try self.barCodeDetect?.detect(sampleBuffer)
        } catch {
            DispatchQueue.main.async() {
                self.instructionLabel.text = "Misconfigured Vouched"
            }
            if let error = error as? VouchedError, let description = error.errorDescription {
                print("Error Barcode: \(description)")
            } else {
                print("Error Barcode: \(error.localizedDescription)")
            }
            return
        }
        
        guard let detectedBarcode = result else {
            DispatchQueue.main.async() {
                self.instructionLabel.text = "Focus camera on barcode"
            }
            return
        }

        captureSession?.stopRunning()
        self.loadingToggle()
        DispatchQueue.main.async() {
            self.instructionLabel.text = "Processing"
        }
        
        do {
            let job = try session.postBackId(detectedBarcode: detectedBarcode)
            print(job)
            
            // if there are job insights, update label and retry card detection
            let insights = VouchedUtils.extractInsights(job)
            if !insights.isEmpty {
                self.updateLabel(insights.first!)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.loadingToggle()
                    self.captureSession?.startRunning()
                }
                return;
            }
            self.buttonShow()
        } catch {
            print("Error Barcode: \(error.localizedDescription)")
        }
        
    }
    
    func captureFrontId(_ sampleBuffer: CMSampleBuffer) {
        do {
            let detectedCard = try cardDetect?.detect(sampleBuffer)
            
            if let detectedCard = detectedCard as? CardDetectResult {
                switch detectedCard.step {
                case .preDetected:
                    DispatchQueue.main.async() {
                        self.instructionLabel.text = "Show ID Card"
                    }
                case .detected:
                    self.updateLabel(detectedCard.instruction)
                case .postable:
                    captureSession?.stopRunning()
                    self.loadingToggle()
                    DispatchQueue.main.async() {
                        self.instructionLabel.text = "Processing Image"
                    }
                    do {
                        let job: Job
                        if inputFirstName.isEmpty && inputLastName.isEmpty {
                            job = try session.postFrontId(detectedCard: detectedCard)
                        } else {
                            let details = Params(firstName: inputFirstName, lastName: inputLastName)
                            job = try session.postFrontId(detectedCard: detectedCard, details: details)
                        }
                        print(job)

                        // if there are job insights, update label and retry card detection
                        let insights = VouchedUtils.extractInsights(job)
                        if !insights.isEmpty {
                            self.updateLabel(insights.first!)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.cardDetect?.reset();
                                self.loadingToggle()
                                self.captureSession?.startRunning()
                            }
                            return;
                        }
                        if includeBarcode {
                            onBarcodeStep = true;
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.loadingToggle()
                                self.captureSession?.sessionPreset = AVCaptureSession.Preset.high
                                self.captureSession?.startRunning()
                            }
                        } else {
                            self.buttonShow()
                        }
                    } catch {
                        print("Error FrontId: \(error.localizedDescription)")
                    }
                @unknown default:
                    DispatchQueue.main.async() {
                        self.instructionLabel.text = "Show ID Card"
                    }
                }
            } else {
                DispatchQueue.main.async() {
                    self.instructionLabel.text = "Show ID Card"
                }
            }
        } catch {
            DispatchQueue.main.async() {
                self.instructionLabel.text = "Misconfigured Vouched"
            }
            if let error = error as? VouchedError, let description = error.errorDescription {
                print("Error FrontId: \(description)")
            } else {
                print("Error FrontId: \(error.localizedDescription)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender:Any?){
        if segue.identifier == "ToFaceDetect"{
            let destVC = segue.destination as! FaceViewController
            destVC.session = self.session
        }
    }
}
