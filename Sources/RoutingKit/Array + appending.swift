import Foundation

extension Array {
    func appending(newElement: Element) -> Self {
        return self.appending(contentsOf: [newElement])
    }
    
    func appending(contentsOf: [Element]) -> Self {
        var copy = self
        copy.append(contentsOf: contentsOf)
        return copy
    }
}
