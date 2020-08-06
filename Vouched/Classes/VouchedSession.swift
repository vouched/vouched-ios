//
//  VouchedSession.swift
//  Vouched
//
//  Created by Marcus Oliver on 7/22/20.
//

import Foundation

public enum VerificationSessionType {
    case idVerification
    case idVerificationWithFace
}

public enum VouchedSessionError: Error {
    case nilCardImage
    case nilFaceImage
}

public class VouchedSession
{
    let type: VerificationSessionType
    var token: String? = nil
    var config: Config? = nil
    
    public init(type: VerificationSessionType) {
        self.type = type
    }

    public func postFrontId(detectedCard: CardDetectResult) throws -> Job {
        var params = Params()
        return try postFrontId(detectedCard: detectedCard, params: &params)
    }
        
    public func postFrontId(detectedCard: CardDetectResult, params: inout Params) throws -> Job {
        params.idPhoto = detectedCard.base64Image
        
        let request = SessionJobRequest(stage: Stage.id, params: params)
        var job = try Utils.retryWithBackoff(withRetries: 3, operation: {
            return try API.jobSession(request: request, token: self.token)
        })
        self.token = job.token
        
        // IDV with only the id. run confirm directly after
        if self.type == .idVerification {
            job = try self.postConfirm()
        }
        
        return job
    }
    
    public func postFace(detectedFace: FaceDetectResult) throws -> Job {
        if detectedFace.base64Image == nil {
            throw VouchedSessionError.nilFaceImage
        }
        let params = Params(userPhoto: detectedFace.base64Image)
        let request = SessionJobRequest(stage: Stage.face, params: params)
        var job = try Utils.retryWithBackoff(withRetries: 3, operation: {
            return try API.jobSession(request: request, token: self.token)
        })
        self.token = job.token
        
        // IDV with id + face. run confirm directly after
        if self.type == .idVerificationWithFace {
            job = try self.postConfirm()
        }
        
        return job
    }
    
    public func postConfirm() throws -> Job {
        let params = Params()
        let request = SessionJobRequest(stage: Stage.confirm, params: params)
        let job = try Utils.retryWithBackoff(withRetries: 3, operation: {
            return try API.jobSession(request: request, token: self.token)
        })
            
        self.token = job.token
        return job
    }

    public func postAuthenticate(id: String, userPhoto: String) throws -> AuthenticateResult{
        let request = AuthenticateRequest(id: id, userPhoto: userPhoto)
        let job = try Utils.retryWithBackoff(withRetries: 3, operation: {
            return try API.authenticate(request: request)
        })
        return job
    }
}
