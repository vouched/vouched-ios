//
//  AuthenticateViewController.swift
//  Vouched_Example
//
//  Copyright © 2021 Vouched.id. All rights reserved.
//

import UIKit
import AVFoundation
import VouchedCore

class AuthenticateViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var authenticationResultLabel: UILabel!
    
    var jobId: String = ""
    var device: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraImage: UIImage?
    var faceDetect = FaceDetect(options: FaceDetectOptionsBuilder().withLivenessMode(.mouthMovement).build())
    var count: Int = 0
    var id:String = ""
    var firstCalled:Bool = true
    var session: VouchedSession?
    var job: Job?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Capture Face To Authenticate"
        
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
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: AVMediaType.video,
                                                                position: .front)
        
        if  discoverySession.devices.count == 0 {
            return
        }
        device = discoverySession.devices[0]
        
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
    func loadingShow(){
        DispatchQueue.main.async() {
            self.loadingIndicator.isHidden = false
        }
    }
    func buttonShow(authenticationResult: AuthenticateResult){
        if authenticationResult.match > 0.9 {
            DispatchQueue.main.async() { // Correct
                self.authenticationResultLabel.text = "Authentication Success"
                self.authenticationResultLabel.isHidden = false
                self.loadingIndicator.isHidden = true
                self.instructionLabel.text = nil
            }
        }else{
            DispatchQueue.main.async() { // Correct
                self.authenticationResultLabel.text = "Authentication Failed"
                self.authenticationResultLabel.isHidden = false
                self.loadingIndicator.isHidden = true
                self.instructionLabel.text = nil
           }
        }
    }
    
    func updateLabel(_ instruction:Instruction) {
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
        default:
            str = "Look Forward"
        }
        DispatchQueue.main.async() {
            self.instructionLabel.text = str
        }
    }
    
    /**
     This method called from AVCaptureVideoDataOutputSampleBufferDelegate - passed in sampleBuffer
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        var result: VouchedCore.DetectionResult?
        do {
            result = try faceDetect?.detect(sampleBuffer)
        } catch {
            DispatchQueue.main.async() {
                self.instructionLabel.text = "Misconfigured Vouched"
            }
            if let error = error as? VouchedError, let description = error.errorDescription {
                print("Error info: \(description)")
            } else {
                print("Error info: \(error)")
            }
            return
        }
        
        if let detectedFace = result as? FaceDetectResult {
            switch detectedFace.step {
            case .preDetected:
                DispatchQueue.main.async() {
                    self.instructionLabel.text = "Look into the Camera"
                }
            case .detected:
                self.updateLabel(detectedFace.instruction)
            case .postable:
                captureSession?.stopRunning()
                DispatchQueue.main.async() {
                    self.instructionLabel.text = "Processing Image"
                }
                self.loadingShow()
                do {
                    let authenticationResult: AuthenticateResult = try session!.postAuthenticate(id: self.jobId, userPhoto: detectedFace.image!, matchId: true)
                    self.buttonShow(authenticationResult: authenticationResult)
                } catch {
                    print("Error info: \(error)")
                    self.buttonShow(authenticationResult: AuthenticateResult(match: 0))
                }
            @unknown default:
                DispatchQueue.main.async() {
                    self.instructionLabel.text = "Look into the Camera"
                }
            }
        } else {
            DispatchQueue.main.async() {
                self.instructionLabel.text = "Look into the Camera"
            }
        }
    }
}
