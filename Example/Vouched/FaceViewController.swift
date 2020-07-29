//
//  FaceViewController.swift
//  Vouched_Example
//
//  Created by David Woo on 7/27/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import Vouched
import Vision

class FaceViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var device: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraImage: UIImage?
    var cardDetect = CardDetect()
    var faceDetect = FaceDetect()
    var count: Int = 0
    var cardDetectJobToken:String = ""
    var id:String = ""
    var firstCalled:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        var discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
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
            print(self.loadingIndicator.isHidden)
            self.loadingIndicator.isHidden = false

        }
    }
    func buttonShow(){
        DispatchQueue.main.async() { // Correct
            print(self.nextButton.isHidden)
            self.nextButton.isHidden = false
            self.loadingIndicator.isHidden = true
        }
    }
    /**
     This method called from AVCaptureVideoDataOutputSampleBufferDelegate - passed in sampleBuffer
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let detectedFace = self.faceDetect.detect(imageBuffer!)
        
        if firstCalled {
            if let udetectedFace = detectedFace{
                print("Found a Face")
                if !self.faceDetect.isFar() && self.faceDetect.isPostable(){
                    print("Face Detected")
                   
                    let selfiePhoto:String? = udetectedFace.base64Image
                    do {
                        self.firstCalled = false
                        self.loadingShow()
                        
                        let params = Params(userPhoto: selfiePhoto)
                        let request = SessionJobRequest(stage: Stage.face, params: params)
                        let job = try API.jobSession(request: request, token: cardDetectJobToken)
                        self.id = job.id
                        self.buttonShow()
                        print("Job Post Success: " + job.id)
                        
                    } catch {
                        print("Error info: \(error)")
                    }
                    
                }else{
                    print("Face Detected but Too Far, Not Postable")
                }
            }
        }
    
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
//        self.cameraView.isHidden = true
//        self.loadingIndicator.isHidden = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
        if segue.identifier == "ToResultPage" {
            let destVC = segue.destination as! ResultsViewController
            destVC.cardDetectJobToken = self.cardDetectJobToken
            destVC.id = self.id
        }
    }


}
