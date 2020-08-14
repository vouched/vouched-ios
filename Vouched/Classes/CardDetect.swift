//
//  CardDetect.swift
//  Vouched
//
//  Created by Marcus Oliver on 7/22/20.
//

import Foundation

// MARK: - public structs
public struct CardDetectResult {
    public let base64Image: String?
    public let boudingBox: CGRect
    public let step: Step
    public let instruction: Instruction
}


// MARK: - public class
@available(iOS 10.0, *)
public class CardDetect {
    let MINIMUM_CONFIDENCE: Float = 0.7;
    let BOX_THRESHOLD: CGFloat = 70_000.0;

    // size of card/passport needed per the device's display scale
    let boxThresholdWithScale: CGFloat
    let modelDataHandler = ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo)

    var step: Step
    var boudingBox: CGRect
    var holdSteadyStart: Date?

    public init() {
        self.boxThresholdWithScale = BOX_THRESHOLD * UIScreen.main.scale
        self.step = .preDetected
        self.boudingBox = CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    /// detects if a card or passport is present within the image
    public func detect(_ cvPixelBuffer: CVPixelBuffer) -> CardDetectResult? {
        /// list of checkpoints ...
        /// checkpoint 1: no card, return nil
        /// checkpoint 2: more than one card, return with Instruction.onlyOne. one card, update boudingBox AND step
        /// checkpoint 3: too far away, return with Instruction.moveCloser
        /// checkpoint 4: time to hold steady, return with Instruction.holdSteady
        /// if all checks pass, convert image to base64, update step, return with Instruction.none
        
        // checkpoint 1
        guard let result = modelDataHandler?.runModel(onFrame: cvPixelBuffer) else {
            return resetStateReturnNil()
        }
        if result.inferences.count == 0 {
            VouchedLogger.shared.debug("Unable to find a card")
            return resetStateReturnNil()
        }

        // checkpoint 2
        if result.inferences.count > 1 {
            VouchedLogger.shared.debug("Found more than one card")
            return getResult(withInstruction: .onlyOne)
        }
        let card = result.inferences[0]
        self.boudingBox = card.rect
        self.step = .detected

        // checkpoint 3
        let boxSize = self.boudingBox.height * self.boudingBox.width
        if boxSize < self.boxThresholdWithScale {
            VouchedLogger.shared.debug("Card is too far away")
            return getResult(withInstruction: .moveCloser)
        }
        
        //checkpoint 4
        self.holdSteadyStart = self.holdSteadyStart ?? Date().addingTimeInterval(3)
        if Date() < self.holdSteadyStart! {
            VouchedLogger.shared.debug("Hold steady")
            return getResult(withInstruction: .holdSteady)
        }
        
        self.step = .postable
        VouchedLogger.shared.debug("Card is ready to be posted")

        // resize image then convert to base64
        let image = UIImage(pixelBuffer: cvPixelBuffer)?.resize(withMaxResolution: 1024.0)
        let jpeg = UIImageJPEGRepresentation(image!, 0.95)
        let base64Image = jpeg!.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
        return getResult(withInstruction: .none, withImage: base64Image)
    }
    
    // MARK: - private helper methods
    private func getResult(withInstruction instruction: Instruction, withImage image: String?=nil) -> CardDetectResult {
         return CardDetectResult(
             base64Image: image,
             boudingBox: self.boudingBox,
             step: self.step,
             instruction: instruction
         )
     }
    
    // reset to initial internal state and return nil
    private func resetStateReturnNil() -> CardDetectResult? {
        self.step = .preDetected
        self.boudingBox = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.holdSteadyStart = nil
        return nil
    }
    
}
