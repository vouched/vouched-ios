import Foundation
import UIKit

public struct ScanditCapturedImage: Sendable {
    public let data: Data
    public let width: Int
    public let height: Int
    public let format: String
    public let nativeData: UIImage?

    public init(data: Data, width: Int, height: Int, format: String = "JPEG", nativeData: UIImage? = nil) {
        self.data = data
        self.width = width
        self.height = height
        self.format = format
        self.nativeData = nativeData
    }
}
