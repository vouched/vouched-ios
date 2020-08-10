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
    var cardDetect = CardDetect()
    var count: Int = 0
    let session: VouchedSession = VouchedSession(type: .idVerificationWithFace)

    var inputFirstName: String = ""
    var inputLastName: String = ""
    
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
    
    /**
     This method called from AVCaptureVideoDataOutputSampleBufferDelegate - passed in sampleBuffer
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let detectedCard = self.cardDetect.detect(imageBuffer!)
        
        if let detectedCard = detectedCard {
            if cardDetect.isFar() {
              DispatchQueue.main.async() {
                  self.instructionLabel.text = "Too Far Away"
              }
            } else if !cardDetect.isPostable() {
              DispatchQueue.main.async() {
                  self.instructionLabel.text = "Hold Steady"
              }
            }
            else {
                captureSession?.stopRunning()
                self.loadingShow()
                DispatchQueue.main.async() {
                    self.instructionLabel.text = "Processing Image"
                }
                do {
                    if inputFirstName.isEmpty && inputLastName.isEmpty {
                        _ = try session.postFrontId(detectedCard: detectedCard)
                    } else {
                        var params = Params(firstName: inputFirstName, lastName: inputLastName)
                        _ = try session.postFrontId(detectedCard: detectedCard, params: &params)
                    }
                    self.buttonShow()
                } catch {
                    print("Error info: \(error)")
                }
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
