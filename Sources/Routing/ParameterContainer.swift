/// A bag for holding parameters resolved during router
public protocol ParameterContainer: class {
    /// The parameters, not yet resolved
    /// so that the `.next()` method can throw any errors.
    var parameters: [ParameterValue] { get set }
}

/// MARK: Next

extension Array where Element == ParameterValue {
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
        guard count > 0 else {
            throw RoutingError(identifier: "next", reason: "Insufficient parameters.")
        }

        let current = self[0]
        guard current.slug == P.routingSlug else {
            throw RoutingError(identifier: "nextType", reason: "Invalid parameter type: \(P.routingSlug) != \(current.slug)")
        }

        let item = try P.resolveParameter(current.value, on: container)
        self = Array(dropFirst())
        return item
    }
}
