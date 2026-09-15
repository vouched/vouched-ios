import Foundation

public struct ScanditDocumentCaptureResult: Sendable {
    public let image: ScanditCapturedImage
    public let distanceImage: ScanditCapturedImage?
    public let documentRectangle: ScanditDocumentRectangle
    public let score: Double?
    public let guideBox: ScanditGuideBox?

    public init(
        image: ScanditCapturedImage,
        distanceImage: ScanditCapturedImage? = nil,
        documentRectangle: ScanditDocumentRectangle,
        score: Double? = nil,
        guideBox: ScanditGuideBox? = nil
    ) {
        self.image = image
        self.distanceImage = distanceImage
        self.documentRectangle = documentRectangle
        self.score = score
        self.guideBox = guideBox
    }
}
