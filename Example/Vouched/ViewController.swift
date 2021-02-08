//
//  ViewController.swift
//  Vouched
//
//  Created by marcusoliver on 07/22/2020.
//  Copyright (c) 2020 marcusoliver. All rights reserved.
//

import UIKit
import AVFoundation
import Vouched
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    var device: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraImage: UIImage?
    var cardDetect = CardDetect(options: CardDetectOptionsBuilder().withEnableDistanceCheck(true).build())
    var count: Int = 0
    let session: VouchedSession = VouchedSession()

    var inputFirstName: String = ""
    var inputLastName: String = ""
    var nextRun: Date = Date();

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
    func buttonShow(){
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
        }
        DispatchQueue.main.async() {
            self.instructionLabel.text = str
        }
    }
    
    /**
     This method called from AVCaptureVideoDataOutputSampleBufferDelegate - passed in sampleBuffer
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let detectedCard = self.cardDetect.detect(imageBuffer!)
        
        if let detectedCard = detectedCard {
            switch detectedCard.step {
            case .preDetected:
                DispatchQueue.main.async() {
                    self.instructionLabel.text = "Show ID Card"
                }
            case .detected:
                self.updateLabel(detectedCard.instruction)
            case .postable:
                captureSession?.stopRunning()
                self.loadingShow()
                DispatchQueue.main.async() {
                    self.instructionLabel.text = "Processing Image"
                }
                do {
                    let job: Job
                    if inputFirstName.isEmpty && inputLastName.isEmpty {
                        job = try session.postFrontId(detectedCard: detectedCard)
                    } else {
                        var params = Params(firstName: inputFirstName, lastName: inputLastName)
                        job = try session.postFrontId(detectedCard: detectedCard, params: &params)
                    }
                    
                    let retryableErrors = VouchedUtils.extractRetryableIdErrors(job)
                    // if there are retryable errors, update label and retry card detection
                    if !retryableErrors.isEmpty {
                        self.updateLabel(retryableErrors.first!)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            self.captureSession?.startRunning()
                        }
                        return;
                    }
                    self.buttonShow()
                } catch {
                    print("Error info: \(error)")
                }
            }
        } else {
            DispatchQueue.main.async() {
                self.instructionLabel.text = "Show ID Card"
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
