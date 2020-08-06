

import Foundation

enum ConfigError: Error {
    case MissingAPIKey()
}
@available(iOS 11.0, *)
func getValue(key:String)-> String?{
    let v = Bundle.main.infoDictionary?[key] as? String
    if v == "" {
        return nil
    }
    return v
}
public class Config {
    public var API_URL: String? = nil
    public var API_KEY: String? = nil

    public init() throws {
//        if let value = ProcessInfo.processInfo.environment["API_URL"] {
        if let value = getValue(key:"API_URL") {
            API_URL = value
        }else{
            API_URL = "https://verify.vouched.id"
        }
        if let value = getValue(key:"API_KEY") {
            API_KEY = value
        }else{
            throw ConfigError.MissingAPIKey()
        }
    }
    
 

}
