//
//  RestManagerTests.swift
//  Vouched_Tests
//
//  Created by John Cao on 7/25/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import Vouched

public struct Users: Decodable {
    let page: Int
    let per_page: Int
    let total: Int
    let total_pages: Int
    var data : [User] 
}
public struct User: Decodable {
    let id: Int
    let email: String 
    let first_name: String
    let last_name: String
    let avatar: URL
}
enum RestManagerTestsError: Error {
    case invalidUrl
    case invalidRequest
}

class RestManagerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }

    override func tearDownWithError() throws {
        // FaceDetect
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRestManager() throws {

        let rest = RestManager()
    
        guard let url = URL(string: "https://reqres.in/api/users") else { throw RestManagerTestsError.invalidUrl }
        guard let results = rest.makeRequest(toURL: url, withHttpMethod: .get) else { throw RestManagerTestsError.invalidRequest }
        let httpStatusCode = results.response?.httpStatusCode
        XCTAssertEqual(httpStatusCode, 200)
        if let data = results.data {
            let decoder = JSONDecoder()
            guard let users = try? decoder.decode(Users.self, from: data) else { return }
            XCTAssertEqual(users.data[0].id, 1)
        } else{
            XCTAssertEqual(false,true)
        }
    }

    func testPerformanceExample() throws {
        self.measure {
        }
    }

}
