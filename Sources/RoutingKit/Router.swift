/// An object that can quickly lookup previously registered routes.
///
/// See `TrieRouter` for concrete implementation.
public protocol Router {
    /// Type of value stored in routes. This will be returned by the router.
    associatedtype Output
//    associatedtype BaseRouterType: Router
    
    var prefix: [PathComponent] { get }
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
