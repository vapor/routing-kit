import Foundation

extension TrieRouter {
    
    /// Compares the constant routes of this router with the routes of another trie.
    ///
    /// - parameter otherTrie: The trie to compare against
    /// - Returns: `true` if both tries share the same sets of routes with an associated output, `false` otherwise
    ///
    /// - Complexity: **Time:** Let V = max(V1, V2) and b = max(b1, b2), then the time complexity
    /// is O(V⋅b⋅log(b)) to sort the routes of both tries, O(V) to compare the routes. **Memory:**  O(V).
    internal func sharesRoutes<RHSOutput>(with otherTrie: TrieRouter<RHSOutput>) -> Bool {
        
        let myRoutes = self.mapBFS { nextNodes in
            return nextNodes.sorted { lhs, rhs in
                return lhs.getAbsolutePath() <= rhs.getAbsolutePath()
             }
        } _: { absolutePath, output in
            return absolutePath
        }
        
        let otherRoutes = otherTrie.mapBFS { nextNodes in
            return nextNodes.sorted { lhs, rhs in
                return lhs.getAbsolutePath() <= rhs.getAbsolutePath()
             }
        } _: { absolutePath, output in
            return absolutePath
        }
        
        return myRoutes == otherRoutes
    }
    
    /// Concatenates two routers with the same set of routes in a single new router, as specified by the parameters.
    /// If that's not possible because the sets of routes don't match, `nil` is returned.
    ///
    /// - Parameter to: The router to concatenate `self` with.
    /// - Parameter transform: An escaping closure that maps the outputs of the two routers to the output of the new router.
    ///
    /// - Complexity: **Time:** O(V⋅b⋅log(b)) to assert that the operation is valid. **Memory:** O(V).
    public func zip<RHSOutput, ZippedOutput>(
        to other: TrieRouter<RHSOutput>,
        _ transform: @escaping (_ absolutePath: [String], _ lhsOutput: Output, _ rhsOutput: RHSOutput) throws -> ZippedOutput
    ) rethrows -> TrieRouter<ZippedOutput>? {
        guard self.sharesRoutes(with: other) else { return nil }
        
        let outputRouter = TrieRouter<ZippedOutput>()
        
        try self.forEach { absolutePath, output in
            var params = Parameters()
            guard let otherOutputForThisPath = other.route(path: absolutePath, parameters: &params) else {
                self.logger.error("sharesRoutes(_:) failed to detect that this router and the parameter router don't share the same routes. Please report to github:NickTheFreak97")
                fatalError()
            }
            
            let absolutePathOfConstants = absolutePath.map { pathComponent in
                return PathComponent.constant(pathComponent)
            }
            
            outputRouter.register(try transform(absolutePath, output, otherOutputForThisPath), at: absolutePathOfConstants)
        }
        
        return outputRouter
    }
    
}

