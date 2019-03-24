/// An object that can quickly lookup previously registered routes.
///
/// See `TrieRouter` for concrete implementation.
public protocol Router {
    /// Type of value stored in routes. This will be returned by the router.
    associatedtype Output
    
    /// The route prefix that exists for this router. If route prefix was [.constant("user"), .parameter("id")], this router could only register routes that start with "/user/:id"
    var prefix: [PathComponent] { get }
    
    /// Routers build route prefixes, but still need to register with their base router
    var baseRouter: TrieRouter<Output>? { get }
    
    /// Registers a new `Route` to the `Router`.
    ///
    /// Extraneous information such as `userInfo` may be discarded.
    mutating func register(route: Route<Output>)
    
    /// Fetches output for a specific route.
    ///
    /// `PathComponent.parameter` values will be stored in the supplied `Parameters`
    /// container during routing.
    ///
    /// If no matching route is found, `nil` is returned.
    ///
    /// - parameters:
    ///     - path: Raw path segments.
    ///     - parameters: Will collect dynamic parameter values.
    /// - returns: Output of matching route, if found.
    func route(path: [String], parameters: inout Parameters) -> Output?
}
