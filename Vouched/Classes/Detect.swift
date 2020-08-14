//
//  Detect.swift
//  Vouched
//
//  Created by Marcus Oliver on 8/14/20.
//

import Foundation

public enum Instruction {
    case onlyOne
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
