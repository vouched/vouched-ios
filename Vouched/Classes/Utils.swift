

import Foundation

@available(iOS 11.0, *)
public class Utils {
    public static func imageToBase64(image: UIImage )->String? {
        let jpegCompressionQuality: CGFloat = 0.9 // Set this to whatever suits your purpose
        if let base64String = UIImageJPEGRepresentation(image, jpegCompressionQuality)?.base64EncodedString() {
       // if let base64String = image.jpegData(compressionQuality: jpegCompressionQuality) )?.base64EncodedString() {
            return base64String
        }
        return nil
    }
}
