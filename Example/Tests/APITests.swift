
import XCTest
import Vouched

enum APITestsError: Error {
    case invalidImage(image: String)
}


class APITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testJobSession() throws {
        guard let idImage = UIImage(named:"oh-id.png")else{ throw APITestsError.invalidImage(image:"oh-id.png")}
        guard let userImage = UIImage(named:"oh-selfie.jpeg")else{ throw APITestsError.invalidImage(image:"oh-selfie.jpeg")}
        let idPhoto:String? = Utils.imageToBase64(image: idImage)
        let userPhoto:String? = Utils.imageToBase64(image: userImage )
        do {
            var params = Params(idPhoto: idPhoto)
            // id submit
            var request = SessionJobRequest(stage: Stage.id, params: params)
            var job = try API.jobSession(request: request)
            
            params = Params(userPhoto: userPhoto )
            // selfie submit + face rec
            request = SessionJobRequest(stage: Stage.face, params: params)
            job = try API.jobSession(request: request, token: job.token)

            // confirm
            params = Params()
            request = SessionJobRequest(stage: Stage.confirm, params: params)
            job = try API.jobSession(request: request, token: job.token)
            
            let result: JobResult = job.result
            let confidence: Confidence = job.result.confidences

            XCTAssertEqual(result.firstName!, "THOR THUNDER")
            XCTAssertEqual(result.lastName!, "ODINSON")
            XCTAssertEqual(result.state, "OH")
            XCTAssertEqual(result.country, "US")
            XCTAssertEqual(result.issueDate, "06/01/2013")
            XCTAssertEqual(result.expireDate, "06/22/2018")
            
            XCTAssert(confidence.nameMatch == nil)
            XCTAssert(confidence.idMatch == nil)
            XCTAssertEqual(confidence.faceMatch!, 0.9473, accuracy: 0.1)
            XCTAssertEqual(confidence.idQuality!, 0.9006, accuracy: 0.1)

        } catch {
            throw error
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
