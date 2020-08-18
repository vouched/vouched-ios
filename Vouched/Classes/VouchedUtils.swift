//
//  VouchedUtils.swift
//  Vouched
//
//  Created by Marcus Oliver on 8/17/20.
//

import Foundation

public enum RetryableError: String {
    case PoorIdImageQuality
    // following come from server
    case InvalidIdError
    case InvalidIdPhotoError
    case InvalidUserPhotoError
    case ExpiredIdError
}


public struct VouchedUtils {
    
    public static func extractRetryableErrors(_ job: Job, idQualityThreshold: Float = 0.7) -> [RetryableError] {
        if let idQuality = job.result.confidences.idQuality {
            if idQuality < idQualityThreshold {
                return [.PoorIdImageQuality]
            }
        }
        
        return job.errors.compactMap { RetryableError(rawValue: $0.type) }
    }
    
}
