//
//  APITests.swift
//  Vouched_Tests
//
//  Created by John Cao on 7/25/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import VouchedCore

class UtilsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testImageToBase64() throws {
        if let idImage = UIImage(named:"oh-id.png"){
            let idStr = Utils.imageToBase64(image: idImage)
            XCTAssertEqual(idStr == nil, false)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
