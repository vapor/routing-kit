import Foundation

extension TrieRouter {
    
    /// Merges this router to another router according to the specified `transform`.
    ///
    /// Unlike `zip`, this method doesn't require that the two routers have the same sets of constant routes. Though, at any
    /// time it is guaranteed that at least one between `lhsOutput` and `rhsOutput` is not nil.
    ///
    /// - Complexity: **Time:** if V = max(lhs.V, rhs.V), d = max(lhs.d, rhs.d), the time complexity is O(V⋅Set<[String]>.insert.cost(d)). 
    /// **Memory:** O(V) for the allocated output router.
    public func merge<RHSOutput, MergedOutput>(
        to other: TrieRouter<RHSOutput>,
        _ transform: @escaping (_ absolutePath: [String], _ lhsOutput: Output?, _ rhsOutput: RHSOutput?) throws -> MergedOutput
    ) rethrows -> TrieRouter<MergedOutput> {
        var allRoutesSet = Set<[String]>()
        
        self.forEach { absolutePath, _ in
            allRoutesSet.insert(absolutePath)
        }
        
        other.forEach { absolutePath, _ in
            allRoutesSet.insert(absolutePath)
        }
 
        let outputRouter = TrieRouter<MergedOutput>()
        
        for path in allRoutesSet {
            var lhsParams = Parameters()
            var rhsParams = Parameters()
            
            let lhsOutput = self.route(path: path, parameters: &lhsParams)
            let rhsOutput = other.route(path: path, parameters: &rhsParams)
            
            outputRouter.register(
                try transform(path, lhsOutput, rhsOutput),
                at: path.toPathConstants()
            )
        }

        return outputRouter
    }
}
