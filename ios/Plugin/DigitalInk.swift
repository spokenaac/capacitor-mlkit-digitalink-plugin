import Foundation

@objc public class DigitalInk: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
