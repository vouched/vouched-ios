

import Foundation

public class RestManager {
    
    // MARK: - Properties
    
    var requestHttpHeaders = RestEntity()
    
    var urlQueryParameters = RestEntity()
    
    var httpBodyParameters = RestEntity()
    
    var httpBody: Data?
    
    
    // MARK: - Public Methods
    
    public init() {}
    public func makeRequest(toURL url: URL,
                     withHttpMethod httpMethod: HttpMethod) -> Results? {
        
        let group = DispatchGroup()
        group.enter()
        var results: Results? = nil
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targetURL = self?.addURLQueryParameters(toURL: url)
            let httpBody = self?.getHttpBody()
            
            guard let request = self?.prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod) else
            {
                results = Results(withError: CustomError.failedToCreateRequest)
                group.leave()
                return
            }
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: request) { (data, response, error) in
//                let json = String(decoding: data!, as: UTF8.self)
//                print("restman:::\(json)")

                results = Results(withData: data,
                                   response: Response(fromURLResponse: response),
                                   error: error)
                group.leave()
            }
            task.resume()
           
        }
        group.wait()    
        return results
    }
    
    
    
    public func getData(fromURL url: URL, completion: @escaping (_ data: Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
                guard let data = data else { completion(nil); return }
                completion(data)
            })
            task.resume()
        }
    }
    
    
    
    // MARK: - Private Methods
    
    private func addURLQueryParameters(toURL url: URL) -> URL {
        if urlQueryParameters.totalItems() > 0 {
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            var queryItems = [URLQueryItem]()
            for (key, value) in urlQueryParameters.allValues() {
                let item = URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                
                queryItems.append(item)
            }
            
            urlComponents.queryItems = queryItems
            
            guard let updatedURL = urlComponents.url else { return url }
            return updatedURL
        }
        
        return url
    }
    
    
    
    private func getHttpBody() -> Data? {
        // guard let contentType = requestHttpHeaders.value(forKey: "Content-Type") else { return nil }
        
        // if contentType.contains("application/json") {
        //     return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(), options: [.prettyPrinted, .sortedKeys])
        // } else if contentType.contains("application/x-www-form-urlencoded") {
        //     let bodyString = httpBodyParameters.allValues().map { "\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
        //     return bodyString.data(using: .utf8)
        // } else {
        return httpBody
        // }
    }
    
    
    
    private func prepareRequest(withURL url: URL?, httpBody: Data?, httpMethod: HttpMethod) -> URLRequest? {
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        for (header, value) in requestHttpHeaders.allValues() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        request.httpBody = httpBody
        return request
    }
}


// MARK: - RestManager Custom Types




public struct RestEntity {
    private var values: [String: String] = [:]
    
    mutating func add(value: String, forKey key: String) {
        values[key] = value
    }
    
    func value(forKey key: String) -> String? {
        return values[key]
    }
    
    func allValues() -> [String: String] {
        return values
    }
    
    func totalItems() -> Int {
        return values.count
    }
}
public struct Response {
    public var response: URLResponse?
    public var httpStatusCode: Int = 0
    public var headers = RestEntity()
    
    init(fromURLResponse response: URLResponse?) {
        guard let response = response else { return }
        self.response = response
        httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        
        if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields {
            for (key, value) in headerFields {
                headers.add(value: "\(value)", forKey: "\(key)")
            }
        }
    }
}
public struct Results {
    public var data: Data?
    public var response: Response?
    public var error: Error?
    
    init(withData data: Data?, response: Response?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
    
    init(withError error: Error) {
        self.error = error
    }
}

public extension RestManager {
    enum HttpMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }

    
    
    
    
    
    
    
    
    
    enum CustomError: Error {
        case failedToCreateRequest
    }
}


// MARK: - Custom Error Description
extension RestManager.CustomError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest: return NSLocalizedString("Unable to create the URLRequest object", comment: "")
        }
    }
}
