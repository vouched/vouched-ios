//
//  CardDetect.swift
//  Vouched
//
//  Created by Marcus Oliver on 7/22/20.
//

import Foundation

public struct CardDetectResult {
    public let base64Image: String
    public let cardFrame: CGRect

}

@available(iOS 10.0, *)
public class CardDetect {
    let MINIMUM_CONFIDENCE: Float = 0.7;
    let BOX_THRESHOLD: CGFloat = 70_000.0;

    // size of card/passport needed per the device's display scale
    let boxThresholdWithScale: CGFloat
    let modelDataHandler = ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo)

    var far: Bool = true
    var postable: Bool = false
    var consecutiveDetections: Int = 0
    
    public init() {
        self.boxThresholdWithScale = BOX_THRESHOLD * UIScreen.main.scale
    }
    
    public func isFar() -> Bool {
        far
    }
    
    public func isPostable() -> Bool {
        postable
    }
    
    /// detects if a card or passport is present within the image
    /// if the card/passport doesn't meet the box threshold, far is set to False
    /// returns the base64 image if card/passport is detected
    public func detect(_ cvPixelBuffer: CVPixelBuffer) -> CardDetectResult? {
        let result = modelDataHandler?.runModel(onFrame: cvPixelBuffer)
        guard let unwrappedResult = result else {
            return nil
        }
        for inference in unwrappedResult.inferences {
            // a card was found
            // update the 'far' flag depending on if it's too far away
            // update consecutiveDetections. when there are 3, postable = true
            // return the base64 image
            if inference.confidence > MINIMUM_CONFIDENCE {
                let frame = inference.rect
                let frameSize = frame.height * frame.width
                self.far = frameSize < self.boxThresholdWithScale
                
                self.consecutiveDetections += 1
                self.postable = self.consecutiveDetections >= 3
                
                // resize image then convert to base64
                let image = UIImage(pixelBuffer: cvPixelBuffer)?.resize(withMaxResolution: 1024.0)
                let jpeg = UIImageJPEGRepresentation(image!, 0.95)
                return CardDetectResult(
                    base64Image: jpeg!.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters),
                    cardFrame: frame)
            }
        }
        
        // no face was found
        self.far = true
        self.postable = false
        self.consecutiveDetections = 0
        return nil
    }

}
