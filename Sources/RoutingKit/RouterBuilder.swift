/// A protocol for building routers by registering routes with their associated outputs.
///
/// `RouterBuilder` provides a common interface for accumulating route registrations
/// and building them into a complete router.
public protocol RouterBuilder: Sendable {
    /// Type of value stored in routes.
    associatedtype Output

    /// The `Router` that gets built by this builder.
    associatedtype Router: RoutingKit.Router

    /// Registers a new `Output` to the `RouterBuilder` at a given path.
    ///
    /// - Parameters:
    ///   - output: Output to register.
    ///   - path: Path to register output at.
    mutating func register(_ output: Output, at path: [PathComponent]) throws

    /// Constructs a new ``Router`` based on the routes registered to this builder.
    func build() -> Router
}
