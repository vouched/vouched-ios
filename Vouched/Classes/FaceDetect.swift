//
//  FaceDetect.swift
//  Vouched
//
//  Created by Marcus Oliver on 7/22/20.
//

import Foundation
import Vision

public struct FaceDetectResult {
    public let base64Image: String
    public let faceFrame: CGRect
}

@available(iOS 11.0, *)
public class FaceDetect {
    let BOX_THRESHOLD_PCT: CGFloat = 0.35;
    // size of face needed per the device's display scale
    let boxThresholdPctWithScale: CGFloat
    
    var far: Bool = true
    var postable: Bool = false
    var consecutiveDetections: Int = 0
    
    public init() {
        self.boxThresholdPctWithScale = BOX_THRESHOLD_PCT / UIScreen.main.scale
    }

    public func isPostable() -> Bool {
        postable
    }
    
    public func isFar() -> Bool {
        far
    }
    
    public func detect(_ cvPixelBuffer: CVPixelBuffer) -> FaceDetectResult? {
        let faceDetection = VNDetectFaceRectanglesRequest()
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: CGImagePropertyOrientation.leftMirrored)

        do {
            try requestHandler.perform([faceDetection])
            let results = faceDetection.results as? [VNFaceObservation]
            
            // a face was found
            // update the 'far' flag depending on if it's too far away
            // update consecutiveDetections. when there are 3, postable = true
            // return the base64 image
            if results != nil && !results!.isEmpty {
                let result = results!.first!

                let frame: CGRect = result.boundingBox
                let frameSize = frame.height * frame.width
                self.far = frameSize < self.boxThresholdPctWithScale
                
                self.consecutiveDetections += 1
                self.postable = self.consecutiveDetections >= 3
                
                // resize image then convert to base64
                let image = UIImage(pixelBuffer: cvPixelBuffer)?.resize(withMaxResolution: 1024.0)
                let jpeg = UIImageJPEGRepresentation(image!, 0.95)
                return FaceDetectResult(
                    base64Image: jpeg!.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters),
                    faceFrame: frame
                )
            }
            
        } catch {
            print("face detect errors")
        }

        // no face was found
        self.far = true
        self.postable = false
        self.consecutiveDetections = 0
        return nil
    }
}
