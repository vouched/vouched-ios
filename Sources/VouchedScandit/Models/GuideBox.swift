import Foundation

public struct ScanditGuideBox: Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        precondition(width >= 0.0 && width <= 1.0, "Width must be between 0.0 and 1.0")
        precondition(height >= 0.0 && height <= 1.0, "Height must be between 0.0 and 1.0")
        self.width = width
        self.height = height
    }
}
