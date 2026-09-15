import Foundation

public struct ScanditPoint: Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct ScanditBoundingBox: Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        precondition(x >= 0.0 && x <= 1.0, "x must be between 0.0 and 1.0")
        precondition(y >= 0.0 && y <= 1.0, "y must be between 0.0 and 1.0")
        precondition(width >= 0.0 && width <= 1.0, "width must be between 0.0 and 1.0")
        precondition(height >= 0.0 && height <= 1.0, "height must be between 0.0 and 1.0")
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct ScanditDocumentRectangle: Sendable {
    public let corners: [ScanditPoint]
    public let boundingBox: ScanditBoundingBox

    public init(corners: [ScanditPoint], boundingBox: ScanditBoundingBox) {
        precondition(corners.count == 4, "Document rectangle must have exactly 4 corners")
        self.corners = corners
        self.boundingBox = boundingBox
    }
}
