/// A route that can be registered to the `TrieRouter`.
///
/// This contains a collection of `PathComponent`s, the path, and an output.
/// The route's path defines how it will match paths passed to `TrieRouter.route(...)`.
///
/// `Route` is also `Extendable` and every route registered to the router is stored.
/// This allows you to attach aribtrary metadata to each route and retrieve it later.
public final class Route<Output> {
    /// Defines this route's dynamic path and how it will match paths
    /// passed to `TrieRouter.route(...)`.
    public var path: [PathComponent]
    
    /// This will be returned by `TrieRouter.route(...)` if this route matches.
    public var output: Output
    
    /// A storage place to extend the `Route` with.
    /// Can store metadata like documentation route descriptions.
    public var userInfo: [AnyHashable: Any]
    
    /// Creates a new `Route`.
    ///
    /// - parameters:
    ///     - path: Defines this route's dynamic path and how it will match paths
    ///             passed to `TrieRouter.route(...)`.
    ///     - output: This will be returned by `Router.route(...)` if this route matches.
    public init(path: [PathComponent], output: Output) {
        self.path = path
        self.output = output
        self.userInfo = [:]
    }
}
