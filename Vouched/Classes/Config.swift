

import Foundation

enum ConfigError: Error {
    case MissingAPIKey()
}
@available(iOS 11.0, *)
public class Config {
    public var API_URL: String? = nil
    public var API_KEY: String? = nil

    public init() throws {
        if let value = ProcessInfo.processInfo.environment["API_URL"] {
            API_URL=value
        }else{
            API_URL="https://verify.vouched.id"
        }
        if let value = ProcessInfo.processInfo.environment["API_KEY"] {
            API_KEY=value
        }else{
            throw ConfigError.MissingAPIKey()
        }
    }
    
 

}
