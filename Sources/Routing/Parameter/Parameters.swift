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
    public mutating func next<P>(_ parameter: P.Type) throws -> P.ResolvedParameter
        where P: Parameter
    {
        guard values.count > 0 else {
            throw RoutingError(identifier: "next", reason: "Insufficient parameters.")
        }

        let current = values[0]
        guard current.slug == P.routingSlug else {
            throw RoutingError(identifier: "nextType", reason: "Invalid parameter type: \(P.routingSlug) != \(current.slug)")
        }

        let item = try P.resolveParameter(current.value)
        values = Array(values.dropFirst())
        return item
    }
}
