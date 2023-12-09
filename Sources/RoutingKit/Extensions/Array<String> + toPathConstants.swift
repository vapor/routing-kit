import Foundation

extension Array where Element == String {
    public func toPathConstants() -> [PathComponent] {
        return self.map { pathComponent in
            return .constant(pathComponent)
        }
    }
}
