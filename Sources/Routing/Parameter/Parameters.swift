/// Holds resolved `Parameter` values that are discovered while routing.
///
/// After this struct has been filled with parameter values, you can use it
/// to fetch them out in order using the `next(...)` method.
///
///     let id = parameters.next(Int.self)
///
public struct Parameters {
    /// The stored `ParameterValue`s. These can be converted into their associated `Parameter`s
    /// using the `next(...)` method.
    ///
    ///     let id = parameters.next(Int.self)
    ///
    public var values: [ParameterValue]

    /// Creates a new `Parameters`. Pass this into the `TrieRouter.route(...)` method to fill with values.
    public init() {
        values = []
    }
    
    /// Gets all parameters from the bag that have the
    /// associated slug.
    ///
    ///     let ids: [String] = parameters["id"]
    ///
    /// - parameters:
    ///   - slug: The slug for the value(s) to fetch.
    ///
    /// - returns: All associated parameter values for the slug.
    public subscript (_ slug: String) -> [String] {
        return self.values.filter { $0.slug == slug }.map { $0.value }
    }
    
    /// Gets all parameters from the bag that have the
    /// associated slug and resolves them.
    ///
    ///     let comments: [Comments.ResolvedParameter] = parameters["comment", as: Comment.self, on: ...]
    ///
    /// - parameters:
    ///   - slug: The slug for the value(s) to fetch.
    ///
    /// - returns: All associated resolved parameter values for the slug.
    public subscript <P>(_ slug: String, as type: P.Type, on container: Container) -> [P.ResolvedParameter] where P: Parameter {
        return self.values.filter { $0.slug == slug }.compactMap { try? P.resolveParameter($0.value, on: container) }
    }
    
    /// Grabs the next parameter from the parameter bag.
    ///
    /// Note: the parameters _must_ be fetched in the order they
    /// appear in the path.
    ///
    /// For example GET /posts/:post_id/comments/:comment_id
    /// must be fetched in this order:
    ///
    ///     let post = try parameters.next(Post.self, on: ...)
    ///     let comment = try parameters.next(Comment.self, on: ...)
    ///
    public mutating func next<P>(_ parameter: P.Type, on container: Container) throws -> P.ResolvedParameter
        where P: Parameter
    {
        guard values.count > 0 else {
            throw RoutingError(identifier: "next", reason: "Insufficient parameters.")
        }

        let current = values[0]
        guard current.slug == P.routingSlug else {
            throw RoutingError(identifier: "nextType", reason: "Invalid parameter type: \(P.routingSlug) != \(current.slug)")
        }

        let item = try P.resolveParameter(current.value, on: container)
        values = Array(values.dropFirst())
        return item
    }
}
