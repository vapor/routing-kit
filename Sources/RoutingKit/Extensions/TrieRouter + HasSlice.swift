import Foundation

extension TrieRouter {
    
    /// Iterates through all the slices in the trie looking for a constant slice named as the parameter.
    /// 
    /// - Parameter named: The name of the slice to find in the trie.
    /// - Parameter rootPath: The root of the subtree where to look for the specified slice.
    ///
    /// - Returns: `true` if the slice is found in the subtree of the specified root, `false` otherwise.
    ///
    /// - Complexity: **Time:** O(V) where V is the number of path components in the subtree rooted in `rootPath`. **Memory:** O(1)
    public func hasSlice(named: String, rootPath: [String] = []) -> Bool {
        var sliceFound: Bool = false
        
        let currentNode = self.nodeForPath(rootPath)
        guard let currentNode = currentNode else {
            self.logger.debug("Attempted to find slice inside subtree of \(rootPath), but this root is not a registered route.")
            return false
        }
        
        do {
            try self.traverse(
                rootNode: currentNode,
                path: rootPath
            ) { absolutePath, output in
                guard let slice = absolutePath.last else { return }
                if slice == named {
                    sliceFound = true
                    throw HasSliceError.interruptSearch(reason: "slice found")
                }
            }
        } catch {
            return true
        }
        
        return sliceFound
    }
    
    private enum HasSliceError: Error {
        case interruptSearch(reason: String)
    }
}
