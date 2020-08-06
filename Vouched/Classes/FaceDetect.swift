//
//  FaceDetect.swift
//  Vouched
//
//  Created by Marcus Oliver on 7/22/20.
//

import Foundation
import Vision

// MARK: - public enums
public enum LivenessDetection {
    case mouthMovement
    case none
}

public enum Instruction {
    case onlyOneFace
    case moveCloser
    case holdSteady
    case openMouth
    case closeMouth
    case none
}

public enum Step {
    case preDetected
    case detected
    case postable
}

// MARK: - public structs
public struct FaceDetectResult {
    public let base64Image: String?
    public let boudingBox: CGRect
    public let step: Step
    public let instruction: Instruction
}

public struct FaceDetectConfig {
    public let liveness: LivenessDetection
    
    public init(liveness: LivenessDetection) {
        self.liveness = liveness
    }
}

// MARK: - public class
@available(iOS 11.0, *)
public class FaceDetect {
    let BOX_THRESHOLD_PCT: CGFloat = 0.35;
    
    var step: Step
    var mouthStates: Stack<MouthState>
    var previousMouthStates: [MouthState]
    var boudingBox: CGRect

    // size of face needed per the device's display scale
    let boxThresholdPctWithScale: CGFloat
    let config: FaceDetectConfig
    
    var holdSteadyStart: Date?
    
    public init(config: FaceDetectConfig) {
        self.step = .preDetected
        self.mouthStates = Stack([.closed, .open, .closed])
        self.previousMouthStates = [.closed, .open, .closed]
        self.boudingBox = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.boxThresholdPctWithScale = BOX_THRESHOLD_PCT / UIScreen.main.scale
        self.config = config
    }

    public func detect(_ cvPixelBuffer: CVPixelBuffer) -> FaceDetectResult? {
        let faceDetection = VNDetectFaceLandmarksRequest()
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: CGImagePropertyOrientation.leftMirrored)

        do {
            try requestHandler.perform([faceDetection])
                        
            /// list of checkpoints ...
            /// checkpoint 1: no faces, return nil
            /// checkpoint 2: more than one face, return with Instruction.onlyOneFace. one face, update boudingBox AND step
            /// checkpoint 3: too far away, return with Instruction.moveCloser
            /// checkpoint 4: liveness check, return with Instruction.openMouth OR closeMouth
            /// checkpoint 5: clear picture check, return with Instruction.holdSteady
            /// if all checks pass, convert image to base64, update step, return with Instruction.none
            
            // checkpoint 1
            guard let faces = faceDetection.results as? [VNFaceObservation] else {
                return resetStateReturnNil()
            }
            if faces.count == 0 {
                return resetStateReturnNil()
            }

            // checkpoint 2
            if faces.count > 1 {
                return getResult(withInstruction: .onlyOneFace)
            }
            let face = faces[0]
            self.boudingBox = face.boundingBox
            self.step = .detected
            
            // checkpoint 3
            let boxSize = self.boudingBox.height * self.boudingBox.width
            if boxSize < self.boxThresholdPctWithScale {
                return getResult(withInstruction: .moveCloser)
            }
                        
            //checkpoint 4
            switch self.config.liveness {
            case .mouthMovement:
                if !self.mouthStates.isEmpty() {
                    do {
                        // TODO: safely unwrap all variables
                        let outerLips = face.landmarks!.outerLips!
                        let innerLips = face.landmarks!.innerLips!
                        let currentMouthState = self.getMouthState(outerLips, innerLips);
                        updatePreviousMouthState(currentMouthState)
                        let needed = self.mouthStates.peek()
                        if currentMouthState == needed {
                            if consecutiveMouthStates() {
                                self.mouthStates.pop()
                            }
                            if !self.mouthStates.isEmpty() {
                                return getResult(withInstruction: self.mouthStates.peek() == .closed ? .closeMouth : .openMouth)
                            }
                        } else {
                            return getResult(withInstruction: needed == .closed ? .closeMouth : .openMouth)
                        }
                    } catch {
                        print("liveness error: \(error)")
                    }
                }
            case .none:
                print("skipping liveness check")
            }
            
            //checkpoint 5
            self.holdSteadyStart = self.holdSteadyStart ?? Date().addingTimeInterval(3)
            if Date() < self.holdSteadyStart! {
                return getResult(withInstruction: .holdSteady)
            }
            
            self.step = .postable
            
            let image = UIImage(pixelBuffer: cvPixelBuffer)?.resize(withMaxResolution: 1024.0)
            let jpeg = UIImageJPEGRepresentation(image!, 0.95)
            let base64Image = jpeg!.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
            return getResult(withInstruction: .none, withImage: base64Image)

        } catch {
            print("face detect errors")
            return resetStateReturnNil()
        }
        
    }
    
    // MARK: - private helper methods
   private func getResult(withInstruction instruction: Instruction, withImage image: String?=nil) -> FaceDetectResult {
        return FaceDetectResult(
            base64Image: image,
            boudingBox: self.boudingBox,
            step: self.step,
            instruction: instruction
        )
    }
    
    // reset to initial internal state and return nil
    private func resetStateReturnNil() -> FaceDetectResult? {
        self.step = .preDetected
        self.mouthStates = Stack([.closed, .open, .closed])
        self.previousMouthStates = [.closed, .open, .closed]
        self.boudingBox = CGRect(x: 0, y: 0, width: 0, height: 0)
        return nil
    }
    
    // keep track of most recent 3 frame's mouth state
    private func updatePreviousMouthState(_ mouthState: MouthState) {
        self.previousMouthStates[0] = self.previousMouthStates[1]
        self.previousMouthStates[1] = self.previousMouthStates[2]
        self.previousMouthStates[2] = mouthState
    }
    
    // if most recent 3 frame's mouth state are equal, return true
    private func consecutiveMouthStates() -> Bool {
        return self.previousMouthStates[0] == self.previousMouthStates[1] && self.previousMouthStates[1] == self.previousMouthStates[2]
    }
    
    // get mouth state from outerLips and innerLips landmarks
    private func getMouthState(_ outerLips: VNFaceLandmarkRegion2D, _ innerLips: VNFaceLandmarkRegion2D) -> MouthState {
        let topLipHeight = getTopLipHeight(outerLips, innerLips)
        let bottomLipHeight = getBottomLipHeight(outerLips, innerLips)
        let mouthOpeningHeight = getMouthOpenHeight(innerLips)
        let openingHeightThresholdRatio: CGFloat = 0.8
        if mouthOpeningHeight > (min(topLipHeight, bottomLipHeight) * openingHeightThresholdRatio) {
            return .open
        } else {
            return .closed
        }
    }
    
    // find the height of the top lip
    private func getTopLipHeight(_ outerLips: VNFaceLandmarkRegion2D, _ innerLips: VNFaceLandmarkRegion2D) -> CGFloat {
        return getHeight(outerLips, innerLips, correspondingPairs: [(0,0), (2,1), (4,2)])
//        return getHeight(outerLips, innerLips, correspondingPairs: [(2,1)])
//        return getHeight(outerLips, innerLips, correspondingPairs: [(0,0), (4,2)])
    }
    
    // find the height of the bottom lip
    private func getBottomLipHeight(_ outerLips: VNFaceLandmarkRegion2D, _ innerLips: VNFaceLandmarkRegion2D) -> CGFloat {
        return getHeight(outerLips, innerLips, correspondingPairs: [(8,5), (7,4), (6,3)])
//        return getHeight(outerLips, innerLips, correspondingPairs: [(7,4)])
//        return getHeight(outerLips, innerLips, correspondingPairs: [(8,5), (6,3)])
    }
    
    // find the height of mouth's opening
    private func getMouthOpenHeight(_ innerLips: VNFaceLandmarkRegion2D) -> CGFloat {
        // for the sake of DRYness, using the same method to get height mouth opening
//        return getHeight(innerLips, innerLips, correspondingPairs: [(5,0), (4,1), (3,2)])
        return getHeight(innerLips, innerLips, correspondingPairs: [(4,1)])
    }
    
    private func getHeight(_ outerLips: VNFaceLandmarkRegion2D, _ innerLips: VNFaceLandmarkRegion2D, correspondingPairs: [(Int, Int)]) -> CGFloat {
        var totalHeight: CGFloat = 0.0
        for pair in correspondingPairs {
            let xHeight: CGFloat = outerLips.normalizedPoints[pair.0].x - innerLips.normalizedPoints[pair.1].x
            let yHeight: CGFloat = outerLips.normalizedPoints[pair.0].y - innerLips.normalizedPoints[pair.1].y
            let height = ((xHeight * xHeight) + (yHeight * yHeight)).squareRoot()
            totalHeight += height
        }
        return totalHeight / CGFloat(correspondingPairs.count)
    }
}

/// internal enums
enum MouthState {
    case open
    case closed
}
