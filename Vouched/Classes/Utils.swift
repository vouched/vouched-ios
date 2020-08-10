

import Foundation

enum RetryError: Error {
    case retryCountOutOfBounds
}

@available(iOS 11.0, *)
public class Utils {
    
    private static let fibonacci: [Int] = [1, 1, 2, 3, 5, 8]

    public static func imageToBase64(image: UIImage )->String? {
        let jpegCompressionQuality: CGFloat = 0.9
        if let base64String = UIImageJPEGRepresentation(image, jpegCompressionQuality)?.base64EncodedString() {
            return base64String
        }
        return nil
    }
    
    // executes the operation with retries
    // the retries are executed using fibonacci backoffs
    static func retryWithBackoff<T>(withRetries retryCount: Int,
                                    operation: () throws -> T,
                                    withMillisecondWaitTime time: Int = 500,
                                    executionCount: Int = 0) throws -> T {
        if retryCount > 6 {
            throw RetryError.retryCountOutOfBounds
        }
        do {
            return try operation()
        } catch {
            if executionCount == retryCount {
                throw error
            } else {
                usleep(useconds_t(Utils.fibonacci[executionCount] * time * 1000))
                return try retryWithBackoff(withRetries: retryCount, operation: operation, withMillisecondWaitTime: time, executionCount: executionCount+1)
            }
        }
    }
}

struct Stack<T> {
    var items: [T]
    
    init(_ items: [T] = []) {
        self.items = items
    }
    
    mutating func push(_ item: T) {
        items.append(item)
    }
    mutating func pop() -> T {
        return items.removeLast()
    }
    func peek() -> T {
        items.last!
    }
    func isEmpty() -> Bool {
        items.isEmpty
    }
}
