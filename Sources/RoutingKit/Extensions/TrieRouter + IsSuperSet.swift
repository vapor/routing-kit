import Foundation
import Logging

extension TrieRouter {
    /// Tests whether or not this trie's (constant) registered routes are a superset of all the (constant) registered routes in `other`.
    ///
    /// - Parameter other: The supposed subset of `self`.
    /// - Returns: `true` if all the (constant) routes in `other` with an associated output, also have an associated output in `self`. `false` otherwise.
    ///
    /// - Complexity: **Time:** O(V) assuming `d << V`. **Memory:** O(1).
    public func isSuperSet<OtherOutput>(of other: TrieRouter<OtherOutput>) -> Bool {
        do {
            try other.forEach { absolutePath, _ in
                var params = Parameters()
                let outputOfSelf = self.route(path: absolutePath, parameters: &params)
                
                if outputOfSelf == nil {
                    throw SearchError.interruptSearch
                }
            }
        } catch SearchError.interruptSearch {
            return false
        } catch {
            self.logger.critical("This path should be unfeasible in \(#file): \(#function); please report to github:NickTheFreak97.")
            fatalError()
        }
        
        return true
    }
}

fileprivate enum SearchError: Error {
    case interruptSearch
}
