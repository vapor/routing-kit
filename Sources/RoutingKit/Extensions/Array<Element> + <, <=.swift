import Foundation

extension Array where Element: Comparable {
    
    internal static func < (lhs: Array<Element>, rhs: Array<Element>) -> Bool {
        let minSize = Swift.min(lhs.count, rhs.count)
        
        for i in 0..<minSize {
            if lhs[i] < rhs[i] {
                return true
            } else {
                if lhs[i] > rhs[i] {
                    return false
                }
            }
        }
        
        return lhs.count < rhs.count
    }
    
    internal static func <= (lhs: Array<Element>, rhs: Array<Element>) -> Bool {
        let minSize = Swift.min(lhs.count, rhs.count)
        
        for i in 0..<minSize {
            if lhs[i] < rhs[i] {
                return true
            } else {
                if lhs[i] > rhs[i] {
                    return false
                }
            }
        }
        
        return lhs.count <= rhs.count
    }
    
}
