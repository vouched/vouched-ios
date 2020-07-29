
import Foundation
import Vouched

@available(iOS 11.0, *)

public enum Type: String, Codable{
   case idv = "id-verification"
}
public enum Stage: String, Codable{
    case start = "init"
    case id
    case face = "face_match"
    case confirm
}
public struct PhotoInfo: Codable {
    var width: Float?
    var height: Float?
    var exif: String?
    var created: String?
    var type: String?
    var modified: String?
    var size: Float?
    var name: String?
    public init(width:Float?, height: Float?, exif: String?, created: String?,
        type: String?, modified: String?, size: Float?, name: String?){
        self.width = width
        self.height = height
        self.exif = exif
        self.created = created
        self.type = type
        self.modified = modified
        self.size = size
        self.name = name
    }
}
public struct Property: Codable  {
    var name: String
    var value: String
    public init(name:String, value: String){
        self.name = name
        self.value = value
    }
}

public struct Confidence: Codable  {
    public var nameMatch: Float?
    public var idMatch: Float?
    public var faceMatch: Float?
    public var idQuality: Float?
}

public struct JobResult: Codable  {
    public var success: Bool
    public var successWithSuggestion: Bool?
    public var type: String?
    public var id: String?
    public var firstName: String?
    public var lastName: String?
    public var issueDate: String?
    public var expireDate: String?
    public var country: String?
    public var state: String?
    public var confidences: Confidence
}

public struct Job: Codable  {
    public var id: String
    public var token: String
    public var result: JobResult
}

public struct Params: Codable{
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var birthDate: String?
    var idPhoto: String?
    var idPhotoInfo: PhotoInfo?
    var userPhotoInfo:PhotoInfo?
    var userPhoto: String?
    var properties: [Property]?

    enum CodingKeys: String, CodingKey {
        case birthDate = "dob"
        case firstName
        case lastName
        case email
        case phone
        case idPhoto
        case idPhotoInfo
        case userPhotoInfo
        case userPhoto
        case properties
    }
    public init(firstName:String? = nil, lastName: String? = nil, email: String? = nil, phone: String? = nil, birthDate: String? = nil,
        idPhotoInfo: PhotoInfo? = nil, userPhotoInfo: PhotoInfo? = nil, idPhoto: String? = nil, userPhoto: String? = nil,
        properties: [Property]? = nil){
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.birthDate = birthDate
        self.idPhotoInfo = idPhotoInfo
        self.userPhotoInfo = userPhotoInfo
        self.idPhoto = idPhoto
        self.userPhoto = userPhoto
    }
}
public struct SessionJobRequest: Codable {
    var type: Type
    var jobConfigId: String?
    var callBackURL: String?
    var stage: Stage
    var params: Params?
    public init(type:Type = Type.idv, callBackURL: String? = nil, stage: Stage, params: Params? = nil, jobConfigId: String?=nil){
        self.type = type
        self.jobConfigId = jobConfigId
        self.callBackURL = callBackURL
        self.stage = stage
        self.params = params
    }
}
public enum APIError: Error {
    case invalidURL(url: String)
    case invalidRequest()
    case invalidAPIKey()
    case connectionError()
    case serverError()
    case invalidConfig(property: String)
}
public class API {
    public static func jobSession(request:SessionJobRequest, token: String?=nil) throws -> Job {
        var request = request
        let rest = RestManager()
        request.jobConfigId = "__token_no_review__"
        do{
            let config = try Config()
            rest.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
            if token != nil{
                rest.requestHttpHeaders.add(value: token!, forKey: "x-session-token")
            }
            let jsonData = try! JSONEncoder().encode(request)
            
            
            rest.httpBody = jsonData
            rest.requestHttpHeaders.add(value: config.API_KEY!, forKey: "x-api-public-key")

            guard let apiURL = config.API_URL else { throw APIError.invalidConfig(property:"API_URL") }
            var urlStr = "\(config.API_URL!)/api/jobs/session"
            guard let url = URL(string: urlStr) else { throw APIError.invalidURL(url:urlStr) }

            guard let results = rest.makeRequest(toURL: url,  withHttpMethod: .post) else { throw APIError.serverError() }
            rest.requestHttpHeaders.add(value: config.API_KEY!, forKey: "x-api-public-key")
            let httpStatusCode = results.response?.httpStatusCode
 
            switch httpStatusCode{
                case 0: throw APIError.connectionError()
                case 500: throw APIError.serverError()
                case 401: throw APIError.invalidAPIKey()
                case 400: throw APIError.invalidRequest()
                default: break;
            }

            if let data = results.data {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
                    throw APIError.serverError()
                }
                let decoder = JSONDecoder()
                guard let job = try? decoder.decode(Job.self, from: data) else { throw APIError.serverError()}
                return job
            } else{
                throw APIError.serverError()
            }
            
        }catch{
            throw error
        }
    }
}
